#!/bin/bash
# core/interaction.sh
# --- KATANA INTERACTION PRIMITIVES ---
#
# Every prompt in KATANA has to answer one question before it reads anything:
# is there a human at the other end? The tool runs in three situations and a
# bare `read` is wrong in two of them:
#
#   1. Interactive menu on a TTY         -> read, that is the point
#   2. `katanaos.sh install --yes` over SSH/CI, stdin closed
#                                        -> read fails immediately, returns 1
#   3. `katanaos.sh install --yes` from a terminal, stdin still a TTY
#                                        -> read blocks forever, nobody types
#
# Case 2 was the worse of the two: a trailing `read -r -p "Press Enter..."` is
# the last command of a function, so its exit status IS the function's return
# value. A completed installation reported failure because nobody pressed a key
# that nobody was asked for. Case 3 hangs a fleet rollout.
#
# The rules these helpers enforce:
#   - a pause never influences a return value (katana_pause always returns 0)
#   - a pause only reads when stdin is a TTY and no non-interactive mode is set
#   - a question that cannot be asked is answered with its documented default,
#     never with a guess
#
# A `read -r -p` in this tool is never just a read. It is one of four things,
# and the four need four different answers when nobody is at the terminal:
#
#   1. a pause      "Press Enter..."          -> katana_pause
#   2. a question   "Install X? [y/N]: "      -> katana_confirm
#   3. a value      "Board name: "            -> katana_read_value
#   4. a menu       ">> COMMAND: "            -> katana_read_menu
#
# The rule per class, and why:
#
#   Pause        skipped. A pause conveys nothing to a machine and must not
#                influence a return value.
#   Question     answered with its documented default. Which default is a
#                per-call decision, never a blanket yes (see katana_confirm).
#   Value        answered with a mandatory default if the call site can name
#                one, otherwise refused with a message that says which
#                variable or flag would have supplied it. A value cannot be
#                invented: guessing a serial port or a board name produces a
#                config that is wrong in a way nobody notices until the
#                printer moves.
#   Menu         refused, and the loop it drives terminates. This is the class
#                that was worst before: a menu `read` on closed stdin returns 1
#                with an empty variable, the `case` falls through to its
#                "invalid choice" arm, and the enclosing `while true` spins —
#                an unattended run pinned a core and filled the log instead of
#                exiting.
#
# Destructive operations are the exception to all of the above and have their
# own gate: katana_confirm_destructive. See its header.
#
# Loaded before every module so any module may call them.

# True when a prompt may block on human input.
#
# Two independent conditions, both required. The TTY test alone is not enough:
# an unattended run started from a terminal (case 3 above) keeps a TTY on stdin
# and would still hang. KATANA_NONINTERACTIVE is what the headless path sets to
# say "there is nobody watching, regardless of what stdin looks like".
katana_is_interactive() {
    [[ "${KATANA_NONINTERACTIVE:-0}" != "1" ]] && [[ -t 0 ]]
}

# Interactive pause. Returns 0 unconditionally — by contract.
#
# The return value is fixed on purpose: a pause is presentation, not logic. Any
# caller ending in `katana_pause` keeps whatever exit status its actual work
# produced, which is what makes the same function usable from both the menu and
# the unattended path.
katana_pause() {
    local prompt="${1:-  Press Enter...}"
    if katana_is_interactive; then
        # A failing read (EOF from a terminal, e.g. CTRL+D) must not leak into
        # the return value either — hence the explicit swallow.
        read -r -p "$prompt" _ || true
    fi
    return 0
}

# Yes/no question with a mandatory default for the unattended case.
#
#   katana_confirm "  Uninstall Mainsail? [y/N]: " no
#   katana_confirm "  Proceed? [Y/n]: " yes
#
# Returns 0 for yes, 1 for no. Without a human, the default is returned without
# reading anything.
#
# Note that --yes deliberately does NOT turn every question into a yes. --yes is
# consent to perform the requested installation; it is not consent to continue
# past an error that happened during it. Questions asked after a failure (e.g.
# "dependencies failed, continue anyway?") therefore default to no, and the run
# aborts with a non-zero exit code instead of producing a half-installed host
# that reports success. That is the whole point of an exit-code contract.
katana_confirm() {
    local prompt="$1"
    local default="${2:-no}"
    local answer=""

    if ! katana_is_interactive; then
        [[ "$default" == "yes" ]]
        return $?
    fi

    if ! read -r -p "$prompt" answer; then
        # EOF mid-session: treat exactly like the unattended case.
        echo ""
        [[ "$default" == "yes" ]]
        return $?
    fi

    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
        [nN]|[nN][oO])     return 1 ;;
        *)
            # Empty input and anything unrecognised both fall back to the
            # documented default rather than to a guess.
            [[ "$default" == "yes" ]]
            return $?
            ;;
    esac
}

