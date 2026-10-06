# 🎬 All 4 Scenarios — Full Explanation — Review 2

> **Every team member must understand all 4 scenarios — what happens, when it happens, and why**

---

## Quick Summary Table

| Scenario | Name | What Happens | Key Feature Tested |
|----------|------|-------------|-------------------|
| 1 | Normal Operation | Only legitimate traffic | Baseline metrics |
| 2 | Attack + Quarantine | Malware attack at t=30s | Risk Scoring + Graduated Quarantine |
| 3 | Link Failure + Self-Healing | Primary link fails at t=60s | Backup path + Self-Healing |
| 4 | **Combined (Best for Demo)** | Attack at t=30s + Link failure at t=60s | ALL features working together |

---

## Scenario 1: Normal Operation (Baseline)

### What Happens (Timeline)

```
t=0s ─────────────────────────────────────────────── t=120s
     │                                                   │
     └── Legitimate traffic flows between all departments ──┘
         No attacks. No link failures. Everything is normal.
```

### Step-by-Step

1. **t=0s:** Simulation starts. All 58 nodes are created, VLANs assigned, routing tables populated.
2. **t=1s:** Legitimate traffic begins. Every department sends UDP packets to Data Center servers:
   - Admin PCs → ERP Server (500 Kbps each)
   - CSE Labs → Web Server (500 Kbps each)
   - IT Labs → Web Server (500 Kbps each)
   - Library → DNS Server (500 Kbps each)
   - COE → ERP Server (500 Kbps each)
   - Hostel → Web Server (500 Kbps each)
   - IoT Sensors → ERP Server (500 Kbps each)
3. **t=2s:** Risk Scoring Engine starts evaluating every 1 second. Heartbeat starts checking every 0.5 seconds.
4. **t=2s–120s:** All traffic is legitimate. All risk scores stay at **0** (no violations detected).
5. **t=120s:** Simulation ends.

### What to Expect
- **All risk scores:** 0 (no suspicious activity)
- **Quarantine events:** 0 (nobody quarantined)
- **Self-healing events:** 0 (no link failures)
- **Packet loss:** Very low (< 0.5%)
- **Throughput:** Full expected throughput

### Purpose
> *"Scenario 1 establishes the baseline. We run the network under normal conditions to measure expected throughput, delay, and packet loss. We then compare Scenarios 2, 3, and 4 against this baseline to quantify the impact of attacks and our security mechanisms."*

---

## Scenario 2: Malware Attack + Dynamic Quarantine

### What Happens (Timeline)

```
t=0s ── t=30s ────── t=36s ──── t=40s ──── t=45s ────── t=120s
   │       │           │          │          │              │
   │       │           │          │          └─ QUARANTINED │
   │       │           │          └─ RATE_LIMITED           │
   │       │           └─ WARNING                          │
   │       └─ ATTACK BEGINS (port scan + unauth + flood)   │
   └─ Normal traffic ─────────────────────────────────────┘
```

### Step-by-Step

**Phase 1: Normal (t=0s to t=30s)**
1. All departments send legitimate traffic
2. Risk scores are 0 for all devices
3. Network operates normally

**Phase 2: Attack Begins (t=30s)**
4. The **Attacker** (`10.0.20.2`, first CSE student node) starts 3 attack vectors simultaneously:
   - **Port Scanning:** Sends packets to ports 1–100 on the ERP Server (`10.0.80.2`) every 2 seconds
   - **Unauthorized Access:** Sends packets to Admin PC (`10.0.10.2`) and COE PC (`10.0.50.2`) every 1 second
   - **Traffic Flood:** Sends 50 packets of 1024 bytes to ERP Server every 0.5 seconds (= ~100 pps)

**Phase 3: Detection (t=31s onward)**
5. The Traffic Monitor on the Core Router detects:
   - **Policy Violation:** `10.0.20.2 → 10.0.10.2` (CSE → Admin) is DENIED → +25 risk points per violation
   - **Policy Violation:** `10.0.20.2 → 10.0.50.2` (CSE → COE) is DENIED → +25 risk points per violation
   - **Port Scan:** More than 10 unique ports detected from `10.0.20.2` → +30 risk points
   - **Traffic Anomaly:** Rate > 80 pps → penalty added
   - **Protocol Violation:** Rate > 160 pps → additional penalty

**Phase 4: Graduated Response**
6. **~t=36s: Score reaches 40 → WARNING**
   - Risk score crosses 40
   - Status changes from NORMAL → WARNING
   - Alert generated, logging intensified
   - NetAnim: Attacker node turns **YELLOW**

7. **~t=40s: Score reaches 55 → RATE_LIMITED**
   - Risk score crosses 55
   - Status changes from WARNING → RATE_LIMITED
   - Device flagged for throttling (state logged)
   - NetAnim: Attacker node turns **ORANGE**

