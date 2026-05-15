#!/bin/bash

# Linux perf 性能分析脚本
# perf 是 Linux 内核自带的性能分析工具
# 支持源代码级别的执行时间分析

set -e


PROJECT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="$PROJECT_DIR/.build_perf_report"
RESULTS_DIR="$BUILD_DIR/report"
EXECUTE_NAME="cpp_profile"

echo "=========================================="
echo "       Linux Perf 性能分析工具"
echo "=========================================="

# 检查 perf 是否安装
if ! command -v perf &> /dev/null; then
    echo "错误: perf 未安装!"
    echo "请使用以下命令安装:"
    echo "  Ubuntu/Debian: sudo apt-get install linux-tools-common linux-tools-generic"
    exit 1
fi



# 编译程序（两种模式）
echo ""
echo "[1/3] 编译程序..."

# 编译带调试信息的版本（用于源代码分析）
echo "编译带调试信息的版本..."
${PROJECT_DIR}/build.sh clean gcc gcov build run

# 创建目录
mkdir -p "$BUILD_DIR"
mkdir -p "$RESULTS_DIR"
cp -rf "$PROJECT_DIR/build/"* "$BUILD_DIR"

echo ""
echo "[2/3] 运行 perf 分析..."

# 1. 基本统计信息
echo ""
echo "------------------------------------------"
echo "[分析 1/6] 基本性能统计"
echo "------------------------------------------$BUILD_DIR/$EXECUTE_NAME"
perf stat -d "$BUILD_DIR/$EXECUTE_NAME" 2>&1 | tee "$RESULTS_DIR/perf_stat.txt"

# 2. 源代码级分析（每行代码执行时间）
echo ""
echo "------------------------------------------"
echo "[分析 2/6] 源代码级别分析（每行代码执行时间）"
echo "------------------------------------------"

# 收集带源代码信息的性能数据
perf record -e cycles -g -- "$BUILD_DIR/$EXECUTE_NAME" 2>/dev/null || \
    sudo perf record -e cycles -g -- "$BUILD_DIR/$EXECUTE_NAME"

# 生成源代码级分析报告
if [ -f "perf.data" ]; then
    echo "生成源代码级分析..."
    # 使用 perf report 生成带源代码的报告
    perf report --stdio -g --show-total-period > "$RESULTS_DIR/perf_source_report.txt" 2>/dev/null || \
        sudo perf report --stdio -g --show-total-period > "$RESULTS_DIR/perf_source_report.txt"
    
    # 使用 perf annotate 生成更详细的源代码分析
    echo "生成详细的源代码注释..."
    perf annotate --stdio > "$RESULTS_DIR/perf_annotate.txt" 2>/dev/null || \
        sudo perf annotate --stdio > "$RESULTS_DIR/perf_annotate.txt"
    
    echo "源代码分析报告已保存:"
    echo "  源代码报告: $RESULTS_DIR/perf_source_report.txt"
    echo "  源代码注释: $RESULTS_DIR/perf_annotate.txt"
    
    rm -f perf.data perf.data.old
else
    echo "警告: 无法生成源代码分析数据"
fi

# 3. CPU 周期分析
echo ""
echo "------------------------------------------"
echo "[分析 3/6] CPU 周期详细分析"
echo "------------------------------------------"
perf record -e cycles -g -- "$BUILD_DIR/$EXECUTE_NAME" 2>/dev/null || \
    sudo perf record -e cycles -g -- "$BUILD_DIR/$EXECUTE_NAME"
perf report --stdio > "$RESULTS_DIR/perf_cycles_report.txt" 2>/dev/null || \
    sudo perf report --stdio > "$RESULTS_DIR/perf_cycles_report.txt"
echo "报告已保存: $RESULTS_DIR/perf_cycles_report.txt"
rm -f perf.data perf.data.old

# 4. 缓存分析
echo ""
echo "------------------------------------------"
echo "[分析 4/6] 缓存命中率分析"
echo "------------------------------------------"
perf stat -e cache-references,cache-misses,L1-dcache-loads,L1-dcache-load-misses \
    "$BUILD_DIR/cpp_profile" 2>&1 | tee "$RESULTS_DIR/perf_cache.txt"

# 5. 分支预测分析
echo ""
echo "------------------------------------------"
echo "[分析 5/6] 分支预测分析"
echo "------------------------------------------"
perf stat -e branches,branch-misses,branch-instructions \
    "$BUILD_DIR/cpp_profile" 2>&1 | tee "$RESULTS_DIR/perf_branch.txt"

# 6. 页面错误分析
echo ""
echo "------------------------------------------"
echo "[分析 6/6] 页面错误分析"
echo "------------------------------------------"
perf stat -e page-faults,major-faults,minor-faults \
    "$BUILD_DIR/cpp_profile" 2>&1 | tee "$RESULTS_DIR/perf_faults.txt"

# 生成综合报告
echo ""
echo "=========================================="
echo "         Perf 分析完成"
echo "=========================================="
echo ""
echo "生成的报告文件:"
echo "  基本统计:     $RESULTS_DIR/perf_stat.txt"
echo "  源代码报告:   $RESULTS_DIR/perf_source_report.txt"
echo "  源代码注释:   $RESULTS_DIR/perf_annotate.txt"
echo "  CPU 周期:     $RESULTS_DIR/perf_cycles_report.txt"
echo "  缓存分析:     $RESULTS_DIR/perf_cache.txt"
echo "  分支预测:     $RESULTS_DIR/perf_branch.txt"
echo "  页面错误:     $RESULTS_DIR/perf_faults.txt"
echo ""
echo "=========================================="
echo "         源代码分析说明"
echo "=========================================="
echo "  1. perf_annotate.txt 文件包含每行代码的执行时间百分比"
echo "  2. 格式示例:"
echo "     :    5.23 │    for (int i = 0; i < 1000000; i++) {"
echo "     :   10.45 │        result += sin(i);"
echo "  3. 百分比表示该行代码占用的 CPU 时间比例"
echo "  4. 数值越高，表示该行代码执行时间越长"
echo ""
echo "=========================================="
echo "         常用 perf 命令"
echo "=========================================="
echo "  perf list                 # 列出可用事件"
echo "  perf top                  # 实时性能监控"
echo "  perf annotate             # 交互式源代码分析"
echo "  perf report               # 交互式报告查看"
echo "  perf diff perf.data.old perf.data  # 比较两次运行的差异"
echo ""
echo "要查看详细的源代码分析:"
echo "  less $RESULTS_DIR/perf_annotate.txt"
echo "  或"
echo "  perf annotate --stdio | less"
