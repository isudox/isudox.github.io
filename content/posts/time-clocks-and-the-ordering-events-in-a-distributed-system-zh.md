---
title: "Time, Clocks, and the Ordering of Events in a Distributed System 论文"
date: 2021-04-19T14:28:46+08:00
tags: 
  - 分布式系统
---

摘要：论文研究在分布式系统中，事件发生先后顺序的概念，并展示了如何定义事件之间的偏序。论文给出了一种用于同步逻辑时钟系统的分布式算法，该逻辑时钟可用于对事件做全序排序。其中，全序是描述解决同步问题的一种方法。该算法专门用于同步物理时钟。

# 引入｜Introduction

> The concept of time is fundamental to our way of thinking. It is derived from the more basic concept of the order in which events occur. We say that something happened at 3:15 if it occurred after our clock read 3:15 and before it read 3:16. The concept of the temporal ordering of events pervades our thinking about systems. For example, in an airline reservation system we specify that a request for a reservation should be granted if it is made before the flight is filled. However, we will see that this concept must be carefully reexamined when considering events in a distributed system.

时间的概念是我们思考的基础。而它源于事件发生顺序这一更基础的概念。当一件事情发生在时钟显示 3:15 且未到 3:16 之前，那我们就说它发生在 3:15。对事件的时间顺序概念遍布于我们对系统的思考。例如，我们在机票预定系统中发起的预定请求，如果它发生在航班订满之前，那就应该被接受。但在分布式系统中，我们会发现事件的时间顺序概念需要被重新审视。

> A distributed system consists of a collection of distinct processes which are spatially separated, and which communicate with one another by exchanging messages. A network of interconnected computers, such as the ARPA net, is a distributed system. A single computer can also be viewed as a distributed system in which the central control unit, the memory units, and the input-output channels are separate processes. A system is distributed if the message transmission delay is not negligible compared to the time between events in a single process.

分布式系统由空间上彼此分开的一组独立进程组成，进程间通过交换消息进行通信。计算机互联的网络，比如 ARPANET（阿帕网）就是一个分布式系统。一台集成了 CPU、内存、I/O 通道等独立处理单元的计算机也可以被视为分布式系统。如果相对于单进程中事件之间的时间，消息传输的延时大到不可忽略时，系统就是分布式的。

> We will concern ourselves primarily with systems of spatially separated computers. However, many of our remarks will apply more generally. In particular, a multiprocessing system on a single computer involves problems similar to those of a distributed system because of the unpredictable order in which certain events can occur.

本文主要关注空间分离的计算机系统。但我们的诸多观点可以得到更普遍的应用。特别的，由于不可预知的事件发生顺序，单机上多进程系统也涉及到类似分布式系统中的问题。

> In a distributed system, it is sometimes impossible to say that one of two events occurred first. The relation " happened before" is therefore only a partial ordering of the events in the system. We have found that problems often arise because people are not fully aware of this fact and its implications.

在分布式系统中，有时候无法确定两个事件哪个先发生。「之前发生」（happened before）只是系统中事件之间的偏序（Partial Ordering）。我们发现，由于人们没有充分认知到这个事实和它的含义，导致问题的出现。

> In this paper, we discuss the partial ordering defined by the " happened before" relation, and give a distributed algorithm for extending it to a consistent total ordering of all the events. This algorithm can provide a useful mechanism for implementing a distributed system. We illustrate its use with a simple method for solving synchronization problems. Unexpected, anomalous behavior can occur if the ordering obtained by this algorithm differs from that perceived by the user. This can be avoided by introducing real, physical clocks. We describe a simple method for synchronizing these clocks, and derive an upper bound on how far out of synchrony they can drift.

在本论文中，我们讨论由「之前发生」所定义的偏序，提供一个分布式算法来将其扩展成对所有事件一致的全序（Total Ordering）。该算法提供了实现分布式系统的有效途径。我们用解决同步问题的一个简单方法，来说明该算法的使用。然而，如果通过该算法获取的事件顺序和用户感知的不同时，会导致异常行为。这可以通过引入真实的物理时钟来规避。我们描述了一种用于同步这些时钟的简单方法，并推导了时钟同步漂移的误差上限。 

# 偏序｜The Partial Ordering

