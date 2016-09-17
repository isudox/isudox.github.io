---
title: Java 常用容器小结
tags:
  - Java
categories:
  - Coding
date: 2016-09-13 20:15:58
---


无论是什么编程语言，容器都是非常重要的概念，在 Java 的实际开发中更是无处不在，各种 List、Set、Map。很多时候就是随着编程的惯性用了 ArrayList 或者 HashMap，但是并没对其特性和适用场景作更多的思考。开发者对 Java 容器的讨论比较多，我自己从源码的角度做个粗浅的整理。

<!-- more -->

## Collection

java.util 包中的基于 Collection 接口的有 List、Set 和 Queue，下面这张图清楚的显示了 Collection 接口的向下实现和继承关系。

![](https://o70e8d1kb.qnssl.com/java-collection-hierarchy.png)

Collection 接口继承了 Iterable 接口，表明所有 Collection 的实现都是可迭代的。Collection 提供最基础的接口方法，如 `add()`、`remove()`、`contains()`、`isEmpty()`、`hashCode()` 等。

### List

> An ordered collection (also known as a sequence). The user of this interface has precise control over where in the list each element is inserted. The user can access elements by their integer index (position in the list), and search for elements in the list.

上面是 Java SE Docs 里对 List 的定义。也就是说，List 是一个有序的 Collection，即队列，List 的使用者通过 List 内元素所在的 index 访问元素，且不限制重复元素。

#### ArrayList

> Resizable-array implementation of the List interface. Implements all optional list operations, and permits all elements, including null. In addition to implementing the List interface, this class provides methods to manipulate the size of the array that is used internally to store the list. (This class is roughly equivalent to Vector, except that it is unsynchronized.)

ArrayList 是 List 里使用度非常高的一个实现。Doc 里有这么几个关键的说明：可动态扩容，允许插入 `null`，非同步。

ArrayList 实例有一个容量（capacity），就是它所能存储的元素数量，默认是 10。当元素不断被添加进 ArrayList 后，它的 size 域接近 capacity 时，capacity 会自动增加。

先来了解 ArrayList 的自动扩容机制。自动扩容是在执行 `add` 或 `addAll` 方法是触发的，这两个方法里会调用 `ensureCapacityInternal()` 方法来增大 capacity，看源码：

```java
public boolean add(E e) {
    ensureCapacityInternal(size + 1);  // Increments modCount!!
    elementData[size++] = e;
    return true;
}

private void ensureCapacityInternal(int minCapacity) {
    if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
        minCapacity = Math.max(DEFAULT_CAPACITY, minCapacity);
    }

    ensureExplicitCapacity(minCapacity);
}

private void ensureExplicitCapacity(int minCapacity) {
    modCount++;

    // overflow-conscious code
    if (minCapacity - elementData.length > 0)
        grow(minCapacity);
}

private void grow(int minCapacity) {
    // overflow-conscious code
    int oldCapacity = elementData.length;
    int newCapacity = oldCapacity + (oldCapacity >> 1);
    if (newCapacity - minCapacity < 0)
        newCapacity = minCapacity;
    if (newCapacity - MAX_ARRAY_SIZE > 0)
        newCapacity = hugeCapacity(minCapacity);
    // minCapacity is usually close to size, so this is a win:
    elementData = Arrays.copyOf(elementData, newCapacity);
}
```

只有当新增元素后的 size 超过当前的容量时，才会触发扩容。扩容的操作由 `grow()` 通过 `Arrays.copyOf()` 完成。自动扩容省去了程序员操心 ArrayList 溢出问题，但也带来一个弊端，就是当需要添加大量元素，会频繁触发自动扩容，JDK 提供了 `ensureCapacity()` 方法手动的预先设置 capacity 去避免这种情况。

```java
public void ensureCapacity(int minCapacity) {
    int minExpand = (elementData != DEFAULTCAPACITY_EMPTY_ELEMENTDATA)
        // any size if not default element table
        ? 0
        // larger than default for default empty table. It's already
        // supposed to be at default size.
        : DEFAULT_CAPACITY;

    if (minCapacity > minExpand) {
        ensureExplicitCapacity(minCapacity);
    }
}
```

#### Vector

> The Vector class implements a growable array of objects. Like an array, it contains components that can be accessed using an integer index. However, the size of a Vector can grow or shrink as needed to accommodate adding and removing items after the Vector has been created.

Vector 和 ArrayList 很类似，不同之处在于，Vector 是同步的，线程安全，自动扩容时，容量是增大 100%（ArrayList 是增大 50%）。

#### LinkedList

> Doubly-linked list implementation of the List and Deque interfaces. Implements all optional list operations, and permits all elements (including null).

LinkedList 是一个双向链表实现，对 LinkedList 内元素的索引都需要从它的头部或尾部遍历。因此 LinkedList 不能像 ArrayList 和 Vector 那样根据元素索引位置进行随机访问，只能通过 LinkedList 里逐个 Node 依次向下（上）迭代进行查找，访问效率相比会差一点。

LinkedList 内元素是以 `Node<E>` 结构存储，Node 包含真实的存储元素 item，前一 Node 的引用 prev，后一 Node 的引用 next：

```java
private static class Node<E> {
    E item;
    Node<E> next;
    Node<E> prev;

    Node(Node<E> prev, E element, Node<E> next) {
        this.item = element;
        this.next = next;
        this.prev = prev;
    }
}
```

双向链表的结构使得数据的插入删除变得非常简单高效：

```java
public void add(int index, E element) {
    checkPositionIndex(index);

    if (index == size)
        linkLast(element);
    else
        linkBefore(element, node(index));
}

void linkBefore(E e, Node<E> succ) {
    // assert succ != null;
    final Node<E> pred = succ.prev;
    final Node<E> newNode = new Node<>(pred, e, succ);
    succ.prev = newNode;
    if (pred == null)
        first = newNode;
    else
        pred.next = newNode;
    size++;
    modCount++;
}
```

插入时，只需要将新元素的 Node 插在 prev 和 next Node之间，并重新建立前后连接关系。同理，删除操作也是。

### Set

> A collection that contains no duplicate elements. More formally, sets contain no pair of elements e1 and e2 such that e1.equals(e2), and at most one null element. As implied by its name, this interface models the mathematical set abstraction.

Set 是不存在重复元素的集合类型。对于重复的定义就是，当 `e1.equals(e2)` 时，就意味着重复。Set 支持 `null`，最多也只能存在一个。

#### HashSet

> This class implements the Set interface, backed by a hash table (actually a HashMap instance). It makes no guarantees as to the iteration order of the set; in particular, it does not guarantee that the order will remain constant over time. This class permits the null element.

凡是和 Hash 相关的都是查询效率很高的集合类型，HashSet 也是。HashSet 内部持有一个 HashMap 域来作为元素的实际存储，也就是说，HashSet 根据元素的 HashCode 来确定顺序，因此 HashSet 无法保证元素的存储顺序和插入顺序一致，甚至都不能保证顺序一直保持不变。参考 OpenJDK 里的源码：

```java
public class HashSet<E> extends AbstractSet<E> implements Set<E>, Cloneable, Serializable {
    private transient HashMap<E, Object> map;
    public boolean isEmpty() {
        return this.map.isEmpty();
    }
    public boolean add(E var1) {
        return this.map.put(var1, PRESENT) == null;
    }
    public boolean remove(Object var1) {
        return this.map.remove(var1) == PRESENT;
    }
    public void clear() {
        this.map.clear();
    }
}
```

#### LinkedHashSet

> Hash table and linked list implementation of the Set interface, with predictable iteration order.

LinkedHashSet 继承了 HashSet，不同的是，LinkedHashSet 内部持有一个双向链表，这个链表决定了其元素遍历的顺序，即元素插入的顺序。因此 LinkedHashSet 是有序的集合。

#### TreeSet

> A NavigableSet implementation based on a TreeMap. The elements are ordered using their natural ordering, or by a Comparator provided at set creation time, depending on which constructor is used.

TreeSet 继承 SortedSet（直接父类是 NavigableSet），是有序的集合。元素顺序可以保持自然排序，或者根据提供的比较器 Comparator 排序，因此 TreeSet 中任意两个元素的值都不同。TreeSet 的元素存储在 NavigableMap 中（父类是 SortedMap）。

TreeSet 是非同步的，如果多线程并行访问 TreeSet，且至少有一个线程会修改它，就必须在外部进行同步。典型的办法是采用包装器去把非同步的对象装饰成同步的对象（Java 并发编程实战里讲得很详细），Collections 包提供了这样的方法：
``` SortedSet set = Collections.synchronizedSortedSet(new TreeSet(...));```

## Map

![](https://o70e8d1kb.qnssl.com/java-map-hierarchy.png)

Map 存储的元素是 K-V 键值对，Map 的具体实现通常是由 key 映射到 value，而 Apache Commons 包的 BidiMap 集合，实现了 value 到 key 的反向映射，参考 [StackOverflow](http://stackoverflow.com/questions/1383797/java-hashmap-how-to-get-key-from-value)。

### HashMap

> This implementation provides all of the optional map operations, and permits null values and the null key. (The HashMap class is roughly equivalent to Hashtable, except that it is unsynchronized and permits nulls.) This class makes no guarantees as to the order of the map; in particular, it does not guarantee that the order will remain constant over time.

之前的[博客](/2016/08/08/how-hashmap-works-in-jdk8/)对 JDK8 里的 HashMap 做了简单的介绍。HashMap 的 key 和 value 允许 null，且它是非同步的，这个 Hashtable 有别（HashMap 继承了 AbstractMap，Hashtable 继承了 Dictionary，两者都实现了 Map 接口）。HashMap 是无序的，因为它的元素通过 key 的哈希值决定其在 hash bucket 中的存储位置。

### Hashtable

Hashtable 和 HashMap 类似，但它是同步的，且不支持 null。在单线程环境下，Hashtable 的性能要稍差于 HashMap。

### TreeMap

> A Red-Black tree based NavigableMap implementation. The map is sorted according to the natural ordering of its keys, or by a Comparator provided at map creation time, depending on which constructor is used.

TreeMap 是基于红黑树的 NavigableMap（父类 SortedMap）实现，是有序集合，以元素 key 的自然顺序或者比较器作为排序依据。它和 TreeSet 除了元素结构的差异，在行为表现上很相似。

## 总览

搬运前人总结的表格，总览几个常用集合的特点：

| Collection class | Base class | Base interfaces | Duplicate elements? | Ordered? | Sorted? | Thread-safe? |
|:------:|:------:|:------:|:------:|:------:|:------:|:------:|
| ArrayList<E> | AbstractList<E> | List<E> | Y | Y | N | N |
|LinkedList<E>|AbstractSequentialList<E>|List<E>; Deque<E>|Y|Y|N|N|
|Vector<E>|AbstractList<E>|List<E>|Y|Y|N|Y|
|HashSet<E>|AbstractSet<E>|Set<E>|N|N|N|N|
|LinkedHashSet<E>|HashSet<E>|Set<E>|N|Y|N|N|
|TreeSet<E>|AbstractSet<E>|NavigableSet<E>|N|Y|Y|N|
|HashMap<K, V>|AbstractMap<K, V>|Map<K, V>|N|N|N|N|
|LinkedHashMap<K, V>|HashMap<K, V>|Map<K, V>|N|Y|N|N|
|Hashtable<K, V>|Dictionary<K, V>|Map<K, V>|N|N|N|Y|
|TreeMap<K, V>|AbstractMap<K, V>|NavigableMap<K, V>|N|Y|Y|N|