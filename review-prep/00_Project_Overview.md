# 🎯 Project Overview — What, Why, How, and Everything Explained

> **Read this FIRST before all other files. This is the complete story of our project in simple words.**

---

## 📌 What is the Project?

### Project Title
**"Autonomous Behavioural Risk Scoring and Graduated Quarantine in Zero-Trust Campus Networks"**

### In One Line
We built a **smart campus network** that can **automatically detect hackers, isolate them step-by-step, and heal itself** when cables/links break — all without any human admin doing anything.

### In Simple Words
Imagine your college has 58 computers spread across 8 departments (CSE, IT, Admin, Library, Hostel, COE, IoT Lab, Data Center). Right now, if a student's laptop gets a virus:
- The virus can spread to **every** computer in the college
- An admin must **manually** find and block the infected device (takes 30-60 minutes)
- During those 30-60 minutes, the virus has already infected 60-80% of devices
- If a network cable breaks at the same time, the whole network goes down

**Our project fixes all of this automatically:**
- Detects the virus in **< 5 seconds** (not 30 minutes)
- Isolates the infected device **gradually** (Warning → Rate-Limit → Full Quarantine) in **< 3 seconds**
- If a cable breaks, heals itself in **< 2 seconds** using a backup path
- Most importantly: when the network heals itself, the quarantined hacker **stays quarantined** (this is what makes our project novel)

---

## 🤔 Why This Project? (The Problem)

### Problem 1: Campus Networks are Vulnerable from Inside

Traditional networks use a **"castle-and-moat" model** — they have a strong firewall at the entrance (the moat), but once you're inside (inside the castle), you can go anywhere freely.

**The reality in a college:**
- 5,000+ students connect their personal laptops to campus WiFi daily
- Any laptop could already be infected with malware from home
- Once connected, that infected laptop is **inside** the firewall
- The malware can spread to Admin servers, exam systems, IoT sensors — everything

```
Traditional Security:
                    ┌──── FIREWALL (strong wall) ────┐
                    │                                  │
                    │  Admin PCs ← freely accessible   │
Internet ──── X ────│  Student PCs ← can reach Admin!  │
  (blocked)         │  IoT Sensors ← can reach Admin!  │
                    │  Hostel WiFi ← can reach Admin!   │
                    │                                  │
                    └──────────────────────────────────┘
                    Everything INSIDE the wall trusts each other ❌
```

### Problem 2: Binary "Allow or Block" Systems Cause False Positives

Current security systems (firewalls, IDS) are **binary** — they either **allow** or **block** a device entirely.

**Real scenario:**
- A CSE student is downloading a 10 GB dataset for their machine learning project
- The download causes a sudden spike in network traffic
- The security system sees high traffic → thinks it's a DoS attack → **BLOCKS the student entirely**
- The student cannot access anything — not even their email or LMS
- An admin must manually investigate and unblock them (takes 30-60 minutes)
- **This is called a false positive** — an innocent person gets punished

### Problem 3: Self-Healing Networks Don't Preserve Security

Modern networks use protocols like OSPF to automatically fix routing when a cable breaks. This is called **self-healing**.

**The dangerous gap:**
1. Device X is a hacker — it has been quarantined (blocked)
2. A network cable breaks elsewhere in the network
3. OSPF recalculates all routes through alternate paths
4. During recalculation, Device X might accidentally get a new route to the Data Center
5. **The quarantine is broken!** The hacker is free again

```
BEFORE link failure:
  Hacker (quarantined) ──X──→ Data Center (blocked ✅)

AFTER OSPF re-routes:
  Hacker (quarantined) ──→ New Path ──→ Data Center (accessible again! ❌)
```

**Nobody has solved this problem before.** This is the research gap we fill.

---

## 💡 How We Solve the Problem (Our 3 Solutions)

### Solution 1: Zero-Trust Architecture + Behavioural Risk Scoring

Instead of trusting devices inside the network, we **continuously monitor every single packet** and calculate a **risk score** for every device.

**What is Zero-Trust?**
Zero-Trust means **"never trust anyone, always verify."** Even if a CSE student's laptop was fine 10 seconds ago, we still check every packet it sends right now. Trust is not permanent — it is continuously earned.

