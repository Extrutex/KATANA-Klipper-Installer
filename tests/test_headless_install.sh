#!/usr/bin/env bash
# ==============================================================================
# KATANA — HEADLESS INSTALL BEHAVIOUR TEST
# ------------------------------------------------------------------------------
# The existing CLI suite (tests/test_headless_cli.py) drives every case with
# --dry-run. A dry run prints the plan and returns before a single step
# executes, which is why fifteen green tests coexisted with an unattended
# install that could not succeed: the web UI step ended in `read -r -p "Press
# Enter..."`, so with stdin closed it returned 1 after a completed install, and
# with a TTY attached it blocked forever.
#
# This test closes that gap. It runs the real orchestrator with steps that
# really execute, with stdin closed and no controlling terminal, and it asserts
# BOTH halves of the contract:
#
#     exit code 0   AND   the artefacts are actually on disk
#
# Either one alone is worthless — the old code could produce an empty
# $HOME/mainsail and a success message, and it could also install correctly and
# report failure.
#
# ------------------------------------------------------------------------------
# WHAT THIS TEST DOES NOT COVER (no container, no root, no systemd)
#
# It runs against a temporary prefix instead of system paths, so these remain
# unverified here and are covered by the container job in .github/workflows/ci.yml
# (job: headless-install-container), which runs this same file as root in a
# Debian image:
#
#   * apt-get         stubbed. Package installation is never executed.
#   * systemd         stubbed. Unit files are not written to /etc/systemd and
#                     no service is started or enabled. Even the container job
#                     cannot fix this: there is no PID 1 in a plain container.
#                     A service actually coming up is only provable on target
#                     hardware or in a systemd-enabled VM.
#   * nginx           unprivileged runs stub sudo, so the vhost is not written
#                     and `nginx -t` is not executed. The container job runs as
#                     root with nginx installed, where both are real.
#   * klipper/moonraker installation is replaced by stubs — a clone plus
#                     virtualenv build is minutes of network per case and the
#                     defect under test is not there.
#   * the release download uses a local fixture over file://, not GitHub. The
#                     network path itself is therefore untested; the failure
#                     handling around it (404, corrupt archive) is tested.
#
# What is fully real here: the argument and exit-code contract, the step
# orchestration and its per-step `set -euo pipefail` subshell, the interaction
# primitives, and the complete web-UI deployment including integrity check,
# staging, atomic swap and cleanup.
# ==============================================================================

# Deliberately no `set -e`: this harness reports every failing case in one run
# and decides the exit code at the bottom. pipefail stays on.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HARNESS="$REPO_ROOT/tests/headless_install_harness.sh"

GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YEL=$'\033[0;33m'; NC=$'\033[0m'
PASS=0; FAIL=0
pass() { echo "  ${GREEN}[PASS]${NC} $1"; PASS=$((PASS+1)); }
fail() { echo "  ${RED}[FAIL]${NC} $1"; FAIL=$((FAIL+1)); }
info() { echo "  ${YEL}[..]${NC} $1"; }

# curl is what katana_fetch_url prefers and the only downloader of the two that
# handles file:// URLs, which is how the fixture is served without network.
for tool in curl unzip zip; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "  ${YEL}[SKIP]${NC} '$tool' not available — headless install test skipped."
        exit 0
    fi
done

WORKROOT="$(mktemp -d "${TMPDIR:-/tmp}/katana-headless-test.XXXXXX")"
cleanup() { rm -rf "$WORKROOT"; }
trap cleanup EXIT

# ------------------------------------------------------------------------------
# Fixtures: a valid release bundle and a corrupt one.
# ------------------------------------------------------------------------------
FIXTURES="$WORKROOT/fixtures"
mkdir -p "$FIXTURES/bundle/assets"
echo '<html><body>mainsail</body></html>' > "$FIXTURES/bundle/index.html"
echo 'body{}'                             > "$FIXTURES/bundle/assets/app.css"
( cd "$FIXTURES/bundle" && zip -qr "$FIXTURES/mainsail.zip" . )