> Most people would probably say that an event a happened before an event b if a happened at an earlier time than b. They might justify this definition in terms of physical theories of time. However, if a system is to meet a specification correctly, then that specification must be given in terms of events observable within the system. If the specification is in terms of physical time, then the system must contain real clocks. Even if it does contain real clocks, there is still the problem that such clocks are not perfectly accurate and do not keep precise physical time. We will therefore define the " happened before" relation without using physical clocks.

大部分人会认为，如果事件 A 发生的时间比事件 B 发生时间早，则事件 A 是在事件 B 「之前发生」。他们根据物理时间的理论来证明该定义的正确性。然而，如果系统要正确地满足一项规约，则该规约必须根据系统可观测的事件给出。如果规约是基于物理时间，那么系统必须要包含真实的时钟。即使包含了真实时钟，仍然存在时钟非完美精确和保持精准物理时间的问题。因此我们不使用物理时钟来定义「之前发生」这一关系。

> We begin by defining our system more precisely. We assume that the system is composed of a collection of processes. Each process consists of a sequence of events. Depending upon the application, the execution of a subprogram on a computer could be one event, or the execution of a single machine instruction could be one event. We are assuming that the events of a process form a sequence, where a occurs before b in this sequence if a happens before b. In other words, a single process is defined to be a set of events with an a priori total ordering. This seems to be what is generally meant by a process. It would be trivial to extend our definition to allow a process to split into distinct subprocesses, but we will not bother to do so.

我们从更精准的定义系统开始。假设系统由一组进程组成。每个进程包含了一系列事件。根据应用程序的不同，事件可以是执行子程序，或者是执行单个机器指令。我们假设一个进程中的事件组成一个序列，当`a`在`b`「之前发生」，则事件序列里`a`就在`b`之前。换个说法，进程是一组全序事件的集合。这似乎也是通常意义上进程的含义。我们也可以把上述定义扩展到子进程，但没必要这么做。

> We assume that sending or receiving a message is an event in a process. We can then define the " happened before" relation, denoted by "->", as follows.

假设发送或接受消息是进程中的事件。我们可以用符号`->`表示「之前发生」，如下所示：

> Definition. The relation "->" on the set of events of a system is the smallest relation satisfying the following three conditions: (1) If a and b are events in the same process, and a comes before b, then a -> b. (2) If a is the sending of a message by one process and b is the receipt of the same message by another process, then a -> b. (3) If a -> b and b -> c then a -> c. Two distinct events a and b are said to be concurrent if a -/-> b and b -/-> a.

**定义**。系统中一组事件之间的`->`关系，是满足以下三个条件的最小关系：

1. 如果 a 和 b 是同一进程中的事件，且 a 在 b 之前，则 a -> b；
2. 如果 a 是一个进程的消息发送事件，b 是另一进程的消息接收事件，则 a -> b ；
3. 如果 a -> b 且 b -> c ，则 a -> c。如果两个独立事件满足 a !-> b 且 b !-> a ，则二者并行（concurrent）；

> We assume that a -/-> a for any event a. (Systems in which an event can happen before itself do not seem to be physically meaningful.) This implies that -/-> is an irreflexive partial ordering on the set of all events in the system.

假设任意事件 a，a !-> a（事件在自身之前发生的系统，并不存在物理意义）。这表明`->`表示的是，系统中事件之间非自反性的偏序关系。

> It is helpful to view this definition in terms of a "space-time diagram" such as Figure 1. The horizontal direction represents space, and the vertical direction represents time--later times being higher than earlier ones. The dots denote events, the vertical lines denote processes, and the wavy lines denote messagesfl It is easy to see that a -> b means that one can go from a to b in the diagram by moving forward in time along process and message lines. For example, we have p<sub>1</sub> -> r<sub>4</sub> in Figure 1.

结合下图 1 所示的时空图，可以帮助我们理解上述定义。其中横轴表示空间，纵轴表示时间——时间靠后则纵坐标越大。图中的点表示事件，竖向的直线表示进程，曲线表示进程间传递的消息。显而易见，a -> b 表示在进程间通过消息，从 a 到达 b。比如图 1 中有 *p*<sub>1</sub> -> *r*<sub>4</sub>。

![space-time-fig-1](/images/clcok-space-time-fig-1.png)

> Another way of viewing the definition is to say that a -> b means that it is possible for event a to causally affect event b. Two events are concurrent if neither can causally affect the other. For example, events p<sub>3</sub> and q<sub>3</sub> of Figure 1 are concurrent. Even though we have drawn the diagram to imply that q<sub>3</sub> occurs at an earlier physical time than p<sub>3</sub>, process P cannot know what process Q did at q<sub>3</sub> until it receives the message at p<sub>4</sub>, (Before event p<sub>4</sub>, P could at most know what Q was planning to do at q<sub>3</sub>.)

