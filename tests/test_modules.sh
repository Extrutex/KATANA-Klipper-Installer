#!/usr/bin/env bash
# ==============================================================================
# KATANAOS — MODULE INTEGRITY TEST HARNESS
# ------------------------------------------------------------------------------
# Prueft das Repository auf Vollstaendigkeit & Funktion, OHNE etwas am System
# zu installieren oder am Shell-Design zu aendern. Reine statische Analyse:
#
#   1) Syntax-Check (bash -n) aller *.sh Dateien
#   2) Sandbox-Load der kompletten Loader-Kette (wie katanaos.sh, aber ohne main)
#   3) Aufloesung aller intern aufgerufenen Funktionen gegen die definierten
#      -> findet "command not found" Bugs (z.B. run_hardening_wizard) BEVOR sie
#         im Live-Betrieb den globalen ERR-Trap ausloesen und das Tool crashen.
#
# Exit 0 = alles gruen, Exit 1 = Fehler gefunden.
# ==============================================================================

set -o pipefail

KATANA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KATANA_ROOT
export CORE_DIR="$KATANA_ROOT/core"
export MODULES_DIR="$KATANA_ROOT/modules"
export CONFIGS_DIR="$KATANA_ROOT/configs"

GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YEL=$'\033[0;33m'; NC=$'\033[0m'
PASS=0; FAIL=0
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; FAIL=$((FAIL+1)); }
pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; PASS=$((PASS+1)); }
info() { echo -e "  ${YEL}[..]${NC} $1"; }

# Loader-Reihenfolge — identisch zu katanaos.sh
CORE_MODULES=(
    "core/logging.sh" "core/ui_renderer.sh" "core/env_check.sh"
    "core/engine_manager.sh" "core/dispatchers.sh" "core/service_manager.sh"
)
OPT_MODULES=(
    modules/diagnostics/dr_katana.sh modules/diagnostics/medic.sh
    modules/hardware/menu.sh modules/hardware/can_manager.sh
    modules/hardware/flash_engine.sh modules/hardware/flash_registry.sh
    modules/hardware/katapult_manager.sh
    modules/security/hardening.sh modules/security/vault.sh modules/security/menu.sh
    modules/system/uninstaller.sh modules/system/backup_restore.sh
    modules/system/printer_config.sh modules/system/auto_restart.sh
    modules/system/mcu_builder.sh modules/system/moonraker_update_manager.sh
    modules/system/instance_manager.sh
    modules/extras/smart_probes.sh modules/extras/multi_material.sh
    modules/extras/katana_flow.sh modules/extras/tuning.sh
    modules/extras/toolchanger.sh modules/extras/timelapse.sh
    modules/engine/install_klipper.sh modules/ui/install_ui.sh
    modules/vision/install_crowsnest.sh
)

# ==============================================================================
echo ""
echo "═══ TEST 1: SYNTAX CHECK (bash -n) ═══"
SYNTAX_OK=1
while IFS= read -r f; do
    if bash -n "$f" 2>/tmp/katana_syn.err; then
        :
    else
        fail "Syntaxfehler: ${f#$KATANA_ROOT/}"
        sed 's/^/        /' /tmp/katana_syn.err
        SYNTAX_OK=0
    fi
done < <(find "$KATANA_ROOT" -name '*.sh' -not -path '*/.git/*')
[ "$SYNTAX_OK" = 1 ] && pass "Alle *.sh Dateien syntaktisch valide"

# ==============================================================================
echo ""
echo "═══ TEST 2: SANDBOX LOAD (Module ohne System-Eingriff laden) ═══"
# Wir laden in einer SUBSHELL mit Stub fuer alles, was das echte System anfasst,
# und geben die definierten Funktionen aus.
DEFINED_FUNCS="$(
    # --- Stubs fuer System-Tools, damit beim Sourcen nichts passiert ---
    sudo()       { :; }
    apt-get()    { :; }
    systemctl()  { return 1; }
    dpkg()       { return 1; }
    export -f sudo apt-get systemctl dpkg 2>/dev/null

    export TERM=xterm-256color
    set +e
    # ERR-Trap NICHT setzen (wir wollen ja alle Module trotz Fehler laden)
    for m in "${CORE_MODULES[@]}" "${OPT_MODULES[@]}"; do
        [ -f "$KATANA_ROOT/$m" ] && source "$KATANA_ROOT/$m" 2>/dev/null
    done
    declare -F | awk '{print $3}'
)"

