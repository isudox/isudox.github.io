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

从截取的部分源码里可以明白断电执行的截图中 `map` 各属性具体的含义：

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
```

### 红黑树

### 优化方法

`loadFactor` 属性可以控制 HashMap 的空间/时间使用：增大 `loadFactor` 则减小内存占用，但查找效率减慢；反之则内存占用变大，查找效率提升。

### JDK 8 下 HashMap 的改动