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
