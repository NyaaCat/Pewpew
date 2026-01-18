#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ASYNC_PROFILER_VERSION="${ASYNC_PROFILER_VERSION:-4.2.1}"
ASYNC_PROFILER_ARCH="${ASYNC_PROFILER_ARCH:-linux-x64}"
ASYNC_PROFILER_DIR="${ASYNC_PROFILER_DIR:-$ROOT_DIR/tmp/async-profiler-$ASYNC_PROFILER_VERSION}"
BASELINE_REPO="${BENCH_BASELINE_REPO:-/home/phoenix/works/pewpew-paper-baseline}"
PAPER_REF="$(grep '^paperRef=' "$ROOT_DIR/gradle.properties" | cut -d= -f2)"
PEWPEW_VERSION="$(grep '^version=' "$ROOT_DIR/gradle.properties" | cut -d= -f2)"
BENCH_PLUGIN_REPO="${BENCH_PLUGIN_REPO:-/home/phoenix/works/pewpew-bench-plugin}"
MULTIVERSE_JAR_URL="${MULTIVERSE_JAR_URL:-https://github.com/Multiverse/Multiverse-Core/releases/download/5.5.0/multiverse-core-5.5.0.jar}"

SEED="${BENCH_SEED:-424242}"
WORLD_NAMES=("world" "world2")
PLAYERS_PER_WORLD="${BENCH_PLAYERS_PER_WORLD:-10}"
BOT_COUNT=$((PLAYERS_PER_WORLD * ${#WORLD_NAMES[@]}))
PLAYER_SPACING="${BENCH_PLAYER_SPACING:-160}"
VILLAGERS_PER_PLAYER="${BENCH_VILLAGERS_PER_PLAYER:-20}"
HOSTILES_PER_PLAYER="${BENCH_HOSTILES_PER_PLAYER:-20}"
VILLAGER_SPAWN_RADIUS="${BENCH_VILLAGER_SPAWN_RADIUS:-12}"
HOSTILE_SPAWN_RADIUS="${BENCH_HOSTILE_SPAWN_RADIUS:-12}"
VILLAGER_SYNC_RADIUS="${BENCH_VILLAGER_SYNC_RADIUS:-24}"
VILLAGE_OFFSET="${BENCH_VILLAGE_OFFSET:-0}"
EFFECT_AMPLIFIER="${BENCH_EFFECT_AMPLIFIER:-4}"
EFFECT_DURATION_TICKS="${BENCH_EFFECT_DURATION_TICKS:-24000}"
EFFECT_REFRESH_TICKS="${BENCH_EFFECT_REFRESH_TICKS:-20}"
VILLAGER_MAINT_TICKS="${BENCH_VILLAGER_MAINT_TICKS:-40}"
VILLAGE_PLACE_DELAY_TICKS="${BENCH_VILLAGE_PLACE_DELAY_TICKS:-200}"
POST_VILLAGE_DELAY_TICKS="${BENCH_POST_VILLAGE_DELAY_TICKS:-200}"
TELEPORT_DELAY_TICKS="${BENCH_TELEPORT_DELAY_TICKS:-20}"
WARMUP_TICKS="${BENCH_WARMUP_TICKS:-0}"
SAMPLE_TICKS="${BENCH_SAMPLE_TICKS:-2700}"
SAMPLE_INTERVAL_TICKS="${BENCH_SAMPLE_INTERVAL_TICKS:-100}"
EXPECTED_TPS="${BENCH_EXPECTED_TPS:-15}"
BENCH_PROFILE="${BENCH_PROFILE:-0}"
BENCH_PROFILE_TARGET="${BENCH_PROFILE_TARGET:-pewpew}"
BENCH_PROFILE_EVENT="${BENCH_PROFILE_EVENT:-cpu}"
BENCH_PROFILE_FORMAT="${BENCH_PROFILE_FORMAT:-text}"
BENCH_PROFILE_ARGS="${BENCH_PROFILE_ARGS:-}"
BENCH_PROFILE_START_TIMEOUT="${BENCH_PROFILE_START_TIMEOUT:-600}"
BENCH_PROFILE_LOG_PATTERN="${BENCH_PROFILE_LOG_PATTERN:-Villages and entities ready; benchmarking can begin.}"
BENCH_THREAD_SNAPSHOT="${BENCH_THREAD_SNAPSHOT:-0}"
BENCH_THREAD_SNAPSHOT_DELAY="${BENCH_THREAD_SNAPSHOT_DELAY:-10}"
BENCH_THREAD_SNAPSHOT_PATTERN="${BENCH_THREAD_SNAPSHOT_PATTERN:-Pewpew-(Async|Tick)-}"

RUN_ID="${BENCH_RUN_ID:-$(date +%Y%m%d-%H%M%S)-$$}"
RUN_ROOT="$ROOT_DIR/tmp/bench/runs/$RUN_ID-multiworld"
RUN_BASELINE_DIR="$RUN_ROOT/baseline"
RUN_PEWPEW_DIR="$RUN_ROOT/pewpew"
REPORT_DIR="$ROOT_DIR/docs/pewpew/findings"
BENCH_PROFILE_OUTPUT_DIR="${BENCH_PROFILE_OUTPUT_DIR:-$REPORT_DIR/profiles}"
BASELINE_SUMMARY_OUT="$REPORT_DIR/multiverse-bench-summary-baseline.json"
BASELINE_SUMMARY_IN="${BENCH_BASELINE_SUMMARY:-$BASELINE_SUMMARY_OUT}"
PEWPEW_SUMMARY_OUT="$REPORT_DIR/multiverse-bench-summary.json"
BASELINE_REPORT_OUT="$REPORT_DIR/multiverse-bench-report-baseline.md"
PEWPEW_REPORT_OUT="$REPORT_DIR/multiverse-bench-report.md"
PEWPEW_JAVA_OPTS="${BENCH_PEWPEW_JAVA_OPTS:--Dpewpew.asyncPathfinding=true -Dpewpew.asyncSensors=true}"

PEWPEW_FEATURE_ASYNC_PATHFINDING="${BENCH_PEWPEW_FEATURE_ASYNC_PATHFINDING:-true}"
PEWPEW_FEATURE_ASYNC_SENSORS="${BENCH_PEWPEW_FEATURE_ASYNC_SENSORS:-true}"
PEWPEW_FEATURE_WORLD_TICK_COORDINATOR="${BENCH_PEWPEW_FEATURE_WORLD_TICK_COORDINATOR:-false}"
PEWPEW_FEATURE_WORLD_TICK_COORDINATOR_TESTING="${BENCH_PEWPEW_FEATURE_WORLD_TICK_COORDINATOR_TESTING:-false}"
PEWPEW_FEATURE_ASYNC_POOL_TESTING="${BENCH_PEWPEW_FEATURE_ASYNC_POOL_TESTING:-false}"
PEWPEW_FEATURE_TICK_THREAD_HARD_THROW="${BENCH_PEWPEW_FEATURE_TICK_THREAD_HARD_THROW:-true}"
PEWPEW_ASYNC_POOL_WORKERS="${BENCH_PEWPEW_ASYNC_POOL_WORKERS:--1}"
PEWPEW_ASYNC_POOL_QUEUE_LIMIT="${BENCH_PEWPEW_ASYNC_POOL_QUEUE_LIMIT:--1}"
PEWPEW_WORLD_TICK_WORKERS="${BENCH_PEWPEW_WORLD_TICK_WORKERS:--1}"
PEWPEW_WORLD_TICK_STALL_NANOS="${BENCH_PEWPEW_WORLD_TICK_STALL_NANOS:-50000000}"
SERVER_PID=""
PROFILER_PID=""
SERVER_JAVA_PID=""

TOTAL_TICKS=$((WARMUP_TICKS + SAMPLE_TICKS))
BENCH_SECONDS=$((TOTAL_TICKS / EXPECTED_TPS + 30))
TOTAL_VILLAGES=$((PLAYERS_PER_WORLD * ${#WORLD_NAMES[@]}))
VILLAGE_DELAY_SECONDS=$((VILLAGE_PLACE_DELAY_TICKS / EXPECTED_TPS))
POST_VILLAGE_DELAY_SECONDS=$((POST_VILLAGE_DELAY_TICKS / EXPECTED_TPS))
DISTRIBUTION_SECONDS=$(((BOT_COUNT * TELEPORT_DELAY_TICKS) / EXPECTED_TPS))
VILLAGE_PLACE_SECONDS=$((TOTAL_VILLAGES / EXPECTED_TPS))
RUN_SECONDS=$((BENCH_SECONDS + DISTRIBUTION_SECONDS + VILLAGE_DELAY_SECONDS + POST_VILLAGE_DELAY_SECONDS + VILLAGE_PLACE_SECONDS + 30))
PROFILE_DEFAULT_SECONDS=$((SAMPLE_TICKS / EXPECTED_TPS))
if [ "$PROFILE_DEFAULT_SECONDS" -lt 10 ]; then
    PROFILE_DEFAULT_SECONDS=10
fi
BENCH_PROFILE_DURATION="${BENCH_PROFILE_DURATION:-$PROFILE_DEFAULT_SECONDS}"

function ensure_baseline_repo() {
    if [ ! -d "$BASELINE_REPO/.git" ]; then
        echo "Cloning Paper baseline into $BASELINE_REPO"
        git clone https://github.com/PaperMC/Paper "$BASELINE_REPO"
    fi
    pushd "$BASELINE_REPO" >/dev/null
    git fetch origin "$PAPER_REF" || true
    git checkout "$PAPER_REF"
    popd >/dev/null
}

function ensure_patches_applied() {
    local repo_dir="$1"
    if [ ! -d "$repo_dir/paper-server/src/main/java/net/minecraft" ]; then
        echo "Applying patches in $repo_dir"
        pushd "$repo_dir" >/dev/null
        ./gradlew applyPatches
        popd >/dev/null
    fi
}

function ensure_pewpew_api_published() {
    if [ "${BENCH_SKIP_PEWPEW_API_PUBLISH:-}" = "1" ]; then
        return
    fi
    pushd "$ROOT_DIR" >/dev/null
    ./gradlew :pewpew-api:publishToMavenLocal
    popd >/dev/null
}

function build_bench_plugin() {
    if [ ! -d "$BENCH_PLUGIN_REPO" ]; then
        echo "Bench plugin repo not found: $BENCH_PLUGIN_REPO"
        exit 1
    fi
    pushd "$BENCH_PLUGIN_REPO" >/dev/null
    ./gradlew jar -PpewpewApiVersion="$PEWPEW_VERSION"
    popd >/dev/null
}

function plugin_jar_path() {
    ls "$BENCH_PLUGIN_REPO/build/libs/pewpew-bench-"*.jar | head -n 1
}

function ensure_async_profiler() {
    if [ ! -x "$ASYNC_PROFILER_DIR/bin/asprof" ] && [ ! -x "$ASYNC_PROFILER_DIR/profiler.sh" ]; then
        ASYNC_PROFILER_DIR="$ASYNC_PROFILER_DIR" \
        ASYNC_PROFILER_VERSION="$ASYNC_PROFILER_VERSION" \
        ASYNC_PROFILER_ARCH="$ASYNC_PROFILER_ARCH" \
        "$ROOT_DIR/scripts/profiler/fetch_async_profiler.sh"
    fi
}

function profiler_cmd() {
    if [ -x "$ASYNC_PROFILER_DIR/bin/asprof" ]; then
        echo "$ASYNC_PROFILER_DIR/bin/asprof"
        return 0
    fi
    if [ -x "$ASYNC_PROFILER_DIR/profiler.sh" ]; then
        echo "$ASYNC_PROFILER_DIR/profiler.sh"
        return 0
    fi
    return 1
}

function should_profile() {
    local label="$1"
    if [ "$BENCH_PROFILE" != "1" ]; then
        return 1
    fi
    case "$BENCH_PROFILE_TARGET" in
        both)
            return 0
            ;;
        baseline)
            [ "$label" = "baseline" ]
            return $?
            ;;
        pewpew)
            [ "$label" = "pewpew" ]
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

function wait_for_log_line() {
    local log_file="$1"
    local pattern="$2"
    local timeout_seconds="$3"
    local elapsed=0
    until grep -Fq "$pattern" "$log_file"; do
        sleep 1
        elapsed=$((elapsed + 1))
        if [ "$elapsed" -ge "$timeout_seconds" ]; then
            echo "Timeout waiting for log line: $pattern"
            return 1
        fi
    done
}

function resolve_profile_format() {
    case "$BENCH_PROFILE_FORMAT" in
        text)
            echo "flat"
            ;;
        html)
            echo "flamegraph"
            ;;
        *)
            echo "$BENCH_PROFILE_FORMAT"
            ;;
    esac
}

function profile_extension() {
    case "$BENCH_PROFILE_FORMAT" in
        flamegraph|html)
            echo "html"
            ;;
        jfr)
            echo "jfr"
            ;;
        text|flat|traces|collapsed|tree)
            echo "txt"
            ;;
        *)
            echo "$BENCH_PROFILE_FORMAT"
            ;;
    esac
}

