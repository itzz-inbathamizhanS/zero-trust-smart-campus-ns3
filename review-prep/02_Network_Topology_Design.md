# 🏗️ Network Topology Design — Review 2 (5 Marks)

> **Rubric Criteria:** Hierarchical design with appropriate devices

---

## What is Network Topology?

**Simple:** Network topology is the **arrangement** of devices (computers, routers, switches) and how they are **connected** to each other. Think of it like a map showing roads between buildings.

---

## Our Topology: 3-Tier Hierarchical Design

We follow the **Cisco 3-Tier Hierarchical Model**, the industry standard for campus networks:

```
                    ┌──────────────────┐
                    │  INTERNET SERVER │ ← External connectivity
                    └────────┬─────────┘
                             │ 1 Gbps P2P (Backbone)
                    ┌────────┴─────────┐
                    │    CORE ROUTER    │ ← Policy Enforcement Point (PEP)
                    │  (Zero-Trust)     │    Risk Scoring + Quarantine
                    └──┬────────────┬───┘
                       │            │ 1 Gbps P2P (Backup Link)
                       │    ┌───────┴──────────┐
                       │    │  BACKUP SWITCH     │ ← Distribution Layer
                       │    │  (DistSwitch2)     │    Redundancy for self-healing
                       │    └───────┬──────────┘
                       │            │
        ┌──────────────┼────────────┼──────────────────────┐
        │              │            │                      │
   ┌────┴────┐   ┌─────┴───┐  ┌────┴────┐           ┌─────┴────┐
   │ Admin   │   │  CSE    │  │  IT     │    ...     │ DataCenter│
   │ VLAN 10 │   │ VLAN 20 │  │ VLAN 30 │           │  VLAN 80  │
   │ 4 nodes │   │ 10 nodes│  │ 10 nodes│           │  7 servers│
   └─────────┘   └─────────┘  └─────────┘           └──────────┘
        ↑              ↑            ↑                      ↑
   ACCESS LAYER — CSMA segments (shared Ethernet, 100 Mbps each)
```

---

## The 3 Layers Explained

### 1. Core Layer (Top) — The Brain
| Property | Details |
|----------|---------|
| **Device** | Core Router (1 node) |
| **Role** | Routes ALL inter-VLAN traffic, enforces Zero-Trust policies, runs the Risk Scoring Engine |
| **Connection** | 1 Gbps Point-to-Point link to Internet Server |
| **IP** | `10.0.1.1` (on backbone) |
| **Why it matters** | Every single packet between departments passes through this router. It is the Policy Enforcement Point (PEP) |

**If Sir asks "Why only 1 core router?"**
> *"In our hierarchical design, the Core Router is the centralised Policy Enforcement Point. All inter-VLAN traffic is funneled through it so our Zero-Trust engine can inspect 100% of cross-department packets. The backup distribution switch provides redundancy."*

---

### 2. Distribution Layer (Middle) — Backup & Redundancy
| Property | Details |
|----------|---------|
| **Device** | Distribution Switch 2 / Backup Switch (1 node) |
| **Role** | Provides an alternate path to the Data Center when the primary link fails |
| **Connection** | 1 Gbps P2P link to Core Router (`10.0.2.0/24`) |
| **Secondary** | CSMA link to Data Center (`10.0.82.0/24`) |
| **Why it matters** | Enables self-healing — if the primary DC link fails, traffic reroutes through this switch |

**If Sir asks "Why do you need a backup switch?"**
> *"The Distribution Switch provides physical redundancy. When the primary CSMA link between the Core Router and Data Center fails at t=60s, the Self-Healing Controller activates this backup path. The routing tables are recomputed, and all traffic seamlessly flows through the backup switch. Recovery happens in under 2 seconds."*

---

### 3. Access Layer (Bottom) — End Devices
| VLAN | Department | Nodes | Device Types |
|------|------------|-------|-------------|
| 10 | Administration | 4 | Admin PC-1, PC-2, PC-3, ERP Terminal |
| 20 | CSE | 10 | Attacker (node 0), Lab-2 to Lab-9, Faculty |
| 30 | IT | 10 | Lab-1 to Lab-9, Faculty |
| 40 | Library | 6 | OPAC-1, OPAC-2, Digital Library, WiFi-1,2,3 |
| 50 | COE | 4 | Research-1, Research-2, HPC-1, HPC-2 |
| 60 | Hostel | 8 | WiFi-1,2, Device-3,4,5, SmartLock-1,2,3 |
| 70 | IoT Lab | 6 | Sensor-1,2, Controller-1,2, Gateway-1,2 |
| 80 | Data Center | 7 | ERP, DB, DHCP, DNS, Web, Email, Backup |

**Total: 58 nodes** (55 department + 3 infrastructure)

---

## Connection Types Used

| Link Type | Where Used | Speed | Delay |
|-----------|-----------|-------|-------|
| **Point-to-Point (P2P)** | Backbone (Internet ↔ Router), Backup link (Router ↔ Backup Switch) | 1 Gbps | 2 ms |
| **CSMA (Shared Ethernet)** | All 8 department segments (VLANs) | 100 Mbps | 6.56 μs |

---

## Why This Design is Good (Marks-Scoring Points)

1. **Hierarchical** — Follows Cisco's proven 3-tier model (Core → Distribution → Access)
2. **Scalable** — New departments can be added by creating a new CSMA segment on the router
3. **Redundant** — Backup distribution switch ensures no single point of failure for Data Center access
4. **Segmented** — 8 separate VLANs limit the blast radius of any attack
5. **Centralized Security** — Single PEP at the core makes policy enforcement consistent and auditable

---

## Questions Sir May Ask

**Q: "What topology did you use?"**
> *"We used a 3-tier hierarchical topology — Core, Distribution, and Access layers. The Core Router serves as the centralized Zero-Trust Policy Enforcement Point. The Distribution layer provides backup path redundancy. The Access layer consists of 8 CSMA-based department segments with 55 end devices."*

**Q: "Why hierarchical and not flat?"**
> *"A flat topology would allow any device to directly reach any other device, making security enforcement nearly impossible. Hierarchical design forces all inter-department traffic through the Core Router, enabling 100% packet inspection and policy enforcement."*

**Q: "How many nodes do you have?"**
> *"58 nodes total: 1 Internet Server, 1 Core Router, 1 Backup Distribution Switch, and 55 department nodes distributed across 8 VLANs."*

**Q: "What devices are in the Data Center?"**
> *"7 servers: ERP Server, Database Server, DHCP Server, DNS Server, Web Server, Email Server, and Backup Server. All on VLAN 80 (10.0.80.0/24)."*

**Q: "How is redundancy achieved?"**
> *"The Data Center has dual-path connectivity. The primary path is a direct CSMA link from the Core Router. The backup path goes through a dedicated Distribution Switch via a P2P link. If the primary fails, the Self-Healing Controller activates the backup and recomputes routing tables in under 2 seconds."*
