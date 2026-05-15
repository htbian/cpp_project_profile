#!/bin/bash

# GCOV 代码覆盖率分析脚本
# gcov 是 GCC 自带的代码覆盖率工具

set -e
PROJECT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="$PROJECT_DIR/.build_gcov_report"
RESULTS_DIR="$BUILD_DIR/report"

echo "=========================================="
echo "       GCOV 代码覆盖率分析工具"
echo "=========================================="

# 检查 gcov 是否可用
if ! command -v gcov &> /dev/null; then
    echo "错误: gcov 未找到!"
    echo "请确保已安装 gcc/g++"
    exit 1
fi

# 检查 lcov 是否安装（可选）
HAS_LCOV=false
if command -v lcov &> /dev/null; then
    HAS_LCOV=true
    echo "检测到 lcov，将生成 HTML 报告"
else
    echo "提示: 安装 lcov 可以生成更美观的 HTML 报告"
    echo "  Ubuntu/Debian: sudo apt-get install lcov"
fi

# 编译/运行程序
echo ""
echo "[1/2] 编译/运行程序 (启用覆盖率检测)..."
${PROJECT_DIR}/build.sh clean gcc gcov build run
# 创建目录
mkdir -p "$BUILD_DIR"
mkdir -p "$RESULTS_DIR"
cp -r "$PROJECT_DIR/build/" "$BUILD_DIR"

# 生成覆盖率报告
echo ""
echo "[2/2] 生成覆盖率报告..."
# 生成覆盖率报告...
if [ "$HAS_LCOV" = true ]; then
    echo "使用 lcov 收集覆盖率数据..."
    lcov --directory "$PROJECT_DIR" --capture --output-file "$RESULTS_DIR/coverage.info"
    # 可选：过滤掉系统头文件和测试框架
    lcov --remove "$RESULTS_DIR/coverage.info" '/usr/*' --output-file "$RESULTS_DIR/coverage.info"
    echo "生成 HTML 报告..."
    genhtml "$RESULTS_DIR/coverage.info" --output-directory "$RESULTS_DIR/html"
    echo ""
    echo "完成! HTML 报告路径: $RESULTS_DIR/html/index.html"
else
    echo "未安装 lcov，只生成 gcov 文本报告..."
    # 遍历所有源文件生成 gcov 报告
    for src_file in "$PROJECT_DIR"/*.cpp; do
        gcov -o "$PROJECT_DIR" "$src_file" -b -c
        # 移动 gcov 文件到结果目录
        mv *.gcov "$RESULTS_DIR/" 2>/dev/null || true
    done
    echo "完成! gcov 文本报告已生成在 $RESULTS_DIR"
fi

echo ""
echo "=========================================="
echo "      GCOV 分析完成!"
echo "=========================================="