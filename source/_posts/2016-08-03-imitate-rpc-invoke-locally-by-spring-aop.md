---
title: Spring AOP 本地模拟线上 RPC
date: 2016-08-03 14:57:22
tags:
  - Spring
categories:
  - Coding
---

成熟的互联网公司内部一般都会有多个线上环境，像在 JD，就有测试环境，预发布环境，生产环境。开发过程通常是现在本地编写代码，功能差不多了提到测试环境，再到预发布联调，测试通过再提交上线包部署到生产环境。但这是理想状况，实际开发中会有上下游系统联调的问题。

<!-- more -->

JD 的项目绝大多数都已经服务化了，服务的提供者和消费者分别在服务中心注册，消费者就能调用服务者的接口。但由于 JD 内部系统繁多，各有不同的开发团队维护各自的项目，除了生产环境和预发布环境能保证各系统间能互联互通，很多情况下，本地运行或在测试环境上运行时，没法调用到服务提供者的接口，这就很尴尬了，因为测试资源的不到位，只能上预发布环境进行上下游系统的对接联调，这是很烦人的，比较好的开发方案是，如果测试环境不完善，就从预发布环境上截取到服务接口的真实数据，把它打包成一个本地的测试数据资源库，以后直接在本地运行就行了。

如何拦截数据？这就需要 AOP 大显身手了。Spring AOP 可以通过 [BeanNameAutoProxyCreatoraaaa](http://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/aop/framework/autoproxy/BeanNameAutoProxyCreator.html) 自动代理目标 bean，属性 `beanNames` 和 `interceptorNames` 分别设置要代理的目标 bean 列表和拦截器数组。这样就很方便的实现了对目标 bean 的切入拦截。

简单说下具体的实现流程：

- 当线上运行时，通过拦截器对目标 bean 内部方法的拦截，将方法调用的结果持久化到结果文件中；
- 当本地运行时，拦截器就不走远程调用，而是直接从结果文件中读取真实的调用结果。

下面给出大致的拦截服务调用数据的代码：

```xml
<!-- spring-aop-config.xml -->
<beans>
  <!-- method interceptor -->
  <bean id="rpcInterceptor" class="com.isudox.utils.RpcInterceptor">
    <property name="mode" value="online"/>
    <property name="fileName" value="/home/sudoz/dev/local-rpc-data.properties"/>
  </bean>
  <!-- auto proxy -->
  <bean id="rpcAutoProxyCreator"
        class="org.springframework.aop.framework.autoproxy.BeanNameAutoProxyCreator">
    <property name="beanNames">
      <list>
        <value>remoteService1</value>
        <value>remoteService2</value>
        <value>remoteService3</value>
        <value>remoteService4</value>
      </list>
    </property>
    <property name="interceptorNames">
      <list>
        <value>rpcInterceptor</value>
      </list>
    </property>
  </bean>
</beans>
```

```java
import org.aopalliance.intercept.MethodInterceptor;
import org.aopalliance.intercept.MethodInvocation;
import com.alibaba.fastjson.JSON;

public class RpcInterceptor implements MethodInteceptors {

    private static final Logger logger = LoggerFactory.getLogger(RpcInterceptor.class);

    private String mode = "local";  // local || online

    private String fileName = "/home/sudoz/dev/local-rpc-data.properties"

    private static File rpcResultFile = null;

    private Properties rpcResultProperties;
    
    public RpcInterceptor() {}

    @Override
    public Object invoke(MethodInvocation invocation) throws Throwable {
        Object result;
        String methodName = invocation.getMethod().getName();
        Class<?> returnType = invocation.getMethod.getReturnType();
        String className = invocation.getMethod().getDeclaringClass().getSimpleName();
        Object[] args = invocation.getArguments();
        
        String key = className + "." + methodName;
        if (StringUtils.equals(getMode(), "local")) {
            String value = rpcResultProperties.getProperty(key);
            if (StringUtils.isNotBlank(value)) {
                result = JSON.parseObject(value, returnType);
            } else {
                result = invocation.proceed();
            }
        } else {
            result = invocation.proceed();
            String value = JSON.toJSONString(result);
            this.appendRpcResult2File(key, value);
        }

        return result;
    }

    public void appendRpcResult2File(String k, String v) {
        try {
            Properties properties = new Properties();
            if (rpcResultFile.exists()) {
                FileInputStream fis = new FileInputStream(rpcResultFile);
                properties.load(fis);
            }
            FileOutputStream fos = new FileOutputStream(rpcResultFile);
            properties.setProperty(k, v);
            properties.store(fos, "blabla...");
            fos.flush();
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("appendRpcResult2File failed, {}", e);
        } finally {
            fos.close();
        }
    }

    public String getMode() {
        return mode;
    }

    public void setMode(String mode) {
        this.mode = mode;
    }

    public String getfileName() {
        return fileName;
    }

    public void setfileName(String fileName) {
        this.fileName = fileName;
    }

}
```

在线上预发布环境跑一次，简单的通过 AOP 就一劳永逸的解决了联调测试的一大困扰。要是线上有一个专门做服务调用数据生成的应用，所有系统和开发人员都能从上面生成真实的测试数据，那就更好了。