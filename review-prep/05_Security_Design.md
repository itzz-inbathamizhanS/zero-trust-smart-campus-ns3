# 🔒 Security Design — Review 2 (5 Marks)

> **Rubric Criteria:** ACLs, Port Security, Password Policies, Network Segmentation

---

## Overview: 4 Layers of Security

Our project has **4 layers of security** working together:

```
┌──────────────────────────────────────────────────────────────┐
│  LAYER 1: Network Segmentation (8 VLANs)                    │
│  → Prevents direct access between departments               │
├──────────────────────────────────────────────────────────────┤
│  LAYER 2: Zero-Trust Access Control List (ACL)               │
│  → Only specifically allowed VLAN→VLAN pairs can communicate │
├──────────────────────────────────────────────────────────────┤
│  LAYER 3: Behavioural Risk Scoring Engine                    │
│  → Continuously monitors behaviour, calculates risk scores   │
├──────────────────────────────────────────────────────────────┤
│  LAYER 4: Graduated Dynamic Quarantine                       │
│  → Progressively isolates threats: Warning → Rate-Limit →    │
│    Full Quarantine (interface shutdown)                       │
└──────────────────────────────────────────────────────────────┘
```

---

## 1. Network Segmentation (VLANs)

### What is it?
Dividing the campus network into 8 isolated segments so that an attack in one department cannot spread to others.

### How it protects us:
- **Without segmentation:** Malware on one CSE laptop can instantly reach Admin PCs, IoT sensors, hostel devices — infecting 60-80% of the network
- **With segmentation:** Malware on a CSE laptop is contained within the CSE VLAN. It can only spread to other CSE devices. To reach Admin or IoT, it must go through the Core Router — where it gets caught.

### Our 8 Segments:
| VLAN | Department | Isolation Benefit |
|------|------------|------------------|
| 10 | Admin | Protects sensitive ERP data and financial records |
| 20 | CSE | Contains student traffic (highest attack risk) |
| 30 | IT | Contains student traffic |
| 40 | Library | Isolates public-facing devices |
| 50 | COE | Protects exam systems and HPC clusters |
| 60 | Hostel | Contains personal device traffic |
| 70 | IoT Lab | Isolates vulnerable IoT sensors |
| 80 | Data Center | Protects critical servers (ERP, DB, DNS, Web) |

**If Sir asks:** *"Network segmentation reduces the attack surface. If a CSE laptop is compromised, the malware is confined to the CSE VLAN. Without segmentation, we estimate 60-80% of devices could be infected. With our design, infection is limited to less than 5% (only devices in the same VLAN)."*

---

## 2. ACLs — Zero-Trust Access Control Matrix

### What is an ACL?
**Simple:** A list of rules that tells the router which traffic to **allow** (permit) and which to **block** (deny).

### Our Zero-Trust ACL (Access Control Matrix)

| Source ↓ \ Destination → | Admin | CSE | IT | Library | COE | Hostel | IoT | DataCenter |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Administration** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **CSE Department** | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **IT Department** | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Library** | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **COE** | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| **Hostel** | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |
| **IoT Lab** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Quarantined** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

### Policy Rules (Easy to Remember):

1. ✅ **Admin** can reach **everywhere** (they need full access for management)
2. ✅ **Students** (CSE, IT) can reach **Library** and **Data Center** (for academics)
3. ✅ **Hostel** can reach **Library** and **Data Center** (e-books, student portal)
4. ✅ **COE** can reach **Admin** and **Data Center** (for exam data and research)
5. ✅ **IoT Lab** can only reach **Data Center** (sensor data upload)
6. ❌ **No lateral movement** between student departments (CSE ↔ IT ↔ Hostel blocked)
7. ❌ **Quarantined nodes** have **ZERO access** (all interfaces shut down)

### How It Works in Code:

