cmake_minimum_required(VERSION 3.10)
project(cpp_profile)
# set(CMAKE_C_COMPILER "clang")
# set(CMAKE_CXX_COMPILER "clang++")


set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)



# 为 gprof 添加配置选项
option(ENABLE_GPROF "Enable gprof profiling" OFF)
if(ENABLE_GPROF)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pg")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pg")
endif()

# 为 gcov/gcovr 添加配置选项
option(ENABLE_GCOV "Enable gcov coverage" OFF)
if(ENABLE_GCOV)
    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        # Clang 使用 llvm-cov
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-instr-generate -fcoverage-mapping -O0 -g")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fprofile-instr-generate -fcoverage-mapping")
    else()
        # GCC 使用 gcov
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage -O0 -g")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
    endif()
endif()

# 为 AddressSanitizer 添加配置选项
option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
if(ENABLE_ASAN)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -g")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
endif()

# 收集源文件
set(SOURCES
    main.cpp
)

# 添加可执行文件
add_executable(${PROJECT_NAME} ${SOURCES})


# 打印配置信息
message(STATUS "CMAKE_CXX_FLAGS: ${CMAKE_CXX_FLAGS}")
message(STATUS "CMAKE_EXE_LINKER_FLAGS: ${CMAKE_EXE_LINKER_FLAGS}")
message(STATUS "Sources: ${SOURCES}")