8. **~t=45s: Score reaches 70 → QUARANTINED**
   - Risk score crosses 70
   - **ALL network interfaces of the attacker are DISABLED**
   - `ipv4->SetDown()` called on all non-loopback interfaces
   - The attacker is completely cut off from the network
   - NetAnim: Attacker node turns **DARK RED**, label says "QUARANTINED!"

**Phase 5: Post-Quarantine (t=45s to t=120s)**
9. Attacker's packets can no longer leave its node (interfaces are down)
10. Risk score slowly decays: `score = score × 0.95` every second
11. The rest of the network continues operating normally
12. Other departments are completely unaffected

### How Identification Works (The Detection Pipeline)

```
Packet from 10.0.20.2 arrives at Core Router
    │
    ├── Check 1: Is source-destination pair allowed?
    │   10.0.20.2 (CSE) → 10.0.10.2 (ADMIN) → ❌ DENIED
    │   → RecordEvent(UNAUTHORIZED_ACCESS, 25 points)
    │
    ├── Check 2: How many unique ports has this source contacted?
    │   Source 10.0.20.2 has contacted 100 unique ports → > 10 threshold
    │   → RecordEvent(PORT_SCAN, 30 points)
    │
    ├── Check 3: What is this source's packet rate?
    │   Source 10.0.20.2 sending at 200 packets/second → > 80 threshold
    │   → RecordEvent(TRAFFIC_ANOMALY, min(200/3, 40) = 40 points)
    │
    └── Check 4: Is the rate extremely high?
        200 pps > 160 (double the threshold)
        → RecordEvent(PROTOCOL_VIOLATION, min(200/10, 20) = 20 points)

Every 1 second:
    │
    ├── Compute weighted score:
    │   Score = 0.35×Access + 0.25×Traffic + 0.25×PortScan + 0.15×Protocol
    │
    ├── Apply decay: score = score × 0.95
    │
    └── Check thresholds:
        Score ≥ 70 → QUARANTINE (disable interfaces)
        Score ≥ 55 → RATE_LIMITED
        Score ≥ 40 → WARNING
        Score < 40 → NORMAL
```

---

## Scenario 3: Link Failure + Self-Healing

### What Happens (Timeline)

```
t=0s ─── t=60s ──── t=60.5s ──── t=62s ──── t=90s ──── t=120s
   │       │           │           │          │            │
   │       │           │           │          └─ Primary link restored
   │       │           │           └─ Recovery complete (< 2s)
   │       │           └─ Failure detected (< 0.5s)
   │       └─ PRIMARY LINK FAILS
   └─ Normal traffic ──────────────────────────────────────┘
```

### Step-by-Step

**Phase 1: Normal (t=0s to t=60s)**
1. All traffic flows normally through the primary Data Center link
2. Heartbeat monitor checks the primary link every 0.5 seconds: "Are you alive?" → "Yes!"

**Phase 2: Link Failure (t=60s)**
3. The primary CSMA link between Core Router and Data Center is **disabled**
   - `ipv4->SetDown(primaryDcIfIndex)` is called on the router
   - Traffic to/from Data Center is disrupted

**Phase 3: Detection (t=60.5s)**
4. Heartbeat monitor (running every 0.5s) detects: "Primary link is DOWN!"
5. Detection time: **< 500 milliseconds**

**Phase 4: Recovery (t=60.5s – t=62s)**
6. Self-Healing Controller activates the backup path:
   - **Step 1:** Enable backup interface: `ipv4->SetUp(backupIfIndex)`
   - **Step 2:** Recompute all routing tables: `Ipv4GlobalRoutingHelper::RecomputeRoutingTables()`
   - **Step 3:** All traffic now flows: Router → Backup Switch (`10.0.2.0/24`) → Data Center (`10.0.82.0/24`)
   - **Step 4:** Quarantine Integrity Check: Verify quarantined devices remain isolated
7. Recovery time: **< 2 seconds**

**Phase 5: Restored (t=90s)**
8. Primary link is restored: `ipv4->SetUp(primaryDcIfIndex)`
9. Routing tables recomputed again (primary link preferred)
10. Backup switch returns to standby mode
11. Quarantine integrity re-verified

### Why This Matters

Normal OSPF self-healing:
```
Link fails → OSPF recalculates routes → Traffic rerouted → Done ✅
But... quarantined device might regain access through new route! ❌
```

Our quarantine-aware self-healing:
```
Link fails → Detect in 0.5s → Activate backup → Recompute routes
→ VERIFY quarantine integrity → Confirm isolated devices stay isolated ✅
→ Done (< 2 seconds total) ✅
```

---

## Scenario 4: Combined — Attack + Self-Healing (BEST FOR DEMO)