function resolve_server_java_pid() {
    local run_dir="$1"
    local timeout_seconds="${2:-30}"
    local elapsed=0
    while [ "$elapsed" -lt "$timeout_seconds" ]; do
        for pid in $(pgrep -f "java" || true); do
            local cwd
            cwd="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
            if [ "$cwd" = "$run_dir" ]; then
                SERVER_JAVA_PID="$pid"
                return 0
            fi
        done
        sleep 1
        elapsed=$((elapsed + 1))
    done
    return 1
}

function capture_pewpew_properties() {
    local label="$1"
    if [ "$BENCH_THREAD_SNAPSHOT" != "1" ]; then
        return
    fi
    if [ -z "$SERVER_JAVA_PID" ]; then
        return
    fi
    local out_dir="$RUN_ROOT/thread-snapshots"
    mkdir -p "$out_dir"
    local out_file="$out_dir/${RUN_ID}-${label}-pewpew-properties.txt"
    if command -v rg >/dev/null 2>&1; then
        jcmd "$SERVER_JAVA_PID" VM.system_properties 2>/dev/null | rg -n "pewpew\\." > "$out_file" || true
    else
        jcmd "$SERVER_JAVA_PID" VM.system_properties 2>/dev/null | grep -E "pewpew\\." > "$out_file" || true
    fi
}

