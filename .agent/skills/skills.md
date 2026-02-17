# Technical Intelligence & Skill Matrix (KATANA)  
**Version:** 3.1 (Ultimate KATANA "Antigravity" Edition)
**Status:** Senior-Level Documentation  

## 1. Core Competencies (Expertise-Matrix)      
| Domäne | Spezialisierung | Fokus-Bereiche |
| :--- | :--- | :--- |
| **Klipper/Kalico** | Core Motion | Kalico-Kinematik, Multi-Instance Management, Macro-Architektur, G-Code-Logic. |
| **Antigravity** | Eddy Probing | Beacon, Cartographer, BTT Eddy (Auto-Scan, Survey, High-Speed Meshing). |
| **Multi-Material** | Filament Flow | ERCF v2 (Happy Hare), EMU (Endless Material Unit), StealthChanger Integration. |
| **CAN-Bus/HW** | Communication | BTT EBB, Toolhead-Orchestrierung, Esoterical CAN-Logik, Udev-Hardening. |
| **Vibration Tuning** | Resonance | Klippain ShakeTune, FFT-Analyse, Input Shaper Auto-Calibration. |
| **MCU Automation** | Deployment | Headless Building, Artifact-Detection (UF2/BIN/DFU), Flash-Path Automation. |
| **System Ops** | Linux Engine | Systemd-Automation, Nginx Reverse-Proxy, Log2Ram, UFW Security. |

## 2. Validierte Knowledge Base (Datenquellen)  

### A. Core Firmware & High-Performance Motion  
* **Klipper3D:** [klipper3d.org](https://www.klipper3d.org/) – Basis für G-Code, Makros & Bed_Mesh.  
* **Kalico Crew:** [github.com/KalicoCrew/kalico](https://github.com/KalicoCrew/kalico) – Erweiterte Kinematik für maximale Präzision.  
* **Voron Design:** [github.com/VoronDesign/Voron-2](https://github.com/VoronDesign/Voron-2) – Gold-Standard Hardware-Referenz.  

### B. Antigravity Stack (Induktive Z-Sensorik)
* **Cartographer:** [github.com/cartographer-project/cartographer](https://github.com/cartographer-project/cartographer) – Eddy-Scanning & High-Speed Meshing.
* **Beacon3D:** [github.com/beacon3d](https://github.com/beacon3d) – Eddy Current Probe & Echtzeit-Z-Mapping.
* **BTT Eddy:** [github.com/bigtreetech/Eddy](https://github.com/bigtreetech/Eddy) – Hardware-Referenz & Induktions-Struktur.

### C. Multi-Material & Toolchanging
* **ERCF v2:** [github.com/Carrot-collective/ERCF_v2](https://github.com/Carrot-collective/ERCF_v2) – Hardware für Enraged Rabbit (MMU).
* **Happy Hare:** [github.com/moggieuk/Happy-Hare](https://github.com/moggieuk/Happy-Hare) – Software-Stack für MMU Management.
* **EMU:** [github.com/DW-Tas/EMU](https://github.com/DW-Tas/EMU) – Endless Material Unit & Filament-Sensorik.
* **StealthChanger:** [github.com/DraftShift/StealthChanger](https://github.com/DraftShift/StealthChanger) – Mechanische Verriegelung & Docking-Makros.

### D. CAN-Bus & Toolboard Architecture
* **BTT EBB:** [github.com/bigtreetech/EBB](https://github.com/bigtreetech/EBB) – CAN-Toolboard Pinouts & Firmware.
* **Esoterical CAN:** [canbus.esoterical.online](https://canbus.esoterical.online/) – Referenz für Topologie & Udev-Regeln.

### E. Tuning & Diagnostics
* **Klippain ShakeTune:** [github.com/Frix-x/klippain-shaketune](https://github.com/Frix-x/klippain-shaketune) – FFT-Vibrationstuning.

## 3. TUI Rendering & Visual Logic         
* **Design Rule:** Der KATANA-ASCII-Style ist unveränderlich.   
* **Alignment:** Nutzung von `printf` mit dynamischen Breiten (`%-25s`).
* **Frame Integrity:** Menürahmen passen sich der Terminalbreite an (`tput cols`).


# Intelligence & Skill Matrix (KATANA)      
**Version:** 3.3 (KATANA "Anti-Slop" Edition)     
**Status:** Senior-Level Validation Standards           

## 1. Core Competencies     
| Domäne | Spezialisierung | Fokus-Bereiche |
| :--- | :--- | :--- |
| **Shell Engineering** | Error Handling | Exit-Codes, Stderr-Redirection, Recovery-Logiken. |
| **Validation Logic** | State Awareness | Systemd-Status, Git-Integrität, Port-Binding Checks. |
| **System Ops** | Minimalism | Dependency-Tracking (Kein Bloat!), Service-Respect (Avahi bleibt!). |
| **UX/UI Design** | TUI Precision | ANSI-Escape-Sanitization, Dynamic Alignment, Clean Borders. |

## 2. Technical Roadmap (Lessons Learned)       
* **Status != Existence:** Ein Ordner bedeutet nicht, dass der Dienst läuft. KATANA nutzt `systemctl is-active` und `git status`.  
* **Minimalist Footprint:** Nur installieren, was Klipper braucht. Admin-Tools (`tcpdump`, `mc`, `ranger`) sind OPTIONAL, nicht Standard.  
* **Service Continuity:** Bestehende Netzwerk-Infrastrukturen (Avahi/mDNS) werden NIEMALS ohne User-Aufforderung entfernt.  


# Technical Intelligence & Skill Matrix (KATANA)      
**Version:** 3.4 (The "Precision" Update)     
**Status:** Senior-Level Validation Standards           

## 1. Core Competencies     
| Domäne | Spezialisierung | Fokus-Bereiche |
| :--- | :--- | :--- |
| **Shell Engineering** | Error Handling | Exit-Codes, Stderr-Redirection, Recovery-Logiken. |
| **Validation Logic** | State Awareness | Systemd-Status, Git-Integrität, Port-Binding Checks. |
| **System Ops** | Minimalism | Dependency-Tracking (Kein Bloat!), Service-Respect (Avahi bleibt!). |
| **UX/UI Design** | TUI Precision | ANSI-Escape-Sanitization, Dynamic Alignment, Clean Borders. |

## 2. Technical Roadmap (Lessons Learned)       
* **Status != Existence:** Ein Ordner bedeutet nicht, dass der Dienst läuft. KATANA nutzt `systemctl is-active` und `git status`.  
* **Minimalist Footprint:** Nur installieren, was Klipper braucht. Admin-Tools (`tcpdump`, `mc`, `ranger`) sind OPTIONAL, nicht Standard.  
* **Service Continuity:** Bestehende Netzwerk-Infrastrukturen (Avahi/mDNS) werden NIEMALS ohne User-Aufforderung entfernt.  
