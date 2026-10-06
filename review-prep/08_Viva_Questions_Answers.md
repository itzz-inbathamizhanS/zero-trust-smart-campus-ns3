# ❓ Viva Questions & Answers — All 30 Marks Covered

> **EVERY possible question Sir can ask, with ready-made answers**
> All 5 members should memorize these answers

---

## Category 1: Network Topology Design (5 Marks)

**Q1: What topology did you use?**
> *"A 3-tier hierarchical topology: Core layer (1 Core Router as Policy Enforcement Point), Distribution layer (1 Backup Switch for redundancy), and Access layer (8 CSMA segments representing campus departments with 55 end devices)."*

**Q2: How many nodes are in your network?**
> *"58 nodes total: 1 Internet Server, 1 Core Router, 1 Backup Distribution Switch, and 55 department nodes across 8 VLANs."*

**Q3: Why hierarchical design? Why not a flat network?**
> *"A flat network allows any device to directly reach any other device, making security enforcement nearly impossible. Hierarchical design forces all inter-department traffic through the Core Router, enabling 100% packet inspection and Zero-Trust policy enforcement. It's also more scalable and easier to manage."*

**Q4: What is a 3-tier architecture?**
> *"It has three layers: Core (handles routing and high-speed forwarding), Distribution (provides redundancy and policy application), and Access (where end devices connect). This is the Cisco-recommended model for campus networks."*

**Q5: What devices are in the Data Center?**
> *"7 servers: ERP Server, Database Server, DHCP Server, DNS Server, Web Server, Email Server, and Backup Server. All on VLAN 80 (10.0.80.0/24)."*

**Q6: What is the role of the Core Router?**
> *"The Core Router serves as the centralized Policy Enforcement Point. It connects to all 8 VLANs, inspects every forwarded packet against the Zero-Trust policy, runs the behavioural risk scoring engine, and triggers quarantine actions when threats are detected."*

**Q7: What is the Backup Switch for?**
> *"The Backup Distribution Switch (DistSwitch2) provides a redundant path to the Data Center. When the primary CSMA link between the Core Router and DC fails, the Self-Healing Controller activates a Point-to-Point link through this switch. It ensures > 95% network availability."*

---

## Category 2: IP Addressing & Subnetting (5 Marks)

**Q8: What IP addressing scheme did you use?**
> *"Class A private address space 10.0.0.0 with /24 subnets. The third octet identifies each department: 10 = Admin, 20 = CSE, 30 = IT, 40 = Library, 50 = COE, 60 = Hostel, 70 = IoT, 80 = Data Center."*

**Q9: What is the subnet mask?**
> *"255.255.255.0, also written as /24. The first 24 bits identify the network, the last 8 bits identify the host. Each subnet provides up to 254 usable addresses."*

**Q10: What is /24? How many hosts can it support?**
> *"/24 means the first 24 bits are the network portion. That leaves 8 bits for hosts, giving 2^8 - 2 = 254 usable host addresses (minus network address and broadcast address)."*

**Q11: Why did you choose 10.0.0.0?**
> *"10.0.0.0/8 is a private IP range defined in RFC 1918. It's not routable on the public internet, making it safe for internal campus use. It also provides over 16 million addresses, giving us flexibility in subnet planning."*

**Q12: What is VLSM? Did you apply it?**
> *"VLSM stands for Variable Length Subnet Masking — using different subnet sizes for different needs to avoid wasting addresses. In our NS-3 simulation, we used uniform /24 for simplicity. In a real deployment, we would use /28 for large departments like CSE (14 hosts) and /29 for smaller ones like Admin (6 hosts)."*

**Q13: What is the IP address of the attacker?**
> *"10.0.20.2 — the first CSE student node in VLAN 20."*

**Q14: How does the router identify which department a packet belongs to?**
> *"By extracting the third octet of the source IP. For example, if a packet comes from 10.0.20.x, the third octet is 20, which maps to CSE. This is implemented in our VlanNameFromIp() function."*

**Q15: What is the difference between public and private IP?**
> *"Public IPs are globally unique and routable on the internet (e.g., 142.250.182.14 for Google). Private IPs (10.x.x.x, 172.16-31.x.x, 192.168.x.x) are only used within internal networks and are not routable on the internet. We use private IPs for our campus."*

---

## Category 3: Routing & Switching (5 Marks)

**Q16: What type of routing do you use — static or dynamic?**
> *"Dynamic routing. NS-3's GlobalRoutingHelper simulates OSPF-like link-state routing. Routes are automatically recalculated when the network topology changes, such as during our self-healing link failure scenario."*

