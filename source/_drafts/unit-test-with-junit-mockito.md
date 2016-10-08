---
title: Mockito 配合 JUnit 单元测试
tags:
  - Java
categories:
  - Coding
---

[JUnit](http://junit.org/junit4/) 是 2015 年 Java 开发者引用最多的库，是 Java 单元测试框架里无可争议的 No.1。JUnit 基本上能覆盖大部分接口的测试，但如果待测接口依赖外部服务，比如我之前写的这篇[小文](/2016/08/03/imitate-rpc-invoke-locally-by-spring-aop)里描述的情况，JUnit 就可能捉襟见肘了。而 [Mockito](http://mockito.org/) 在 Mock 数据方面功能强大，正好弥补了 JUnit 在这方面的不足。风云合璧，摩诃无量。

<!-- more -->

### JUnit

> PS: 虽然 JUnit5 已经发布，但目前使用最多的还是 JUnit4，所以本文还是以 JUnit4 为准。

利用 Maven 初始化一个简单的 Java 应用：

```shell
mvn archetype:generate -DgroupId=com.isudox -DartifactId=test-demo -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
```

Maven 会自动创建好类文件和测试类，路径如下：

```
test-demo
├── pom.xml       ---- pom 依赖配置文件
└── src           ---- 源码路径
    ├── main      ---- 类文件
    │   └── java
    │       └── com
    │           └── isudox
    │               └── App.java
    └── test      ---- 测试类
        └── java
            └── com
                └── isudox
                    └── AppTest.java
```

在 pom.xml 中引入 JUnit4，

```xml
<dependencies>
  <!-- junit4 -->
  <dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.12</version>
    <scope>test</scope>
  </dependency>
</dependencies>
```



### Mockito


参考资料：
  - [Getting Started with Mocking in Java using Mockit](https://dzone.com/articles/getting-started-mocking-java)