function capture_thread_snapshot() {
    local label="$1"
    if [ "$BENCH_THREAD_SNAPSHOT" != "1" ]; then
        return
    fi
    if [ -z "$SERVER_JAVA_PID" ]; then
        return
    fi
    local out_dir="$RUN_ROOT/thread-snapshots"
    mkdir -p "$out_dir"
    local out_file="$out_dir/${RUN_ID}-${label}-threads.txt"
    if command -v rg >/dev/null 2>&1; then
        jcmd "$SERVER_JAVA_PID" Thread.print 2>/dev/null | rg -n "\"${BENCH_THREAD_SNAPSHOT_PATTERN}" > "$out_file" || true
    else
        jcmd "$SERVER_JAVA_PID" Thread.print 2>/dev/null | grep -E "\"${BENCH_THREAD_SNAPSHOT_PATTERN}" > "$out_file" || true
    fi
}

function start_profiler() {
    local label="$1"
    local output_dir="$BENCH_PROFILE_OUTPUT_DIR"
    local output_ext
    output_ext="$(profile_extension)"
    local output_file="$output_dir/${RUN_ID}-${label}-${BENCH_PROFILE_EVENT}.${output_ext}"
    local output_log="$output_dir/${RUN_ID}-${label}-${BENCH_PROFILE_EVENT}.log"
    local profile_format
    profile_format="$(resolve_profile_format)"
    local extra_args=()
    local cmd
    cmd="$(profiler_cmd || true)"
    if [ -z "$cmd" ]; then
        echo "async-profiler launcher not found in $ASYNC_PROFILER_DIR" >&2
        return
    fi
    if [ -z "$SERVER_JAVA_PID" ]; then
        echo "Skipping profiling; server Java PID not resolved." >&2
        return
    fi
    if [ -n "$BENCH_PROFILE_ARGS" ]; then
        read -r -a extra_args <<< "$BENCH_PROFILE_ARGS"
    fi
    mkdir -p "$output_dir"
    echo "Starting async-profiler ($BENCH_PROFILE_EVENT) for ${BENCH_PROFILE_DURATION}s -> $output_file" >&2
    "$cmd" \
        -d "$BENCH_PROFILE_DURATION" \
        -e "$BENCH_PROFILE_EVENT" \
        -o "$profile_format" \
        -f "$output_file" \
        "${extra_args[@]}" \
        "$SERVER_JAVA_PID" > "$output_log" 2>&1 &
    PROFILER_PID=$!
}

