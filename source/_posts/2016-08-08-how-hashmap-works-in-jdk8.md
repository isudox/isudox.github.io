---
title: JDK 8 中 HashMap 的工作原理
tags:
  - Java
categories:
  - Coding
date: 2016-08-08 17:31:32
---


Java 容器类中，`HashMap` 是一个绕不开的重点，无论是实际开发还是求职面试。由于对 JDK 6 下 `HashMap` 的讨论已经很多了，而且 JDK 8 对 `HashMap` 做了比较大的改进，本文仅对 **JDK 8** 中 HashMap 的实现和工作原理做一点粗浅的讨论。

<!-- more -->

> 文中 Java 代码均基于 **JDK 8**

### 引入

为了便于切入话题，先写一段最简单的 HashMap 样例代码：

```java
public class HashMapTest {
    public static void main(String[] args) {
        HashMap<String, String> map = new HashMap<>();
        map.put("China", "Beijing");
        map.put("Japan", "Tokyo");
        map.put("Korea", "Seoul");
        for (String country : map.keySet()) {  // set a break point
            String capital = map.get(country);
            System.out.println(country + "--" + capital);
        }
    }
}
```

在 `for` 循环处进入断点，查看变量，IntelliJ IDEA 中显示如下：
![](https://o70e8d1kb.qnssl.com/hashmap-breakpoint.png)

变量 `map` 包含 `table` 属性和 `entrySet` 属性。其中，`table` 属性是一个长度为 16 的 `Map.Entry` 数组；`entrySet` 属性是一个元素类型为 `Map.Entry` 的 `Set` 对象。打开 JDK 8 的 `java.util.HashMap` 源码，对其属性一探究竟。

```java
public class HashMap<K,V> extends AbstractMap<K,V>
    implements Map<K,V>, Cloneable, Serializable {

    static final int DEFAULT_INITIAL_CAPACITY = 1 << 4; // aka 16
    static final int MAXIMUM_CAPACITY = 1 << 30;
    static final float DEFAULT_LOAD_FACTOR = 0.75f;
    static final int TREEIFY_THRESHOLD = 8;
    static final int UNTREEIFY_THRESHOLD = 6;
    static final int MIN_TREEIFY_CAPACITY = 64;

    /* ---------------- Fields -------------- */

    transient Node<K,V>[] table;

    transient Set<Map.Entry<K,V>> entrySet;

    transient int size;

    transient int modCount;

    int threshold;

    final float loadFactor;

    /* ---------------- Public operations -------------- */

    public Set<K> keySet() {
        Set<K> ks;
        return (ks = keySet) == null ? (keySet = new KeySet()) : ks;
    }

    public Collection<V> values() {
        Collection<V> vs;
        return (vs = values) == null ? (values = new Values()) : vs;
    }

}
```

从截取的源码里，可以理解上面断点执行的 `map` 各属性具体的含义：

- `table`： 即 hash bucket 数组，存储 Node 单向链表。
- `entrySet`： 存储 Entry 的 Set；
- `size`： `map` 中键值对的数量；
- `modCount`： 记录当前 `HashMap` 结构被改变的次数；
- `threshold`： 所能容纳的键值对的最大值
- `loadFactor`： 当前 `table` 的负载因子，当 `table` 中 entries 的数量超过负载时，会被重新 hash，table 的容量会增大为先前的 2 倍。默认初始容量为 16，负载因子为 0.75；
- `keySet()`: 返回当前 `map` 中 key 组成的 Set；
- `values()`: 返回当前 `map` 中 value 组成的 Collection；

这样还是不够明白，下面接着说 HashMap 里的数据结构。

### HashMap 中的数据结构

首先来看 `table` 属性所存储的 Node 链表：

```java
// HashMap.Node
static class Node<K,V> implements Map.Entry<K,V> {
    final int hash;
    final K key;
    V value;
    Node<K,V> next;

    Node(int hash, K key, V value, Node<K,V> next) {
        this.hash = hash;
        this.key = key;
        this.value = value;
        this.next = next;
    }

    public final K getKey()        { return key; }
    public final V getValue()      { return value; }
    public final String toString() { return key + "=" + value; }

    public final int hashCode() {
        return Objects.hashCode(key) ^ Objects.hashCode(value);
    }

    public final V setValue(V newValue) {
        V oldValue = value;
        value = newValue;
        return oldValue;
    }

    public final boolean equals(Object o) {
        if (o == this)
            return true;
        if (o instanceof Map.Entry) {
            Map.Entry<?,?> e = (Map.Entry<?,?>)o;
            if (Objects.equals(key, e.getKey()) &&
                Objects.equals(value, e.getValue()))
                return true;
        }
        return false;
    }
}
```

`Node` 包含的域有 `hash`，`key`，`value` 和 `next`，其中 `next` 指向下一 `Node` 节点。`hashCode()` 方法通过求 `key` 和 `value` 的哈希值的异或计算 `hash`;

![](https://upload.wikimedia.org/wikipedia/commons/d/d0/Hash_table_5_0_1_1_1_1_1_LL.svg)

### put() / get()

HashMap 最主要的操作就是 `put()` 和 `get()`，先来看 `put()` 方法：

```java
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}

final V putVal(int hash, K key, V value, boolean onlyIfAbsent, boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
    if ((p = tab[i = (n - 1) & hash]) == null)
        tab[i] = newNode(hash, key, value, null);
    else {
        Node<K,V> e; K k;
        if (p.hash == hash && ((k = p.key) == key ||
            (key != null && key.equals(k))))
            e = p;
        else if (p instanceof TreeNode)
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        else {
            for (int binCount = 0; ; ++binCount) {
                if ((e = p.next) == null) {
                    p.next = newNode(hash, key, value, null);
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        treeifyBin(tab, hash);
                    break;
                }
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    break;
                p = e;
            }
        }
        if (e != null) { // existing mapping for key
            V oldValue = e.value;
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;
            afterNodeAccess(e);
            return oldValue;
        }
    }
    ++modCount;
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict);
    return null;
}

static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```

拆解上面的 `putVal()` 方法，该方法有 5 个入参，主要的入参是 key 的哈希值，key 和 value，onlyIfAbsent 标识是否改变已存在的 value（默认 false，改变已存在的 value），evict 标识 hash bucket 数组是否为 creation mode（默认 true，非 creation mode）。`putVal()` 用了几个 `if-else` 对插入 key-value 时可能出现的情况做了不同的处理：

- 通过 key 的哈希值计算 hash bucket 数组的 index 位置，如果该 index 位置的 Node 对象为空，则新建 Node 并写入 bucket 数组的 index 位置；
- 如果 index 位置上已存在 Node 对象，即发生碰撞时，也存在多种情况：
  - 如果该 Node 对象的 hash 和 key 都和入参 hash 和 key 一致，说明节点已存在；
  - 如果该 Node 对象是红黑树节点，则把待插入的 Node 节点对象转换为红黑树节点对象 TreeNode；
  - 否则，迭代 index 位置上存储的 Node 链表，直到最后一个 Node 节点，创建新的 Node 节点并接在末尾。如果 Node 链表长度超过 TREEIFY_THRESHOLD，就把 Node 链表转换为红黑树 TreeNode；
- 如果节点已存在，就将节点的 value 替换为入参 value，并返回原 value 值。

再看 `get()` 方法：

```java
public V get(Object key) {
    Node<K,V> e;
    return (e = getNode(hash(key), key)) == null ? null : e.value;
}

final Node<K,V> getNode(int hash, Object key) {
    Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
    if ((tab = table) != null && (n = tab.length) > 0 &&
        (first = tab[(n - 1) & hash]) != null) {
        if (first.hash == hash && // always check first node
            ((k = first.key) == key || (key != null && key.equals(k))))
            return first;
        if ((e = first.next) != null) {
            if (first instanceof TreeNode)
                return ((TreeNode<K,V>)first).getTreeNode(hash, key);
            do {
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    return e;
            } while ((e = e.next) != null);
        }
    }
    return null;
}
```

`get()` 方法简明易懂，通过 key 的哈希值来定位 bucket 数组的 index，找到 Node 节点，从而找到所匹配的 value 值。

- 从 index 上的 Node 链表的头节点开始，如果头节点的 hash 和 key 域都匹配，则命中，直接返回 value；
- 头节点没命中，意味着存在冲撞，就继续向下迭代，每次迭代一个 Node 节点时都判断当前节点是否为红黑树节点
  - 如果当前节点是红黑树节点，则获取从红黑树的 root 节点处开始遍历寻找匹配的 key 和 hash；
  - 如果当前节点非红黑树节点，则检查节点的 hash 和 key 域，若匹配则返回 value 值；

### 红黑树

### 优化方法

`loadFactor` 属性可以控制 HashMap 的空间/时间使用：增大 `loadFactor` 则减小内存占用，但查找效率减慢；反之则内存占用变大，查找效率提升。

### JDK 8 下 HashMap 的改动