---
title: 简历（未完成更新）
date: 2020-07-23T01:10:06+08:00
show_comments: false
show_date: false
---

# 个人信息

- 章健
- 手机：185\*\*\*\*8421
- 邮箱：me@isudox.com
- 博客：[https://isudox.com](https://isudox.com)
- 教育经历：
  - 2013 - 2015 北京理工大学 - 电子与通信工程 - 硕士
  - 2009 - 2013 中国农业大学 - 电子信息工程 - 本科

---

# 工作经历

## 美团点评 - 支付平台（2017.03 - 至今）

### 账户系统 (2017.03 - 2019.03)

负责美团支付平台账户系统的开发，包括核心业务、基础性能、稳定性的建设，支撑起日处理记账请求 8 千万，流水过亿，峰值 QPS 4000 的大型分布式系统。

### 支付单元化 (2019.03 - 至今)

参与支付平台的单元化架构建设，实现从同城到异地的容灾体系。逐步完成从应用到存储的单元化，解决流量的路由，数据的拆分，以及存储副本间的同步。目前已完成以聚合支付为核心的链路的单元化，并在北京地区实现同城双活的容灾能力。

---

## 京东商城 - 交易平台（2015.07 - 2017.03）

### 京东陪伴计划

陪伴计划是京东针对母婴品类精准营销的战略项目，营销覆盖商品、社区和内容。本人负责陪伴计划的前后端及后台管理的开发，并在后续迭代中重构优化代码。

- 基于 Spring / SpringMVC 开发后端中间件，前台 Web 应用（PC 端和移动端），基于 Bootstrap 开发管理后台；
- 重构优惠券代码，通过设计模式把耦合代码分拆，使得优惠券业务彼此独立且灵活可控；
- 重构数据模型，由 ElasticSearch 取代 MySQL 存储，并统一数据结构和前台数据获取方式，提升项目新增或修改需求时的开发效率；
- 前端模板引擎采用 Thymeleaf 取代 Velocity，尝试实现前后端分离，降低前后端开发联调的时间成本；

### 京东医药城

医药城是京东的医药垂直业务，是京东电商的核心业务之一，涉及自营和第三方商家 OTC 商品。京东垂直业务链包括单品页、购物车、结算页、订单等，本人参与医药城的购物车和结算页的开发。

- 基于 Spring / Struts 开发购物车和结算页，继承主站逻辑并定制垂直业务需求，接入同时优化并重构原有代码；
- 通过设计模式把原本复杂的购物车结算页参数功能分拆，实现参数构建职责单一明确，不再冗余；
- 面向接口编程，重构原有信息校验逻辑，将原有复杂冗余逻辑简化为灵活的链式逻辑；
- 尝试运用恰当的编程思想对部分紧急业务敏捷开发，快速上线交付；

### 京东全球购

全球购是京东海外业务的拓展，是电商核心业务之一。本人参与全球购的购物车和结算页的开发。

- 对接京东整套交易系统，设计用户、运营、券卡、订单、仓储、金融等；
- 在开发业务代码的同时，重构原有逻辑，利用装饰器、建造者、责任链等设计模式进行重构；

### 京东共读

京东共读是类播客的微信端项目，碎片化阅读和创新付费阅读的一次尝试。本人参与了项目的全程开发。

- 利用状态机模型，将用户的动作和状态更迭抽象化，使业务逻辑和代码更加清晰可扩展；
- 优化原有的复杂跳转逻辑，改成星状网结构，统一请求的分发和跳转；
- 通过反射统一 RPC 的调用入口，使得 Provider 和 Consumer 可以并行开发；
- 在付费阅读业务中，将微信支付接入京东的台账系统；