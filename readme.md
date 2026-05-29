# C++ Performance Profiling Demo

A comprehensive C++ project for demonstrating various performance profiling and analysis tools.

## Prerequisites

### Base Environment

| Tool | Version | Installation |
|------|---------|--------------|
| CMake | >= 3.10 | `sudo apt install cmake` |
| GCC/G++ | >= 9 | `sudo apt install build-essential` |
| Clang/LLVM | >= 12 | `sudo apt install clang llvm` |
| Python3 | >= 3.6 | `sudo apt install python3 python3-pip` |

### Profiling Tools

```bash
# Ubuntu/Debian installation
sudo apt-get update
sudo apt-get install \
    linux-tools-common linux-tools-generic \
    valgrind kcachegrind \
    lcov graphviz \
    git

# Python packages
pip3 install gprof2dot
```

| Tool | Purpose |
|------|---------|
| **perf** | Linux kernel profiling, CPU cycles, cache analysis |
| **Valgrind** | Memory checking, cache profiling, callgraph |
| **gprof** | Function-level profiling with callgraphs |
| **gcov/lcov** | Code coverage analysis |
| **FlameGraph** | Visualization of stack traces |
| **gprof2dot** | Convert profiling data to DOT graphs |
| **graphviz** | Graph visualization |

### Optional Tools

```bash
# AddressSanitizer - built into GCC/Clang, no separate install needed
# Just enable with ENABLE_ASAN=ON
```

## Project Structure

```
cpp_project_profile_demo/
├── CMakeLists.txt          # Build configuration
├── main.cpp                # Source code
├── build.sh                # Main build script
├── scripts/
│   ├── perf_analyze.sh     # Linux perf analysis
│   ├── perf_analyzer.py    # Custom perf HTML report generator
│   ├── gprof_analyze.sh    # gprof analysis
│   ├── gcov_coverage.sh    # Code coverage analysis
│   ├── valgrind_analyze.sh # Valgrind analysis suite
│   └── flamegraph.sh       # FlameGraph generation
├── .clang-format           # Code formatting rules
├── .clang-tidy             # Static analysis rules
└── .gitignore              # Git ignore rules
```

## Quick Start

### Build and Run

```bash
# Simple build
./build.sh build

# Build and run
./build.sh build run

# Clean, build and run
./build.sh clean build run
```

### Common Build Options

```bash
# Compiler selection
./build.sh gcc build          # Use GCC
./build.sh clang build        # Use Clang

# Build type
./build.sh debug build        # Debug mode
./build.sh release build      # Release mode (default)

# Enable profiling features
./build.sh gprof build        # Enable gprof
./build.sh gcov build         # Enable code coverage
./build.sh asan build         # Enable AddressSanitizer

# Custom build directory
./build.sh -B ./mybuild build

# Combine options
./build.sh clean gcc debug gcov build run
```

## Profiling Scripts

### 1. `build.sh` - Main Build Script

Handles compilation with various profiling options.

```bash
# Show help
./build.sh help

# Common combinations
./build.sh clean build run                # Clean, build, run
./build.sh gcc debug asan build run       # GCC + Debug + ASAN
./build.sh clang gcov build run           # Clang + Coverage
```

**Options:**
- `b, build` - Build project
- `r, run` - Run executable
- `c, clean` - Clean build directory
- `gcc/clang` - Select compiler
- `debug/release` - Build type
- `gprof` - Enable gprof profiling
- `gcov` - Enable code coverage
- `asan` - Enable AddressSanitizer
- `-B <dir>` - Specify build directory

---

### 2. `scripts/perf_analyze.sh` - Linux Perf Analysis

Uses Linux `perf` for detailed CPU performance analysis.

```bash
bash scripts/perf_analyze.sh
```

**Reports generated in `.build_perf_report/report/`:**
- `perf_stat.txt` - Basic performance statistics
- `perf_source_report.txt` - Source-level profiling
- `perf_annotate.txt` - Line-by-line execution time
- `perf_cycles_report.txt` - CPU cycle analysis
- `perf_cache.txt` - Cache hit/miss analysis
- `perf_branch.txt` - Branch prediction analysis
- `perf_faults.txt` - Page fault analysis

---

### 3. `scripts/perf_analyzer.py` - Custom HTML Report

Generates lcov-style HTML reports from perf data, showing execution time per line of source code.

```bash
python3 scripts/perf_analyzer.py \
    .build_perf_report/report/perf_source_report.txt \
    $(pwd) \
    .build_perf_report/report/html
```

**Output:** HTML files in the specified output directory with:
- Index page showing function-level performance
- Source code files annotated with execution percentages
- Color-coded hotspots (Critical: >=5%, Hot: >=1%)

---

### 4. `scripts/gprof_analyze.sh` - gprof Analysis

Uses gprof for function-level profiling with callgraph visualization.

```bash
bash scripts/gprof_analyze.sh
```

**Reports generated in `.build_gprof_report/report/`:**
- `gprof_report.txt` - Text profiling report
- `callgraph.dot` - DOT format callgraph
- `callgraph.png` - PNG callgraph image

---

### 5. `scripts/gcov_coverage.sh` - Code Coverage

Generates code coverage reports showing which lines were executed.

```bash
bash scripts/gcov_coverage.sh
```

**Reports generated in `.build_gcov_report/report/`:**
- Text coverage files (`.gcov`)
- HTML report if `lcov` is installed (in `html/` subdirectory)

---

### 6. `scripts/valgrind_analyze.sh` - Valgrind Suite

Comprehensive memory and performance analysis using Valgrind.

```bash
bash scripts/valgrind_analyze.sh
```

**Reports generated in `.build_valgrind_report/report/`:**
- `valgrind_memcheck.txt` - Memory error detection (leaks, use-after-free)
- `cachegrind_report.txt` - Cache profiling
- `callgrind.out` - Call graph data (view with `kcachegrind`)
- `massif_report.txt` - Heap memory usage analysis

---

### 7. `scripts/flamegraph.sh` - Flame Graphs

Generates interactive flame graphs for visualizing CPU time.

```bash
bash scripts/flamegraph.sh oncpu    # On-CPU flame graph
bash scripts/flamegraph.sh offcpu   # Off-CPU flame graph
bash scripts/flamegraph.sh mem      # Memory allocation flame graph
```

**Output:** SVG flame graphs in `.build_flamegraph_report/report/`

## Code Quality Tools

### Format with clang-format

```bash
clang-format -i main.cpp
```

### Static analysis with clang-tidy

```bash
clang-tidy main.cpp -- -std=c++17
```

### Or integrate with CMake

Add to your CMakeLists.txt:
```cmake
set(CMAKE_CXX_CLANG_TIDY clang-tidy -checks=-*,clang-analyzer-*,performance-*,readability-*)
```

## Example Workflow

```bash
# 1. Basic build and test
./build.sh clean build run

# 2. Check for memory errors
bash scripts/valgrind_analyze.sh

# 3. Profile CPU performance
bash scripts/perf_analyze.sh

# 4. Generate HTML report
python3 scripts/perf_analyzer.py \
    .build_perf_report/report/perf_source_report.txt \
    $(pwd) \
    .build_perf_report/report/html

# 5. Generate flame graph
bash scripts/flamegraph.sh oncpu

# 6. Check code coverage
bash scripts/gcov_coverage.sh
```

## License

MIT License
