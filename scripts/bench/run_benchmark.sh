#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASELINE_REPO="${BENCH_BASELINE_REPO:-/home/phoenix/works/pewpew-paper-baseline}"
PAPER_REF="$(grep '^paperRef=' "$ROOT_DIR/gradle.properties" | cut -d= -f2)"
PEWPEW_VERSION="$(grep '^version=' "$ROOT_DIR/gradle.properties" | cut -d= -f2)"
BENCH_PLUGIN_REPO="${BENCH_PLUGIN_REPO:-/home/phoenix/works/pewpew-bench-plugin}"
BENCH_PLUGIN_API_COORDS="${BENCH_PLUGIN_API_COORDS:-}"

BOT_COUNT="${BENCH_BOT_COUNT:-10}"
SEED="${BENCH_SEED:-424242}"
CELLS="${BENCH_CELLS:-$BOT_COUNT}"
VILLAGERS_PER_CELL="${BENCH_VILLAGERS_PER_CELL:-40}"
HOSTILES_PER_CELL="${BENCH_HOSTILES_PER_CELL:-40}"
WARMUP_TICKS="${BENCH_WARMUP_TICKS:-2400}"
SAMPLE_TICKS="${BENCH_SAMPLE_TICKS:-6000}"
PHASE_TICKS="${BENCH_PHASE_TICKS:-2400}"
SAMPLE_INTERVAL_TICKS="${BENCH_SAMPLE_INTERVAL_TICKS:-100}"
JOB_ROTATE_TICKS="${BENCH_JOB_ROTATE_TICKS:-20}"
HOSTILE_RETARGET_TICKS="${BENCH_HOSTILE_RETARGET_TICKS:-20}"
ENTITY_MAINT_TICKS="${BENCH_ENTITY_MAINT_TICKS:-100}"
EXPECTED_TPS="${BENCH_EXPECTED_TPS:-12}"

RUN_ID="${BENCH_RUN_ID:-$(date +%Y%m%d-%H%M%S)-$$}"
RUN_ROOT="$ROOT_DIR/tmp/bench/runs/$RUN_ID"
RUN_BASELINE_DIR="$RUN_ROOT/baseline"
RUN_PEWPEW_DIR="$RUN_ROOT/pewpew"
REPORT_DIR="$ROOT_DIR/docs/pewpew/findings"
BASELINE_RESULT="$REPORT_DIR/bench-baseline.json"
COMPARE_RESULT="$REPORT_DIR/bench-compare.json"
REPORT_OUT="$REPORT_DIR/perf-bench-report.md"
PEWPEW_JAVA_OPTS="${BENCH_PEWPEW_JAVA_OPTS:--Dpewpew.asyncPathfinding=true -Dpewpew.asyncSensors=true}"

PEWPEW_FEATURE_ASYNC_PATHFINDING="${BENCH_PEWPEW_FEATURE_ASYNC_PATHFINDING:-true}"
PEWPEW_FEATURE_ASYNC_SENSORS="${BENCH_PEWPEW_FEATURE_ASYNC_SENSORS:-true}"
PEWPEW_FEATURE_WORLD_TICK_COORDINATOR="${BENCH_PEWPEW_FEATURE_WORLD_TICK_COORDINATOR:-false}"
PEWPEW_FEATURE_WORLD_TICK_COORDINATOR_TESTING="${BENCH_PEWPEW_FEATURE_WORLD_TICK_COORDINATOR_TESTING:-false}"
PEWPEW_FEATURE_ASYNC_POOL_TESTING="${BENCH_PEWPEW_FEATURE_ASYNC_POOL_TESTING:-false}"
PEWPEW_FEATURE_TICK_THREAD_HARD_THROW="${BENCH_PEWPEW_FEATURE_TICK_THREAD_HARD_THROW:-true}"
PEWPEW_ASYNC_POOL_WORKERS="${BENCH_PEWPEW_ASYNC_POOL_WORKERS:--1}"
PEWPEW_ASYNC_POOL_QUEUE_LIMIT="${BENCH_PEWPEW_ASYNC_POOL_QUEUE_LIMIT:--1}"
PEWPEW_ASYNC_PATH_MONSTER_SYNC_FALLBACK="${BENCH_PEWPEW_ASYNC_PATH_MONSTER_SYNC_FALLBACK:-true}"
PEWPEW_WORLD_TICK_WORKERS="${BENCH_PEWPEW_WORLD_TICK_WORKERS:--1}"
PEWPEW_WORLD_TICK_STALL_NANOS="${BENCH_PEWPEW_WORLD_TICK_STALL_NANOS:-50000000}"
PEWPEW_WORLD_TICK_DEDICATED_WORLDS="${BENCH_PEWPEW_WORLD_TICK_DEDICATED_WORLDS:-}"
SERVER_PID=""

