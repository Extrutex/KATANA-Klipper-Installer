# KATANAOS vs. KIAUH — geprüft, nicht behauptet

> Stand: 2026-08-29. Alle Aussagen unten sind an KIAUHs `master` verifiziert
> (Quelldateien und offene Issues sind je Zeile genannt). Die vorherige Fassung
> dieses Dokuments behauptete „Kein Firmware-Flash. Kein MCU-Handling." — das
> ist **falsch** und hätte im ersten Fachgespräch die gesamte Positionierung
> gekippt. Wer hier etwas ergänzt: erst nachsehen, dann schreiben.

## Die Ausgangslage ehrlich

| | KIAUH | KATANAOS |
|---|---|---|
| Sterne | 4.508 | 78 (~58×) |
| Contributor | 71 | im Wesentlichen einer |
| Sprache | **Python, seit v6** (~28k Zeilen) | Bash (~8,1k) + Python-Kern (~1,6k) |
| Letzter Commit | 2026-08-03 | laufend |
| Erweiterungen | 20 Extensions | Module im Repo |

**Wichtig:** KIAUH ist seit v6 kein Bash-Projekt mehr. Die Positionierung
„gegen das alte, unwartbare Bash-Monster" ist sachlich falsch — und ausgerechnet
KATANA ist heute der Bash-lastigere von beiden. Reichweitenparität ist kein
erreichbares Ziel; Vorsprung entsteht nur in einzelnen, benennbaren Punkten.

## Was KIAUH kann — inklusive dem, was oft übersehen wird

Install / Update / Remove für Klipper, Moonraker, Mainsail, Fluidd,
KlipperScreen, Crowsnest sowie 20 Extensions (Obico, OctoEverywhere,
Mobileraker, Spoolman, klipper-backup, TMC Autotune, gcode_shell_cmd …).

Dazu, entgegen der alten Fassung dieses Dokuments, **sehr wohl**:

- **Firmware bauen und flashen** — `Advanced → [1] Build`, `[2] Flash`,
  `[3] Build + Flash` (`kiauh/core/menus/advanced_menu.py`)
- **MCU-ID auslesen** — `Advanced → [4] Get MCU ID`
- **DFU-Flash über USB** — `ConnectionType.USB_DFU`
  (`kiauh/components/klipper_firmware/flash_options.py`)
- **RP2040-USB und UART** — `USB_RP2040`, `UART`, ebenda
- **SD-Card-Flash** — `FlashMethod.SD_CARD`
- **Repository-Rollback** für Klipper und Moonraker
- **Input Shaper Dependencies**, Hostname ändern

## Die belegten Lücken — hier und nur hier ist KATANA vorn

| Punkt | KIAUH | KATANAOS | Beleg |
|---|:---:|:---:|---|
| **Katapult-Bootloader** | ❌ | ✅ Build + Flash | Issues #439, #480, #757 — alle **offen** |
| **CAN-Bus** | ❌ | ✅ Wizard + can0-Setup | `FlashMethod` kennt nur Regular/SD-Card, `ConnectionType` kein CAN |
| **Unbeaufsichtigte Installation** | ❌ | ✅ `katanaos.sh install --yes` | KIAUH Issue #594 „Make a headless mode" — **offen** |
| **Engine-Switch Klipper ↔ Kalico ↔ RatOS** | ❌ | ✅ | KIAUH bricht auf RatOS aktiv ab (`check_if_ratos`) |
| **Linux Host MCU** | ❌ | ✅ auto-configure + Service | keine Entsprechung in `components/` |
| **Diagnose-Ebene** (Service-Status, dmesg, Repair) | ❌ | ✅ | keine Entsprechung in `components/` |

Das sind **sechs** Punkte, nicht vierzehn. Sie tragen trotzdem, weil sie genau
die Fälle abdecken, die einen Werkstattbetrieb Zeit kosten: ein neues Board mit
Katapult über CAN in Betrieb nehmen, und eine Maschine ohne Menü provisionieren.

## Wo KIAUH vorn ist

- **Reichweite und Vertrauen.** 58× mehr Sterne, 71 Contributor. Das ist keine
  Funktion, aber es entscheidet, was ein Fremder installiert.
- **Extension-Ökosystem.** 20 Erweiterungen inklusive Spoolman, klipper-backup,
  TMC Autotune. KATANA hat kein Fremd-Erweiterungsmodell.
- **Cloud- und Bot-Anbindungen** (Obico, OctoEverywhere, Mobileraker, Telegram).
  Bewusst nicht geplant — aber es als Schwäche von KIAUH zu führen wäre unehrlich.
- **Wartbarkeit.** Getippter Python-Code mit Klassenstruktur gegen 8k Zeilen
  Bash. Das ist der Grund für die Strangler-Strategie
  (`docs/PYTHON_CORE_STRATEGY.md`) — nicht ein Detail.

## Der eine Satz, der stimmt

> KIAUH installiert den Stack und kann Firmware bauen und flashen. KATANAOS
> deckt zusätzlich die Fälle ab, an denen KIAUH heute aussteigt: Katapult, CAN,
> RatOS/Kalico und die unbeaufsichtigte Installation ganzer Flotten.

Alles darüber hinaus — „ersetzt KIAUH vollständig", „KIAUH kann keine Firmware" —
ist nicht haltbar und schadet mehr, als es nützt.

## Unbeaufsichtigte Installation (der neue Punkt)

```bash
# Plan ansehen, ohne irgendetwas zu verändern
./katanaos.sh install --profile standard --dry-run

# Wirklich installieren, ohne Rückfrage
./katanaos.sh install --profile standard --ui mainsail --yes

# Nur der Kern, keine Weboberfläche
./katanaos.sh install --profile minimal --ui none --yes
```

Exit-Codes, weil ein Skript nur darauf reagieren kann:
`0` erfolgreich · `1` ein Schritt fehlgeschlagen (Name auf stderr) ·
`2` Aufruf falsch (unbekannte Option, fehlender Wert) · `3` `--yes` fehlt.

Ein unbekanntes Flag bricht ab, statt ignoriert zu werden — für ein Werkzeug,
das unbeaufsichtigt läuft, ist stillschweigendes Ignorieren der schlimmste
Fehlerfall: es meldet Erfolg für etwas, das es nie getan hat.
