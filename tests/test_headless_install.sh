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
# 4. Fail-fast inside a step. A step whose MIDDLE command fails must fail, and
#    the commands after the failure must not run. This is the property the
#    per-step `set -e` exists for, and for a while it was only claimed: the step
#    was invoked as `if ! ( set -euo pipefail; ... )` under a caller using
#    `|| return`, and Bash ignores -e in both. A failed clone was followed by
#    the virtualenv build, the closing log_success and exit 0.
#
#    The assertions are on marker files, not on the exit code alone — "exit 1"
#    is also what a step returns after running to its end and failing late.
# ------------------------------------------------------------------------------
assert_step_stops_at_failure() {
    local label="$1"

    if [ "$CASE_RC" -eq 1 ]; then
        pass "$label: run exits 1 (step failed)"
    else
        fail "$label: run exited $CASE_RC (expected 1) — a failed command inside the step went unnoticed"
        sed 's/^/        /' "$CASE_OUT" | tail -12
    fi

    if [ -f "$CASE_HOME/step-markers/before-failure" ]; then
        pass "$label: the step ran up to the failing command"
    else
        fail "$label: the step never started — this case is not exercising the failure"
    fi

    if [ ! -e "$CASE_HOME/step-markers/after-failure" ]; then
        pass "$label: nothing after the failing command ran"
    else
        fail "$label: the step CONTINUED past its failing command"
    fi

    if [ ! -d "$CASE_HOME/moonraker" ] && [ ! -d "$CASE_HOME/mainsail" ]; then
        pass "$label: no later step was started"
    else
        fail "$label: a later step ran after the failed one"
    fi

    if grep -q "step 'klipper' failed" "$CASE_OUT"; then
        pass "$label: the failing step is named"
    else
        fail "$label: no diagnostic naming the failing step"
    fi

    if grep -q "step 'klipper' aborted" "$CASE_OUT"; then
        pass "$label: the failing command is named"
    else
        fail "$label: no diagnostic naming the command that aborted the step"
    fi

    if ! grep -q "headless install complete" "$CASE_OUT"; then
        pass "$label: the run does not report completion"
    else
        fail "$label: the run reported completion after a failed step"
    fi
}

run_case "step-midfail" "file://$FIXTURES/mainsail.zip" "step-midfail"
assert_step_stops_at_failure "mid-step failure"

# The realistic shape: the failing command is a helper returning non-zero
# (exec_silent around `git clone`), called as a bare statement.
run_case "step-midfail-nested" "file://$FIXTURES/mainsail.zip" "step-midfail-nested"
assert_step_stops_at_failure "mid-step failure in a helper"

# The calling convention is enforced, not assumed. Invoked from a tested
# context, -e cannot work — so the step must not run at all, and must say why.
run_case "tested-context" "file://$FIXTURES/mainsail.zip" "tested-context"

if [ "$CASE_RC" -ne 0 ]; then
    pass "tested context: the run fails instead of installing without fail-fast (exit $CASE_RC)"
else
    fail "tested context: the run exited 0 with 'set -e' ignored in every step"
fi

if [ ! -e "$CASE_HOME/step-markers/before-failure" ]; then
    pass "tested context: the step body was never executed"
else
    fail "tested context: the step ran although its fail-fast could not work"
fi

if grep -q "tested context" "$CASE_OUT"; then
    pass "tested context: the refusal names its cause"
else
    fail "tested context: no diagnostic explaining the refusal"
fi

# The same property through the real entrypoint. Everything above goes through
# the harness, which calls run_headless_install itself; what decides whether -e
# is live in production is the call chain in katanaos.sh, from the last line of
# the file through main() down to the step. So the real katanaos.sh is run from
# a scratch tree: the real core, and one module that supplies the preflight and
# the two steps of the `minimal` profile. Nothing else is substituted.
#
# Two cases, and the passing one matters as much as the failing one: it proves
# the canary accepts the production call chain. If main() ever wraps the call in
# a tested context again, the steps are refused and this case exits 1.
ENTRY_TREE="$WORKROOT/entrypoint-tree"
mkdir -p "$ENTRY_TREE/modules/engine"
cp "$REPO_ROOT/katanaos.sh" "$ENTRY_TREE/katanaos.sh"
cp -R "$REPO_ROOT/core" "$ENTRY_TREE/core"
cat > "$ENTRY_TREE/modules/engine/install_klipper.sh" <<'STUBMODULE'
#!/bin/bash
# Test module. Loaded by the real katanaos.sh in place of the real installer.
check_environment() { return 0; }

do_install_klipper() {
    mkdir -p "$HOME/step-markers" "$HOME/klipper"
    : > "$HOME/step-markers/before-failure"
    if [ "${KATANA_TEST_STEP:-ok}" = "midfail" ]; then
        false
    fi
    : > "$HOME/step-markers/after-failure"
    log_success "Klipper instance ready."
}

do_install_moonraker() {
    mkdir -p "$HOME/moonraker"
    log_success "Moonraker ready."
}
STUBMODULE