### What Happens (Timeline)

```
t=0s ─ t=30s ── t=36s ── t=40s ── t=45s ── t=60s ── t=62s ── t=90s ── t=120s
  │      │        │        │        │        │        │        │         │
  │      │        │        │        │        │        │        └─ Link restored
  │      │        │        │        │        │        └─ Recovery + quarantine OK
  │      │        │        │        │        └─ PRIMARY LINK FAILS
  │      │        │        │        └─ QUARANTINED (score ≥ 70)
  │      │        │        └─ RATE_LIMITED (score ≥ 55)
  │      │        └─ WARNING (score ≥ 40)
  │      └─ ATTACK BEGINS
  └─ Normal traffic
```

### Step-by-Step

This combines Scenario 2 and Scenario 3:

1. **t=0s–30s:** Normal traffic, all scores at 0
2. **t=30s:** Attacker (`10.0.20.2`) begins port scanning, unauthorized access, and flooding
3. **t=36s:** Score hits 40 → **WARNING** (yellow)
4. **t=40s:** Score hits 55 → **RATE_LIMITED** (orange)
5. **t=45s:** Score hits 70 → **QUARANTINED** (dark red, interfaces disabled)
6. **t=45s–60s:** Attacker is completely isolated. Network operates normally.
7. **t=60s:** Primary Data Center link **FAILS**
8. **t=60.5s:** Heartbeat detects failure
9. **t=62s:** Backup path activated, routes recomputed, **quarantine integrity verified**
   - The quarantined attacker is STILL isolated (interfaces are disabled on the DEVICE, not the router)
10. **t=90s:** Primary link restored, routes recomputed, quarantine re-verified
11. **t=120s:** Simulation ends

### Why Scenario 4 is the Best Demo

It demonstrates **ALL 3 novel contributions** in one run:
1. ✅ **Risk Scoring Engine** — detects the attack through 4 signals
2. ✅ **Graduated Quarantine** — progressively isolates the attacker (Warning → Rate-Limit → Quarantine)
3. ✅ **Quarantine-Aware Self-Healing** — recovers from link failure while keeping the attacker isolated

---

## How to Run Each Scenario

### In WSL Terminal:
```bash
cd ~/ns-allinone-3.41/ns-3.41

# Scenario 1 (Normal)
./ns3 run "smart-campus-network --scenario=1"

# Scenario 2 (Attack + Quarantine)
./ns3 run "smart-campus-network --scenario=2"

# Scenario 3 (Self-Healing)
./ns3 run "smart-campus-network --scenario=3"

# Scenario 4 (Combined — RECOMMENDED FOR DEMO)
./ns3 run "smart-campus-network --scenario=4"

# Scenario 4 with detailed logging
./ns3 run "smart-campus-network --scenario=4 --verbose=true"
```

---

## Questions Sir May Ask About Scenarios

**Q: "What scenario are you demonstrating?"**
> *"Scenario 4, the combined scenario. It demonstrates all three novel contributions in one run: the risk scoring engine detects the malware attack at t=30s, the graduated quarantine progressively isolates the attacker by t=45s, and the quarantine-aware self-healing recovers from a link failure at t=60s while verifying the attacker remains isolated."*

**Q: "When does the attack start?"**
> *"At t=30 seconds. The compromised CSE node at 10.0.20.2 begins three simultaneous attack vectors: port scanning the ERP server, unauthorized access attempts to Admin and COE subnets, and a 5 Mbps UDP traffic flood."*

**Q: "How long does it take to detect the attack?"**
> *"Less than 5 seconds. The traffic monitor runs on every forwarded packet, and the risk scoring engine evaluates scores every 1 second. By t=36s (6 seconds after attack start), the score crosses the WARNING threshold of 40."*

**Q: "How long does quarantine take?"**
> *"About 15 seconds from attack start. The score crosses 70 (quarantine threshold) at approximately t=45s. This includes the graduated escalation through WARNING and RATE_LIMITED states, which provides time for admin notification before full isolation."*

**Q: "What happens to the rest of the network during the attack?"**
> *"Nothing changes. Other departments continue their legitimate traffic unaffected. The attack is contained within the CSE VLAN by our segmentation, and once quarantined, the attacker's interfaces are disabled at the device level, not the router level, so no other traffic is impacted."*

**Q: "What if the link fails while an attacker is quarantined?"**
> *"That's exactly what Scenario 4 demonstrates. At t=60s, the primary Data Center link fails — 15 seconds after the attacker was quarantined. Our Self-Healing Controller activates the backup path and recomputes routing tables. Critically, the quarantined attacker remains isolated because the quarantine is applied to the device's own interfaces (ipv4->SetDown), not to the router's interfaces. The rerouting doesn't help the attacker regain access."*