function write_config() {
    local out_dir="$1"
    local plugin_dir="$out_dir/plugins/PewpewBench"
    mkdir -p "$plugin_dir"
    cat > "$plugin_dir/config.yml" <<CONFIG
mode: multiworld
world: ${WORLD_NAMES[0]}
worlds:
  - ${WORLD_NAMES[0]}
  - ${WORLD_NAMES[1]}
teleport-on-join: true
players-per-world: $PLAYERS_PER_WORLD
player-spacing: $PLAYER_SPACING
villagers-per-player: $VILLAGERS_PER_PLAYER
hostiles-per-player: $HOSTILES_PER_PLAYER
villager-spawn-radius: $VILLAGER_SPAWN_RADIUS
hostile-spawn-radius: $HOSTILE_SPAWN_RADIUS
villager-sync-radius: $VILLAGER_SYNC_RADIUS
place-villages: true
village-offset: $VILLAGE_OFFSET
effect-amplifier: $EFFECT_AMPLIFIER
effect-duration-ticks: $EFFECT_DURATION_TICKS
effect-refresh-ticks: $EFFECT_REFRESH_TICKS
villager-maintenance-ticks: $VILLAGER_MAINT_TICKS
village-place-delay-ticks: $VILLAGE_PLACE_DELAY_TICKS
post-village-delay-ticks: $POST_VILLAGE_DELAY_TICKS
teleport-delay-ticks: $TELEPORT_DELAY_TICKS
invulnerable-players: true
invulnerable-villagers: true
scan-nearby-villagers: true
warmup-ticks: $WARMUP_TICKS
sample-ticks: $SAMPLE_TICKS
sample-interval-ticks: $SAMPLE_INTERVAL_TICKS
phase-ticks: 2400
job-site-rotation-ticks: 20
hostile-retarget-ticks: 20
entity-maintenance-ticks: 100
CONFIG
}