对该定义的另一种理解是，a -> b 表示事件 a 有可能导致事件 b 发生。当两个事件互相不为因果时，两者就是并行的。举例来说，图 1 里的事件 *p*<sub>3</sub> 和 *q*<sub>3</sub> 是并行发生的，即使图中描述的情形是 *q*<sub>3</sub> 发生的物理时间是在在 *p*<sub>3</sub> 之前，但对进程 P 而言，在 *p*<sub>4</sub> 时间点收到消息之前，它无法得知进程 Q 在 *q*<sub>3</sub> 时在做什么。（在事件 *p*<sub>4</sub> 之前，进程 P 最多知道进程 Q 在 *q*<sub>3</sub> 时将要做什么）。

> This definition will appear quite natural to the reader familiar with the invariant space-time formulation of special relativity, as described for example in [1] or the first chapter of [2]. In relativity, the ordering of events is defined in terms of messages that could be sent. However, we have taken the more pragmatic approach of only considering messages that actually are sent. We should be able to determine if a system performed correctly by knowing only those events which did occur, without knowing which events could have occurred.

这个定义对于熟悉狭义相对论不变时空方程的读者，理解起来非常自然。现实中，通过**可能被发送**的消息来定义事件顺序。但是我们采用更加务实的办法，即只考虑**实际被发送**的消息。当系统知道明确已发生的事件，我们就可以确定系统是否正确运行，而无需知道那些可能发生的事件。

# 逻辑时钟｜Logical Clocks

> We now introduce clocks into the system. We begin with an abstract point of view in which a clock is just a way of assigning a number to an event, where the number is thought of as the time at which the event occurred. More precisely, we define a clock C<sub>i</sub> for each process P<sub>i</sub> to be a function which assigns a number C<sub>i</sub>\<a\> to any event a in that process. The entire system ofclbcks is represented by the function C which assigns to any event b the number C\<b\>, where C\<b\> = C<sub>j</sub>(b) if b is an event in process P<sub>j</sub>. For now, we make no assumption about the relation of the numbers C<sub>i</sub>\<a\> to physical time, so we can think of the clocks Ci as logical rather than physical clocks. They may be implemented by counters with no actual timing mechanism.

现在，我们引入时钟。从一个抽象的观点开始——时钟是为事件分配编号的方式，其中编号可看作为事件发生的时间。更精确的表述，对于任意进程 *P*<sub>i</sub>，定义时钟 *C*<sub>i</sub>，其中，*C*<sub>i</sub>(a) 表示进程 *P*<sub>i</sub> 中事件 a 的编号分配函数。整个时钟系统通过函数 C 来分配，如果事件 b 在进程 *P*<sub>j</sub> 中，那么 *C*(b) = *C*<sub>j</sub>(b)。到目前为止，我们没有做任何关于时钟 *C*<sub>i</sub>(a) 和物理时间关系的假设，所以我们可以把 *C*<sub>i</sub>(a) 看成是逻辑时钟而非物理时钟。逻辑时钟可以不通过真实的计时工具来进行计数。

> We now consider what it means for such a system of clocks to be correct. We cannot base our definition of correctness on physical time, since that would require introducing clocks which keep physical time. Our definition must be based on the order in which events occur. The strongest reasonable condition is that if an event a occurs before another event b, then a should happen at an earlier time than b. We state this condition more formally as follows.<br/></br>Clock Condition. For any events a, b:</br>&emsp;&emsp;&emsp;&emsp;if a -> b then C(a) < C(b).

我们现在来思考该时钟系统正确性的含义。我们不能把定义的正确性建立在物理时钟之上，否则会导致引入记录物理时间的时钟。逻辑时钟的定义必须基于事件发生的顺序。最合理的条件是，如果事件 a 发生在事件 b 之前，那么 a 的发生事件应该比 b 更早。通过下面的式子更正式的进行表达该条件：

```plain
时钟条件，对于任意事件 a、b：
            if a -> b then C(a) < C(b)
```

> Note that we cannot expect the converse condition to hold as well, since that would imply that any two concurrent events must occur at the same time. In Figure 1, p<sub>2</sub> and p<sub>3</sub> are both concurrent with q<sub>3</sub>, so this would mean that they both must occur at the same time as q<sub>3</sub>, which would contradict the Clock Condition because p<sub>2</sub> -> p<sub>3</sub>.

