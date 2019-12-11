---
title: Spring MVC 集成 Thymeleaf
date: 2016-07-06 15:25:45
tags:
  - Spring
  - Thymeleaf
  - Frontend
  - Java
categories:
  - Coding
---

在狗厂，我所接触的项目里，Spring 的视图解析器采用最广泛的就是 [Velocity](http://velocity.apache.org/)。最近也一直在想前后端分离的事，略显古老的 Velocity 并不是前后端分离的好选择。还好，近几年 Java Web 诞生了一款新的视图解析器——“百里香叶” [Thymeleaf](http://www.thymeleaf.org/)，就像它的名字一样美妙。

<!-- more -->

和 Velocity 类似，Thymeleaf 支持通过 `@Controller` 注解的映射方法返回模板名称；模板支持 Spring Expression Language；支持在模板中创建表单，表单验证。（这就比较像 Jinja2 了）。

## 模板标准方言

### 引入

Thymeleaf 的模板标准语言中绝大多数 processors 都是 attribute processors，这就意味着浏览器可以正常地表现 XHTML/HTML5 模板文件，即使是在模板引擎没有加载的情况下，因为浏览器会忽略额外的 attribute。这就是 Thymeleaf 比前辈 JSP 厉害的地方之一。来看下面的 input 标签，JSP 里会加入浏览器无法直接识别的代码:

```html
<form:inputText name="userName" value="${user.name}" />
```

而 Thymeleaf 模板标准语言会这样写：

```html
<input type="text" name="userName" value="James Carrot" th:value="${user.name}" />
```

浏览器能直接识别上述 Thymeleaf 的 input 标签，而且还能在加载模板引擎后，由后端返回的数据渲染 value 值。也就是这一特性，可以让前后端工程师在同一个模板文件上协作开发，避免了从静态页面到模板页面的转换，前后端并行开发，这就是未来的趋势，也被称作 Natural Templating，页面即模板，模板即页面。

### 标准表达式语法

#### 基本表达式

Thymeleaf 模板方言里最重要的就是它的标准表达式语法了。Thymeleaf 的表达式有：

- 简单表达式：
  - 变量表达式：`${...}`
  - 选择变量表达式：`*{...}`
  - 消息表达式：`#{...}`
  - URL 表达式：`@{...}`

- 字面值表达式：
  - 文本：'ABC', '你好'
  - 数字：0, 1, 2.0, 12.3
  - 布尔值：`true`, `false`
  - Null：`null`
  - 字面值 token：`one`, `sometext`, `main`

- 算术操作：
  - 二元：`+`, `-`, `*`, `/`, `%`
  - 一元：`-`

- 布尔运算符：
  - 二元：`and`, `or`
  - 一元：`!`, `not`

- 比较运算符：
  - 不等比较：`>`, `<`, `>=`, `<=` (`gt`, `lt`, `ge`, `le`)
  - 相等比较：`==`, `!=` (`eq`, `ne`)

- 条件运算符：
  - If-then: `(if) ? (then)`
  - If-then-else: `(if) ? (then) : (else)`
  - Default: `(value) ?: (default_value)`

参考如下模板代码：

```
'User is of type ' + (${user.isAdmin()} ? 'Administrator' : (${user.type} ?: 'Unknown'))
```

#### 变量

变量表达式 `${...}` 会把模板 context 内保存的变量解释出来。例如下面的表达式中

```html
<p>Today is: <span th:text="${today}">13 August 2016</span>.</p>
```

实际上是执行了这样的代码：

```java
ctx.getVariables().get("today");
```

复合结构的变量：

```html
<p th:utext="#{home.welcome(${session.user.name})}">
  Welcome to our grocery store, Sebastian Pepper!
</p>
```

变量执行的代码是

```java
((User) ctx.getVariables().get("session").get("user")).getName();
```

`getter` 方法只是其中一个功能，变量表达式就像 Python 一样极富表现力：

```javascript
// 通过 `.` 符访问变量属性值
${person.father.name}

// 通过 `[]` 符访问变量属性值
${person['father']['name']}

// 如果对象是一个字典，则 `.` 和 `[]` 都能执行 `get(...)` 方法
${countriesByCode.ES}
${personsByName['Stephen Zucchini'].age}

// 访问数组元素
${personsArray[0].name}

// 访问方法
${person.createCompleteName()}
${person.createCompleteNameWithSeparator('-')}
```

另外，`*{...}` 也是取变量的表达式，两者的区别是：`*{...}` 会从选定的对象中匹配，而 `${...}` 是从整个 context 中去匹配。当未指定对象的前提下，二者的作用是一样的。参考下面的代码：

```html
<div th:object="${session.user}">
  <p>Name: <span th:text="*{firstName}">Sebastian</span>.</p>
  <p>Surname: <span th:text="*{lastName}">Pepper</span>.</p>
  <p>Nationality: <span th:text="*{nationality}">Saturn</span>.</p>
</div>
```

就等同于

```html
<div>
  <p>Name: <span th:text="${session.user.firstName}">Sebastian</span>.</p>
  <p>Surname: <span th:text="${session.user.lastName}">Pepper</span>.</p>
  <p>Nationality: <span th:text="${session.user.nationality}">Saturn</span>.</p>
</div>
```

#### URL

URL 是变量之外的另一个要点，由 `@{...}` 表达式解释，通过标签 `th:href` 或 `th:src` 指定。参见下面的示例代码：

```html
<!-- 绝对路径 -->
<a href="details.html" th:href="@{http://localhost:8080/gtvg/order/details(orderId=${o.id})}">view</a>

<!-- 相对路径 -->
<a href="details.html" th:href="@{/order/details(orderId=${o.id})}">view</a>

<a href="details.html" th:href="@{/order/{orderId}/details(orderId=${o.id})}">view</a>
```

上述表达式中，orderId=${o.id} 是作为 URL 的参数，多个参数也是类似如此。

#### 字面值

字面值很简单，就是做字面内容的替换，包括文本、数字、布尔值、空值 null。

```html
<!-- 文本 -->
<p>Now you are looking at a <span th:text="'working web application'">template file</span>.</p>
<!-- 数字 -->
<p>The year is <span th:text="2016">1984</span>.</p>
<p>In two years, it will be <span th:text="2013 + 3">1494</span>.</p>
<!-- 布尔 -->
<div th:if="${user.isAdmin()} == false">
<!-- null -->
<div th:if="${variable.something} == null"> ...
```

#### 字符串替换

有时候需要动态的改变文本的某一段内容，这就需要用到拼接和替换：

```html
<span th:text="'The name of the user is ' + ${user.name}">
<span th:text="'Welcome to our application, ' + ${user.name} + '!'">
<!-- || 符号内的字符做拼接处理，效果同上 -->
<span th:text="|Welcome to our application, ${user.name}!|">
<span th:text="${onevar} + ' ' + |${twovar}, ${threevar}|">
```

#### 运算 / 比较操作符

基础的运算符包括加减乘除取余，比较操作符中由于存在 `>` 和 `<`，所以需要转义处理：

```html
<div th:with="isEven=(${prodStat.count} % 2 == 0)">
<div th:if="${prodStat.count} &gt; 1">
<div th:text="'Execution mode is ' + ( (${execMode} == 'dev')? 'Development' : 'Production')">
```

### 属性标签

前面提到了一些不属于 HTML 规范的属性标签，这都是 Thymeleaf 自定义的，通过这些属性标签来设置 HTML 标签的属性。

#### 设置任意属性

Thymeleaf 的 `th:attr` 属性标签可以对 HTML 中任意属性值进行设置。例如 `th:attr="action=abc"` 是对 `action` 属性的设置；`th:attr="value=xyz` 是对 `value` 属性的设置。示例代码如下：

```html
<form action="subscribe.html" th:attr="action=@{/subscribe}">
  <fieldset>
    <input type="text" name="email" />
    <input type="submit" value="Subscribe me!" th:attr="value=#{subscribe.submit}"/>
  </fieldset>
</form>
```

#### 设置指定属性

除了上面的通用型属性标签外，Thymeleaf 还自定义了其他的特定属性标签。如 `th:attr` 标签指定 `attr` 属性；`th:value` 指定 `value` 标签。

```html
<input type="submit" value="Subscribe me!" th:value="#{subscribe.submit}"/>
<form action="subscribe.html" th:action="@{/subscribe}">
<li><a href="product/list.html" th:href="@{/product/list}">Product List</a></li>
```

还有许多其他的 `th:*` 自定义标签，都是和 HTML 标签一一对应，这里不逐个例举了。

#### 同时设置多个属性

如果需要 Thymeleaf 动态设置多个属性，可以像上面一样依次指定，也可以同时指定，不同属性通过 `-`  连接：`th:alt-title` 同时设置 `alt` 和 `title` 属性； `th:lang-xmllang` 同时设置 `lang` 和 `xml:lang` 属性。

```html
<!-- 依次指定 -->
<img src="../../images/gtvglogo.png"
     th:attr="src=@{/images/gtvglogo.png},title=#{logo},alt=#{logo}" />
<img src="../../images/gtvglogo.png" 
     th:src="@{/images/gtvglogo.png}" th:title="#{logo}" th:alt="#{logo}" />
<!-- 同时指定 -->
<img src="../../images/gtvglogo.png" 
     th:src="@{/images/gtvglogo.png}" th:alt-title="#{logo}" />
```

#### 前置和后置

有些情况下,可能需要改变属性的一部分值,比如 DOM 节点样式属性中的某个样式，这就需要在已有属性的基础上前置或后置新的属性。对此，Thymeleaf 提供了 `th:attrappend` 和 `th:attrprepend` 属性标签。

```html
<input type="button" value="Do it!" class="btn" th:attrappend="class=${' ' + cssStyle}" />
```

#### 迭代

前端页面里经常会用到表格，像 Bootstrap 中就专门有 DataTable 来处理表格的渲染。Thymeleaf 的 `th:each` 属性标签实现了对表格 DOM 下各个 `<tr>` 元素的迭代渲染，类似 Python 中的 `for in` 用法。

```html
<table>
  <tr>
    <th>NAME</th>
    <th>PRICE</th>
    <th>IN STOCK</th>
  </tr>
  <tr th:each="prod : ${prods}">
    <td th:text="${prod.name}">Onions</td>
    <td th:text="${prod.price}">2.41</td>
    <td th:text="${prod.inStock}? #{true} : #{false}">yes</td>
  </tr>
</table>
```

#### 条件

Thymeleaf 的条件表达式包括 `if`，`unless` 和 `switch`。

```html
<a href="comments.html"
   th:href="@{/product/comments(prodId=${prod.id})}" 
   th:if="${not #lists.isEmpty(prod.comments)}">view</a>
```

上面代码中，如果条件标签 `th:if` 的结果为真，则显示 `a` 标签的内容，否则不显示。
`th:if` 判 true 的情况有：
- 布尔值 true
- 非零数字
- 非零字符
- 除 "false" "off" "no" 以外的字符串
- 布尔值、数字、字符、字符串之外的变量形式

`th:unless` 的用法正好和 `th:if` 相反，要实现和上面代码一样的作用，`th:unless` 会这样写：

```html
<a href="comments.html"
   th:href="@{/comments(prodId=${prod.id})}" 
   th:unless="${#lists.isEmpty(prod.comments)}">view</a>
```

`th:switch` 和多数编程语言的 switch-case 用法是很类似的，其中 default 情况的表达式是 `th:case="*"`：

```html
<div th:switch="${user.role}">
  <p th:case="'admin'">User is an administrator</p>
  <p th:case="#{roles.manager}">User is a manager</p>
  <p th:case="*">User is some other thing</p>
</div>
```

### 块和引用

如果用过 Python 的优秀模板 Jinja2 的话，一定会对 Jinja2 的 `block` 印象深刻，因为这实现了模板的分块和复用，避免了大段代码的重复。Thymeleaf 同样也实现了这种优秀的特性，由标签 `th:fragment` 进行分块，`th:include` 进行引用。
下面是页面 footer.html 的代码：

```html
<html>
  <body>
    <div th:fragment="copy">
      &copy; 2016 The Good Thymes Virtual Grocery
    </div>
  </body>
</html>
```

在另外一个页面中同样需要 footer 中的版权信息，所以把名为 copy 的块引入进来：

```html
<body>
  <!-- ... -->
  <div th:include="footer :: copy"></div>
</body>
```

`th:include="templatename::domselector"` 指定了引入模板块所在文件名称和模板块的名称。

引用模板块不仅仅只是支持 Thymeleaf 自定义的 `th:fragment`，还支持 HTML 原生的 DOM 节点选择。

```html
<div th:include="footer :: #copy"></div>
```

如上引入的就是 footer.html 中 id=copy 的 DOM。

另一个和 `th:include` 标签类似的是 `th:replace`，两者都能引入模板块，但区别是 `th:include` 是把模板块内的内容引入到 `th:include` 所在的 DOM 节点；`th:replace` 是把模板块整个引入到 `th:replace` 签所在 DOM 节点：

```html
<body>
  <div th:include="footer :: copy"></div>
  <div th:replace="footer :: copy"></div>
</body>
```

最终渲染的结果如下：

```html
<body>
  <div>
    &copy; 2011 The Good Thymes Virtual Grocery
  </div>
  <footer>
    &copy; 2011 The Good Thymes Virtual Grocery
  </footer>
</body>
```

## 集成 Thymeleaf

大致梳理了下 Thymeleaf 的基础用法，接下来就把它集成到 Spring MVC 中。Thymeleaf 分别提供了 [thymeleaf-spring3](https://mvnrepository.com/artifact/org.thymeleaf/thymeleaf-spring3) 和 [thymeleaf-spring4](https://mvnrepository.com/artifact/org.thymeleaf/thymeleaf-spring4) 来支持 Spring 3.x 和 Spring 4.x，下面以最新的 4.x 版本为例。

### 设置模板引擎

首先需要把 Thymeleaf 配置为 Spring MVC 的模板引擎：

```xml
<bean id="templateResolver"
       class="org.thymeleaf.templateresolver.ServletContextTemplateResolver">
  <property name="prefix" value="/WEB-INF/templates/" />
  <property name="suffix" value=".html" />
  <property name="templateMode" value="HTML5" />
</bean>
    
<bean id="templateEngine"
      class="org.thymeleaf.spring4.SpringTemplateEngine">
  <property name="templateResolver" ref="templateResolver" />
</bean>
```

配置内容很清晰，上述 xml 设置了模板文件所在路径，后缀名，因此 `@Controller` 下的方法只需要返回模板的名称，模板引擎就能通过路径和后缀名，拼接找到对应模板进行渲染。

### View 和 View Resolver

Thymeleaf 实现了 `org.thymeleaf.spring4.view.ThymeleafView` 和 `org.thymeleaf.spring4.view.ThymeleafViewResolver` 来替换 Spring 内置的视图解析。这两个类负责在 Thymeleaf 模板中处理 `@Controller` 方法执行的结果。配置 ViewResolver 如下：

```xml
<bean class="org.thymeleaf.spring4.view.ThymeleafViewResolver">
  <property name="templateEngine" ref="templateEngine" />
  <property name="order" value="1" />
  <property name="viewNames" value="*.html,*.xhtml" />
</bean>
```

其中，属性 `templateEngine` 引用了之前配置的模板引擎，`order` 属性设置了 ViewResolver 的处理优先级，这是可选的参数，在配置多视图解析器时会需要用到。这里对 `prefix` 和 `suffix` 属性进行设置，因为已经在 Template Resolver 中设置了。
如果需要定义一个 View 的 bean，并预置静态变量，也很简单：

```xml
<bean name="main" class="org.thymeleaf.spring4.view.ThymeleafView">
  <property name="staticVariables">
    <map>
      <entry key="footer" value="Some company: &lt;b&gt;ACME&lt;/b&gt;" />
    </map>
  </property>
</bean>
```

### Spring MVC 配置

Spring MVC 的配置中除了指定 Template Engine 和 View Resolver 外，还需要指定标准的 Spring MVC artifacts，如静态文件的处理，注解的扫描：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
       xmlns:mvc="http://www.springframework.org/schema/mvc"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/mvc
                           http://www.springframework.org/schema/mvc/spring-mvc-3.0.xsd
                           http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans-3.0.xsd
                           http://www.springframework.org/schema/context
                           http://www.springframework.org/schema/context/spring-context-3.0.xsd">
    
  <!-- **************************************************************** -->
  <!--  RESOURCE FOLDERS CONFIGURATION                                  -->
  <!--  Dispatcher configuration for serving static resources           -->
  <!-- **************************************************************** -->
  <mvc:resources location="/images/" mapping="/images/**" />
  <mvc:resources location="/css/" mapping="/css/**" />
  <mvc:resources location="/js/" mappijs="/js/**" />

  <!-- **************************************************************** -->
  <!--  SPRING ANNOTATION PROCESSING                                    -->
  <!-- **************************************************************** -->
  <mvc:annotation-driven conversion-service="conversionService" />
  <context:component-scan base-package="thymeleafexamples.stsm" />

  <!-- **************************************************************** -->
  <!--  THYMELEAF-SPECIFIC ARTIFACTS                                    -->
  <!--  TemplateResolver <- TemplateEngine <- ViewResolver              -->
  <!-- **************************************************************** -->

  <bean id="templateResolver"
        class="org.thymeleaf.templateresolver.ServletContextTemplateResolver">
    <property name="prefix" value="/WEB-INF/templates/" />
    <property name="suffix" value=".html" />
    <property name="templateMode" value="HTML5" />
  </bean>
    
  <bean id="templateEngine"
        class="org.thymeleaf.spring4.SpringTemplateEngine">
    <property name="templateResolver" ref="templateResolver" />
  </bean>
   
  <bean class="org.thymeleaf.spring4.view.ThymeleafViewResolver">
    <property name="templateEngine" ref="templateEngine" />
  </bean>    

</beans>
```