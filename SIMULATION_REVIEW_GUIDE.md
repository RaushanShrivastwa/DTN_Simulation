# DTN Simulation & Routing Protocols: Comprehensive Review & Viva Guide

This guide is a complete, exhaustive reference manual for the **Opportunistic Network Environment (ONE) Simulator** project. It explains all network entity configurations, configuration files, routing algorithms (`ImprovedProphetRouter`, `MaxPropRouter`, and `MaxPropDijkstra`), UI modifications, and anticipated questions with detailed answers for academic review and project defense (viva).

---

## Table of Contents
1. [Simulation Entity Configuration & Architecture](#1-simulation-entity-configuration--architecture)
   - [Configuration Files Overview](#configuration-files-overview)
   - [How Nodes and Groups are Configured](#how-nodes-and-groups-are-configured)
   - [Node ID and Addressing Conventions](#node-id-and-addressing-conventions)
   - [Source and Destination Setup](#source-and-destination-setup)
   - [Radio Interfaces & Transmission Parameters](#radio-interfaces--transmission-parameters)
   - [Movement Models & World Dimensions](#movement-models--world-dimensions)
2. [Step-by-Step Customization Guide](#2-step-by-step-customization-guide)
   - [How to Change the Number of Nodes](#how-to-change-the-number-of-nodes)
   - [How to Change Source and Destination Nodes](#how-to-change-source-and-destination-nodes)
   - [How to Change Transmission Range and Speed](#how-to-change-transmission-range-and-speed)
   - [How to Change Simulation Area (Map Size)](#how-to-change-simulation-area-map-size)
   - [How to Change Buffer Size and Message Lifetimes](#how-to-change-buffer-size-and-message-lifetimes)
3. [Deep Dive: Routing Algorithms Implementation](#3-deep-dive-routing-algorithms-implementation)
   - [Hybrid Epidemic-PRoPHET (`ImprovedProphetRouter.java`)](#hybrid-epidemic-prophet-improvedprophetrouterjava)
     - [Architecture & Two-Phase Design](#architecture--two-phase-design)
     - [Mathematical Formulations](#mathematical-formulations-prophet)
     - [Code Breakdown](#code-breakdown-improvedprophetrouter)
   - [MaxProp & Dijkstra Cost Graph (`MaxPropRouter.java`)](#maxprop--dijkstra-cost-graph-maxproprouterjava)
     - [Core Principles of MaxProp](#core-principles-of-maxprop)
     - [Meeting Probability Updates & Normalization](#meeting-probability-updates--normalization)
     - [Dijkstra Shortest Path Cost Formulation](#dijkstra-shortest-path-cost-formulation)
     - [Adaptive Threshold Partitioning & Packet Prioritization](#adaptive-threshold-partitioning--packet-prioritization)
     - [Buffer Management & ACK Flooding](#buffer-management--ack-flooding)
4. [Custom Simulator Enhancements Added to this Project](#4-custom-simulator-enhancements-added-to-this-project)
   - [Real-time Metrics Dashboard (`MetricsPanel.java`)](#real-time-metrics-dashboard-metricspaneljava)
   - [Hop Journey & Transmission Cards (`PathHopsPanel.java`)](#hop-journey--transmission-cards-pathhopspaneljava)
   - [Full-Width Event Log & Selections Bar (`EventLogPanel.java`)](#full-width-event-log--selections-bar-eventlogpaneljava)
   - [Interactive Animated Transmission Beams (`MessagePathGraphic.java`)](#interactive-animated-transmission-beams-messagepathgraphicjava)
   - [Simulation Speed Multipliers (`GUIControls.java`)](#simulation-speed-multipliers-guicontrolsjava)
5. [Comprehensive Viva & Review Q&A (20 Critical Questions)](#5-comprehensive-viva--review-qa-20-critical-questions)

---

## 1. Simulation Entity Configuration & Architecture

### Configuration Files Overview
In the ONE Simulator, all parameters are declared in flat key-value settings files (e.g., `SingleMessagePath_settings.txt` or `default_settings.txt`). The simulation engine parses these using the `core.Settings` class.

Key files involved:
- **`SingleMessagePath_settings.txt`**: Main active configuration file specifying host groups, router parameters, message generation events, and radio interfaces.
- **`default_settings.txt`**: Base template containing default properties inherited when specific values are omitted.
- **`src/routing/ImprovedProphetRouter.java`**: Implements the hybrid routing logic (Phase 1 Limited Epidemic + Phase 2 PRoPHET).
- **`src/routing/MaxPropRouter.java`**: Implements the MaxProp protocol using probability calculation and Dijkstra's algorithm.

---

### How Nodes and Groups are Configured
Nodes in DTN are grouped into **Host Groups** sharing movement models, speed ranges, buffer sizes, and routing protocols.

In `SingleMessagePath_settings.txt`:
```properties
# 1. Declare the total number of host groups
Scenario.nrofHostGroups = 2

# 2. Configure common group properties (inherited by Group1 and Group2)
Group.movementModel = RandomWaypoint
Group.router = ImprovedProphetRouter
Group.bufferSize = 50M
Group.nrofInterfaces = 1
Group.interface1 = Interface1

# 3. Configure Group 1 (Pedestrians)
Group1.groupID = p
Group1.nrofHosts = 4
Group1.speed = 0.5, 1.5
Group1.waitTime = 0, 20

# 4. Configure Group 2 (Vehicles / Cars)
Group2.groupID = c
Group2.nrofHosts = 2
Group2.speed = 2.7, 5.0
Group2.waitTime = 0, 20
```

---

### Node ID and Addressing Conventions
The ONE Simulator assigns sequential integer host addresses starting at `0`:
- **Group 1** (`groupID = p`, `nrofHosts = 4`):
  - Internal IDs: `0, 1, 2, 3`
  - Display Names: `p0, p1, p2, p3`
- **Group 2** (`groupID = c`, `nrofHosts = 2`):
  - Internal IDs: `4, 5`
  - Display Names: `c4, c5`
- Total nodes in the network = `4 + 2 = 6` nodes (IDs `0` through `5`).

> [!IMPORTANT]
> When configuring event generators or routing rules, **internal IDs (0-indexed integers)** are used, **not** the lettered string names.

---

### Source and Destination Setup
Traffic injection is managed by an **Event Generator** defined under `Events`:
```properties
Events.nrof = 1
Events1.class = MessageEventGenerator

# Message creation interval: (min, max) in seconds
Events1.interval = 100, 100

# Simulation time window during which messages are generated: [start, end]
Events1.time = 0, 0

# Message payload size (bytes)
Events1.size = 500k, 500k

# SOURCE HOST: [min inclusive, max exclusive]
Events1.hosts = 0, 1

# DESTINATION HOST: [min inclusive, max exclusive]
Events1.tohosts = 5, 6

# Message ID Prefix
Events1.prefix = M
```

**How Source and Destination are selected:**
- `Events1.hosts = 0, 1`: The generator chooses randomly from $[0, 1)$. The only integer in this range is `0` $\rightarrow$ **Node `p0` is the Source**.
- `Events1.tohosts = 5, 6`: The generator chooses randomly from $[5, 6)$. The only integer in this range is `5` $\rightarrow$ **Node `c5` is the Destination**.
- `Events1.time = 0, 0`: Creates exactly 1 message at simulation second $0.0s$.

---

### Radio Interfaces & Transmission Parameters
Wireless communication characteristics are defined under `Scenario.interfaces`:
```properties
Scenario.interfaces = Interface1

Interface1.type = SimpleBroadcastInterface
Interface1.transmitSpeed = 250k    # Data rate: 250 KB/sec (2,000,000 bps)
Interface1.transmitRange = 100     # Radio range: 100 meters
```
- A connection between node $A$ and node $B$ is established when:
  $$\text{EuclideanDistance}(A, B) \le \text{transmitRange} = 100\text{ m}$$
- Transmission transfer duration for message size $S$ is calculated as:
  $$T_{\text{transfer}} = \frac{S}{\text{transmitSpeed}} = \frac{500\text{ KB}}{250\text{ KB/s}} = 2.0\text{ seconds}$$

---

### Movement Models & World Dimensions
Physical topology dimensions and spatial boundaries:
```properties
MovementModel.worldSize = 300, 300   # 300m width x 300m height boundary
MovementModel.rngSeed = 1            # Random seed for reproducible node walks
```
- `RandomWaypoint`: A node selects a random destination $(x, y) \in [0, 300] \times [0, 300]$, moves at a uniformly chosen speed between `speed.min` and `speed.max`, pauses for `waitTime` seconds upon arrival, and repeats.

---

## 2. Step-by-Step Customization Guide

### How to Change the Number of Nodes
Open `SingleMessagePath_settings.txt`:
1. Find `Group1.nrofHosts` and `Group2.nrofHosts`.
2. For example, to simulate **10 pedestrians** and **5 cars**:
   ```properties
   Group1.nrofHosts = 10
   Group2.nrofHosts = 5
   ```
3. Network addresses update automatically:
   - Pedestrians `p0` through `p9` (IDs `0` to `9`)
   - Cars `c10` through `c14` (IDs `10` to `14`)
   - Total nodes = `15` (IDs `0` to `14`)

---

### How to Change Source and Destination Nodes
Suppose you have 10 nodes (IDs `0` to `9`) and you want **Node #2** (`p2`) to send a message to **Node #8** (`c8`):
```properties
# Source = Node 2: range [2, 3) selects integer 2
Events1.hosts = 2, 3

# Destination = Node 8: range [8, 9) selects integer 8
Events1.tohosts = 8, 9
```
If you want random source and random destination across all nodes:
```properties
Events1.hosts = 0, 10
Events1.tohosts = 0, 10
```

---

### How to Change Transmission Range and Speed
In `SingleMessagePath_settings.txt`:
```properties
# Increase radio range from 100m to 150m (increases contact probability)
Interface1.transmitRange = 150

# Increase bandwidth from 250 KB/s to 1 MB/s (reduces transfer delay)
Interface1.transmitSpeed = 1M
```

---

### How to Change Simulation Area (Map Size)
```properties
# Change world size from 300x300 meters to 1000x1000 meters
MovementModel.worldSize = 1000, 1000
```
*(Larger world sizes decrease node contact frequency, challenging routing protocols with longer delays).*

---

### How to Change Buffer Size and Message Lifetimes
```properties
# Set node storage capacity to 100 Megabytes
Group.bufferSize = 100M

# Optionally configure message Time-To-Live (TTL) in minutes
# Group.msgTtl = 300   # 300 minutes (5 hours)
```

---

## 3. Deep Dive: Routing Algorithms Implementation

### Hybrid Epidemic-PRoPHET (`ImprovedProphetRouter.java`)

#### Architecture & Two-Phase Design
Standard PRoPHET suffers from high delivery delay during the cold-start phase because delivery predictabilities have not yet matured through contacts. Standard Epidemic routing achieves low latency but floods the network, exhausting node buffers and radio energy.

`ImprovedProphetRouter` combines both into an optimized hybrid protocol:
1. **Phase 1: Limited Epidemic Forwarding**
   - Active when:
     $$n_m < \text{maxForwards} \quad \text{AND} \quad \text{hopCount} < \text{maxHops}$$
   - Where $n_m$ is the number of times this specific message copy has been replicated, and $\text{hopCount}$ is the distance from source.
   - During Phase 1, the message is replicated unconditionally to any encountered neighbor lacking the message.
2. **Phase 2: PRoPHET Predictability Routing**
   - Activated once Epidemic limits are exhausted ($n_m \ge \text{maxForwards}$ OR $\text{hopCount} \ge \text{maxHops}$).
   - The node checks whether the encountered peer has a higher historical likelihood of delivering the message to the final destination:
     $$P(\text{peer}, \text{destination}) > P(\text{thisNode}, \text{destination})$$
   - Forwarding occurs **only if** this inequality holds.

---

#### Mathematical Formulations (PRoPHET)

##### 1. Encounter Update (Direct Contact)
When node $A$ encounters node $B$, the delivery predictability $P(A, B)$ increases:
$$P(A, B) = P(A, B)_{\text{old}} + \Big(1 - P(A, B)_{\text{old}}\Big) \times P_{\text{init}}$$
- $P_{\text{init}} \in [0, 1]$: Initialization constant (configured as `Group.pInit = 0.75`).
- If $P(A, B)_{\text{old}} = 0$, $P(A, B) = 0.75$.
- Subsequent encounters asymptotically push $P(A, B) \to 1.0$.

##### 2. Transitivity Update (Indirect Contact)
If node $A$ frequently meets node $B$, and node $B$ frequently meets node $C$, then node $A$ has a transitive probability of reaching $C$:
$$P(A, C) = \max\Big(P(A, C)_{\text{old}}, \; P(A, C)_{\text{old}} + \big(1 - P(A, C)_{\text{old}}\big) \times P(A, B) \times P(B, C) \times \beta\Big)$$
- $\beta \in [0, 1]$: Transitivity scaling factor (configured as `Group.beta = 0.25`).

##### 3. Predictability Aging (Decay Over Time)
If two nodes have not encountered each other for an extended duration, their delivery predictability decays:
$$P(A, B) = P(A, B) \times \gamma^k$$
- $\gamma \in (0, 1)$: Aging constant (configured as `Group.gamma = 0.98`).
- $k$: Elapsed time units:
  $$k = \frac{t_{\text{current}} - t_{\text{lastAging}}}{\text{secondsInTimeUnit}}$$
  *(Configured as `Group.secondsInTimeUnit = 30`).*

---

#### Code Breakdown (`ImprovedProphetRouter.java`)
- **Forwarding Decision Engine** (`tryOtherMessages()`, Lines 333–396):
  ```java
  int nm = getForwardCount(m);
  int hm = m.getHopCount();
  DTNHost destination = m.getTo();

  // Phase 1: Limited Epidemic check
  boolean isEpidemic = (nm < maxForwards) && (hm < maxHops);

  // Phase 2: PRoPHET check
  double myPred = getPredFor(destination);
  double peerPred = peerRouter.getPredFor(destination);
  boolean isProphet = !isEpidemic && (peerPred > myPred);

  // Transfer triggered if either condition holds
  if (isEpidemic || isProphet) {
      startTransfer(m, con);
  }
  ```
- **Incrementing Epidemic Count** (`transferDone()`, Lines 445–453):
  ```java
  if (nm < maxForwards && hm < maxHops) {
      myMsg.updateProperty(FORWARD_COUNT, Integer.valueOf(nm + 1));
  }
  ```
- **Encounter & Transitivity Updates** (`changedConnection()`, Lines 512–617):
  Updates local map `preds` on connection up event using $P_{\text{init}}$ and transitive factor $\beta$.

---

### MaxProp & Dijkstra Cost Graph (`MaxPropRouter.java`)

#### Core Principles of MaxProp
MaxProp (Burgess et al., IEEE INFOCOM 2006) is a high-performance DTN routing protocol designed for vehicle and opportunistic networks. It features:
1. Probability-based link costs.
2. Dijkstra's shortest path algorithm over the contact probability graph.
3. Adaptive buffer partitioning based on hop counts.
4. Active network-wide message deletion through Flooded Acknowledgment (ACK) lists.

---

#### Meeting Probability Updates & Normalization
In `src/routing/maxprop/MeetingProbabilitySet.java`:
Each node maintains a set of meeting probabilities $P(i, j)$ representing the probability that the next node encountered is node $j$:
1. When node $i$ meets node $j$, the probability is incremented by parameter $\alpha$ (default $\alpha = 1.0$):
   $$P_{\text{temp}}(i, j) = P(i, j) + \alpha$$
2. All probabilities in the set are normalized by dividing by $(1 + \alpha)$:
   $$P_{\text{new}}(i, k) = \frac{P(i, k)}{1 + \alpha} \quad \forall k \neq j$$
   $$P_{\text{new}}(i, j) = \frac{P(i, j) + \alpha}{1 + \alpha}$$
3. This guarantees that $\sum_{k} P(i, k) = 1.0$ at all times.

---

#### Dijkstra Shortest Path Cost Formulation
In `src/routing/maxprop/MaxPropDijkstra.java`:
- The "cost" or "distance" of a direct contact edge between node $u$ and node $v$ is defined as the complement of their meeting probability:
  $$\text{cost}(u, v) = 1 - P(u, v)$$
- If node $u$ meets node $v$ with high probability ($P \to 1.0$), the link cost is near $0$. If encounters are rare ($P \to 0$), the link cost approaches $1.0$.
- For any destination node $D$, MaxProp runs Dijkstra's algorithm from the current node's perspective over the topology graph:
  $$\text{PathCost}(S, D) = \sum_{(u, v) \in \text{path}} \big(1 - P(u, v)\big)$$
- The path with the minimum sum of cost complements is selected.

---

#### Adaptive Threshold Partitioning & Packet Prioritization
MaxProp calculates an adaptive hop-count threshold $x$ using `calcThreshold()`:
- It computes the average number of bytes transferred per contact opportunity ($\bar{b}$).
- Packets in the node's buffer are sorted into two priority groups:
  1. **New / Low-Hop Messages ($\text{hopCount} \le x$):**
     - Sorted strictly by **lowest hop count**.
     - Rationale: Newer messages that have not traveled far are given immediate priority to propagate away from the source before getting trapped.
  2. **Older / High-Hop Messages ($\text{hopCount} > x$):**
     - Sorted by **lowest Dijkstra delivery cost** to destination: $\min \sum (1 - P)$.
     - Rationale: Packets that have traveled far compete based on which has the highest probability of reaching its final destination.

---

#### Buffer Management & ACK Flooding
- **Buffer Drop Policy**: When buffer space is exhausted, MaxProp drops messages from the buffer that have the **highest cost** (i.e. lowest likelihood of delivery).
- **ACK Lists (`ackedMessageIds`)**:
  - When a message is successfully delivered to its destination, the destination generates an acknowledgment (ACK).
  - Nodes exchange their lists of ACKed message IDs on every contact:
    ```java
    this.ackedMessageIds.addAll(otherRouter.ackedMessageIds);
    otherRouter.ackedMessageIds.addAll(this.ackedMessageIds);
    deleteAckedMessages();
    ```
  - Any node holding a copy of an ACKed message frees its buffer space immediately, eliminating unnecessary redundant forwards across the network.

---

## 4. Custom Simulator Enhancements Added to this Project

| Component | File Path | Enhancement Details |
| :--- | :--- | :--- |
| **Telemetry Dashboard** | `src/gui/playfield/MetricsPanel.java` | Real-time heads-up display calculating live Delivery Ratio %, Latency, Hop Count, Overhead Ratio, and Active Wireless Links. |
| **Hop Journey Cards** | `src/gui/playfield/PathHopsPanel.java` | Real-time card feed tracking every transmission event labeled with status: `FORWARDED` (cyan), `DUPLICATE` (amber), `DELIVERED` (emerald), `ABORTED` (rose). Clicking a hop card jumps simulation time. |
| **Event Log & Selections** | `src/gui/EventLogPanel.java` | Full-width embedded selections bar at the top with quick toggles for Connection, Message, Node movement, and Radio events. No horizontal window resizing needed. |
| **Animated Beams** | `src/gui/playfield/MessagePathGraphic.java` | Pulsing directional energy beams and anti-aliased transmission rings drawn on the field during message exchanges. |
| **Speed Multipliers** | `src/gui/GUIControls.java` | Quick speed selection buttons (`0.25x`, `0.5x`, `1x`, `2x`, `5x`, `10x`) added directly above the playfield. |

---

## 5. Comprehensive Viva & Review Q&A (20 Critical Questions)

### Q1: What is a Delay Tolerant Network (DTN) and how does it differ from traditional IP networks?
**Answer:** Traditional IP networks rely on continuous end-to-end connectivity, where packets are dropped if an end-to-end path does not exist. Delay Tolerant Networks (DTNs) operate in challenged environments characterized by frequent partitions, long or variable delays, and high error rates. DTNs employ the **Store-Carry-and-Forward** paradigm: intermediate nodes store messages in persistent buffers, carry them as they move physically, and forward them upon opportunistic contacts with other nodes.

---

### Q2: What is the Store-Carry-and-Forward mechanism?
**Answer:** Unlike traditional packet switching where routers hold packets in memory buffers for milliseconds, DTN nodes:
1. **Store**: Receive messages and hold them in non-volatile buffer storage.
2. **Carry**: Move physically through space while holding the message copies.
3. **Forward**: Replicate or transfer messages to newly encountered nodes within radio transmission range when contact opportunities arise.

---

### Q3: How are nodes, sources, and destinations configured in the ONE simulator?
**Answer:** They are defined in the settings text file (`SingleMessagePath_settings.txt`):
- `Scenario.nrofHostGroups` sets the number of node types.
- `Group1.nrofHosts` and `Group2.nrofHosts` specify the number of nodes per group.
- The simulator assigns sequential 0-indexed integer IDs: Group 1 gets `0` to $N_1 - 1$, Group 2 gets $N_1$ to $N_1 + N_2 - 1$.
- `Events1.hosts = 0, 1` selects internal ID `0` (`p0`) as Source.
- `Events1.tohosts = 5, 6` selects internal ID `5` (`c5`) as Destination.

---

### Q4: What does the range `0, 1` mean in `Events1.hosts = 0, 1`?
**Answer:** The ONE simulator uses a half-open interval $[min, max)$, where $min$ is inclusive and $max$ is exclusive. A uniform pseudo-random integer is generated such that $min \le \text{hostID} < max$. Thus, `0, 1` deterministically selects integer `0`.

---

### Q5: What is the delivery ratio and how is it computed?
**Answer:** The Delivery Ratio ($\eta$) measures the routing protocol's delivery reliability:
$$\text{Delivery Ratio} = \frac{M_{\text{delivered}}}{M_{\text{created}}} \times 100\%$$
Where:
- $M_{\text{delivered}}$ is the number of unique messages received by their intended destinations.
- $M_{\text{created}}$ is the total number of unique messages generated at source nodes.

---

### Q6: What is the Overhead Ratio and why is it important in DTN?
**Answer:** The Overhead Ratio evaluates network bandwidth and energy efficiency:
$$\text{Overhead Ratio} = \frac{M_{\text{relayed}} - M_{\text{delivered}}}{M_{\text{delivered}}}$$
Where $M_{\text{relayed}}$ is the total number of hop-by-hop transmissions (including duplicates). A lower overhead ratio indicates fewer redundant copies were forwarded per successful delivery, saving battery and buffer capacity.

---

### Q7: Explain the two phases of `ImprovedProphetRouter`.
**Answer:**
1. **Phase 1 (Limited Epidemic)**: Forwards messages unconditionally to any neighbor that does not have a copy, provided $n_m < \text{maxForwards}$ and $\text{hopCount} < \text{maxHops}$. This solves PRoPHET's cold-start delay problem.
2. **Phase 2 (PRoPHET)**: Once epidemic limits are reached, forwarding becomes selective: a message is transferred only if the encountered peer has higher delivery predictability to the destination ($P_{\text{peer}} > P_{\text{self}}$). This prevents unlimited packet flooding.

---

### Q8: What are the three mathematical equations in PRoPHET?
**Answer:**
1. **Encounter Equation**:
   $$P(A, B) = P(A, B)_{\text{old}} + (1 - P(A, B)_{\text{old}}) \times P_{\text{init}}$$
2. **Transitivity Equation**:
   $$P(A, C) = P(A, C)_{\text{old}} + (1 - P(A, C)_{\text{old}}) \times P(A, B) \times P(B, C) \times \beta$$
3. **Aging Equation**:
   $$P(A, B) = P(A, B) \times \gamma^{\Delta t / \text{secondsInTimeUnit}}$$

---

### Q9: How does MaxProp decide which packet to transmit first?
**Answer:** MaxProp uses an adaptive hop-count threshold $x$ computed via `calcThreshold()`:
- Packets with $\text{hopCount} \le x$ are given priority and sorted by **lowest hop count first** (clearing young packets away from the source).
- Packets with $\text{hopCount} > x$ are sorted by **lowest Dijkstra shortest-path cost** $\min \sum (1 - P)$ to the destination.

---

### Q10: How does Dijkstra's algorithm work inside MaxProp?
**Answer:** `MaxPropDijkstra.java` treats the DTN as a directed graph where vertices are known nodes and edge weights between node $u$ and $v$ are given by:
$$\text{Weight}(u, v) = 1 - P(u, v)$$
Dijkstra's priority queue finds the path to the destination with the minimum sum of $(1 - P)$ values. A lower path cost indicates higher compounded meeting probabilities.

---

### Q11: How does MaxProp prevent stale messages from clogging buffers after delivery?
**Answer:** Through **Acknowledgment (ACK) Lists** (`ackedMessageIds`). When a message reaches its destination, an ACK is recorded and exchanged with every encountered node. Any node holding a copy of an ACKed message immediately purges it from its buffer (`deleteAckedMessages()`).

---

### Q12: How does MaxProp normalize its meeting probabilities?
**Answer:** When node $i$ meets node $j$:
1. $P(i, j)$ is incremented by $\alpha$ (default 1.0).
2. All entries in the probability table are divided by $(1 + \alpha)$:
   $$P_{\text{new}}(i, k) = \frac{P(i, k)}{1 + \alpha}$$
This guarantees that the sum of all meeting probabilities always equals $1.0$.

---

### Q13: What happens when a node's buffer becomes full in DTN?
**Answer:** When buffer space is exhausted, a **Buffer Drop Policy** dictates which message is discarded:
- In FIFO, the oldest message is dropped.
- In `ImprovedProphetRouter`, messages with the lowest delivery predictability or highest hop count are candidates.
- In `MaxPropRouter`, messages with the highest delivery cost (lowest delivery probability) are dropped first (`getNextMessageToRemove()`).

---

### Q14: What is the transmission time formula between two nodes in the ONE?
**Answer:**
$$\text{Time} = \frac{\text{Message Size (bytes)}}{\text{Interface Transmit Speed (bytes/sec)}}$$
For a 500 KB message with a 250 KB/s interface:
$$\text{Time} = \frac{500 \times 1024}{250 \times 1024} = 2.0\text{ seconds}$$
If contact breaks before 2.0s elapse, the transmission is aborted and marked as failed.

---

### Q15: What distinguishes a FORWARDED, DUPLICATE, and DELIVERED hop in the Path Hops Panel?
**Answer:**
- **`FORWARDED`**: A message copy was successfully transferred to an intermediate relay node that did not previously hold it.
- **`DUPLICATE`**: An exchange attempt occurred between two nodes where the target node already possessed that message copy (or rejected it as redundant).
- **`DELIVERED`**: The message was successfully transmitted into the final destination node's buffer.

---

### Q16: How do you adjust node movement speeds in `SingleMessagePath_settings.txt`?
**Answer:** Modify the `speed` property of the host group:
```properties
# Sets pedestrian movement speed between 0.5 m/s and 1.5 m/s
Group1.speed = 0.5, 1.5

# Sets vehicle movement speed between 10.0 m/s and 25.0 m/s
Group2.speed = 10.0, 25.0
```

---

### Q17: What is the difference between Epidemic routing and Spray-and-Wait?
**Answer:**
- **Epidemic**: Replicates messages infinitely to every encountered node with no quota limits. Maximizes delivery ratio at the cost of high bandwidth and buffer saturation.
- **Spray-and-Wait**: Limits message replication to an exact quota of $L$ copies. In the *Spray* phase, the source gives $L/2$ copies to encountered nodes; in the *Wait* phase, nodes only deliver to the destination directly.

---

### Q18: What is the role of `GUIControls.java` and `one.bat`?
**Answer:**
- `GUIControls.java` provides interactive simulation playback controls: Play/Pause, Step, Fast Forward, and custom speed multiplier buttons (`0.25x` to `10x`).
- `one.bat` is a Windows batch launcher that detects the Java JDK/JRE runtime, sets classpath libraries, and launches the simulator GUI with the target configuration file.

---

### Q19: Why was the Event Log selections panel redesigned?
**Answer:** In the original simulator, the control checkboxes were placed in a narrow horizontal split pane (`weight 0.15`) that crushed controls into an unreadable 45-pixel strip. The redesigned `EventLogPanel.java` embeds a full-width toolbar directly at the top with a toggle button, ensuring clean visibility without manual resizing.

---

### Q20: How do you run the simulation from the command line in GUI vs Batch mode?
**Answer:**
- **GUI Mode** (Interactive visualization):
  ```cmd
  one.bat SingleMessagePath_settings.txt
  ```
- **Batch Mode** (Headless execution for metric gathering without graphical overhead):
  ```cmd
  one.bat -b SingleMessagePath_settings.txt
  ```
- **Custom Report Generation**: Add reports under `Report.report1 = SingleMessagePathReport` in the settings file; outputs are saved to `reports/`.
