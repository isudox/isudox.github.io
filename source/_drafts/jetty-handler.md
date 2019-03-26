---
title: Jetty Handler
tags: Java
---

从 Jetty 嵌入式启动的 Hello World 起手：

```java
public class JettyServer {

    public void start() throws Exception {
        // Server & ThreadPool(QueuedThreadPool as default)
        Server server = new Server();
        // Connector
        ServerConnector connector = new ServerConnector(server);
        connector.setIdleTimeout(3600000);
        connector.setPort(8080);

        server.setConnectors(new Connector[]{connector});
        // Handler
        server.setHandler(new DefaultHandler());

        server.start();
        server.join();
    }

    public static void main(String[] args) {
        JettyServer server = new JettyServer();

        try {
            server.start();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

`Server` 类是 Jetty 的起点，在构建 Server 时会初始化 Jetty 的组件：`Connector`、`Handler` 以及 `ThreadPool`：

- `Connector` 组件负责接收 TCP 连接，并为每个连接创建 `Connection` 实例；
- `Handler` 组件负责处理请求并生成响应；
- `ThreadPool` 内部实现的 QueuedThreadPool 提供处理具体工作的线程；

Jetty 的设计架构

![Jetty Architecture](https://www.eclipse.org/jetty/documentation/9.4.x/images/jetty-high-level-architecture.png)

`Handler` 是 `Jetty` 处理请求的组件。
