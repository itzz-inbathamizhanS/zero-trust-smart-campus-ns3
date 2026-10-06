# 🔀 Routing & Switching — Review 2 (5 Marks)

> **Rubric Criteria:** Static/Dynamic Routing, VLANs, Inter-VLAN Routing

---

## Part 1: Switching & VLANs

### What is a Switch?
**Simple:** A switch connects devices within the same network (LAN). It reads the MAC address of incoming data and sends it only to the correct device, not to everyone.

### What is a VLAN?
**Simple:** A VLAN (Virtual LAN) is a way to logically divide one physical switch into multiple isolated networks. Devices in the same VLAN can talk to each other. Devices in different VLANs CANNOT talk to each other without a router.

**Real-world analogy:** Think of a school building with different floors. Each floor is a VLAN. Students on the same floor can talk to each other, but to visit another floor, they must go through the staircase (router).

### Our VLANs

We have **8 VLANs**, each representing a campus department:

| VLAN ID | Department | Subnet | Number of Devices | Purpose |
|---------|------------|--------|-------------------|---------|
| 10 | Administration | 10.0.10.0/24 | 4 | Admin PCs, ERP terminals |
| 20 | CSE Department | 10.0.20.0/24 | 10 | Student labs, faculty workstations |
| 30 | IT Department | 10.0.30.0/24 | 10 | Student labs, faculty workstations |
| 40 | Library | 10.0.40.0/24 | 6 | OPAC systems, digital library, WiFi APs |
| 50 | COE (Centre of Excellence) | 10.0.50.0/24 | 4 | Research systems, HPC clusters |
| 60 | Hostel | 10.0.60.0/24 | 8 | Student WiFi, smart locks |
| 70 | IoT Lab | 10.0.70.0/24 | 6 | Sensors, controllers, gateways |
| 80 | Data Center | 10.0.80.0/24 | 7 | ERP, DB, DHCP, DNS, Web, Email, Backup servers |

### How VLANs Are Created in NS-3

In NS-3, each VLAN is implemented as a separate **CSMA (Carrier Sense Multiple Access) segment**:

```cpp
// Helper function used in our code to create each VLAN
auto createVlan = [&] (NodeContainer &deptNodes, const char *base)
{
    NodeContainer lan;
    lan.Add (topo.router);        // Router connects to every VLAN
    lan.Add (deptNodes);           // Department devices
    NetDeviceContainer devs = csma.Install (lan);  // Shared Ethernet bus
    addr.SetBase (base, "255.255.255.0");
    return addr.Assign (devs);     // Assign IP addresses
};

// Creating all 8 VLANs:
topo.adminIf   = createVlan (topo.adminNodes,   "10.0.10.0");
topo.cseIf     = createVlan (topo.cseNodes,     "10.0.20.0");
topo.itIf      = createVlan (topo.itNodes,      "10.0.30.0");
topo.libraryIf = createVlan (topo.libraryNodes, "10.0.40.0");
topo.coeIf     = createVlan (topo.coeNodes,     "10.0.50.0");
topo.hostelIf  = createVlan (topo.hostelNodes,  "10.0.60.0");
topo.iotIf     = createVlan (topo.iotNodes,     "10.0.70.0");
// Data Center has primary + backup segments
```

### Why VLANs Are Important for Security

Without VLANs (flat network):
```
ALL 58 devices on ONE network → attacker can reach EVERYONE
```

With VLANs (segmented network):
```
CSE VLAN │ IT VLAN │ Admin VLAN │ ... │ DC VLAN
    ↕          ↕         ↕                ↕
    └──────────┴─────────┴────────────────┘
                   Must go through Core Router
                   (Zero-Trust policy applied!)
```

**If Sir asks "What is the benefit of VLANs?"**
> *"VLANs provide network segmentation, which limits the blast radius of security incidents. If a CSE laptop is infected with malware, it can only spread within the CSE VLAN — it cannot directly reach Administration, IoT Lab, or Data Center devices. All cross-VLAN traffic must pass through our Core Router where the Zero-Trust policy is enforced."*

---

## Part 2: Routing

### What is Routing?
**Simple:** Routing is the process of finding the best path for data packets to travel from the source to the destination across different networks.

### Static Routing vs Dynamic Routing

| Feature | Static Routing | Dynamic Routing |
|---------|---------------|-----------------|
| **Configuration** | Manually configured by admin | Automatically learned by protocol |
| **Adaptability** | Does NOT adapt to changes | Automatically adapts to failures |
| **CPU Usage** | Low | Higher (protocol overhead) |
| **Example** | Admin types route commands | OSPF, RIP, BGP calculate routes |
| **Best for** | Small, stable networks | Large, complex networks |

### What We Use: Dynamic Routing (OSPF-like)

Our project uses **dynamic routing** via NS-3's `Ipv4GlobalRoutingHelper`:

```cpp
// Step 1: Initially calculate all routes
Ipv4GlobalRoutingHelper::PopulateRoutingTables();

// Step 2: When primary link fails, RECOMPUTE all routes
Ipv4GlobalRoutingHelper::RecomputeRoutingTables();
// Now traffic automatically flows through the backup path!
```

This simulates how **OSPF (Open Shortest Path First)** works:
1. Each router builds a map of the entire network
2. Uses **Dijkstra's shortest-path algorithm** to find the best route
3. If a link fails, routes are recalculated automatically

