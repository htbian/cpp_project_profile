#!/bin/bash

# 编译运行脚本
# 参数说明:
#   b, build           - 编译项目
#   r, run            - 运行程序
#   c, clean          - 清空build目录
#   gcc               - 使用 GCC 编译器
#   clang             - 使用 Clang 编译器
#   gprof             - 启用 gprof 性能分析
#   gcov              - 启用 gcov 代码覆盖率
#   asan              - 启用 AddressSanitizer
#   debug             - 调试模式 (Debug)
#   release           - 发布模式 (Release，默认)
#   -B <dir>, --build-dir <dir> - 指定构建目录
#   help              - 显示帮助信息

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_DIR/build"
PROJECT_NAME="cpp_profile"

# 默认编译器和选项
COMPILER=""
BUILD_TYPE="Release"
ENABLE_GPROF="OFF"
ENABLE_GCOV="OFF"
ENABLE_ASAN="OFF"
NEED_CLEAN="false"

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]..."
    echo ""
    echo "编译选项:"
    echo "  b, build           编译项目"
    echo "  r, run            运行程序"
    echo "  c, clean          清空build目录（优先执行）"
    echo ""
    echo "编译器选择:"
    echo "  gcc               使用 GCC 编译器"
    echo "  clang             使用 Clang 编译器"
    echo ""
    echo "构建模式:"
    echo "  debug             调试模式 (Debug)"
    echo "  release           发布模式 (Release，默认)"
    echo ""
    echo "功能开关:"
    echo "  gprof             启用 gprof 性能分析"
    echo "  gcov              启用 gcov 代码覆盖率"
    echo "  asan              启用 AddressSanitizer"
    echo ""
    echo "支持多个参数组合使用:"
    echo "  $0 gcc debug build run       # GCC + Debug + 编译运行"
    echo "  $0 -B ./mybuild clean build  # 指定构建目录并清空编译"
    echo "  $0 clean gcc gcov build      # 先清空，再用GCC编译带覆盖率"
    echo ""
    echo "示例:"
    echo "  $0 build                     # 编译项目（默认 Release）"
    echo "  $0 debug build               # Debug 模式编译"
    echo "  $0 clean build               # 先清空再编译"
    echo "  $0 -B build_gcc gcc build    # 使用指定目录编译"
}

# 编译项目
compile_project() {
    echo "=========================================="
    echo "          编译项目"
    echo "=========================================="
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    echo ""
    echo "正在配置 CMake..."
    
    # 构建 CMake 参数
    CMAKE_ARGS=""
    
    # 设置编译器
    if [ -n "$COMPILER" ]; then
        if [ "$COMPILER" = "gcc" ]; then
            echo "使用 GCC 编译器"
            CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++"
        elif [ "$COMPILER" = "clang" ]; then
            echo "使用 Clang 编译器"
            CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++"
        fi
    else
        echo "使用默认编译器"
    fi
    
    # 设置构建模式
    echo "构建模式: $BUILD_TYPE"
    CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_BUILD_TYPE=$BUILD_TYPE"
    
    # 设置功能选项
    if [ "$ENABLE_GPROF" = "ON" ]; then
        echo "启用 gprof 性能分析"
        CMAKE_ARGS="$CMAKE_ARGS -DENABLE_GPROF=ON"
    fi
    
    if [ "$ENABLE_GCOV" = "ON" ]; then
        echo "启用 gcov 代码覆盖率"
        CMAKE_ARGS="$CMAKE_ARGS -DENABLE_GCOV=ON"
    fi
    
    if [ "$ENABLE_ASAN" = "ON" ]; then
        echo "启用 AddressSanitizer"
        CMAKE_ARGS="$CMAKE_ARGS -DENABLE_ASAN=ON"
    fi
    
    # 执行 CMake
    cmake .. $CMAKE_ARGS
    
    echo ""
    echo "正在编译..."
    make -j$(nproc)
    
    echo ""
    echo "编译完成！"
}

# 运行程序
run_program() {
    echo "=========================================="
    echo "          运行程序"
    echo "=========================================="
    
    if [ ! -f "$BUILD_DIR/$PROJECT_NAME" ]; then
        echo "错误: 程序未编译！请先运行 make"
        exit 1
    fi
    
    cd "$BUILD_DIR"
    echo ""
    ./"$PROJECT_NAME"
}

# 清空build目录
clean_build() {
    echo "=========================================="
    echo "          清空build目录"
    echo "=========================================="
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        echo "已清空 build 目录: $BUILD_DIR"
    else
        echo "build 目录不存在: $BUILD_DIR"
    fi
}

# 主程序
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        gcc|clang)
            COMPILER="$arg"
            ;;
        debug|release)
            BUILD_TYPE=$(echo "$arg" | tr '[:lower:]' '[:upper:]')
            ;;
        gprof)
            ENABLE_GPROF="ON"
            ;;
        gcov)
            ENABLE_GCOV="ON"
            ;;
        asan)
            ENABLE_ASAN="ON"
            ;;
        c|clean)
            NEED_CLEAN="true"
            ;;
        help)
            show_help
            exit 0
            ;;
    esac
    i=$((i+1))
done

# 先执行 clean（如果需要）
if [ "$NEED_CLEAN" = "true" ]; then
    clean_build
    # 清空后需要重新创建目录用于编译
    mkdir -p "$BUILD_DIR"
fi

# 执行其他动作（按参数顺序）
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        b|build)
            compile_project
            ;;
        r|run)
            run_program
            ;;
        c|clean)
            # 已经执行过了
            ;;
        help)
            # 已经处理过了
            ;;
        gcc|clang|debug|release|gprof|gcov|asan)
            # 配置参数已在上一步处理
            ;;
        *)
            echo "错误: 未知选项 '$arg'"
            echo ""
            show_help
            exit 1
            ;;
    esac
    i=$((i+1))
done
