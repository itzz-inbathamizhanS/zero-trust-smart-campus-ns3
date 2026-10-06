# 🎤 Technical Presentation & Demo Guide — Review 2 (5 Marks)

> **Rubric Criteria:** Demo, explanation, teamwork (5 marks)

---

## Team Member Roles (5 Members)

Each member should OWN a specific part. During the review, that person presents their section. But **ALL members must know ALL sections** in case Sir asks cross-questions.

### Suggested Role Assignment

| # | Member | Section to Present | Duration | Key Slides/Sections |
|---|--------|-------------------|----------|-------------------|
| 1 | **Inbathamizhan S** | Project Overview + Live Terminal Demo | 3 min | Abstract, problem statement, run `./ns3 run` |
| 2 | **Sadiq Vali** | Network Topology + IP Addressing | 3 min | 3-tier design, 8 VLANs, IP scheme |
| 3 | **Judson Pushparaj** | Security Design + ACL | 3 min | Zero-Trust matrix, 4 security layers |
| 4 | **Surya Prakash** | Risk Scoring Engine + Quarantine | 3 min | 4 signals, formula, graduated levels |
| 5 | **Balaji** | Self-Healing + Results Dashboard | 3 min | Link failure, NetAnim, graphs |

> **Total: ~15 minutes**

---

## Presentation Flow (Step by Step)

### Step 1: Introduction (Member 1 — 2 min)

**What to say:**
> *"Good morning Sir. Our project is titled 'Autonomous Behavioural Risk Scoring and Graduated Quarantine in Zero-Trust Campus Networks.' We have also published a research paper: zero_trust_risk_scoring.docx.*
>
> *The problem: Campus networks face internal threats — compromised student laptops, lateral malware movement, and network outages. Traditional firewalls use binary allow/deny rules that cause false positives, and standard OSPF self-healing doesn't preserve quarantine state during failover.*
>
> *Our solution has 3 novel contributions:*
> 1. *Multi-factor behavioural risk scoring engine with temporal decay*
> 2. *Graduated dynamic quarantine (4 levels instead of binary block)*
> 3. *Quarantine-aware self-healing that maintains isolation during link failures*
>
> *We implemented this in NS-3 with 58 nodes across 8 department VLANs. Let me hand over to [Member 2] to explain the network design."*

---

### Step 2: Network Topology + IP (Member 2 — 3 min)

**What to show:** Draw or display the topology diagram

**What to say:**
> *"We use a 3-tier hierarchical design:*
> - *Core Layer: One Core Router acting as the Zero-Trust Policy Enforcement Point*
> - *Distribution Layer: A Backup Distribution Switch for redundancy*
> - *Access Layer: 8 CSMA segments representing campus departments*
>
> *IP addressing uses the 10.0.X.0/24 scheme. The third octet identifies the department — 10 for Admin, 20 for CSE, 30 for IT, up to 80 for Data Center. We have 58 nodes total: 3 infrastructure nodes and 55 department nodes.*
>
> *Each department is on its own VLAN, connected to the router via CSMA at 100 Mbps. The backbone and backup links use Point-to-Point at 1 Gbps.*
>
> *Now [Member 3] will explain our security design."*

---

### Step 3: Security Design + ACL (Member 3 — 3 min)

**What to show:** The Access Control Matrix table

**What to say:**
> *"We implement 4 layers of security:*
>
> *Layer 1 — Network Segmentation: 8 VLANs isolate departments. An infection in CSE cannot spread to Admin or IoT.*
>
> *Layer 2 — Zero-Trust Access Control: Our ACL follows default-deny. Only explicitly permitted VLAN-to-VLAN pairs are allowed. For example, CSE can reach Library and Data Center but NOT Admin or COE. Admin has full access. Quarantined nodes have zero access.*
>
> *Layer 3 — Behavioural Monitoring: Instead of one-time authentication, we continuously inspect every packet forwarded by the router and track 4 behavioural signals per source IP.*
>
> *Layer 4 — Graduated Quarantine: Instead of binary block, we have 4 progressive levels. [Member 4] will explain this in detail."*

---

### Step 4: Risk Scoring + Quarantine (Member 4 — 3 min)

**What to show:** The risk formula and quarantine state diagram