**Q17: What is OSPF?**
> *"Open Shortest Path First — a link-state dynamic routing protocol. Each router maintains a complete topology map of the network and uses Dijkstra's shortest-path algorithm to calculate optimal routes. When a link changes, routers flood updates and recompute their routing tables."*

**Q18: What is the difference between static and dynamic routing?**
> *"Static routes are manually configured and don't adapt to network changes. Dynamic routes are learned automatically through protocols like OSPF and adapt when links fail or new paths appear. We need dynamic routing for our self-healing feature — when the primary link fails, routes must automatically shift to the backup path."*

**Q19: What is a VLAN?**
> *"A Virtual LAN — a logical grouping of devices that behave as if they're on the same physical network, even if they're not. VLANs provide broadcast domain isolation. We use 8 VLANs to segment our campus departments."*

**Q20: How does Inter-VLAN routing work?**
> *"Devices in different VLANs cannot communicate directly — they need a router. In our design, the Core Router has interfaces on all 8 VLANs. When a CSE device (10.0.20.3) wants to reach the Web Server (10.0.80.6), the packet goes to the router, which checks the Zero-Trust policy and forwards it to the Data Center VLAN."*

**Q21: What happens when the primary link fails?**
> *"Our Self-Healing Controller detects the failure within 500ms using heartbeat monitoring, activates the backup distribution switch, calls RecomputeRoutingTables() to recalculate all routes, verifies quarantine integrity, and completes recovery in under 2 seconds."*

**Q22: What is the difference between a switch and a router?**
> *"A switch operates at Layer 2 and forwards frames based on MAC addresses within the same VLAN. A router operates at Layer 3 and forwards packets based on IP addresses between different subnets/VLANs. Our CSMA segments act as switches, and the Core Router handles inter-VLAN routing."*

---

## Category 4: Security Design (5 Marks)

**Q23: What security mechanisms have you implemented?**
> *"Four layers: (1) Network segmentation with 8 VLANs, (2) Zero-Trust ACL with default-deny policy, (3) Multi-factor behavioural risk scoring engine with 4 signals and temporal decay, (4) Graduated dynamic quarantine with 4 progressive levels."*

**Q24: What is Zero-Trust?**
> *"A security model based on 'never trust, always verify.' Unlike the old perimeter model that trusts everything inside the firewall, Zero-Trust continuously verifies every device regardless of location. In our implementation, every packet forwarded by the router is checked against the access policy, and every device has a continuously computed risk score."*

**Q25: What is an ACL?**
> *"Access Control List — a set of permit/deny rules on a router. Our Zero-Trust Access Matrix is an extended ACL that filters based on both source and destination VLAN. It follows default-deny: any traffic not explicitly permitted is dropped and flagged as a security event."*

**Q26: How does the risk scoring work?**
> *"Four behavioural signals are monitored: unauthorized access violations (+25 points), traffic anomaly (>80 pps), port scanning (>10 unique ports), and protocol abuse (>160 pps). The weighted formula is: Score = 0.35×Access + 0.25×Traffic + 0.25×PortScan + 0.15×Protocol. A temporal decay of 0.95 per second prevents permanent quarantine."*

**Q27: What is temporal decay and why is it important?**
> *"Temporal decay is a multiplicative factor (γ = 0.95) applied to risk scores every second. It makes old events fade away — a score of 100 decays to ~50 in 14 seconds if no new suspicious activity occurs. This is crucial for false-positive recovery: if a student temporarily triggers high traffic (like downloading a large dataset), their score drops back to normal automatically without admin intervention."*

**Q28: How does quarantine physically work?**
> *"When a device's risk score reaches 70 or above, the Quarantine Controller calls ipv4->SetDown() on all non-loopback interfaces of that device's NS-3 node. This disables the device's network connectivity at Layer 3, completely isolating it from the network. Recovery occurs when the score decays below 70 and ipv4->SetUp() is called."*

**Q29: Why graduated quarantine instead of binary?**
> *"Binary quarantine has a false-positive problem: a student downloading a large file might get immediately blocked, disrupting their academics. Our graduated system first moves them to WARNING (admin gets alert, student keeps working), then RATE_LIMITED if behaviour persists, and only QUARANTINES if multiple signals confirm malicious activity. This reduces false-positive disruption while maintaining rapid response to real threats."*

**Q30: What is port scanning and how do you detect it?**
> *"Port scanning is when an attacker sends packets to many different ports on a target to discover running services. We maintain a stateful set of unique destination ports per source IP within a 5-second window. If a source contacts more than 10 unique ports, we flag it as a scan and add 30 risk points."*