**How the Risk Score Works:**

We monitor 4 things (called "behavioural signals"):

| Signal | What It Detects | How It's Detected | Points Added |
|--------|----------------|-------------------|-------------|
| **Unauthorized Access** | A CSE student trying to reach Admin servers | Packet violates our access rules | +25 per violation |
| **Traffic Anomaly** | A device sending too much data (possible DoS) | Packets per second > 80 | Up to +40 |
| **Port Scanning** | A device checking which services are running on a server | > 10 unique destination ports in 5 seconds | +30 |
| **Protocol Abuse** | Extreme traffic suggesting a flood attack | Packets per second > 160 | Up to +20 |

**The Formula:**
```
Risk Score = 0.35 × Unauthorized Access Score
           + 0.25 × Traffic Anomaly Score
           + 0.25 × Port Scan Score
           + 0.15 × Protocol Abuse Score
```

Maximum score = 100. The higher the score, the more dangerous the device.

**The Magic: Temporal Decay (Automatic Forgiveness)**

Every 1 second, ALL scores are multiplied by **0.95**:
```
New Score = (Old Score × 0.95) + New Suspicious Events
```

**Why this is important:**
- A score of 100 drops to ~50 in just 14 seconds (if the device stops being suspicious)
- That CSE student downloading a dataset? Their score goes up briefly, but comes back down automatically
- **No admin needs to manually unblock them** — the system forgives on its own
- But a real hacker keeps triggering events, so their score stays high despite decay

---

### Solution 2: Graduated Dynamic Quarantine (Not Binary!)

Instead of immediately blocking a device (which causes false positives), we have **4 levels**:

```
Risk Score:  0 ─────── 40 ─────── 55 ─────── 70 ─────── 100
             │          │          │          │
          NORMAL     WARNING   RATE-LIMITED  QUARANTINED
          (green)    (yellow)   (orange)     (red)
```

| Level | Score Range | What Happens | Effect on User |
|-------|-----------|-------------|---------------|
| **NORMAL** | 0 – 39 | Nothing | Full access. Student works normally |
| **WARNING** | 40 – 54 | Alert generated, logging intensified | Student still has access. Admin gets notified |
| **RATE-LIMITED** | 55 – 69 | Device flagged for bandwidth throttling | Student's speed may be reduced |
| **QUARANTINED** | 70 – 100 | **All network interfaces DISABLED** | Student is completely cut off from network |

**How it works step by step (example):**

```
Student downloads 10GB dataset:
  → Traffic spike → Score goes to 42 → WARNING
  → Admin sees alert, but student keeps working
  → Download finishes → Score decays back to 0 → NORMAL
  → FALSE POSITIVE AVOIDED ✅

Hacker runs port scan + tries to reach Admin:
  → Score quickly jumps to 45 → WARNING
  → Keeps scanning → Score hits 58 → RATE-LIMITED
  → Tries unauthorized access → Score hits 75 → QUARANTINED ❌
  → All interfaces disabled → Cannot send or receive anything
  → REAL THREAT STOPPED ✅
```

**How Quarantine Works Technically:**
```cpp
// When score ≥ 70, this code runs:
for (uint32_t i = 1; i < ipv4->GetNInterfaces(); ++i)
    ipv4->SetDown(i);  // Disables each network interface on the device
// The device is now completely disconnected from the network
```

**How Recovery Works:**
```cpp
// When score drops below 40 (thanks to temporal decay):
for (uint32_t i = 1; i < ipv4->GetNInterfaces(); ++i)
    ipv4->SetUp(i);  // Re-enables each interface
// The device can now communicate again
```

---

### Solution 3: Quarantine-Aware Self-Healing

**What is Self-Healing?**
When a network cable or link breaks, the network automatically finds another path for data to travel. Like GPS rerouting you when a road is closed.

**What makes ours special: "Quarantine-Aware"**
After rerouting, our system **checks that quarantined devices are still quarantined**. No other system does this.

**How it works:**