**If Sir asks "Is this static or dynamic routing?"**
> *"We use dynamic routing. NS-3's GlobalRoutingHelper simulates OSPF-like link-state routing. Initially, PopulateRoutingTables() calculates optimal routes for all 58 nodes. When the primary Data Center link fails at t=60s, our Self-Healing Controller calls RecomputeRoutingTables(), which automatically reroutes all traffic through the backup distribution switch — just like OSPF reconvergence."*

---

## Part 3: Inter-VLAN Routing

### What is Inter-VLAN Routing?
**Simple:** Since devices in different VLANs cannot talk directly, a **router** is needed to pass traffic between them. This is called Inter-VLAN Routing.

### How It Works in Our Network

```
CSE Student (10.0.20.3) wants to access Web Server (10.0.80.6)

Step 1: CSE Student sends packet to its default gateway (10.0.20.1 = Router)
Step 2: Router receives packet on CSE VLAN interface
Step 3: Router checks Zero-Trust Access Matrix:
        - Source: CSE → Destination: DATACENTER → ALLOWED ✅
Step 4: Router checks risk score of 10.0.20.3:
        - Score = 0 → NORMAL state → Forward packet
Step 5: Router forwards packet out of its Data Center VLAN interface (10.0.80.1)
Step 6: Web Server (10.0.80.6) receives the packet
```

### Example of a BLOCKED Inter-VLAN Request

```
CSE Attacker (10.0.20.2) tries to reach Admin PC (10.0.10.2)

Step 1: Attacker sends packet to gateway (10.0.20.1 = Router)
Step 2: Router receives packet on CSE VLAN interface
Step 3: Router checks Zero-Trust Access Matrix:
        - Source: CSE → Destination: ADMIN → DENIED ❌
Step 4: Router drops the packet
Step 5: Router adds 25 risk points to 10.0.20.2's score
Step 6: If score reaches ≥ 70, attacker gets quarantined!
```

### The Router-on-a-Stick Concept

Our Core Router is connected to ALL 8 VLANs simultaneously. It has one interface on each VLAN:

| Router Interface | VLAN | IP Address |
|-----------------|------|-----------|
| Interface for Admin | VLAN 10 | 10.0.10.1 |
| Interface for CSE | VLAN 20 | 10.0.20.1 |
| Interface for IT | VLAN 30 | 10.0.30.1 |
| Interface for Library | VLAN 40 | 10.0.40.1 |
| Interface for COE | VLAN 50 | 10.0.50.1 |
| Interface for Hostel | VLAN 60 | 10.0.60.1 |
| Interface for IoT | VLAN 70 | 10.0.70.1 |
| Interface for DC | VLAN 80 | 10.0.80.1 |
| Backbone | — | 10.0.1.2 |
| Backup Link | — | 10.0.2.1 |

> The router has **10 interfaces** (one per VLAN + backbone + backup)

---

## Part 4: Self-Healing Routing (Our Novel Contribution)

### The Problem with Normal OSPF

Normal OSPF recalculates routes when a link fails — but it is **security-agnostic**. It doesn't know or care which devices are quarantined. So when traffic is rerouted through a backup path, a quarantined device might accidentally regain connectivity.

### Our Solution: Quarantine-Aware Self-Healing

```
t=60s: Primary DC link fails
  │
  ├── Step 1: Heartbeat timeout (0.5 seconds)
  │           Router detects: "Primary link is DOWN"
  │
  ├── Step 2: Activate backup interface
  │           ipv4->SetUp(backupIfIndex)
  │
  ├── Step 3: Recompute routing tables
  │           Ipv4GlobalRoutingHelper::RecomputeRoutingTables()
  │           Traffic now flows through Backup Switch
  │
  ├── Step 4: ★ QUARANTINE INTEGRITY CHECK ★
  │           "Are quarantined devices still isolated?"
  │           Answer: YES — because quarantine disables the DEVICE's
  │           interfaces, not the ROUTER's. So rerouting doesn't help them.
  │
  └── Step 5: Recovery complete (< 2 seconds total)

t=90s: Primary link restored
  │
  ├── Step 1: Enable primary interface
  ├── Step 2: Recompute routes (primary preferred again)
  └── Step 3: Quarantine integrity re-verified
```

---

## Questions Sir May Ask

**Q: "What type of routing do you use?"**
> *"Dynamic routing. We use NS-3's GlobalRoutingHelper which simulates OSPF-like link-state routing. Routes are automatically recalculated when the network topology changes, such as during our self-healing link failure scenario."*

**Q: "How does Inter-VLAN routing work in your project?"**
> *"The Core Router has interfaces on all 8 VLANs. When a device in CSE (VLAN 20) wants to reach the Data Center (VLAN 80), the packet goes to the router (10.0.20.1), which checks the Zero-Trust policy, and if allowed, forwards it through its Data Center interface (10.0.80.1)."*

**Q: "What happens when a link fails?"**
> *"Our Self-Healing Controller detects the failure within 500ms using heartbeat monitoring. It activates the backup distribution switch, calls RecomputeRoutingTables() to recalculate all routes, verifies that quarantined devices remain isolated, and completes recovery in under 2 seconds."*

**Q: "What is the difference between a switch and a router?"**
> *"A switch operates at Layer 2 (Data Link) and forwards frames based on MAC addresses within the same VLAN. A router operates at Layer 3 (Network) and forwards packets based on IP addresses between different VLANs/subnets. In our design, each CSMA segment acts as a virtual switch, and the Core Router handles inter-VLAN routing."*

**Q: "Why is OSPF called a link-state protocol?"**
> *"Because each router maintains the complete 'state' of every 'link' in the network. Unlike distance-vector protocols (like RIP) which only know the next hop, link-state routers have a full topology map and use Dijkstra's algorithm to compute the shortest path tree."*
