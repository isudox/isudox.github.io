---
title: [译]使用 Django 认证系统
date: 2016-03-22 20:06:17
tags: Django
categories:
- Coding
- Translation
---

> 译自[Django Documentation](https://docs.djangoproject.com/en/1.9/topics/auth/default/)，版本1.9

本文介绍了 Django 认证系统在默认配置下的使用。默认配置已经发展到能够满足大多数项目需求，处理相当数量的任务，而且具备严谨的密码和权限实现。对于有自定义验证需求的项目，Django 支持[扩展验证](https://docs.djangoproject.com/en/1.9/topics/auth/customizing/)。
Django 认证系统提供认证和授权功能，由于两部分功能有耦合，因此通常简称为认证系统。

## User objects
