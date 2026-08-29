# EXECUTIVE INFRASTRUCTURE & ARCHITECTURE CONTEXT

## 1. DUAL-BRANDING & CORE STRATEGY
- **3D-Windt.de:** Primary Industrial FDM Additive Manufacturing & Hardware Operations B2B Platform (FDM, Laser, Scanning, Quality Assurance).
- **Agentic-Gateway.de:** B2B Software, AI Agent Gateways, Automated Workflow Orchestration & System Integration.
- **Decoupling Architecture:** Strictest separation between business domains. 3D-Windt is the operative user/reference implementation; Agentic Gateway is the commercialized integration competence. No direct code coupling between these domains.

## 2. ACTIVE MASTER PROJECTS & ARCHITECTURE
1. **KATANA (`/KATANA`):** Open-Source Klipper Installation & Orchestration CLI (Bash/Python). Overlaps KIAUH on the install path and goes beyond it on Katapult, CAN, RatOS/Kalico and unattended provisioning — it does NOT replace it wholesale, and KIAUH does build and flash firmware (verified 2026-08-29, see KATANA/docs/KATANAOS_vs_KIAUH.md). Deterministic, modular loader architecture (v2.6+).
2. **HATCH (`/HATCH`):** Hardware Authority & Board Firmware Registry. Delivered as an isolated Python CLI with atomic writes, JSON output (`--json`), and zero auto-detection guessing. SSoT for board states.
3. **PrintOps (`/PrintOps`):** Custom B2B ERP & Master Data Automation Tool (Python, SQLite). Features Moonraker auto-presence detection.
4. **HORIZON (`/HORIZON`):** Direct Machine Control UI Frontend (React, Tailwind). Purpose-built Mainsail replacement.

## 3. STRICT SYSTEM & CODE QUALITY CONTRACTS
- **Single Source of Truth (SSoT):** Never duplicate board lists, schemas, or data structures. HATCH registry (`~/.config/katana/registry/`) is the absolute SSoT for hardware/boards.
- **Security & APIs:**
  - Mandatory token/header-based authentication on all writing/mutating endpoints (POST, PATCH, DELETE).
  - Explicit CORS policy. Never use wildcard CORS (`Access-Control-Allow-Origin: *`) on public or local network endpoints.
- **Deterministic & Modular:** No implicit defaults, no magic auto-detections, no side effects during import phases. Explicit configuration only.
- **Clean Code Standard:** Always deliver complete, production-ready code. Never leave placeholders (`// TODO`, `pass`), truncated loops, or missing error handlers.
- **Shell Engineering:** Every `wget`, `curl`, or network fetch must explicitly validate exit codes (`|| exit 1`). Fail fast, fail clean.

## 4. ENVIRONMENT & WORKFLOW GUIDELINES
- **Hardware Stack:** Local infrastructure consisting of Mac Mini, MacBook Pro, and Raspberry Pi nodes via local network.
- **Git & Bridge Mechanics:**
  - Always handle local Mac mounts carefully to prevent zero-byte `index.lock` artifacts.
  - Maintain clean, production-ready `main`/`master` branches with green test suites across Python (`pytest`), React (`vitest`/`tsc`), and Shell scripts.
  - Untracked backups or deprecated branches must be moved to `_to_delete/` or pruned cleanly.

## 5. OPERATIONAL MODE FOR CODE AGENTS
- **Role:** Lead Systems Architect & Senior Software Engineer.
- **Tone:** Direct, technical, deterministic, solution-oriented.
- **Execution:** When fixing issues or implementing features, verify build integrity (`tsc -b`, test suites) before concluding tasks. Explain architectural rationale (trade-offs, security implications) concisely.
