---
title: 责任链模式的实际运用
tags:
  - 设计模式
categories:
  - Coding
date: 2016-06-06 18:23:51
---

加入 JD 已有大半年了，想了想差不多一直是在写业务代码。老实讲，有时候自己感觉有点累，对不断更改和新增的业务需求总是沿用低效堆代码的方式去解决，review 自己写的代码时，好像一直在 repeat yourself。代码不应该那样写，把复杂业务拆分，松耦合，利用设计模式将业务代码简化，而不是一味的去用过程编程的思维去实现业务逻辑，又苦又累毫无乐趣。

<!-- more -->

### 重构之前

趁着 JD 618 大促的机会，把陪伴计划项目部分业务重构了下。前期开发时因为业务需求多、时间紧张，没有对业务逻辑深入的分析，代码拿上来就写，导致逻辑的紧耦合、难以更改，难以扩展，面对新增的业务只能从头再写而无法做到有效复用。

要做到代码的合理复用，直接有效的途径就是把业务逻辑拆分细化，颗粒度最细的拆分就是将业务逻辑拆分成原子操作，但这样做会导致代码过于细碎，未免过犹不及。业务松耦合，并非零耦合。让每一个细分业务只负责单一逻辑，通过灵活可配的组合实现复杂逻辑，这是实现松耦合，提高扩展性行之有效的办法。

以这次的小范围重构为例，京东陪伴计划项目包含大量的优惠券促销业务，其逻辑涉及到诸多信息，比如宝贝档案、风险控制、券卡类别库存、会员信息、领取时间等多个维度。重构前的代码把优惠券业务里所涉及的多维度逻辑统统杂糅在一个接口实现里。这样的处理很草率，唯一的好处就是，在从零到一编写代码的过程中，思维可以很清楚的沿着业务逻辑线性写下去，说白了就是无脑编程。试想一下，如果优惠券部分的业务发生改变或者新增维度信息，很难灵活应变，而且代码冗余，牵扯面大，很难灵活扩展。

### 原味责任链模式

