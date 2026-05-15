#!/bin/bash

# Valgrind 内存和性能分析脚本
# Valgrind 是一个强大的内存调试和分析工具套件

set -e
PROJECT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="$PROJECT_DIR/.build_valgrind_report"
RESULTS_DIR="$BUILD_DIR/report"
EXECUTE_NAME="cpp_profile"


echo "=========================================="
echo "       Valgrind 分析工具套件"
echo "=========================================="

# 检查 valgrind 是否安装
if ! command -v valgrind &> /dev/null; then
    echo "错误: valgrind 未安装!"
    echo "请使用以下命令安装:"
    echo "  Ubuntu/Debian: sudo apt-get install valgrind"
    echo "  CentOS/RHEL:   sudo yum install valgrind"
    exit 1
fi



# 编译程序
echo ""
echo "[1/2] 编译程序 (调试模式)..."
${PROJECT_DIR}/build.sh clean gcc gprof debug build run

# 创建目录
mkdir -p "$BUILD_DIR"
mkdir -p "$RESULTS_DIR"
cp -rf "$PROJECT_DIR/build/"* "$BUILD_DIR"

echo ""
echo "[2/2] 运行 Valgrind 分析..."

# 1. Memcheck - 内存错误检测
echo ""
echo "------------------------------------------"
echo "[分析 1/4] Memcheck - 内存错误检测"
echo "------------------------------------------"
valgrind --tool=memcheck \
         --leak-check=full \
         --show-leak-kinds=all \
         --track-origins=yes \
         --verbose \
         --log-file="$RESULTS_DIR/valgrind_memcheck.txt" \
         $BUILD_DIR/$EXECUTE_NAME 2>&1 | head -50

echo "详细报告: $RESULTS_DIR/valgrind_memcheck.txt"

# 2. Cachegrind - 缓存分析
echo ""
echo "------------------------------------------"
echo "[分析 2/4] Cachegrind - 缓存命中率分析"
echo "------------------------------------------"
valgrind --tool=cachegrind \
         --cachegrind-out-file="$RESULTS_DIR/cachegrind.out" \
         $BUILD_DIR/$EXECUTE_NAME 2>&1 | tail -20

# 生成缓存分析报告
cg_annotate "$RESULTS_DIR/cachegrind.out" > "$RESULTS_DIR/cachegrind_report.txt" 2>/dev/null || echo "cg_annotate 不可用，跳过详细报告"

echo "原始数据: $RESULTS_DIR/cachegrind.out"
echo "分析报告: $RESULTS_DIR/cachegrind_report.txt"

# 3. Callgrind - 调用图分析
echo ""
echo "------------------------------------------"
echo "[分析 3/4] Callgrind - 函数调用分析"
echo "------------------------------------------"
valgrind --tool=callgrind \
         --callgrind-out-file="$RESULTS_DIR/callgrind.out" \
          $BUILD_DIR/$EXECUTE_NAME 2>&1 | tail -10

echo "原始数据: $RESULTS_DIR/callgrind.out"
echo "使用 KCachegrind 查看: kcachegrind $RESULTS_DIR/callgrind.out"

# 4. Massif - 堆分析
echo ""
echo "------------------------------------------"
echo "[分析 4/4] Massif - 堆内存使用分析"
echo "------------------------------------------"
valgrind --tool=massif \
         --massif-out-file="$RESULTS_DIR/massif.out" \
          $BUILD_DIR/$EXECUTE_NAME 2>&1 | tail -10

# 生成堆分析报告
ms_print "$RESULTS_DIR/massif.out" > "$RESULTS_DIR/massif_report.txt" 2>/dev/null || echo "ms_print 不可用，跳过详细报告"

echo "原始数据: $RESULTS_DIR/massif.out"
echo "分析报告: $RESULTS_DIR/massif_report.txt"

echo ""
echo "=========================================="
echo "         Valgrind 分析完成"
echo "=========================================="
echo ""
echo "生成的文件:"
echo "  内存错误检测: $RESULTS_DIR/valgrind_memcheck.txt"
echo "  缓存分析:     $RESULTS_DIR/cachegrind_report.txt"
echo "  调用图:       $RESULTS_DIR/callgrind.out (用 KCachegrind 打开)"
echo "  堆分析:       $RESULTS_DIR/massif_report.txt"
echo ""
echo "内存泄漏摘要:"
echo "----------------------"
grep -A 5 "LEAK SUMMARY" "$RESULTS_DIR/valgrind_memcheck.txt" 2>/dev/null || echo "无内存泄漏信息"