# Free-text or numeric input, with an optional default for the unattended case.
#
#   katana_read_value board_name "  >> Name: "
#   katana_read_value baudrate   "  >> Baudrate: " "250000"
#
# Returns 0 when the named variable holds a usable value, 1 when the question
# could not be asked and the call site named no default. On 1 the variable is
# left untouched and the caller must abort — it must NOT carry on with an empty
# string, which is how an empty serial port ends up written into printer.cfg.
#
# Why a default is optional here but mandatory for katana_confirm: a yes/no
# question always has two answers and one of them is defensible without a
# human. A value has an unbounded domain. "250000" is a defensible default for
# a baudrate; there is no defensible default for a CAN UUID, and inventing one
# produces a configuration that is wrong in a way nobody notices until the
# printer moves. So the primitive refuses instead, and says what would have
# supplied the answer.
#
# The fourth argument is that explanation — the environment variable or flag an
# operator can set. It is a documentation string, not a lookup: resolving the
# variable here would spread configuration handling across every call site.
katana_read_value() {
    local __katana_rv_name="$1"
    local __katana_rv_prompt="$2"
    local __katana_rv_default="${3-}"
    local __katana_rv_source="${4-}"
    local __katana_rv_answer=""

    if katana_is_interactive; then
        if read -r -p "$__katana_rv_prompt" __katana_rv_answer; then
            # An empty line means "take the default" when there is one, and is
            # a non-answer when there is not.
            if [[ -z "$__katana_rv_answer" && -n "$__katana_rv_default" ]]; then
                __katana_rv_answer="$__katana_rv_default"
            fi
            if [[ -n "$__katana_rv_answer" ]]; then
                printf -v "$__katana_rv_name" '%s' "$__katana_rv_answer"
                return 0
            fi
            return 1
        fi
        # EOF mid-session (CTRL+D) is handled exactly like the unattended case.
        echo ""
    fi

    if [[ -n "$__katana_rv_default" ]]; then
        printf -v "$__katana_rv_name" '%s' "$__katana_rv_default"
        return 0
    fi

    printf '%s\n' "  [non-interaktiv] Eingabe erforderlich, aber kein Terminal verfuegbar:" >&2
    printf '%s\n' "  ${__katana_rv_prompt#"${__katana_rv_prompt%%[![:space:]]*}"}" >&2
    if [[ -n "$__katana_rv_source" ]]; then
        printf '%s\n' "  Abhilfe: $__katana_rv_source" >&2
    fi
    return 1
}