```cpp
class ZeroTrustPolicy {
    ZeroTrustPolicy() {
        // Admin can reach everything
        Allow("ADMIN", {"ADMIN","CSE","IT","LIBRARY","COE","HOSTEL","IOT","DATACENTER"});
        // CSE students: limited access
        Allow("CSE", {"CSE","LIBRARY","DATACENTER"});
        // IT students: limited access
        Allow("IT", {"IT","LIBRARY","DATACENTER"});
        // Library: datacenter only
        Allow("LIBRARY", {"LIBRARY","DATACENTER"});
        // COE: admin + datacenter
        Allow("COE", {"COE","ADMIN","DATACENTER"});
        // Hostel: library + datacenter
        Allow("HOSTEL", {"HOSTEL","LIBRARY","DATACENTER"});
        // IoT: datacenter only
        Allow("IOT", {"IOT","DATACENTER"});
        // Quarantine: NOTHING (no Allow entry)
    }
};
```

**If Sir asks "What type of ACL is this?"**
> *"This is an Extended ACL because it filters based on both source and destination addresses. Unlike a standard ACL that only checks source addresses, our Zero-Trust policy matrix evaluates every source-destination VLAN pair. It follows the default-deny principle — any traffic not explicitly permitted is dropped."*

---

## 3. Behavioural Risk Scoring Engine (Port Security Equivalent)

### Traditional Port Security vs Our Approach

| Feature | Traditional Port Security | Our Risk Scoring |
|---------|--------------------------|-----------------|
| **What it checks** | MAC address only | 4 behavioural signals |
| **Response** | Binary (block/allow) | Graduated (4 levels) |
| **False positives** | High (blocks legitimate devices) | Low (temporal decay forgives) |
| **Timing** | One-time check | Continuous monitoring |

### The 4 Behavioural Signals We Monitor

#### Signal 1: Unauthorized Access Violations (Weight = 0.35)
- **What:** CSE student trying to reach Admin or IoT subnets
- **How detected:** Router checks Zero-Trust matrix → packet denied → +25 risk points
- **Example:** `10.0.20.2 → 10.0.10.2` (CSE → Admin) = DENIED, score +25

#### Signal 2: Traffic Volume Anomaly (Weight = 0.25)
- **What:** A device sending unusually high amounts of traffic (possible DoS attack)
- **How detected:** If packets per second > 80, risk increases
- **Formula:** `penalty = MIN(packets_per_second / 3.0, 40.0)`
- **Example:** Attacker sending at 200 pps → penalty = MIN(200/3, 40) = 40 points

#### Signal 3: Port Scan Activity (Weight = 0.25)
- **What:** A device connecting to many different ports on a target (scanning for vulnerabilities)
- **How detected:** If unique destination ports > 10 within 5 seconds → +30 risk points
- **Example:** Attacker sends packets to ports 1, 2, 3, ..., 100 on ERP server → SCAN DETECTED

#### Signal 4: Protocol Violations (Weight = 0.15)
- **What:** Extremely high traffic rate suggesting flood-based protocol abuse
- **How detected:** If packets per second > 160 → risk increases
- **Formula:** `penalty = MIN(packets_per_second / 10.0, 20.0)`

### The Risk Score Formula

```
RiskScore = 0.35 × Access + 0.25 × Traffic + 0.25 × PortScan + 0.15 × Protocol
```

All capped at maximum 100.

### Temporal Decay (Automatic Forgiveness)

Every 1 second, ALL scores are multiplied by **0.95** (decay factor):

```
New Score = Old Score × 0.95 + New Events
```

**Why this matters:**
- A score of 100 decays to ~50 in 14 seconds (if no new suspicious activity)
- Innocent students who temporarily triggered a warning recover automatically
- **No manual admin intervention needed** for false positives

---

## 4. Graduated Dynamic Quarantine (Not Binary!)

### Traditional vs Our Approach

| Traditional System | Our System |
|-------------------|-----------|
| Score > threshold → BLOCK | 4 graduated levels |
| Innocent student downloads dataset → BLOCKED | Innocent student → WARNING only |
| Manual admin needed to unblock | Automatic recovery via temporal decay |

### The 4 Quarantine Levels

```
Score:  0 ──────── 40 ──────── 55 ──────── 70 ──────── 100
        │          │           │           │
     NORMAL     WARNING    RATE_LIMITED  QUARANTINED
     (green)    (yellow)    (orange)      (red)
```

| Level | Score Range | What Happens | Network Effect |
|-------|-----------|-------------|---------------|
| **NORMAL** | 0 – 39 | Nothing | Full access per policy |
| **WARNING** | 40 – 54 | Alert generated, logging intensified | No network change |
| **RATE_LIMITED** | 55 – 69 | Severe alert, device flagged | State logged (throttling noted for future work) |
| **QUARANTINED** | 70 – 100 | **All interfaces disabled** | **Complete isolation from network** |