注意，上述式子的反推是不成立的（C(a) < C(b)，不能反推出 a -> b），否则就意味着两个并行的事件必须发生在同一时间。在图 1 中，事件 *p*<sub>2</sub>、*p*<sub>3</sub> 均和事件 *q*<sub>3</sub> 并行，如果要求它们必须和 *q*<sub>3</sub> 在相同时间发生，就和时钟条件 *p*<sub>2</sub> -> *p*<sub>3</sub> 相矛盾。

> It is easy to see from our definition of the relation "->" that the Clock Condition is satisfied if the following two conditions hold.</br>&emsp;C1. If a and b are events in process P<sub>i</sub>, and a comes before b, then C<sub>i</sub>(a) < C<sub>i</sub>(b).<br>&emsp;C2. If a is the sending of a message by process P<sub>i</sub> and b is the receipt of that message by process P<sub>j</sub>, then C<sub>i</sub>(a) < C<sub>j</sub>(b).

从对`->`关系的定义中，容易得出，满足时钟条件需要符合以下两点：

- C1: 当进程 P<sub>i</sub> 中的事件 a 在事件 b 之前，则 *C*<sub>i</sub>(a) < *C*<sub>i</sub>(b)
- C2: 当事件 a 是进程 P<sub>i</sub> 的消息发送事件，事件 b 是进程 P<sub>j</sub> 的消息接收事件，则 *C*<sub>i</sub>(a) < *C*<sub>j</sub>(b)

> Let us consider the clocks in terms of a space-time diagram. We imagine that a process clock "ticks" through every number, with the ticks occurring between the process events. For example, if a and b are consecutive events in process P<sub>i</sub> with C<sub>i</sub>(a) = 4 and C<sub>i</sub>(b) = 7, then clock ticks 5, 6, and 7 occur between the two events. We draw a dashed "tick line" through all the likenumbered ticks of the different processes. The spacetime diagram of Figure 1 might then yield the picture in Figure 2. Condition C1 means that there must be a tick line between any two events on a process line, and condition C2 means that every message line must cross a tick line. From the pictorial meaning of ->, it is easy to see why these two conditions imply the Clock Condition.

结合时间-空间图来分析时钟。我们想象一个进程的时钟会对每个数字做「滴答」，且「滴答」发生在进程中的事件之间。举个例子，如果进程 P<sub>i</sub> 中的相邻事件 a 和 b，有 *C*<sub>i</sub>(a) = 4 和 *C*<sub>i</sub>(b) = 7，那么时钟会在这两个事件中间，依次滴答 5，6，7。我们把不同进程间连续的「滴答」用虚线连接，图 1 就变成如下图 2。条件 C1 意味着同一进程中任意两个事件必然存在一条「滴答」虚线；条件 C2 意味着任意消息线必然会穿过一条「滴答」线。通过对`->`关系的图示，很容易明白为什么满足上述两个条件 C1、C2 意味着时钟条件的成立。

![space-time-fig-2](/images/clcok-space-time-fig-2.png)

> We can consider the tick lines to be the time coordinate lines of some Cartesian coordinate system on spacetime. We can redraw Figure 2 to straighten these coordinate lines, thus obtaining Figure 3. Figure 3 is a valid alternate way of representing the same system of events as Figure 2. Without introducing the concept of physical time into the system (which requires introducing physical clocks), there is no way to decide which of these pictures is a better representation.

我们可以把「滴答」线作为时间-空间笛卡尔坐标系里的时间轴。将图 2 中的「滴答」线画直，就得到如下图 3。图 3 是图 2 所表达的事件系统的另一种表现形式。如果不引入物理时间（这会导致引入物理时钟），就无法决定哪个图示更好的表现了真实系统。

> The reader may find it helpful to visualize a two-dimensional spatial network of processes, which yields a three-dimensional space-time diagram. Processes and messages are still represented by lines, but tick lines become two-dimensional surfaces.

读者可能发现，如果把二维的网络进程可视化，构成一个三维的时间-空间图，会很有帮助。进程和消息仍然用线条表示，而「滴答」线则用二维平面来表示。

> Let us now assume that the processes are algorithms, and the events represent certain actions during their execution. We will show how to introduce clocks into the processes which satisfy the Clock Condition. Process P<sub>i</sub>'s clock is represented by a register C<sub>i</sub>, so that C<sub>i</sub>(a) is the value contained by C<sub>i</sub> during the event a. The value of C<sub>i</sub> will change between events, so changing C<sub>i</sub> does not itself constitute an event.