# A ZIP truncated mid-stream: unzip -t must reject it before anything is
# extracted. This is the "download died halfway" case.
head -c 120 "$FIXTURES/mainsail.zip" > "$FIXTURES/mainsail-corrupt.zip"

# A ZIP that is intact but is not a web bundle (no index.html).
mkdir -p "$FIXTURES/notaui"
echo 'readme' > "$FIXTURES/notaui/README.txt"
( cd "$FIXTURES/notaui" && zip -qr "$FIXTURES/mainsail-noindex.zip" . )

# ------------------------------------------------------------------------------
# run_case <name> <mainsail-url> <mode>
#   Executes the harness in a fresh prefix with stdin closed. Sets, for the
#   assertions that follow: CASE_RC, CASE_HOME, CASE_OUT.
# ------------------------------------------------------------------------------
run_case() {
    local name="$1" url="$2" mode="${3:-ok}"

    CASE_HOME="$WORKROOT/$name/home"
    CASE_OUT="$WORKROOT/$name/output.txt"
    mkdir -p "$CASE_HOME" "$WORKROOT/$name"

    # `< /dev/null` is the whole point: stdin is closed, exactly as under
    # systemd, ssh -n, cron or a CI runner.
    env -i \
        PATH="$PATH" \
        HOME="$CASE_HOME" \
        TERM=dumb \
        KATANA_ROOT="$REPO_ROOT" \
        LOG_FILE="$WORKROOT/$name/katana.log" \
        KATANA_MAINSAIL_URL="$url" \
        bash "$HARNESS" "$mode" > "$CASE_OUT" 2>&1 < /dev/null
    CASE_RC=$?
}

echo ""
echo "═══ HEADLESS INSTALL — REAL RUN, STDIN CLOSED ═══"

# ------------------------------------------------------------------------------
# 1. The contract: a successful unattended install exits 0 AND leaves artefacts.
# ------------------------------------------------------------------------------
run_case "happy" "file://$FIXTURES/mainsail.zip" "ok"

if [ "$CASE_RC" -eq 0 ]; then
    pass "unattended install exits 0 with stdin closed"
else
    fail "unattended install exited $CASE_RC (expected 0)"
    sed 's/^/        /' "$CASE_OUT" | tail -20
fi

if [ -f "$CASE_HOME/mainsail/index.html" ]; then
    pass "artefact present: \$HOME/mainsail/index.html"
else
    fail "artefact missing: \$HOME/mainsail/index.html — exit code alone proves nothing"
fi

if [ -f "$CASE_HOME/mainsail/assets/app.css" ]; then
    pass "artefact present: the full bundle, not just its root file"
else
    fail "artefact missing: \$HOME/mainsail/assets/app.css"
fi

# The staging directory is a sibling of the target; if the trap did not fire,
# it is still lying next to it.
leftovers="$(find "$CASE_HOME" -maxdepth 1 -name '.katana-*' 2>/dev/null)"
if [ -z "$leftovers" ]; then
    pass "staging directory cleaned up"
else
    fail "staging directory left behind: $leftovers"
fi

if grep -q "headless install complete" "$CASE_OUT"; then
    pass "run reports completion"
else
    fail "completion line missing from output"
fi

# ------------------------------------------------------------------------------
# 2. Regression guard. Re-introduces the pre-fix ending (a bare `read` as the
#    function's last command) and requires this test to catch it. Without this
#    case, nothing stops the bug from coming back the next time someone adds a
#    "Press Enter" to an install function.
# ------------------------------------------------------------------------------
run_case "prefix-bug" "file://$FIXTURES/mainsail.zip" "prefix-bug"

if [ "$CASE_RC" -ne 0 ]; then
    pass "regression guard: the pre-fix \`read\` ending is detected (exit $CASE_RC)"