```
Step 1: Primary Data Center cable breaks
        ┌─────────┐       X        ┌──────────┐
        │  Router  │───── ✂ ───────│   Data   │
        └────┬────┘    (broken!)   │  Center  │
             │                      └─────┬───┘
        ┌────┴──────┐                     │
        │  Backup   │─────────────────────┘
        │  Switch   │     (backup path)
        └───────────┘

Step 2: Heartbeat detects failure (< 0.5 seconds)
        "Hey primary link, are you alive?" → No response → FAILURE!

Step 3: Activate backup path
        Router enables its interface to the Backup Switch
        
Step 4: Recompute all routes
        All traffic now flows through the backup path
        
Step 5: ★ QUARANTINE INTEGRITY CHECK ★
        "Is the quarantined hacker still isolated?"
        → Check: Are their interfaces still disabled?
        → Answer: YES — quarantine is on the DEVICE, not the ROUTER
        → The hacker remains isolated even after rerouting ✅

Step 6: Recovery complete (< 2 seconds total)
```

**Why quarantine survives the rerouting:**
In other systems, quarantine is applied on the **router** (e.g., an ACL rule on the router's port). When the router recalculates routes, those rules might not apply to the new path.

In **our system**, quarantine is applied on the **device itself** — we disable the hacker's own network interfaces. Even if the router reroutes everything, the hacker's interfaces are still down. The rerouting doesn't help them.

---

## 🏗️ What is a VLAN and How We Use It

### What is a VLAN? (Simple Explanation)

**VLAN = Virtual Local Area Network**

Imagine a school building with one big open hall. All students from all classes are in the same hall. If one student shouts, **everyone hears it**. If one student has the flu, **everyone can catch it**.

Now imagine that same hall divided into 8 separate rooms with walls between them:
- Room 1: CSE students
- Room 2: IT students  
- Room 3: Admin staff
- Room 4: Library
- ...and so on

Now if a CSE student shouts, only CSE students hear it. If a CSE student has the flu, only CSE students are at risk. **The walls isolate them.**

**A VLAN is those virtual walls — but in a network.**

Without VLANs:
```
All 58 devices on ONE network
→ Everyone can see everyone's traffic
→ Malware spreads to ALL devices instantly
→ No privacy between departments
```

With VLANs:
```
8 separate virtual networks
→ CSE traffic stays in CSE
→ Admin traffic stays in Admin
→ Malware can only spread within its VLAN
→ To cross VLANs, traffic must go through the Router (where we check it!)
```

### How VLANs Are Used in Our Project

We have **8 VLANs** — one per department:

| VLAN | Department | Network | Devices | What They Do |
|------|------------|---------|---------|-------------|
| 10 | Administration | 10.0.10.0/24 | 4 PCs | Manage college ERP, finances, HR |
| 20 | CSE Department | 10.0.20.0/24 | 10 labs | Student coding, assignments, research |
| 30 | IT Department | 10.0.30.0/24 | 10 labs | Student work, IT operations |
| 40 | Library | 10.0.40.0/24 | 6 systems | OPAC catalogs, digital library, WiFi |
| 50 | COE (Centre of Excellence) | 10.0.50.0/24 | 4 systems | Research, HPC clusters, exam systems |
| 60 | Hostel | 10.0.60.0/24 | 8 devices | Student WiFi, smart locks |
| 70 | IoT Lab | 10.0.70.0/24 | 6 devices | Sensors, controllers, gateways |
| 80 | Data Center | 10.0.80.0/24 | 7 servers | ERP, DB, DHCP, DNS, Web, Email, Backup |

### VLAN Access Rules (Who Can Talk to Whom)

Not all VLANs can communicate with each other. We have strict rules:

| From ↓ | Can Access → |
|--------|-------------|
| **Admin** | Everything (they manage the college) |
| **CSE** | Only Library + Data Center (for academics) |
| **IT** | Only Library + Data Center (for academics) |
| **Library** | Only Data Center (for digital resources) |
| **COE** | Only Admin + Data Center (for exams and research) |
| **Hostel** | Only Library + Data Center (for student portal) |
| **IoT Lab** | Only Data Center (to upload sensor data) |
| **Quarantined** | NOTHING (completely isolated) |

**Key rule: NO lateral movement between student departments!**
- CSE ❌ → IT (blocked)
- CSE ❌ → Hostel (blocked)
- CSE ❌ → Admin (blocked)
- CSE ❌ → IoT (blocked)

This means: If a CSE laptop gets infected, it **cannot** attack IT, Admin, or IoT devices. It can only try to reach Library or Data Center — and when it does, the router's risk scoring engine catches the suspicious behaviour.

### How VLANs Are Created (The Code)

In NS-3, each VLAN is a separate CSMA (shared Ethernet) segment:

```cpp
// Each VLAN = a shared Ethernet bus with the router + department nodes
CsmaHelper csma;
csma.SetChannelAttribute("DataRate", DataRateValue(DataRate("100Mbps")));

// Create CSE VLAN
NodeContainer cseLan;
cseLan.Add(router);         // Router connects to this VLAN
cseLan.Add(cseNodes);       // 10 CSE devices
NetDeviceContainer devs = csma.Install(cseLan);

// Assign IP addresses: 10.0.20.0/24
addr.SetBase("10.0.20.0", "255.255.255.0");
addr.Assign(devs);
// Router gets 10.0.20.1, CSE devices get 10.0.20.2 through 10.0.20.11
```

---

## 🔧 How the Problem is Addressed (Complete Flow)

Here is the **complete story** of how our system handles an attack, from start to finish:

### Minute 0:00 — Network Starts
- All 58 nodes boot up
- VLANs are assigned, IP addresses configured
- Routing tables calculated (all devices know how to reach each other via the router)
- Legitimate traffic begins: students browsing, IoT uploading data, admin using ERP

### Minute 0:30 — Attack Begins
- A CSE student's laptop (`10.0.20.2`) is infected with malware
- The malware does 3 things simultaneously:
  1. **Port Scans** the ERP server (trying to find vulnerable services)
  2. **Tries to access** Admin PCs and COE systems (lateral movement)
  3. **Floods** the ERP server with high-volume traffic (DoS attempt)

### Minute 0:31 — Detection (< 1 Second)
- The Core Router's **Traffic Monitor** intercepts the packets
- **Check 1:** `10.0.20.2 → 10.0.10.2` → CSE to Admin? → **DENIED** → +25 risk points
- **Check 2:** 100 unique destination ports from `10.0.20.2` → **PORT SCAN** → +30 risk points
- **Check 3:** 200 packets/second from `10.0.20.2` → **TRAFFIC ANOMALY** → +40 risk points
- **Check 4:** 200 pps > 160 threshold → **PROTOCOL ABUSE** → +20 risk points

### Minute 0:36 — WARNING State (Score = 42)
- The weighted risk score crosses 40
- System generates an **alert**: "Device 10.0.20.2 showing suspicious behaviour"
- Logging is intensified for this device
- **But the device still has network access** (no disruption yet — avoids false positive)

### Minute 0:40 — RATE-LIMITED State (Score = 58)
- More violations accumulate
- Score crosses 55
- Device is flagged for potential bandwidth throttling
- Admin is warned: "This device is likely malicious"

### Minute 0:45 — QUARANTINED (Score = 75)
- Score crosses 70 — **CONFIRMED THREAT**
- System calls `ipv4->SetDown()` on ALL of the attacker's network interfaces
- The attacker is **completely cut off** from the network
- Cannot send or receive any packet
- All other 57 devices continue working normally

### Minute 1:00 — Primary Link Fails
- The cable between Core Router and Data Center breaks
- All departments lose access to servers (ERP, Web, DNS, Email)

### Minute 1:00.5 — Self-Healing Kicks In
- Heartbeat detects: "Primary link is dead!"
- Backup Switch is activated
- New path: Router → Backup Switch → Data Center
- All routing tables recalculated
- **Quarantine Integrity Check:** "Is 10.0.20.2 still isolated?" → **YES** ✅

### Minute 1:02 — Recovery Complete
- All 57 legitimate devices can access Data Center via backup path
- Attacker (10.0.20.2) remains quarantined
- Total downtime: **< 2 seconds**

### Minute 1:30 — Primary Link Restored
- The broken cable is fixed
- Router switches back to primary path (faster/preferred)
- Routing tables recalculated again
- Quarantine re-verified: attacker still isolated ✅

### Minute 2:00 — Simulation Ends
- **Results:**
  - 150 data flows monitored
  - 25,030 Kbps total throughput
  - 0.68% packet loss (99.32% delivered successfully)
  - 1 device quarantined (the attacker)
  - 0 innocent devices affected (zero false positives)

---

## 🔬 What is NS-3 and Why We Used It

### What is NS-3?
NS-3 (Network Simulator 3) is a free, open-source **discrete-event network simulator** used for research and education. You write C++ code to create virtual networks and study how they behave.

### Why NS-3 and Not Cisco Packet Tracer?

| Feature | Packet Tracer | NS-3 (Our Choice) |
|---------|--------------|-------------------|
| **Custom algorithms** | ❌ Cannot write custom code | ✅ Full C++ programming |
| **Risk scoring engine** | ❌ Impossible | ✅ We wrote our own class |
| **Traffic monitoring** | ❌ Limited | ✅ Packet-level inspection callbacks |
| **Dynamic quarantine** | ❌ Manual only | ✅ Programmatic ipv4->SetDown() |
| **Self-healing** | ❌ OSPF only (no quarantine check) | ✅ Custom controller with quarantine verification |
| **Result analysis** | ❌ Basic | ✅ CSV export + Python graphs |
| **Academic validity** | ❌ Not accepted in research papers | ✅ Standard research tool |

**If Sir asks "Why not Packet Tracer?"**
> *"Packet Tracer is an instructional tool with fixed Cisco IOS commands. It cannot implement custom algorithms like our risk scoring engine or quarantine controller. NS-3 allows us to write custom C++ classes that model our novel contributions precisely, and it's the standard simulator accepted in IEEE research publications."*

---

## 📊 What Output Does the Simulation Produce?

After running the simulation, we get **6 output files**:

| File | Content | Used For |
|------|---------|---------|
| `risk-scores.csv` | Risk score of every device at every second | Risk Score Evolution graph |
| `quarantine-events.csv` | Timestamp and level when quarantine state changes | Quarantine Timeline graph |
| `self-healing-events.csv` | Link failure/recovery events and recovery time | Self-Healing Recovery graph |
| `throughput.csv` | Throughput, delay, and loss for every data flow | Throughput Comparison graph |
| `flowmon.xml` | NS-3 FlowMonitor detailed statistics | Detailed analysis |
| `animation.xml` | Node positions, colors, and movements for NetAnim | Live visual animation |

These CSV files are then processed by our Python script (`analyze-results.py`) to generate **publication-quality graphs** for the research paper.

---

## 📝 Quick Reference Card (Print This!)

### Project Title
Autonomous Behavioural Risk Scoring and Graduated Quarantine in Zero-Trust Campus Networks

### 3 Novel Contributions
1. **Multi-Factor Behavioural Risk Scoring Engine** with temporal decay (γ = 0.95)
2. **Graduated Dynamic Quarantine** (Normal → Warning → Rate-Limited → Quarantined)
3. **Quarantine-Aware Self-Healing** (preserves isolation during link failures)

### Key Numbers
- **58 nodes** across **8 VLANs** (departments)
- **4 risk signals** with **4 quarantine levels**
- Risk formula: `Score = 0.35A + 0.25T + 0.25P + 0.15V`
- Decay factor: **0.95** per second
- Thresholds: Warning = **40**, Rate-Limit = **55**, Quarantine = **70**
- Detection time: **< 5 seconds** (vs 5-30 min traditional)
- Recovery time: **< 2 seconds** (vs 30-60 sec traditional)
- Packet loss: **0.68%** during combined attack + link failure

### Simulator
NS-3 (Network Simulator 3) v3.41, implemented in C++ (~1765 lines)

### Research Paper
`zero_trust_risk_scoring.docx` — published and ready

### How to Run
```bash
wsl
cd ~/ns-allinone-3.41/ns-3.41
./ns3 run "smart-campus-network --scenario=4"
```