现在假设，执行过程就是算法，事件则表示执行的具体动作。我们会展示如何在进程执行过程中，引入满足时钟条件的时钟。进程 P<sub>i</sub> 的时钟用寄存器 C<sub>i</sub> 表示，因此 C<sub>i</sub>(a) 表示事件 a 发生时，寄存器 C<sub>i</sub> 的值。C<sub>i</sub> 的值会在事件之间变化，因此变更 C<sub>i</sub> 的值并不构成事件本身。

> To guarantee that the system of clocks satisfies the Clock Condition, we will insure that it satisfies conditions C1 and C2. Condition C1 is simple; the processes need only obey the following implementation rule:<br>&emsp;IR1. Each process P<sub>i</sub> increments C<sub>i</sub> between any two successive events.

要保证这个时钟系统可以满足时钟条件，我们要确保其同时满足条件 C1 和 C2。条件 C1 很简单，只需要进程遵循下面的规则：

- IR1. 进程 P<sub>i</sub> 中， C<sub>i</sub> 会在连续的事件中递增。

> To meet condition C2, we require that each message m contain a timestamp T<sub>m</sub> which equals the time at which the message was sent. Upon receiving a message timestamped T<sub>m</sub>, a process must advance its clock to be later than T<sub>m</sub>. More precisely, we have the following rule.<br>&emsp;IR2. (a) If event a is the sending of a message m by process P<sub>i</sub>, then the message m contains a timestamp T<sub>m</sub> = C<sub>i</sub>(a). (b) Upon receiving a message m, process P<sub>i</sub> sets C<sub>i</sub> greater than or equal to its present value and greater than T<sub>m</sub>.

要满足条件 C2，我们要求任意消息 m 包含它被发送的时间戳信息 T<sub>m</sub>。当另一进程接收到时间戳 T<sub>m</sub> 的消息时，该进程必须将其时钟调整到大于 T<sub>m</sub>。我们用下面的规则做更准确的描述：

- IR2. (a) 如果事件 a 是进程 P<sub>i</sub> 发送消息 m 的事件，而消息 m 包含了时间戳 T<sub>m</sub> = C<sub>i</sub>(a)。(b) 当进程 P<sub>j</sub> 接收到消息 m 时，P<sub>j</sub> 把 C<sub>j</sub> 设置为大于或等于它当前的值，且大于 T<sub>m</sub>。

> In IR2(b) we consider the event which represents the receipt of the message m to occur after the setting of C<sub>j</sub>. (This is just a notational nuisance, and is irrelevant in any actual implementation.) Obviously, IR2 insures that C2 is satisfied. Hence, the simple implementation rules IR1 and IR2 imply that the Clock Condition is satisfied, so they guarantee a correct system of logical clocks.

在规则 IR2(b) 中，我们认为接收消息 m 的事件发生在 C<sub>j</sub> 被设置之后。很明显，规则 IR2 保证满足条件 C2。因此，规则 IR1 和 IR2 的实现，满足了时钟条件，从而保证正确的逻辑时钟系统。

# 全局事件顺序｜Ordering the Events Totally

> We can use a system of clocks satisfying the Clock Condition to place a total ordering on the set of all system events. We simply order the events by the times at which they occur. To break ties, we use any arbitrary total ordering < of the processes. More precisely, we define a relation => as follows: if a is an event in process P<sub>i</sub> and b is an event in process P<sub>j</sub>, then a => b if and only if either (i) Ci(a) < Cj(b) or (ii) Ci(a) = Cj(b) and Pi < Pj. It is easy to see that this defines a total ordering, and that the Clock Condition implies that if a -> b then a => b. In other words, the relation => is a way of completing the "happened before" partial ordering to a total ordering.

我们可以用满足时钟条件的时钟系统，给系统中所有事件设置全局的顺序。简单的通过事件发生的时间进行排序。为了打破平局，我们使用了进程间的任意的一个全序关系`<`。更准确的说，我们定义了一种关系`=>`:如果 a 是进程 P<sub>i</sub> 种的事件，b 是进程 P<sub>j</sub> 中的事件，则当且仅当满足以下任意条件时，a => b：
- C<sub>i</sub>(a) < C<sub>j</sub>(b)
- C<sub>i</sub>(a) = C<sub>j</sub>(b) 且 P<sub>i</sub> < P<sub>j</sub> 。

