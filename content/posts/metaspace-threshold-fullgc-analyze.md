---
title: "Metaspace 堆积引起 Full GC 的排查"
date: 2021-03-10T23:19:09+08:00
tag: JVM
---

> 摘要：线上系统频繁 Full GC，通过监控告警、GC 日志、Heap 分析，逐步定位根因，并确定修复思路。

<!-- more -->

# 问题现象

支付服务异地部署前，需要提前打开北京、上海两地单元间数据副本的双向复制，以及存在互备关系的数据副本间的核对。当核对任务开启后，loader 模块却频繁发生 Full GC。

![](/images/689195193.png)

公司的 CAT 监控：

![](/images/689270418.png)

从上面 GC 监控图可以观察到，FGC 在各服务节点上都存在，且集中发生在当前小时的前十几分钟，而这也是核对任务开始调度执行的时间段。

# 分析排查

## 初步分析

发生 FGC 首先想到的是老年代使用空间超限，下图是 FGC 发生时，老年代的使用情况监控：

![](/images/689270419.png)

可以看到，在 FGC 时老年代使用率并不高，处在正常水平，远远没有到达触发 FGC 的阈值。loader 模块的 jvm 主要参数有：

```
-Xmx4g
-Xms4g
-XX:NewRatio=2
-XX:SurvivorRatio=8
-XX:PermSize=128m
-XX:MaxPermSize=256m
-XX:+PrintFlagsFinal
-XX:+PrintCommandLineFlags
-XX:+DisableExplicitGC
-XX:+UseConcMarkSweepGC
-XX:CMSFullGCsBeforeCompaction=0
-XX:+UseCMSCompactAtFullCollection
-XX:CMSInitiatingOccupancyFraction=70
-XX:+PrintGCDateStamps
-XX:+PrintGCDetails
-XX:+PrintGCTimeStamps
-XX:+PrintHeapAtGC
-XX:+PrintGCApplicationStoppedTime
-XX:+PrintTenuringDistribution
-XX:+HeapDumpOnOutOfMemoryError
-XX:+UseCMSInitiatingOccupancyOnly
-XX:MaxMetaspaceSize=256m
-XX:MetaspaceSize=128m
```

由此根因可以排除老年代增长过快导致 FGC。

## GC 日志分析

选择一台主机，查看 GC 日志，直接定位 `Full GC` 关键字。

![](/images/689197960.png)

从日志中明确了引起 FGC 的原因是触发了 Metadata GC Threshold，且 vim 中匹配了 12 次，即由于 metadata 堆积引起了 12 次 FGC。

回到 JVM 监控上查看 meta 区监控：

![](/images/689197961.png)

FGC 和 metaspace 区使用上涨的时间点是重合的，从监控上也反映出了 gc 日志中的信息。

到这，问题的直接原因已经确认，就是由于 meta 区暴涨引起频繁 FGC。

## 根因定位

接下来就需要分析是什么原因导致 meta 区被爆。

横向对比旧版的服务模块（engine + loader），老服务的 metaspace 区非常稳定（即使拉长时间区间，metaspace 区变化也非常小）。

![](/images/689197962.png)

而 loader 模块逻辑非常简单，它只提供一个 RPC 接口，由 engine 模块传入数据查询的基本信息，通过 JDBC 执行 SQL。此外，loader 模块很长一段时间都没有变更（有流水线发布，但代码没有变更）。但可以确定的是：线上服务发生稳态的破坏，一定是引入了系统变量。联系最近一周的线上变更动作，有：

- engine 模块调整 SQL 生成方式；
- 新增北京、上海单元副本的核对任务，存量任务配置增加差集数据的过滤脚本；

前者对 loader 的影响只是变更了实际执行的 SQL，因此初步推断相关性低；后者增加的过滤脚本，会在 loader 查询到结果集后，通过 Groovy 解析过滤掉差集数据，这个环节会创建清洗规则 `CleanRule` 的实例，但创建的临时变量会通过 YGC 回收掉，推断相关性也不大。

既然经验分析找不到根因，只能做 dump heap 分析。

## Dump Heap

摘掉一个线上服务节点，dump 堆内存进行分析。考虑到 metaspace 区是用来存储 class 元信息，因此如果要爆掉 metaspace 区，必然是加载了大量 class。直接定位到类标签上，

![](/images/689197963.png)

发现存在大量和 groovy 相关的类，而 loader 中使用到 groovy 的地方，只有上文提到的动态解析过滤规则。接着点开重复类标签，注意到有创建了大量 Script 对象，而且是通过不同的类加载器进行加载……

![](/images/689197964.png)

从上面的 Heap 分析，基本可以得出下面的结论：

1. metaspace 区存储了大量 groovy runtime 创建类的元信息，导致 metaspace 区使用短时间内暴涨；

2. loader 模块动态解析 groovy 脚本，是引起 metaspace 区被爆的诱因；

## 代码分析

下面是 loader 模块中，动态解析 groovy 脚本的代码：

```java
if (StringUtils.isNotEmpty(cleanRule)) {
    dataCleanService.clean(rows, new CleanRule() {
        @Override
        public Boolean apply(Map<String, Object> stringObjectMap) {
            String field = GroovyParser.getField(cleanRule);
            String value = (String) stringObjectMap.get(field);
            if (StringUtils.isNotEmpty(field)) {
                Binding binding = new Binding();
                binding.setVariable(field, value);
                GroovyShell shell = new GroovyShell(binding);
                String command = GroovyParser.genCommand(cleanRule);
                return (Boolean) shell.evaluate(command);
            }
            return true;
        }
    });
}
```

这里创建了 GroovyShell，并执行脚本。进入 `evaluate()` 方法看源码：