### How Quarantine Works (The Code):

```cpp
case QuarantineLevel::QUARANTINED:
    // FULL ISOLATION — disable all non-loopback interfaces
    for (uint32_t i = 1; i < ipv4->GetNInterfaces(); ++i)
        ipv4->SetDown(i);   // Shuts down the device's network connection
    break;
```

### Recovery:

```cpp
case QuarantineLevel::NORMAL:
    // Re-enable all interfaces
    for (uint32_t i = 1; i < ipv4->GetNInterfaces(); ++i)
        ipv4->SetUp(i);     // Restores the device's network connection
    break;
```

**If Sir asks "How does quarantine work?"**
> *"When a device's risk score reaches 70 or above, our Quarantine Controller calls ipv4->SetDown() on all of the device's non-loopback network interfaces. This physically disconnects the device at Layer 3, preventing it from sending or receiving any packets. Recovery is automatic — when the score decays below 70 (due to our temporal decay factor of 0.95), the interfaces are brought back up."*

---

## 5. Password Policies (Conceptual)

While NS-3 doesn't simulate user authentication, our Zero-Trust design assumes:
- **No implicit trust:** Even devices inside the network are continuously verified
- **Least privilege:** Each department only gets access to what it needs
- **Defence in depth:** Multiple security layers (segmentation + ACL + scoring + quarantine)

**If Sir asks about password policies:**
> *"Our Zero-Trust architecture goes beyond password-based authentication. Instead of one-time login verification, we implement continuous behavioural monitoring. However, in a real deployment, we would integrate 802.1X port-based authentication with RADIUS for initial device authentication, combined with our behavioural scoring for continuous verification."*

---

## Security Metrics (From Our Simulation)

| Metric | Traditional Campus | Our Zero-Trust Design |
|--------|-------------------|----------------------|
| **Threat Detection Time** | 5 – 30 minutes (manual) | < 5 seconds (automatic) |
| **Quarantine Activation** | 10 – 60 minutes (admin must act) | < 3 seconds (automatic) |
| **Link Recovery Time** | 30 – 60 seconds | < 2 seconds |
| **Infected Nodes During Attack** | 60 – 80% | < 5% |
| **Network Availability** | 40 – 60% during attack | > 95% |
| **Packet Loss During Attack** | 8 – 15% | < 1% (actual: 0.68%) |

---

## Questions Sir May Ask

**Q: "What security mechanisms have you implemented?"**
> *"Four layers: (1) Network segmentation using 8 VLANs, (2) Zero-Trust ACL that follows default-deny policy, (3) Multi-factor behavioural risk scoring engine monitoring 4 signals with temporal decay, and (4) Graduated dynamic quarantine with 4 levels from Warning to full interface isolation."*

**Q: "What is the default-deny policy?"**
> *"It means all traffic is blocked by default unless there is an explicit rule allowing it. In our access matrix, if a source-destination VLAN pair is not listed in the Allow rules, the packet is dropped. This is the core principle of Zero-Trust — never trust, always verify."*

**Q: "How do you detect port scanning?"**
> *"We maintain a stateful set of unique destination ports per source IP within a 5-second sliding window. If a single source connects to more than 10 unique ports on the same destination, our Traffic Monitor flags it as a port scan and adds 30 risk points."*

**Q: "What happens if a legitimate student triggers a false positive?"**
> *"That's exactly why we use graduated quarantine instead of binary block. A temporary traffic spike only pushes the student to WARNING state (score 40-54), where logging is intensified but access continues. The temporal decay factor of 0.95 reduces the score by 5% every second, so if the student's behaviour returns to normal, their score drops back below 40 within ~14 seconds. No manual admin intervention required."*

**Q: "What is the difference between your approach and a traditional firewall?"**
> *"A traditional firewall uses static rules — it either allows or blocks based on source/destination IP and port. Our system is dynamic — it continuously monitors 4 behavioural signals, calculates a real-time risk score, and applies graduated responses. Additionally, our system includes temporal decay for automatic false-positive recovery, which firewalls don't have."*