容易发现这定义了全序（Total ordering），且时钟条件表明如果 a -> b，则 a => b。换言之，`=>` 关系是把「之前发生」（happened before）的偏序关系补全成全序关系的一种方式。

> The ordering => depends upon the system of clocks C<sub>i</sub>, and is not unique. Different choices of clocks which satisfy the Clock Condition yield different relations =>. Given any total ordering relation => which extends ->, there is a system of clocks satisfying the Clock Condition which yields that relation. It is only the partial ordering which is uniquely determined by the system of events.

全序关系`=>`依赖时钟系统 C<sub>i</sub>，但并不唯一。选择不同的时钟，会产生不同的`=>`关系。给定任意一个由偏序关系`->`扩展而来的全序关系`=>`，都存在一个满足时钟条件的时钟，从而构成该关系。只有偏序关系`->`才是系统中的事件唯一确定的。

> Being able to totally order the events can be very useful in implementing a distributed system. In fact, the reason for implementing a correct system of logical clocks is to obtain such a total ordering. We will illustrate the use of this total ordering of events by solving the following version of the mutual exclusion problem. Consider a system composed of a fixed collection of processes which share a single resource. Only one process can use the resource at a time, so the processes must synchronize themselves to avoid conflict. We wish to find an algorithm for granting the resource to a process which satisfies the following three conditions: <br>(I) A process which has been granted the resource must release it before it can be granted to another process.<br>(II) Different requests for the resource must be granted in the order in which they are made.<br>(III) If every process which is granted the resource eventually releases it, then every request is eventually granted.

确定事件的全序关系，对实现分布式系统非常有用。实际上，实现逻辑时钟系统的目的就是为了获取全序关系。我们会通过解决版本互斥问题来描述事件全序关系的使用。对于由一组共享单一资源的进程所组成的系统，同一时刻只能有一个进程使用该资源，因此进程间必须同步以避免冲突。我们希望找到一种满足以下 3 个条件的资源分配算法：

1. 进程要获取资源，必须要等待当前获取该资源的进程将其释放；
2. 对资源的多个请求，必须要按其创建的顺序依次处理；
3. 如果获取资源的进程最终都会释放掉资源，则所有对资源的请求都将最终成功；

> We assume that the resource is initially granted to exactly one process.

我们假定单一资源初始时被授予单个进程。

> These are perfectly natural requirements. They precisely specify what it means for a solution to be correct/ Observe how the conditions involve the ordering of events. Condition II says nothing about which of two concurrently issued requests should be granted first.

这都是非常自然的条件。它们准确地说明了什么样的方案才是正确的。观察上述条件是是如何关系到事件顺序的。条件-2 没有说明对并发请求资源的授予顺序。

> It is important to realize that this is a nontrivial problem. Using a central scheduling process which grants requests in the order they are received will not work, unless additional assumptions are made. To see this, let P<sub>0</sub> be the scheduling process. Suppose P<sub>1</sub> sends a request to P<sub>0</sub> and then sends a message to P<sub>2</sub>. Upon receiving the latter message, P<sub>2</sub> sends a request to P<sub>0</sub>. It is possible for P<sub>2</sub>'s request to reach P<sub>0</sub> before P<sub>1</sub>'s request does. Condition II is then violated if P<sub>2</sub>'s request is granted first.

意识到这是一个关键问题很重要。通过中心进程同一分配资源的方式不可取，除非设定额外的假设。来看这样一个场景，P<sub>0</sub> 是做资源分配的中心进程。假设进程 P<sub>1</sub> 向 P<sub>0</sub> 发送资源请求，再向 P<sub>2</sub> 发送一条消息。在接收到信息后，P<sub>2</sub>向 P<sub>0</sub> 发送资源请求。P<sub>2</sub> 的请求可能会比 P<sub>1</sub> 先到达 P<sub>0</sub>，如果 P<sub>2</sub> 的资源请求被先授予，则违背了条件-2 的要求。

> To solve the problem, we implement a system of clocks with'rules IR1 and IR2, and use them to define a total ordering => of all events. This provides a total ordering of all request and release operations. With this ordering, finding a solution becomes a straightforward exercise. It just involves making sure that each process learns about all other processes' operations.