**Q31: What is network segmentation? Why is it important?**
> *"Network segmentation divides a large network into isolated pieces using VLANs. If malware infects a CSE laptop, it's confined to the CSE VLAN — it cannot directly spread to Admin, IoT, or Data Center. Without segmentation, 60-80% of nodes could be infected. With segmentation, we limit it to under 5%."*

---

## Category 5: Technical Presentation (5 Marks)

**Q32: Which simulator did you use and why?**
> *"NS-3 (Network Simulator 3). We chose NS-3 over Cisco Packet Tracer because Packet Tracer only supports pre-built Cisco IOS commands and cannot implement custom algorithms. NS-3 lets us write custom C++ classes for our risk scoring engine, traffic monitor, quarantine controller, and self-healing controller."*

**Q33: Can you show the simulation running?**
> *[Run this command]:* `cd ~/ns-allinone-3.41/ns-3.41 && ./ns3 run "smart-campus-network --scenario=4"`
> *Point out: scenario number, attack timing, quarantine event, link failure, results table*

**Q34: What are your simulation results?**
> - *Total Flows: 150*
> - *Total Throughput: 25,030 Kbps*
> - *Average Delay: 1.85 ms*
> - *Packet Loss: 0.68%*
> - *Detection Time: < 5 seconds (vs 5-30 min traditional)*
> - *Quarantine Time: < 3 seconds (vs 10-60 min traditional)*
> - *Link Recovery: < 2 seconds (vs 30-60 sec traditional)*

**Q35: What is the contribution of each member?**
> *"Member 1 designed the overall architecture and coordinated the simulation. Member 2 handled network topology and IP addressing. Member 3 implemented the security policy and ACL. Member 4 developed the risk scoring engine and quarantine logic. Member 5 built the self-healing controller and analysis graphs."*

**Q36: What are the limitations of your project?**
> *"Three main limitations: (1) Rate-limiting enforcement — the RATE_LIMITED state is logged but actual traffic throttling via TC queuing disciplines is not simulated. (2) The comparison metrics (Traditional vs Proposed) are theoretical estimates, not experimental measurements from a real campus. (3) The simulation uses centralized routing rather than a fully distributed OSPF implementation."*

**Q37: What is your future work?**
> *"Three directions: (1) Implement actual bandwidth throttling using NS-3's TrafficControlHelper for the RATE_LIMITED state. (2) Integrate machine learning for anomaly detection to improve risk scoring accuracy. (3) Deploy on a real campus testbed and compare actual vs simulated performance."*

**Q38: Do you have a research paper?**
> *"Yes, our paper 'Autonomous Behavioural Risk Scoring and Graduated Quarantine in Zero-Trust Campus Networks' is saved as zero_trust_risk_scoring.docx. It covers the full methodology, NS-3 implementation, results, and comparison with existing work."*

---

## Bonus: Unexpected Questions

**Q: What is the OSI model?**
> *"The 7-layer model: Physical, Data Link, Network, Transport, Session, Presentation, Application. Our project primarily works at Layer 3 (Network — IP routing and forwarding) and Layer 2 (Data Link — CSMA segments and MAC addressing)."*

**Q: What is TCP vs UDP?**
> *"TCP is connection-oriented (reliable delivery, checks for errors, retransmits lost packets). UDP is connectionless (faster, no error checking, used for real-time applications). Our simulation uses UDP for all traffic because campus traffic like streaming and web browsing benefits from speed over reliability."*

**Q: What is a MAC address?**
> *"A hardware address (48-bit) burned into every network interface card. Written as six pairs of hex digits (AA:BB:CC:DD:EE:FF). Used by switches at Layer 2 for forwarding frames within the same VLAN."*

**Q: What is the difference between a hub, switch, and router?**
> *"Hub: Layer 1, broadcasts everything to all ports (dumb). Switch: Layer 2, forwards frames based on MAC addresses to specific ports (smart). Router: Layer 3, forwards packets based on IP addresses between different networks/VLANs (smartest)."*

**Q: What is NAT?**
> *"Network Address Translation — converts private IPs (like our 10.0.x.x) to public IPs for internet access. In our simulation, the Internet Server represents the external network, and the router would perform NAT in a real deployment."*

**Q: What is a firewall?**
> *"A network security device that monitors and controls traffic based on rules. Our Core Router functions as an advanced next-generation firewall — instead of static allow/deny rules, it uses continuous behavioural monitoring and dynamic risk scoring."*

---

> **Final tip:** The most important thing is **confidence**. Speak clearly, point to the terminal output, and say *"as you can see in the simulation..."* — showing is more convincing than telling.