if [ -z "$DEFINED_FUNCS" ]; then
    fail "Sandbox-Load lieferte keine Funktionen (Load fehlgeschlagen)"
else
    n=$(echo "$DEFINED_FUNCS" | grep -c .)
    pass "Sandbox-Load OK — $n Funktionen definiert"
fi

# ==============================================================================
echo ""
echo "═══ TEST 3: FUNKTIONS-AUFLOESUNG (undefined function references) ═══"
# Projekt-Funktionen folgen snake_case mit diesen Praefixen.
PREFIX='run|do|dispatch|install|vault|update|check|setup|post|switch|require|handle|show|change|draw|box|sub|warn|print|menu|visible|exec|flash|render|build|enable|disable|view|manage|scan|inject|wait|uninstall|restore|backup'

# Tokens in KOMMANDO-Position (kein Variablen-Assignment, kein Argument):
#   1) Zeilenanfang:        ^   <tok>
#   2) case-Branch:         ...)  <tok> ;;
#   3) nach then/else/do/{:  then <tok>
#   4) nach &&/||:           ... && <tok>
extract_calls() {
    local f="$1"
    # Kommentare weg + Zuweisungs-/Config-Zeilen (key = value) raus, dann Calls extrahieren
    sed 's/#.*$//' "$f" | sed -E '/^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*[:=]/d' | grep -oE \
        "(^[[:space:]]*|[)][[:space:]]+|(then|else|do)[[:space:]]+|[{][[:space:]]+|(&&|\|\|)[[:space:]]*)(${PREFIX})_[a-z0-9_]+([[:space:]]|;|\)|$)" \
      | grep -oE "(${PREFIX})_[a-z0-9_]+"
}

CALLED="$(
    for m in "${CORE_MODULES[@]}" "${OPT_MODULES[@]}"; do
        f="$KATANA_ROOT/$m"; [ -f "$f" ] || continue
        extract_calls "$f"
    done | sort -u
)"

# Tokens, die irgendwo per `declare -f X` / `type X` abgesichert sind -> optional.
GUARDED="$(
    for m in "${CORE_MODULES[@]}" "${OPT_MODULES[@]}"; do
        f="$KATANA_ROOT/$m"; [ -f "$f" ] || continue
        grep -oE "(declare -f|type)[[:space:]]+(${PREFIX})_[a-z0-9_]+" "$f" \
          | grep -oE "(${PREFIX})_[a-z0-9_]+"
    done | sort -u
)"

CRIT=0; WARN=0
while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    # bereits definiert?
    echo "$DEFINED_FUNCS" | grep -qx "$tok" && continue
    # echtes externes Kommando? (z.B. install_, build_ binaries gibt es i.d.R. nicht)
    command -v "$tok" >/dev/null 2>&1 && continue

    if echo "$GUARDED" | grep -qx "$tok"; then
        echo -e "  ${YEL}[WARN]${NC} Verdrahtung tot (abgesichert via declare -f/type): ${YEL}${tok}()${NC}"
        grep -rn --include='*.sh' -E "[)}][[:space:]]*${tok}\b|then[[:space:]]+${tok}\b|^[[:space:]]*${tok}\b" \
            "$KATANA_ROOT/core" "$KATANA_ROOT/modules" | grep -vE "declare -f|type[[:space:]]" \
            | sed 's/^/        /' | head -2
        WARN=$((WARN+1))
    else
        fail "KRITISCH — ungeschuetzt aufgerufen, NICHT definiert: ${RED}${tok}()${NC}  (crasht via ERR-Trap)"
        grep -rn --include='*.sh' -E "[)}][[:space:]]*${tok}\b|then[[:space:]]+${tok}\b|^[[:space:]]*${tok}\b" \
            "$KATANA_ROOT/core" "$KATANA_ROOT/modules" | sed 's/^/        /' | head -3
        CRIT=$((CRIT+1))
    fi
done <<< "$CALLED"

[ "$CRIT" -eq 0 ] && pass "Keine ungeschuetzten undefined-function Aufrufe (keine Crash-Pfade)"
[ "$WARN" -gt 0 ] && echo -e "  ${YEL}-> $WARN abgesicherte Verdrahtungsfehler (Feature tot, kein Crash)${NC}"

# ==============================================================================
echo ""
echo "═══ ERGEBNIS ═══"
echo -e "  Bestanden: ${GREEN}${PASS}${NC}  |  Fehlgeschlagen: ${RED}${FAIL}${NC}"
echo ""
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