要解决该问题，我们实现了一个符合 IR1 和 IR2 的时钟系统，并且通过该时钟系统来定义所有事件的全序关系`=>`。这提供了所有资源请求和释放处理的全序关系。有了这个顺序，找到解决方案变得直观可行。只要确保每个进程知道所有其他进程的处理。

> To simplify the problem, we make some assumptions. They are not essential, but they are introduced to avoid distracting implementation details. We assume first of all that for any two processes P<sub>i</sub> and P<sub>j</sub>, the messages sent from P<sub>i</sub> to P<sub>j</sub> are received in the same order as they are sent. Moreover, we assume that every message is eventually received. (These assumptions can be avoided by introducing message numbers and message acknowledgment protocols.) We also assume that a process can send messages directly to every other process.

为了简化问题，我们做出一些假设。它们非必需，但它们的引入可以规避过多的细节。首先假设任意两个进程 P<sub>i</sub> 和 P<sub>j</sub>，P<sub>i</sub> 发送到 P<sub>j</sub> 的多个消息，会按照它们的发送顺序依次被接收。此外，我们假设所有消息最终都会被接收（避免引入消息序号和消息确认协议）。我们还假设进程可以直接向其他任意进程发送消息。

> Each process maintains its own request queue which is never seen by any other process. We assume that the request queues initially contain the single message T<sub>0</sub>:P<sub>0</sub> requests resource, where P<sub>0</sub> is the process initially granted the resource and T<sub>0</sub> is less than the initial value of any clock.

每个进程维护其请求队列，并对其他进程不可见。假设请求队列初始时包含一条资源请求消息 T<sub>0</sub>:P<sub>0</sub>，其中 P<sub>0</sub> 表示初始时获得资源的进程，T<sub>0</sub> 小于任意时钟的初始时间。

> The algorithm is then defined by the following five rules. For convenience, the actions defined by each rule are assumed to form a single event.

算法由以下 5 条规则定义。方便起见，假定每个规则定义的动作都构成一个单一事件。

> 1. To request the resource, process P<sub>i</sub> sends the message T<sub>m</sub>:P<sub>i</sub> requests resource to every other process, and puts that message on its request queue, where T<sub>m</sub> is the timestamp of the message.

1. 规则 1: 为了请求资源，进程 P<sub>i</sub> 发送消息 T<sub>m</sub>:P<sub>i</sub> 到所有其他进程，并把该消息放进自己的请求队列里。T<sub>m</sub> 是消息的时间戳。

> 2. When process P<sub>j</sub> receives the message T<sub>m</sub>:P<sub>i</sub> requests resource, it places it on its request queue and sends a (timestamped) acknowledgment message to P<sub>i</sub>

2. 规则 2: 当进程 P<sub>j</sub> 接收到消息 T<sub>m</sub>:P<sub>i</sub>，将其放入到自己的请求队列，并发送一个带时间戳的 ack 消息到 P<sub>i</sub>。

> 3. To release the resource, process P<sub>i</sub> removes any T<sub>m</sub>:P<sub>i</sub> requests resource message from its request queue and sends a (timestamped) P<sub>i</sub> releases resource message to every other process.

3. 规则 3: 为了释放资源，进程 P<sub>i</sub> 移除自己所有 T<sub>m</sub>:P<sub>i</sub> 消息，并发送一个带时间戳的 P<sub>i</sub> 释放资源的消息给所有其他进程。

> 4. When process P<sub>j</sub> receives a P<sub>i</sub> releases resource message, it removes any T<sub>m</sub>:P<sub>i</sub> requests resource message from its request queue.

4. 规则 4: 当进程 P<sub>j</sub> 接收到 P<sub>i</sub> 释放资源的消息，就删除自己请求队列中的所有 T<sub>m</sub>:P<sub>i</sub> 消息。

> 5. Process P<sub>i</sub> is granted the resource when the following two conditions are satisfied: (i) There is a T<sub>m</sub>:P<sub>i</sub> requests resource message in its request queue which is ordered before any other request in its queue by the relation =>. (To define the relation "=>" for messages, we identify a message with the event of sending it.) (ii) P<sub>i</sub> has received a message from every other process timestamped later than T<sub>m</sub>.<br>Note that conditions (i) and (ii) of rule 5 are tested locally by P<sub>i</sub>.