function write_pewpew_config() {
    local out_dir="$1"
    cat > "$out_dir/pewpew.yml" <<EOF
config-version: 1
features:
  async-pathfinding: $PEWPEW_FEATURE_ASYNC_PATHFINDING
  async-sensors: $PEWPEW_FEATURE_ASYNC_SENSORS
  world-tick-coordinator: $PEWPEW_FEATURE_WORLD_TICK_COORDINATOR
  world-tick-coordinator-testing: $PEWPEW_FEATURE_WORLD_TICK_COORDINATOR_TESTING
  async-pool-testing: $PEWPEW_FEATURE_ASYNC_POOL_TESTING
  tick-thread-hard-throw: $PEWPEW_FEATURE_TICK_THREAD_HARD_THROW
settings:
  async-pool-workers: $PEWPEW_ASYNC_POOL_WORKERS
  async-pool-queue-limit: $PEWPEW_ASYNC_POOL_QUEUE_LIMIT
  world-tick-coordinator-workers: $PEWPEW_WORLD_TICK_WORKERS
  world-tick-coordinator-stall-threshold-nanos: $PEWPEW_WORLD_TICK_STALL_NANOS
EOF
}

function write_server_properties() {
    local out_dir="$1"
    cat > "$out_dir/server.properties" <<EOF
level-name=${WORLD_NAMES[0]}
level-seed=$SEED
online-mode=false
enforce-secure-profile=false
motd=PewpewBench
view-distance=8
simulation-distance=8
spawn-protection=0
max-players=64
enable-command-block=true
EOF
    echo "eula=true" > "$out_dir/eula.txt"
}