[责任链模式](https://en.wikipedia.org/wiki/Chain-of-responsibility_pattern)的基本思想是通过连锁处理单元，链式的处理客户端请求。链是由一系列处理单元自由组成的集合，可以是直线、环、树状结构，不同的处理单元将业务逻辑解耦。责任链上的每个处理单元或节点，都是客户端请求的潜在处理者，且客户端请求必定会在责任链上被处理。
![](https://o70e8d1kb.qnssl.com/Chain_of_responsibility1-2x.png)

标准的责任链结构，其节点包含处理方法 handle()，后一节点的引用 nextHandler，因此可以灵活配置责任链的每个节点，从而实现复杂业务的组合。
![](https://o70e8d1kb.qnssl.com/Chain_of_responsibility__-2x.png)

客户端的请求从责任链的根节点开始，依次往下执行，如果当前节点能胜任处理工作，则完成任务，否则将请求往下传递，直到到达能处理该请求的节点。下面编写一段简单的 Java 示例代码：

先来一段又臭又长的代码，举个栗子
```java
public class BullshitCode {
    public static void main(String[] args) {
        int cmd = Integer.parseInt(args[0]);
        switch (cmd) {
            case 1:
                System.out.println("my name is sudoz");
                break;
            case 2:
                System.out.println("this is my site");
                break;
            case 3:
                System.out.println("any advice is welcome");
                break;
            case 4:
                System.out.println("reach me via e-mail at me@isudox.com");
                break;
            default:
                break;
        }
    }
} 
```
上面的代码没有什么实际意义，只是一种很具有代表性的写法，通过一长串的 `if-else` 逻辑去处理业务，导致所有可能的处理缓解都堆积杂糅在一块，设想一下如果新增了业务需求，是不是再往里面插一个 `if-else` 了事？总是用这种方式去写代码会让程序越来越臃肿，难以维护和扩展，尤其是当你接手别人的代码发现以百行计的 `if-else` 语句块时，你一定会一脸懵逼看不下去，沃泽法克什么鬼？！
![](https://o70e8d1kb.qnssl.com/confused-face.png)

升职加薪对码农而言，就像是马儿眼前的草，给不给草啊，难道又要马儿跑又要马儿不吃草，互联网公司好像还真这么想……说多了就是两行泪，上头的 Boss 和 HR 们层层把关，不是想加就能加。
```java
// 管理层抽象类
public abstract class Manager {
    protected Manager successor;

    public Manager(Manager successor) {
        this.successor = success;
    }

    public void setSuccessor(Manager successor) {
        this.successor = successor;
    }
    
    public abstract void handleRequest(PromotionRequest request);
}
```

```java
// 抠门的管理人员
public class LittleBoss extends Manager {
    public void handleRequest(PromotionRequest request) {
        if (request.getRise <= 1000) {
            System.out.println("Give u the money");
        } else {
            successor.handleRequest(request);
        }
    }
}

public class MiddleBoss extends Manager {
    public void handleRequest(PromotionRequest request) {
        if (request.getRise <= 2000) {
            System.out.println("Give u the money");
        } else {
            successor.handleRequest(request);
        }
    }
}

public class BigBoss extends Manager {
    public void handleRequest(PromotionRequest request) {
        if (request.getRise <= 3000) {
            System.out.println("Give u the money");
        } else {
            System.out.println("Get the fxxk off!");
        }
    }
}
```

见过小中大领导后，我要提加薪申请了，看招！
```java
public static void main(String[] args) {
    PromotionRequest request = new PromotionRequest(5000);
    Manager LittleManager zhangsan = new LittleManager();
    Manager MiddleManager lisi = new LittleManager();
    Manager BigManager wangwu = new LittleManager();
    zhangsan.setSuccessor(lisi);
    lisi.setSuccessor(wangwu);

    zhangsan.handle(request);   // heard "Get the fxxk off!"
}
```

提交给部门领导张三了，我要加薪 5000，被驳回了，叫我滚蛋……生无可恋。

上面就是很简单的责任链模式的示例，只是表达下原始的责任链模式的实际过程，并不完善。真正的生产开发中运用责任链模式可以根据场景适当变型，接下来我就把我重构京东陪伴计划优惠券模块的过程简单记一笔。

### 实际运用

前面提到了京东陪伴计划对优惠券部分的业务的处理，比如客户端的优惠券展示，不同用户看到的可领优惠券是不同的，另外，后台配置的优惠券也是差异化的。因此优惠券的展示可能涉及到的维度有：业务类型，用户 ID，宝贝档案信息，券卡类型，用户等级，展示期，有效期，风控级别等，而且要有可扩展性，保不定哪天就要增加新维度。同样，优惠券的发放领取也涉及到类似的条件筛查。那重构前的代码是怎么处理的呢，其实就跟上一小节给出的那段又臭又长的代码一个样，就是不断的通过 `if-else` 去判断条件，如果符合了就予以展示或发放，不符合就舍去，这就是过程编程不好的地方，代码冗余，可重用性差，难以扩展。

不难发现，上面的优惠券场景是适用于责任链模式的，因为优惠券展示/发放所涉及到的各个筛查条件都可以作为责任链上的节点，只是在这里，不能做原教旨主义者，需要对教科书上的责任链模式略作改动，在配置用于优惠券展示/发放的责任链后，优惠券信息经过责任链的处理时，当前的责任节点必须对请求进行处理，而不是原始的责任链模式中提到的只有一个节点作为处理者。换个说法，每张可能的优惠券从责任链的起始节点开始被筛查，如果结果是真则往下一节点继续筛查，否则中断筛查，抛弃该潜在优惠券。

责任链节点对象，内有优惠券筛查处理器接口方法
```java
public interface CheckChainNode {
    /**
    * 通用检查处理器
    */
    BizResult checkHandler(BizParameter param);
}
```

责任链对象
```java
public class CheckChain {
    private static Logger logger = LoggerFactory.getLogger(CheckChain.class);
    private List<CheckChainNode> checkList;

    public BizResult checkIt(BizParameter params) {
        BizResult result = new BizResult();
        if (CollectionUtils.isEmpty(checkList)) {
            // 如果检查链为空
            logger.error("检查链为空");
            result.setShowMessage("检查链为空");
            return result;
        }
        try {
            for (CheckChainNode checkNode : checkList) {
                BizResult curResult = checkNode.checkHandler(params);
                result = curResult == null ? result : curResult;
                if (!result.isSuccess()) break;
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("执行检查链时发生异常: {}", e);
            result.setResultCode(-1);
            result.setShowMessage("执行检查链时发生异常");
            return result;
        }
        if (result.isSuccess()) result.setBizParameter(params);
        return result;
    }

    public List<CheckChainNode> getCheckList() {
        return checkList;
    }

    /**
    * Spring 配置注入
    */
    public void setCheckList(List<CheckChainNode> checkList) {
        this.checkList = checkList;
    }
}
```

责任链节点的多种实现，分别对应不同的筛查条件
```java
@Service(value = "timeCheckHandlerNode")
public class TimeCheckHandlerNode implements CheckChainNode {
    @Override
    public BizResult checkHandler(BizParameter param) {
        BizResult result = new BizResult();
        if (param != null && !param.isEmpty()) {
            String pin = param.getString(CouponConst.PIN);
            final int age = param.getInt(CouponConst.AGE);
            CouponBatch couponBatch = param.getObject(CouponConst.COUPON, CouponBatch.class);
            result.setSuccess(this.doCheck(couponBatch, age));
        }
        return result;
    }

    private boolean doCheck(CouponBatch couponBatch, int age) {
        final Date today = new Date();
        return couponBatch.getValidityStartTime().before(today) &&
                couponBatch.getValidityEndTime().after(today) &&
                couponBatch.getEndTime().after(today) &&
                couponBatch.getMinPreferAge() <= age &&
                couponBatch.getMaxPreferAge() >= age;
    }
}

// 其余筛查节点略过
@Service(value = "riskCheckHandlerNode")
public class RiskCheckHandlerNode implements CheckChainNode {}

@Service(value = "stockCheckHandlerNode")
public class StockCheckHandlerNode implements CheckChainNode {}
```

Spring 配置优惠券筛查的责任链，注入检查链对象
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd"
       default-autowire="byName">

  <!-- 优惠券展示链 -->
  <bean id="displayCouponCheckChain" class="com.isudox.service.coupon.CheckChain">
    <property name="checkList">
      <list>
        <ref bean="timeCheckHandlerNode"/>
        <ref bean="riskCheckHandlerNode"/>
        <ref bean="receivedCheckHandlerNode"/>
        <ref bean="stockCheckHandlerNode"/>
      </list>
    </property>
  </bean>
  <!-- 优惠券发放链 -->
  <bean id="sendCouponCheckChain" class="com.isudox.service.coupon.CheckChain">
    <property name="checkList">
      <list>
        <ref bean="receivedCheckHandlerNode"/>
        <ref bean="stockCheckHandlerNode"/>
        <ref bean="timeCheckHandlerNode"/>
        <ref bean="riskCheckHandlerNode"/>
      </list>
    </property>
  </bean>
</beans>
```

这样就可以对优惠券部分的业务灵活配置，如果需要新增逻辑，不用更改已有的代码，再实现一个 CheckChainNode 接口就可以了。另外，如果想更改筛查链，也只需要对 Spring 的配置进行修改，重启实例就能生效，无需再次编译发布。简直轻松愉快！