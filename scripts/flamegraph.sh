#!/bin/bash
set -e

# ===============================
# 配置
# ===============================
PROJECT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="$PROJECT_DIR/.build_flamegraph_report"
RESULTS_DIR="$BUILD_DIR/report"
EXECUTE_NAME="cpp_profile"
FLAMEGRAPH_DIR="$HOME/FlameGraph"
MODE="${1:-oncpu}"   # 可选: oncpu | offcpu | mem

# ===============================
# 检测环境
# ===============================
IS_WSL2=false
grep -qi microsoft /proc/version &>/dev/null && IS_WSL2=true && echo "[INFO] 检测到 WSL2 环境"

command -v perf &>/dev/null && PERF_AVAILABLE=true || PERF_AVAILABLE=false
command -v valgrind &>/dev/null && VALGRIND_AVAILABLE=true || VALGRIND_AVAILABLE=false

# 下载 FlameGraph
[ ! -d "$FLAMEGRAPH_DIR" ] && git clone --depth 1 https://github.com/brendangregg/FlameGraph.git "$FLAMEGRAPH_DIR"

# 编译
echo "[1/3] 编译程序..."
"$PROJECT_DIR/build.sh" clean gcc gcov build

# 创建目录
mkdir -p "$BUILD_DIR" "$RESULTS_DIR"
cp -rf "$PROJECT_DIR/build/"* "$BUILD_DIR"

# 选择工具
if [ "$PERF_AVAILABLE" = true ]; then
    USE_PERF=true
    TOOL="perf"
elif [ "$VALGRIND_AVAILABLE" = true ]; then
    USE_CALLGRIND=true
    TOOL="Valgrind"
else
    echo "[ERROR] 需要 perf 或 valgrind"
    exit 1
fi

cd "$RESULTS_DIR"

# ===============================
# 通用函数
# ===============================
run_perf() {
    local event=$1
    local output=$2
    echo "[INFO] perf 采样事件: $event"
    rm -f perf.data
    if ! perf record -F 99 -e "$event" -g -- "$BUILD_DIR/$EXECUTE_NAME"; then
        echo "[WARN] perf record 失败, 尝试 sudo..."
        sudo perf record -F 99 -e "$event" -g -- "$BUILD_DIR/$EXECUTE_NAME"
    fi
    perf script | "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" > "$output"
}

run_valgrind_callgrind() {
    local output=$1
    valgrind --tool=callgrind \
             --callgrind-out-file="$output" \
             --instr-atstart=yes \
             "$BUILD_DIR/$EXECUTE_NAME" 2>&1 | tail -10
}

generate_flamegraph() {
    local folded_file=$1
    local svg_file=$2
    local title=$3
    local color=$4
    "$FLAMEGRAPH_DIR/flamegraph.pl" "$folded_file" \
        --title="$title" \
        --colors="$color" \
        > "$svg_file"
    echo "$svg_file"
}

# ===============================
# 模式分发
# ===============================
case "$MODE" in
    oncpu)
        if [ "$USE_PERF" = true ]; then
            run_perf "cpu-clock" "on_cpu.folded"
            SVG=$(generate_flamegraph "on_cpu.folded" "on_cpu_flamegraph.svg" "On-CPU Flame Graph" "red")
        else
            run_valgrind_callgrind "callgrind.out"
            # TODO: 可以用 callgrind_annotate 或生成示例 folded
            SVG=$(generate_flamegraph "on_cpu.folded" "on_cpu_flamegraph.svg" "On-CPU Flame Graph (Callgrind)" "red")
        fi
        ;;
    offcpu)
        if [ "$USE_PERF" = true ]; then
            run_perf "sched:sched_switch" "off_cpu.folded"
            SVG=$(generate_flamegraph "off_cpu.folded" "off_cpu_flamegraph.svg" "Off-CPU Flame Graph" "blue")
        else
            echo "[ERROR] Callgrind 不支持 OFF-CPU"
            exit 1
        fi
        ;;
    mem)
        if [ "$USE_PERF" = true ]; then
            run_perf "kmem:mm_page_alloc" "memory.folded" || echo "[WARN] perf 内存事件不可用"
            SVG=$(generate_flamegraph "memory.folded" "memory_flamegraph.svg" "Memory Flame Graph" "green")
        elif [ "$VALGRIND_AVAILABLE" = true ]; then
            valgrind --tool=massif --massif-out-file="massif.out" "$BUILD_DIR/$EXECUTE_NAME" 2>&1 | tail -10
            SVG=$(generate_flamegraph "memory.folded" "memory_flamegraph.svg" "Memory Flame Graph (Massif)" "green")
        fi
        ;;
    *)
        echo "[ERROR] 未知模式: $MODE"
        exit 1
        ;;
esac

# ===============================
# 完成提示
# ===============================
echo "[3/3] 火焰图生成完成! ($TOOL)"
echo "火焰图: $SVG"
echo "浏览器打开: firefox $SVG | google-chrome $SVG"