function prepare_run_dir() {
    local out_dir="$1"
    local plugin_jar="$2"
    rm -rf "$out_dir"
    mkdir -p "$out_dir/plugins"
    cp "$plugin_jar" "$out_dir/plugins/PewpewBench.jar"
    curl -L -o "$out_dir/plugins/Multiverse-Core.jar" "$MULTIVERSE_JAR_URL"
    write_server_properties "$out_dir"
    write_config "$out_dir"
    write_pewpew_config "$out_dir"
}

function wait_for_ready() {
    local log_file="$1"
    local timeout_seconds=240
    local elapsed=0
    until grep -q "Done (" "$log_file"; do
        sleep 1
        elapsed=$((elapsed + 1))
        if [ "$elapsed" -ge "$timeout_seconds" ]; then
            echo "Server failed to start in time. Check $log_file"
            return 1
        fi
    done
}

function wait_for_marker() {
    local marker_file="$1"
    local timeout_seconds=600
    local elapsed=0
    until [ -f "$marker_file" ]; do
        sleep 1
        elapsed=$((elapsed + 1))
        if [ "$elapsed" -ge "$timeout_seconds" ]; then
            echo "Timeout waiting for marker file: $marker_file"
            return 1
        fi
    done
}

function ensure_bots_deps() {
    if ! command -v node >/dev/null 2>&1; then
        echo "node is required for mineflayer bots."
        exit 1
    fi
    pushd "$ROOT_DIR/scripts/bench" >/dev/null
    if [ ! -d "node_modules" ]; then
        npm install
    fi
    popd >/dev/null
}

function run_server() {
    local repo_dir="$1"
    local task_name="$2"
    local run_dir="$3"
    local result_out="$4"
    local java_opts="$5"
    local profile_label="$6"

    local fifo="$run_dir/console.in"
    rm -f "$fifo"
    mkfifo "$fifo"
    exec 3<> "$fifo"
    SERVER_FIFO="$fifo"

    echo "Starting server: $task_name in $run_dir"
    pushd "$repo_dir" >/dev/null
    JAVA_TOOL_OPTIONS="$java_opts" ./gradlew "$task_name" -Ppaper.runWorkDir="$run_dir" <&3 > "$run_dir/server.log" 2>&1 &
    local server_pid=$!
    SERVER_PID="$server_pid"
    popd >/dev/null

    wait_for_ready "$run_dir/server.log"

    SERVER_JAVA_PID=""
    if resolve_server_java_pid "$run_dir"; then
        echo "Resolved server Java PID: $SERVER_JAVA_PID"
        capture_pewpew_properties "$profile_label"
    else
        echo "Failed to resolve server Java PID for $run_dir"
    fi

    echo "Creating extra world via Multiverse"
    printf "mv create ${WORLD_NAMES[1]} normal -s %s\n" "$SEED" >&3
    printf "mv load ${WORLD_NAMES[1]}\n" >&3
    wait_for_marker "$run_dir/plugins/PewpewBench/multiworld-ready.txt"

    echo "Spawning $BOT_COUNT bots for $RUN_SECONDS seconds"
    node "$ROOT_DIR/scripts/bench/bots.js" --count "$BOT_COUNT" --duration "$RUN_SECONDS" >/dev/null 2>&1 &
    local bot_pid=$!
    if [ "$BENCH_THREAD_SNAPSHOT" = "1" ]; then
        sleep "$BENCH_THREAD_SNAPSHOT_DELAY"
        capture_thread_snapshot "$profile_label"
    fi

    PROFILER_PID=""
    if should_profile "$profile_label"; then
        ensure_async_profiler
        wait_for_log_line "$run_dir/server.log" "$BENCH_PROFILE_LOG_PATTERN" "$BENCH_PROFILE_START_TIMEOUT"
        start_profiler "$profile_label"
    fi

    wait "$bot_pid"
    if [ -n "$PROFILER_PID" ]; then
        wait "$PROFILER_PID" || true
    fi
    sleep 5

    echo "Stopping server"
    printf "stop\n" >&3
    wait "$server_pid"
    rm -f "$fifo"
    exec 3>&-
    SERVER_PID=""
    SERVER_FIFO=""
    SERVER_JAVA_PID=""

    local summary="$run_dir/plugins/PewpewBench/bench-summary.json"
    if [ ! -f "$summary" ]; then
        echo "Bench summary missing at $summary"
        exit 1
    fi
    cp "$summary" "$result_out"
}

