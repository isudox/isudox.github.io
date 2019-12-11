---
title: Spring Boot 学习笔记 1：起手式 Hello World
tags:
  - Spring
  - Java
categories:
  - Coding
date: 2017-02-10 23:59:24
---


[Spring Boot](https://projects.spring.io/spring-boot/) 是 Pivotal 团队开发的开源 Java Web 框架，相比同门师兄 Spring，Spring Boot 把开发者从繁重的配置中解放出来，遵循“约定大于配置”(convention over configuration)的设计范式。从零搭建 Spring Boot 项目几乎是傻瓜化的，因为框架把大量配置自动完成了。

<!-- more -->

## Spring Initializr 创建空项目

[Spring Initializr](http://start.spring.io/) 是 Spring 官方提供的 Spring Boot 项目初始化工具，为开发者实现一个基本的项目骨架。很多 Java IDE 也集成了这个工具，以 Intellij IDEA 为例，新建项目，选择 Spring Initializr，进入如下组件选择面板

![spring boot dependencies](https://o70e8d1kb.qnssl.com/spring-initializr.png)

其中 Core 包含了像 AOP Cashe 这些核心组件，Web 包含了 SpringMVC Thymeleaf 等 Web 开发组件，还有数据库相关，配置中心相关等一系列组件……因为是 Hello World 程序演示，就不选组件了，直接点下一步，创建空项目。空项目结构如下图。

![spring boot project structure](https://o70e8d1kb.qnssl.com/spring-boot-structure.png)

- `DemonApplication.java`：是应用程序的启动引导类（bootstrap class），也是主要的 Spring 配置类；
- `DemoApplicationTest.java`：集成 JUnit 的测试类；
- `application.properties`：配置应用程序和 Spring Boot 的属性；

OK，到此为止，第一个 Spring Boot 项目就创建完成了！是的，几乎什么都不需要做，一个能编译能运行的 Spring 项目已经搭建好了，真是幸福到泪奔啊~~o(>_<)o~~
但是空项目什么效果都看不到，所以接下来就往里面填充内容，实现一个简单的 Web 应用。

## 集成基础 Web 组件

上面的项目采用 gradle 作为项目构建工具，所以依赖组件是配置在 `build.gradle` 文件中。gradle 和 maven 用法相似，选用 gradle 的好处很多，简洁是很重要的一点，参考下面的示例：

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>
```

```gradle
dependencies {
    compile('org.springframework.boot:spring-boot-starter-web')
}
```

向 `build.gradle` 中添加 SpringMVC 

*************************************************

参考资料：
- 《Spring Boot 实战》 Craig Walls