```java
protected synchronized String generateScriptName() {
    return "Script" + (++counter) + ".groovy"; // 此处就是 Script1 的由来
}
public Object evaluate(final String scriptText) throws CompilationFailedException {
    return evaluate(scriptText, generateScriptName(), DEFAULT_CODE_BASE);
}
public Object evaluate(GroovyCodeSource codeSource) throws CompilationFailedException {
    Script script = parse(codeSource);
    return script.run();
}
public Script parse(final GroovyCodeSource codeSource) throws CompilationFailedException {
    return InvokerHelper.createScript(parseClass(codeSource), context);
}
private Class parseClass(final GroovyCodeSource codeSource) throws CompilationFailedException {
    // Don't cache scripts
    return loader.parseClass(codeSource, false);
}
public Class parseClass(GroovyCodeSource codeSource, boolean shouldCacheSource) throws CompilationFailedException {
    synchronized (sourceCache) {
        Class answer = sourceCache.get(codeSource.getName());
        if (answer != null) return answer;
        answer = doParseClass(codeSource);
        if (shouldCacheSource) sourceCache.put(codeSource.getName(), answer);
        return answer;
    }
}
private Class doParseClass(GroovyCodeSource codeSource) {
    validate(codeSource);
    Class answer;  // Was neither already loaded nor compiling, so compile and add to cache.
    CompilationUnit unit = createCompilationUnit(config, codeSource.getCodeSource());
    if (recompile!=null && recompile || recompile==null && config.getRecompileGroovySource()) {
        unit.addFirstPhaseOperation(TimestampAdder.INSTANCE, CompilePhase.CLASS_GENERATION.getPhaseNumber());
    }
    SourceUnit su = null;
    File file = codeSource.getFile();
    if (file != null) {
        su = unit.addSource(file);
    } else {
        URL url = codeSource.getURL();
        if (url != null) {
            su = unit.addSource(url);
        } else {
            su = unit.addSource(codeSource.getName(), codeSource.getScriptText());
        }
    }

    ClassCollector collector = createCollector(unit, su);
    unit.setClassgenCallback(collector);
    int goalPhase = Phases.CLASS_GENERATION;
    if (config != null && config.getTargetDirectory() != null) goalPhase = Phases.OUTPUT;
    unit.compile(goalPhase);

    answer = collector.generatedClass;
    String mainClass = su.getAST().getMainClassName();
    for (Object o : collector.getLoadedClasses()) {
        Class clazz = (Class) o;
        String clazzName = clazz.getName();
        definePackageInternal(clazzName);
        setClassCacheEntry(clazz);
        if (clazzName.equals(mainClass)) answer = clazz;
    }
    return answer;
}
protected ClassCollector createCollector(CompilationUnit unit, SourceUnit su) {
    InnerLoader loader = AccessController.doPrivileged(new PrivilegedAction<InnerLoader>() {
        public InnerLoader run() {
            return new InnerLoader(GroovyClassLoader.this);
        }
    });
    return new ClassCollector(loader, unit, su);
}
```

上面的源码，我按调用栈依次粘贴，比较乱。可以直接看最后一个方法：

![](/images/689461704.png)

注意到，每次执行 `evaluate` 方法时，都会创建一个新的 `ClassCollector` 实例来对脚本进行编译，这个过程中，在 `createCollector` 方法中，创建了 `InnerLoader` 类加载器。这也是为什么从上面的 heap 分析中，观察到大量通过 `GroovyClassLoader$InnerLoader` 加载的同名类 `Script1.class`。正是因为 `InnerLoader` 类加载器的存在，可以运行时创建 Groovy 脚本的多个类。

# 场景复现和修复

通过源码基本定位根因，实现一个 demo 简单复现下故障场景。

```java
public class MetaLeak {

    public void loop() {
        String rule = "[\"hello\",\"world\"].contains(text)";
        Binding binding = new Binding();
        binding.setVariable("text", "hi");
        GroovyShell shell = new GroovyShell(binding);
        shell.evaluate(rule);
    }

    /**
     * -Xms128m
     * -Xmx256m
     * -XX:+HeapDumpOnOutOfMemoryError
     * -XX:MetaspaceSize=10m
     * -XX:MaxMetaspaceSize=20m
     * -XX:+PrintGCDetails
     */
    public static void main(String[] args) {
        MetaLeak demo = new MetaLeak();
        try {
            while (true)
                demo.loop();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

MetaLeak 类是存在 metaspace 区被爆隐患的，因为 for 循环执行时都在加载 `Script` 类。下面是运行过程中的部分 GC 日志：

![](/images/689463877.png)

高频出现 Metadata 被爆导致的 FGC，另外 Last ditch collection 是由于上一次 FGC 没有将 metaspace 区清理出足够空间。

因此，修复思路是规避掉频繁解析规则，即已经解析过的规则，直接复用 Script 实例，不再动态编译加载。

```java
public class MetaSafe {

    private static final Map<String, Script> store = new ConcurrentHashMap<>();
    private static final GroovyShell SHELL = new GroovyShell();

    static {
        SHELL.getContext().setVariable("text", "123456");
    }

    public void loop() {
        String rule = "[\"hello\",\"world\"].contains(text)";
        if (!store.containsKey(rule)) {
            store.put(rule, SHELL.parse(rule));
        }
        store.get(rule).run();
    }

    /**
     * -Xms128m
     * -Xmx256m
     * -XX:+HeapDumpOnOutOfMemoryError
     * -XX:MetaspaceSize=10m
     * -XX:MaxMetaspaceSize=20m
     * -XX:+PrintGCDetails
     */
    public static void main(String[] args) {
        MetaSafe demo = new MetaSafe();
        try {
            while (true)
                demo.loop();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

运行后，Metaspace 区使用率正常。