# run_entrypoint <name> <ok|midfail>  — sets CASE_RC, CASE_HOME, CASE_OUT
run_entrypoint() {
    CASE_HOME="$WORKROOT/$1/home"
    CASE_OUT="$WORKROOT/$1/output.txt"
    mkdir -p "$CASE_HOME"
    env -i \
        PATH="$PATH" \
        HOME="$CASE_HOME" \
        KATANA_TEST_STEP="$2" \
        bash "$ENTRY_TREE/katanaos.sh" install --profile minimal --yes \
        > "$CASE_OUT" 2>&1 < /dev/null
    CASE_RC=$?
}

run_entrypoint "entrypoint-ok" "ok"
if [ "$CASE_RC" -eq 0 ] && [ -d "$CASE_HOME/moonraker" ] \
        && [ -f "$CASE_HOME/step-markers/after-failure" ]; then
    pass "katanaos.sh install: the production call chain runs its steps and exits 0"
else
    fail "katanaos.sh install: healthy steps did not complete (exit $CASE_RC) — is the step called from a tested context?"
    sed 's/^/        /' "$CASE_OUT" | tail -12
fi

run_entrypoint "entrypoint-midfail" "midfail"
if [ "$CASE_RC" -eq 1 ]; then
    pass "katanaos.sh install: a mid-step failure exits 1"
else
    fail "katanaos.sh install: a mid-step failure exited $CASE_RC (expected 1)"
    sed 's/^/        /' "$CASE_OUT" | tail -12
fi
if [ -f "$CASE_HOME/step-markers/before-failure" ] \
        && [ ! -e "$CASE_HOME/step-markers/after-failure" ] \
        && [ ! -d "$CASE_HOME/moonraker" ]; then
    pass "katanaos.sh install: the step stopped at the failure and no later step ran"
else
    fail "katanaos.sh install: the step or the run continued past the failing command"
fi

# ------------------------------------------------------------------------------
# 5. Interrupting a run. CTRL+C delivers SIGINT to the foreground process group;
#    the step and the child it is waiting on (git, pip, apt-get) must die with
#    the orchestrator. This is what rules out running the step as a background
#    job: without job control an asynchronous command ignores SIGINT, so the
#    orchestrator would exit and leave the install running as an orphan.
#
#    `set -m` gives the harness its own process group, which stands in for the
#    terminal's foreground group; the signal is sent to the group, as the tty
#    driver does. Confined to a subshell so job control does not leak into the
#    rest of this file.
# ------------------------------------------------------------------------------
SIG_DIR="$WORKROOT/step-sigint"
SIG_HOME="$SIG_DIR/home"
SIG_PIDFILE="$SIG_HOME/step-markers/child.pid"
mkdir -p "$SIG_HOME"

(
    set -m
    env -i \
        PATH="$PATH" \
        HOME="$SIG_HOME" \
        TERM=dumb \
        KATANA_ROOT="$REPO_ROOT" \
        LOG_FILE="$SIG_DIR/katana.log" \
        KATANA_MAINSAIL_URL="file://$FIXTURES/mainsail.zip" \
        bash "$HARNESS" "step-sigint" > "$SIG_DIR/output.txt" 2>&1 < /dev/null &
    harness_pid=$!

    waited=0
    while [ ! -s "$SIG_PIDFILE" ] && [ "$waited" -lt 100 ]; do
        sleep 0.1
        waited=$((waited + 1))
    done
    if [ ! -s "$SIG_PIDFILE" ]; then
        kill -KILL -- "-$harness_pid" 2>/dev/null
        wait "$harness_pid" 2>/dev/null
        echo "never-started" > "$SIG_DIR/result"
        exit 0
    fi

    kill -INT -- "-$harness_pid"
    wait "$harness_pid"
    echo "$?" > "$SIG_DIR/result"
) 2>/dev/null

SIG_RESULT="$(cat "$SIG_DIR/result" 2>/dev/null || echo "no-result")"
SIG_CHILD="$(cat "$SIG_PIDFILE" 2>/dev/null || true)"

if [ "$SIG_RESULT" = "never-started" ] || [ "$SIG_RESULT" = "no-result" ] || [ -z "$SIG_CHILD" ]; then
    fail "interrupt: the step never reached its child process ($SIG_RESULT)"
else
    if [ "$SIG_RESULT" -ne 0 ]; then
        pass "interrupt: the run ends with a non-zero status ($SIG_RESULT)"
    else
        fail "interrupt: the run exited 0 after SIGINT"
    fi

    # The child gets a moment to disappear: its exit is asynchronous to the
    # orchestrator's. A process that ignored the signal is still there after it.
    waited=0
    while kill -0 "$SIG_CHILD" 2>/dev/null && [ "$waited" -lt 30 ]; do
        sleep 0.1
        waited=$((waited + 1))
    done
    if ! kill -0 "$SIG_CHILD" 2>/dev/null; then
        pass "interrupt: the step's child process is gone, nothing is orphaned"
    else
        fail "interrupt: the step's child process (pid $SIG_CHILD) survived SIGINT as an orphan"
        kill -KILL "$SIG_CHILD" 2>/dev/null
    fi

    if [ ! -e "$SIG_HOME/step-markers/after-interrupt" ] && [ ! -d "$SIG_HOME/moonraker" ]; then
        pass "interrupt: nothing ran after the interrupted command"
    else
        fail "interrupt: the run continued after SIGINT"
    fi
fi

# ------------------------------------------------------------------------------
# 6. The other half of the defect: a TTY on stdin with nobody watching.
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
