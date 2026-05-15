#!/bin/bash

# gprof 性能分析脚本（使用 gprof2dot 生成 PNG 图表）
# gprof2dot 是一个将 gprof 输出转换为 DOT 格式的工具

set -e
PROJECT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="$PROJECT_DIR/.build_gprof_report"
RESULTS_DIR="$BUILD_DIR/report"
EXECUTE_NAME="cpp_profile"

echo "=========================================="
echo "       Gprof 性能分析工具 (gprof2dot)"
echo "=========================================="

# 检查并安装 gprof2dot
check_and_install_gprof2dot() {
    if command -v gprof2dot &> /dev/null; then
        echo "检测到 gprof2dot"
        return 0
    fi
    
    echo "gprof2dot 未安装，尝试安装..."
    
    # 检查 pip3
    if command -v pip3 &> /dev/null; then
        echo "使用 pip3 安装 gprof2dot..."
        pip3 install gprof2dot --user
        return 0
    fi
    
    # 检查 pip
    if command -v pip &> /dev/null; then
        echo "使用 pip 安装 gprof2dot..."
        pip install gprof2dot --user
        return 0
    fi
    
    echo "错误: 无法找到 pip，请手动安装 gprof2dot:"
    echo "  pip3 install gprof2dot"
    echo "  或"
    echo "  sudo apt-get install python3-pip && pip3 install gprof2dot"
    return 1
}

# 检查 graphviz
check_graphviz() {
    if command -v dot &> /dev/null; then
        echo "检测到 graphviz (dot)"
        return 0
    fi
    
    echo "错误: graphviz 未安装"
    echo "请使用以下命令安装:"
    echo "  Ubuntu/Debian: sudo apt-get install graphviz"
    return 1
}

# 检查工具
check_and_install_gprof2dot || exit 1
check_graphviz || exit 1

# 步骤1: 使用 gprof 选项编译
echo ""
echo "[1/3] 编译程序 (启用 gprof)... 运行程序生成分析数据..."
${PROJECT_DIR}/build.sh clean gcc gprof debug build run

# 创建目录
mkdir -p "$BUILD_DIR"
mkdir -p "$RESULTS_DIR"
cp -rf "$PROJECT_DIR/build/"* "$BUILD_DIR"
# 检查 gmon.out
if [ ! -f "$BUILD_DIR/gmon.out" ]; then
    echo "错误: gmon.out 未生成"
    exit 1
fi

# 步骤3: 生成 gprof 分析报告
echo ""
echo "[3/3] 生成 gprof 分析报告..."

# 步骤3: 生成 gprof 分析报告...
GP_OUTPUT="$RESULTS_DIR/gprof_report.txt"
DOT_OUTPUT="$RESULTS_DIR/callgraph.dot"
PNG_OUTPUT="$RESULTS_DIR/callgraph.png"

cd "$BUILD_DIR"
echo "生成 gprof 文本报告..."
gprof ./${EXECUTE_NAME} gmon.out > "$GP_OUTPUT"
echo "gprof 文本报告生成完成: $GP_OUTPUT"

echo "生成 DOT 文件 (gprof2dot)..."
gprof2dot -f prof "$GP_OUTPUT" -o "$DOT_OUTPUT"
echo "DOT 文件生成完成: $DOT_OUTPUT"

echo "生成 PNG 图表 (graphviz dot)..."
dot -Tpng "$DOT_OUTPUT" -o "$PNG_OUTPUT"
echo "PNG 图表生成完成: $PNG_OUTPUT"

echo ""
echo "=========================================="
echo "      Gprof 分析完成!"
echo "      文本报告: $GP_OUTPUT"
echo "      调用图: $PNG_OUTPUT"
echo "=========================================="
