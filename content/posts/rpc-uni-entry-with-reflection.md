---
title: 通过反射统一 RPC 调用入口
date: 2017-02-06 15:18:55
tags:
  - Java
  - RPC
categories:
  - Coding
---

最近项目开发中，有这样一个场景，依赖外部很多服务，每个服务从功能上彼此独立，因此各个外部服务的调用也是相对独立的。因此当时为每个调用都写了一个专属的 Porcessor 去处理服务调用的结果。当然好处就是功能区分清晰，不好的地方就是当 Processor 多了后维护起来不太方便。一种思路就是利用反射思想，为 Processor 中的 RPC 调用添加统一入口，通过服务名和方法名对调用进行定位。

<!-- more -->

代理的思路很简单，但真的非常实用，在实际开发中，合理使用代理，能精简很多固有代码。从代理的统一入口进入，根据传入的远程服务名和方法名，自动定位到需要被远程调用的方法，再传入入参并调用该方法，就能代理过多的 Processor 调用 RPC。

代理入口的代码如下：

```java
@Service(value = "rpcEntry")
public class RpcEntry {
    @Resource
	private Map<String, Object> serviceMap;  // 远程服务的 k-v 映射

    private final Map<String, Method> actions = new HashMap<>();  // 存储方法调用

    public Result process(String invokeStr, Object[] args) {
        String serviceName = methodKey.split("\\.")[0];
        if (!actions.containsKey(invokeStr)) {
            Object service = serviceMap.get(serviceName);
            if (service != null) {
                for (Method m : service.getClass().getMethods()) {
                    actions.put(String.format("%s.%s", serviceName, m.getName()), m);
                }
            }
        }
        Method method = actions.get(invokeStr);  // 定位要调用的方法

        if (method != null) {
            Object service = serviceMap.get(serviceName);
            Object res = method.invoke(service, args);

            // 对调用结果进行自定义处理
        } else {
            log.error(String.format("调用的方法[%s]不存在，请确认。", methodKey));
        }
    }

    return null;
}
```

上面代码中的远程服务映射可以在 Spring 中配置：

```xml
<bean id="serviceMap" class="java.util.HashMap">
  <constructor-arg>
    <map>
      <entry key="example1" value-ref="example1ServiceImpl" />
      <entry key="example2" value-ref="example2ServiceImpl" />
      <entry key="example3" value-ref="example3ServiceImpl" />
    </map>
  </constructor-arg>
</bean>
```

有了统一的调用入口后，如果想调用 example1ServiceImpl.debug() 方法，不需要在专门的 Processor 中进行调用，只需用下面的代码进行调用：

```java
@Resource
private RpcEntry rpcEntry;

public void test() {
    rpcEntry.process("example1.debug", null);
}
```