TOTAL_TICKS=$((WARMUP_TICKS + SAMPLE_TICKS))
RUN_SECONDS=$((TOTAL_TICKS / EXPECTED_TPS + 60))

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
    ./gradlew :paper-api:publishToMavenLocal
    popd >/dev/null
}

function build_bench_plugin() {
    if [ ! -d "$BENCH_PLUGIN_REPO" ]; then
        echo "Bench plugin repo not found: $BENCH_PLUGIN_REPO"
        exit 1
    fi
    local gradle_args=("jar" "-PpewpewApiVersion=$PEWPEW_VERSION")
    if [ -n "$BENCH_PLUGIN_API_COORDS" ]; then
        gradle_args+=("-PbenchApiCoordinates=$BENCH_PLUGIN_API_COORDS")
    fi
    pushd "$BENCH_PLUGIN_REPO" >/dev/null
    ./gradlew "${gradle_args[@]}"
    popd >/dev/null
}

function plugin_jar_path() {
    ls "$BENCH_PLUGIN_REPO/build/libs/pewpew-bench-"*.jar | head -n 1
}

function write_config() {
    local out_dir="$1"
    local plugin_dir="$out_dir/plugins/PewpewBench"
    mkdir -p "$plugin_dir"
    cat > "$plugin_dir/config.yml" <<EOF
mode: single
world: world
worlds: []
cells: $CELLS
villagers-per-cell: $VILLAGERS_PER_CELL
hostiles-per-cell: $HOSTILES_PER_CELL
cell-size: 64
cell-spacing: 256
layout-seed: $SEED
warmup-ticks: $WARMUP_TICKS
sample-ticks: $SAMPLE_TICKS
sample-interval-ticks: $SAMPLE_INTERVAL_TICKS
phase-ticks: $PHASE_TICKS
job-site-rotation-ticks: $JOB_ROTATE_TICKS
hostile-retarget-ticks: $HOSTILE_RETARGET_TICKS
entity-maintenance-ticks: $ENTITY_MAINT_TICKS
teleport-on-join: true
EOF
}

function write_pewpew_config() {
    local out_dir="$1"
    local dedicated_worlds="[]"
    if [ -n "$PEWPEW_WORLD_TICK_DEDICATED_WORLDS" ]; then
        dedicated_worlds="[$PEWPEW_WORLD_TICK_DEDICATED_WORLDS]"
    fi
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
  async-pathfinding-monster-sync-fallback: $PEWPEW_ASYNC_PATH_MONSTER_SYNC_FALLBACK
  world-tick-coordinator-workers: $PEWPEW_WORLD_TICK_WORKERS
  world-tick-coordinator-stall-threshold-nanos: $PEWPEW_WORLD_TICK_STALL_NANOS
  world-tick-coordinator-dedicated-worlds: $dedicated_worlds
EOF
}

function write_server_properties() {
    local out_dir="$1"
    cat > "$out_dir/server.properties" <<EOF
level-name=world
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
    write_server_properties "$out_dir"
    write_config "$out_dir"
    write_pewpew_config "$out_dir"
}

function wait_for_ready() {
    local log_file="$1"
    local timeout_seconds=120
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

    echo "Spawning $BOT_COUNT bots for $RUN_SECONDS seconds"
    node "$ROOT_DIR/scripts/bench/bots.js" --count "$BOT_COUNT" --duration "$RUN_SECONDS" >/dev/null 2>&1
    sleep 5

    echo "Stopping server"
    printf "stop\n" >&3
    wait "$server_pid"
    rm -f "$fifo"
    exec 3>&-
    SERVER_PID=""
    SERVER_FIFO=""

    local summary="$run_dir/plugins/PewpewBench/bench-summary.json"
    if [ ! -f "$summary" ]; then
        echo "Bench summary missing at $summary"
        exit 1
    fi
    cp "$summary" "$result_out"
}

function cleanup_run_root() {
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

run_server "$BASELINE_REPO" ":paper-server:runDevServer" "$RUN_BASELINE_DIR" "$BASELINE_RESULT" ""
run_server "$ROOT_DIR" ":pewpew-server:runDevServer" "$RUN_PEWPEW_DIR" "$COMPARE_RESULT" "$PEWPEW_JAVA_OPTS"

python3 "$ROOT_DIR/scripts/bench/compare_results.py" "$BASELINE_RESULT" "$COMPARE_RESULT" "$REPORT_OUT"
echo "Bench report written to $REPORT_OUT"
