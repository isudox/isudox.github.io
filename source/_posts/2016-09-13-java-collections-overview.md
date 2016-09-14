---
title: Java 常用容器小结
tags:
  - Java
Categories:
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

#### HashSet

#### LinkedHashSet

#### TreeSet

### 比较总结

## Map

![](https://o70e8d1kb.qnssl.com/java-map-hierarchy.png)

### HashMap

### TreeMap

### HashTable

### 比较总结