# A menu selection. Same shape as katana_read_value with no default, but it
# exists as its own name because the failure mode differs and the call sites
# must handle it differently.
#
#   while true; do
#       draw_some_menu
#       katana_read_menu choice "  >> COMMAND: " "FORGE" || break
#       case "$choice" in ... esac
#   done
#
# Without a human this returns 1 after one line of explanation, and the `||
# break` terminates the loop. Before this existed, the bare `read` returned 1
# with `choice` empty, the `case` fell through to its "invalid choice" arm, and
# the `while true` spun forever: an unattended invocation that reached any
# submenu pinned a CPU core and grew katana.log without bound until it filled
# the disk. That is a worse outcome than the exit-code bug this branch started
# from, because it has no exit code at all.
#
# It also returns 1 on EOF, which is what makes CTRL+D leave a submenu instead
# of re-rendering it.
katana_read_menu() {
    local __katana_rm_name="$1"
    local __katana_rm_prompt="$2"
    local __katana_rm_label="${3:-Menue}"
    local __katana_rm_answer=""

    if ! katana_is_interactive; then
        printf '%s\n' "  [non-interaktiv] '$__katana_rm_label' benoetigt ein Terminal — uebersprungen." >&2
        return 1
    fi

    if ! read -r -p "$__katana_rm_prompt" __katana_rm_answer; then
        echo ""
        return 1
    fi

    # Trim leading and trailing whitespace once, here, instead of in each of
    # the ~40 call sites that used to do it (or forget to).
    __katana_rm_answer="${__katana_rm_answer#"${__katana_rm_answer%%[![:space:]]*}"}"
    __katana_rm_answer="${__katana_rm_answer%"${__katana_rm_answer##*[![:space:]]}"}"
    printf -v "$__katana_rm_name" '%s' "$__katana_rm_answer"
    return 0
}

# Confirmation for an operation that destroys something: flashing a board,
# erasing firmware, deleting a config or an instance, overwriting a file,
# restoring over live data, uninstalling.
#
#   katana_confirm_destructive "  Are you sure? [y/N]: " flash
#   katana_confirm_destructive "  Type 'DELETE' to confirm: " delete DELETE
#
# Returns 0 only on an explicit, present-tense yes. Unattended it returns 1 —
# a refusal, not a default — unless KATANA_ALLOW_DESTRUCTIVE names this exact
# operation.
#
# Why this is not just katana_confirm with default=no. The difference is what
# happens at the call site and what the operator is told. A defaulted "no" is
# silent and indistinguishable from "the user declined"; a refusal says why the
# run stopped and what would have let it proceed. On a fleet rollout that is
# the difference between an operator seeing "flash refused: set
# KATANA_ALLOW_DESTRUCTIVE=flash" and seeing nothing at all while eight boards
# quietly go unflashed.
#
# Why --yes does not cover it. --yes is consent to perform the installation
# that was requested on the command line. It is not consent to erase a board
# that happened to be plugged in. Those are different decisions with different
# blast radii and they get different switches — and there is deliberately no
# value of KATANA_ALLOW_DESTRUCTIVE that means "all", because a blanket yes to
# every destructive path is the thing this gate exists to prevent. An operator
# who wants two classes names two classes.
#
#   KATANA_ALLOW_DESTRUCTIVE="flash"            one class
#   KATANA_ALLOW_DESTRUCTIVE="flash,uninstall"  two classes
#   KATANA_ALLOW_DESTRUCTIVE="all"              not a thing; matches nothing
#
# The classes in use. A new call site joins the class whose blast radius it
# shares instead of inventing a name, so an operator's allow-list keeps meaning
# what it meant when it was written:
#
#   flash      build-and-flash, Katapult, DFU and CAN flashing, the MCU flash
#              after a Klipper update, stopping Klipper for a flash
#   delete     a saved board, a printer instance
#   overwrite  replacing something that already exists with generated content:
#              printer.cfg from the Printer Config Wizard (a timestamped backup
#              is written first, see printer_cfg_guard_overwrite in
#              modules/system/printer_config.sh), a CAN UUID written into
#              printer.cfg, the can0 interface file, the StealthChanger config,
#              ~/klipper and ~/klippy-env on an engine switch
#   uninstall  every remove path — Klipper, Moonraker, web UIs, nginx, extras
#   reinstall  installing over an existing checkout of an extra
#   restore    restoring a backup or a vault snapshot over live data
#   repair     the Dr. KATANA auto-healer
#   reset      writing or removing the auto-restart drop-ins under /etc/systemd
#
# Third argument: when given, the interactive path demands that exact string
# rather than y/n. That preserves the deliberately high-friction confirmations
# that already existed ("Type 'RESTORE' to confirm") instead of quietly
# downgrading them to a keystroke.
katana_confirm_destructive() {
    local prompt="$1"
    local operation="$2"
    local token="${3-}"
    local answer=""

    if [[ -z "$operation" ]]; then
        # A programming error, not an operator error: an unnamed operation
        # could never be allowed, so failing loudly beats failing silently.
        printf '%s\n' "  [BUG] katana_confirm_destructive ohne Operationsnamen aufgerufen." >&2
        return 1
    fi

    if ! katana_is_interactive; then
        # Word-split on comma and whitespace, then match whole tokens. A
        # substring test would let KATANA_ALLOW_DESTRUCTIVE=flashing authorise
        # `flash`, and prefix accidents are exactly what must not happen here.
        local allowed entry
        allowed="${KATANA_ALLOW_DESTRUCTIVE:-}"
        allowed="${allowed//,/ }"
        for entry in $allowed; do
            if [[ "$entry" == "$operation" ]]; then
                printf '%s\n' "  [non-interaktiv] '$operation' durch KATANA_ALLOW_DESTRUCTIVE freigegeben." >&2
                return 0
            fi
        done
        printf '%s\n' "  [non-interaktiv] VERWEIGERT: '$operation' zerstoert Daten oder Hardware-Zustand" >&2
        printf '%s\n' "                  und wird ohne Bestaetigung nicht ausgefuehrt." >&2
        printf '%s\n' "                  Bewusst freigeben mit: KATANA_ALLOW_DESTRUCTIVE=$operation" >&2
        return 1
    fi

    if ! read -r -p "$prompt" answer; then
        # EOF is not consent.
        echo ""
        return 1
    fi

    if [[ -n "$token" ]]; then
        [[ "$answer" == "$token" ]]
        return $?
    fi

    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
        # Everything else — including an empty line — is a no. A destructive
        # operation has no defensible default and does not get one.
        *)                 return 1 ;;
    esac
}