else
    fail "regression guard: the pre-fix \`read\` ending exited 0 — this test no longer detects the bug"
fi

# It must fail for the right reason: the install itself completed, only the
# return value was wrong. If the artefacts are missing, the case is proving
# something else and the guard is worthless.
if [ -f "$CASE_HOME/mainsail/index.html" ]; then
    pass "regression guard: failure reported despite a completed install (the exact defect)"
else
    fail "regression guard: artefacts missing — this case is not reproducing the original bug"
fi

# ------------------------------------------------------------------------------
# 3. Failure paths must fail. A corrupt or missing download may never produce
#    exit 0, and may never leave a half-installed directory behind for nginx to
#    serve as a blank page.
# ------------------------------------------------------------------------------
run_case "corrupt" "file://$FIXTURES/mainsail-corrupt.zip" "ok"

if [ "$CASE_RC" -ne 0 ]; then
    pass "corrupt archive fails the run (exit $CASE_RC)"
else
    fail "corrupt archive exited 0"
fi

if [ ! -d "$CASE_HOME/mainsail" ]; then
    pass "corrupt archive leaves no half-installed directory"
else
    fail "corrupt archive left \$HOME/mainsail behind"
fi

if grep -qi "corrupt" "$CASE_OUT"; then
    pass "corrupt archive is named as the cause"
else
    fail "corrupt archive: no diagnostic naming the cause"
fi

run_case "missing" "file://$FIXTURES/does-not-exist.zip" "ok"

if [ "$CASE_RC" -ne 0 ]; then
    pass "unreachable release URL fails the run (exit $CASE_RC)"
else
    fail "unreachable release URL exited 0"
fi

if grep -qi "download failed" "$CASE_OUT"; then
    pass "failed download is named as the cause"
else
    fail "failed download: no diagnostic naming the cause"
fi

run_case "noindex" "file://$FIXTURES/mainsail-noindex.zip" "ok"

if [ "$CASE_RC" -ne 0 ]; then
    pass "archive without index.html fails the run (exit $CASE_RC)"
else
    fail "archive without index.html exited 0 — an empty web root would be served"
fi

# ------------------------------------------------------------------------------
# 4. The other half of the defect: a TTY on stdin with nobody watching.
#    `script` allocates a pty, so katana_pause sees a terminal. Under
#    KATANA_NONINTERACTIVE it must return immediately; the pre-fix code blocked
#    here until the timeout killed it.
# ------------------------------------------------------------------------------
if command -v script >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
    pty_probe="$WORKROOT/pty_probe.sh"
    cat > "$pty_probe" <<EOF
source "$REPO_ROOT/core/interaction.sh"
export KATANA_NONINTERACTIVE=1
[ -t 0 ] || { echo "NO_PTY"; exit 64; }
katana_pause "  Press Enter..."
echo "PAUSE_RETURNED_\$?"
EOF
    pty_out="$(timeout 10 script -qec "bash $pty_probe" /dev/null 2>&1)"
    pty_rc=$?

    if [ "$pty_rc" -eq 124 ]; then
        fail "pause blocked on a TTY despite KATANA_NONINTERACTIVE (timed out)"
    elif printf '%s' "$pty_out" | grep -q "NO_PTY"; then
        info "script(1) did not provide a pty — TTY case skipped"
    elif printf '%s' "$pty_out" | grep -q "PAUSE_RETURNED_0"; then
        pass "pause returns 0 immediately on a TTY when non-interactive"
    else
        fail "pause on a TTY returned unexpectedly: $pty_out"
    fi
else
    info "script(1)/timeout not available — TTY case skipped"
fi

# ------------------------------------------------------------------------------
echo ""
echo "  Bestanden: ${GREEN}${PASS}${NC}  |  Fehlgeschlagen: ${RED}${FAIL}${NC}"
echo ""
[ "$FAIL" -eq 0 ]