**What to say:**
> *"The Risk Scoring Engine monitors 4 signals:*
> 1. *Unauthorized access violations — +25 points when a packet violates the ACL*
> 2. *Traffic volume anomaly — triggered when packets per second exceed 80*
> 3. *Port scan detection — triggered when a source contacts more than 10 unique ports*
> 4. *Protocol abuse — triggered at extremely high rates above 160 pps*
>
> *The weighted formula is: Score = 0.35×Access + 0.25×Traffic + 0.25×PortScan + 0.15×Protocol*
>
> *The temporal decay factor γ = 0.95 is applied every second. This means if a student accidentally triggers a spike, the score fades automatically — no manual admin intervention needed. A score of 100 decays to about 50 in 14 seconds.*
>
> *Based on the score:*
> - *Below 40 → Normal (full access)*
> - *40-54 → Warning (alert + logging)*
> - *55-69 → Rate-Limited (severe alert)*
> - *70+ → Quarantined (all interfaces disabled, complete isolation)*
>
> *In our Scenario 4 demo, the attacker's score crosses 70 at about t=45 seconds, and its interfaces are shut down. Now [Member 5] will show the self-healing and results."*

---

### Step 5: Self-Healing + Demo + Results (Member 5 — 3 min)

**What to show:** NetAnim visualization + Dashboard graph

**What to say:**
> *"The third novel contribution is quarantine-aware self-healing. At t=60s, the primary Data Center link fails. Our heartbeat monitor detects this within 500 milliseconds. The backup distribution switch is activated, routing tables are recomputed, and traffic flows through the alternate path. Total recovery takes under 2 seconds.*
>
> *The critical difference: standard OSPF is security-agnostic — rerouting might restore access to quarantined devices. In our system, quarantine is applied at the device level (ipv4->SetDown on the device's interfaces), not on the router. So rerouting doesn't help the attacker. We verify this with a quarantine integrity check after every self-healing event.*
>
> *Here are our results from Scenario 4:*
> - *Total flows: 150*
> - *Throughput: 25,030 Kbps*
> - *Average delay: 1.85 ms*
> - *Packet loss: only 0.68%*
> - *Detection time: < 5 seconds vs 5-30 minutes traditionally*
> - *Recovery time: < 2 seconds vs 30-60 seconds traditionally"*

---

### Step 6: Live Terminal Demo (Member 1 — 2 min)

**Commands to run:**
```bash
# Open WSL
wsl

# Navigate to NS-3
cd ~/ns-allinone-3.41/ns-3.41

# Run the combined scenario
./ns3 run "smart-campus-network --scenario=4"
```

**What to point out as it runs:**
1. Header showing Scenario 4, 120s duration
2. Attack scheduled at t=30s from `10.0.20.2`
3. Link failure at t=60s, restore at t=90s
4. Results table: flows, throughput, delay, packet loss
5. Comparison table: Traditional vs Proposed

---

## How to Handle Questions from Sir

### General Strategy

1. **Listen carefully** to the full question before answering
2. **Start with the simple answer**, then add technical detail
3. **Relate it to the code** if possible — "In our implementation, line X does Y"
4. **If you don't know:** Say *"That specific detail was handled by [member name], let me ask them to explain"* — this shows teamwork

### Emergency Answers (If Stuck)

If Sir asks something you're unsure about, use these safe responses:

- **"How does X work internally?"** → *"Let me explain the high-level flow: [describe what you know], and the implementation details are in our smart-campus-network.cc file, Section [X]."*

- **"Why did you choose X over Y?"** → *"We evaluated both options. X was chosen because [advantage 1] and [advantage 2]. However, Y would be suitable for [different use case]."*

- **"What is the limitation?"** → *"Our current implementation focuses on proving the architecture's feasibility. Rate-limiting enforcement uses state logging rather than actual traffic control, and the performance comparison uses theoretical estimates. These are documented in our paper for future work."*

---

## Files to Keep Open During Demo

| File / Tool | Purpose |
|-------------|---------|
| **WSL Terminal** | Run `./ns3 run "smart-campus-network --scenario=4"` |
| **NetAnim** | Visual animation of the network |
| **combined_dashboard.png** | 4-panel results graph |
| **risk_score_evolution.png** | Shows attacker's score rising |
| **This guide (on phone)** | Emergency reference during viva |

---

## Teamwork Points to Mention

When Sir evaluates teamwork, make sure to:

1. **Reference each other:** "As [member] explained earlier..."
2. **Don't talk over each other**
3. **If one member struggles with a question, another can politely help:** "I can add to that — in the code we..."
4. **Show that everyone contributed:**
   - Member 1: Overall architecture and simulation coordination
   - Member 2: Network topology design and IP addressing
   - Member 3: Security policy and ACL implementation
   - Member 4: Risk scoring engine and quarantine logic
   - Member 5: Self-healing controller and analysis graphs

---

## Pre-Review Checklist

- [ ] All 5 members have read the 01_Technical_Glossary.md
- [ ] All 5 members have read their assigned section file
- [ ] All 5 members know how to run Scenario 4 in WSL
- [ ] Terminal is tested and working (run scenario before the review)
- [ ] NetAnim opens successfully
- [ ] Dashboard image is ready to show
- [ ] Each member can answer basic questions about ANY section (not just their own)
- [ ] Each member can state the project title, 3 contributions, and key metrics from memory