function cleanup_run_root() {
    if [ -n "${PROFILER_PID:-}" ] && kill -0 "$PROFILER_PID" >/dev/null 2>&1; then
        kill "$PROFILER_PID" >/dev/null 2>&1 || true
    fi
    if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" >/dev/null 2>&1; then
        kill "$SERVER_PID" >/dev/null 2>&1 || true
        sleep 2
        kill -9 "$SERVER_PID" >/dev/null 2>&1 || true
    fi
    if [ "${BENCH_KEEP_RUN_DIR:-}" = "1" ]; then
        echo "Leaving run directory intact: $RUN_ROOT"
        return
    fi
    if [ -z "${RUN_ROOT:-}" ] || [ "$RUN_ROOT" = "/" ]; then
        return
    fi
    rm -rf "$RUN_ROOT"
}

trap cleanup_run_root EXIT

ensure_baseline_repo
ensure_patches_applied "$BASELINE_REPO"
ensure_pewpew_api_published
build_bench_plugin
ensure_bots_deps

mkdir -p "$RUN_ROOT"
mkdir -p "$REPORT_DIR"

PLUGIN_JAR="$(plugin_jar_path)"
prepare_run_dir "$RUN_BASELINE_DIR" "$PLUGIN_JAR"
prepare_run_dir "$RUN_PEWPEW_DIR" "$PLUGIN_JAR"

if [ "${BENCH_SKIP_BASELINE:-}" = "1" ]; then
    if [ ! -f "$BASELINE_SUMMARY_IN" ]; then
        echo "Baseline summary not found: $BASELINE_SUMMARY_IN"
        exit 1
    fi
    BASELINE_SUMMARY_IN_REAL="$(readlink -f "$BASELINE_SUMMARY_IN")"
    BASELINE_SUMMARY_OUT_REAL="$(readlink -f "$BASELINE_SUMMARY_OUT" 2>/dev/null || true)"
    if [ "$BASELINE_SUMMARY_IN_REAL" != "$BASELINE_SUMMARY_OUT_REAL" ]; then
        cp "$BASELINE_SUMMARY_IN" "$BASELINE_SUMMARY_OUT"
    fi
else
    run_server "$BASELINE_REPO" ":paper-server:runDevServer" "$RUN_BASELINE_DIR" "$BASELINE_SUMMARY_OUT" "" "baseline"
fi
run_server "$ROOT_DIR" ":pewpew-server:runDevServer" "$RUN_PEWPEW_DIR" "$PEWPEW_SUMMARY_OUT" "$PEWPEW_JAVA_OPTS" "pewpew"

python3 "$ROOT_DIR/scripts/bench/multiverse_report.py" \
    --summary "$BASELINE_SUMMARY_OUT" \
    --output "$BASELINE_REPORT_OUT" \
    --worlds "${WORLD_NAMES[*]}" \
    --players-per-world "$PLAYERS_PER_WORLD" \
    --villagers-per-player "$VILLAGERS_PER_PLAYER" \
    --warmup-ticks "$WARMUP_TICKS" \
    --sample-ticks "$SAMPLE_TICKS" \
    --sample-interval "$SAMPLE_INTERVAL_TICKS" \
    --seed "$SEED" \
    --duration-seconds "$RUN_SECONDS"

python3 "$ROOT_DIR/scripts/bench/multiverse_report.py" \
    --summary "$PEWPEW_SUMMARY_OUT" \
    --output "$PEWPEW_REPORT_OUT" \
    --worlds "${WORLD_NAMES[*]}" \
    --players-per-world "$PLAYERS_PER_WORLD" \
    --villagers-per-player "$VILLAGERS_PER_PLAYER" \
    --warmup-ticks "$WARMUP_TICKS" \
    --sample-ticks "$SAMPLE_TICKS" \
    --sample-interval "$SAMPLE_INTERVAL_TICKS" \
    --seed "$SEED" \
    --duration-seconds "$RUN_SECONDS"

echo "Multiworld bench reports written to $BASELINE_REPORT_OUT and $PEWPEW_REPORT_OUT"