5. 规则 5: 进程 P<sub>i</sub> 在满足下列两个条件时，会被授予资源：i. P<sub>i</sub> 的请求队列中有一条消息 T<sub>m</sub>:P<sub>i</sub> 位于队头，即`=>`关系。（为了定义消息的`=>`关系，我们会识别发送消息的事件）ii. P<sub>i</sub> 接收到所有其他进程返回的时间戳晚于 T<sub>m</sub> 的 ack 消息。注意，条件 i 和 ii 只需由 P<sub>i</sub> 本地确认。

> It is easy to verify that the algorithm defined by these rules satisfies conditions I-III. First of all, observe that condition (ii) of rule 5, together with the assumption that messages are received in order, guarantees that P<sub>i</sub> has learned about all requests which preceded its current request. Since rules 3 and 4 are the only ones which delete messages from the request queue, it is then easy to see that condition I holds. Condition II follows from the fact that the total ordering => extends the partial ordering ->. Rule 2 guarantees that after Pi requests the resource, condition (ii) of rule 5 will eventually hold. Rules 3 and 4 imply that if each process which is granted the resource eventually releases it, then condition (i) of rule 5 will eventually hold, thus proving condition III.

验证由以上规则所定义的算法满足前面定义的条件 I 到条件 III 很简单。首先，观察规则 5 的条件 ii，结合对消息有序接收的前提设定，则可以保证 P<sub>i</sub> 已经接收到所有排在它当前请求之前的请求。规则 3、4 是仅有的会删除消息的规则，所以很容易看出符合条件 I。条件 II 基于全序`=>`由偏序`->`扩展的事实而来。规则 2 保证了在 P<sub>i</sub> 发出资源请求后，规则 5 条件 ii 最终一定会满足。规则 3 和规则 4 意味着如果进程被授予资源后最终会释放资源，则规则 5 条件 i 最终会满足，从而证明条件 III。

> This is a distributed algorithm. Each process independently follows these rules, and there is no central synchronizing process or central storage. This approach can be generalized to implement any desired synchronization for such a distributed multiprocess system. The synchronization is specified in terms of a State Machine, consisting of a set C of possible commands, a set S of possible states, and a function e: C×S->S. The relation e(C, S) = S' means that executing the command C with the machine in state S causes the machine state to change to S'. In our example, the set C consists of all the commands P<sub>i</sub> requests resource and P<sub>i</sub> releases resource, and the state consists of a queue of waiting request commands, where the request at the head of the queue is the currently granted one. Executing a request command adds the request to the tail of the queue, and executing a release command removes a command from the queue.

这是一个分布式算法。每个进程各自遵循上述规则，且不存在中心化的同步进程或存储。该方法可以通用化的实现任何分布式系统的同步机制。同步过程是依据**状态机**来指定，由集合`C`表示可能的指令，集合`S`表示可能的状态，以及函数`e: C * S -> S` 组成。关系式`e(C, S) = S'`表示在状态为`S`时执行命令`C`，使状态机流转到`S'`。在前面的例子中，集合`C`包括 P<sub>i</sub> 所有请求资源和释放资源的命令，集合`S`包括包括处于等待状态的请求命令队列，该队列头部是正要被授予资源的请求。执行申请资源命令会添加到队尾，而执行释放资源的命令则会从队头移除命令。

> Each process independently simulates the execution of the State Machine, using the commands issued by all the processes. Synchronization is achieved because all processes order the commands according to their timestamps (using the relation =>), so each process uses the same sequence of commands. A process can execute a command timestamped T when it has learned of all commands issued by all other processes with timestamps less than or equal to T. The precise algorithm is straightforward, and we will not bother to describe it.

每个进程使用所有进程发出的命令，独立地模拟状态机的执行。之所以能够实现同步，是因为所有进程都根据其时间戳对命令进行排序（使用全序关系`=>`），所以每个进程使用相同的命令序列。当进程已经获悉所有其他进程发出的`<= T`的命令时，就可以执行带有时间戳`T`的命令。精确的算法已经很直观了，本文不再赘述。

> This method allows one to implement any desired form of multiprocess synchronization in a distributed system. However, the resulting algorithm requires the active participation of all the processes. A process must know all the commands issued by other processes, so that the failure of a single process will make it impossible for any other process to execute State Machine commands, thereby halting the system.

这个方法可是在分布式系统中实现任何形式的多进程同步。TODO: P562-

![space-time-fig-3](/images/clcok-space-time-fig-3.png)

# 反常行为｜Anomalous Behavior

# 结论

# 附

--------

[Lamport 论文链接](https://lamport.azurewebsites.net/pubs/time-clocks.pdf)
