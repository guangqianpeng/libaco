cmake_minimum_required(VERSION 2.6)

project(libaco CXX C ASM)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

set(OUTPUT_SUFFIX "")

option(ACO_BUILD_M32 "Build with i386 binary output" OFF)
option(ACO_CONFIG_SHARE_FPU_MXCSR_ENV "Build libaco with share fpu and mxcsr environment" OFF)
option(ACO_USE_VALGRIND "Build libaco with valgrind" OFF)

macro(add_cxx_flags)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARGV}")
endmacro(add_cxx_flags)
macro(add_c_flags)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ARGV}")
endmacro(add_c_flags)
macro(add_asm_flags)
    set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} ${ARGV}")
endmacro(add_asm_flags)
macro(add_flags)
    add_cxx_flags(${ARGV})
    add_c_flags(${ARGV})
    add_asm_flags(${ARGV})
endmacro(add_flags)

add_flags("-g -Wall -Werror -fno-omit-frame-pointer")
add_cxx_flags("-std=c++11")

if(ACO_BUILD_M32)
    add_flags("-m32")
    set(OUTPUT_SUFFIX ${OUTPUT_SUFFIX}.m32)
endif()

if(ACO_USE_VALGRIND)
    add_flags("-DACO_USE_VALGRIND")
    set(OUTPUT_SUFFIX ${OUTPUT_SUFFIX}.valgrind)
else()
    set(OUTPUT_SUFFIX ${OUTPUT_SUFFIX}.no_valgrind)  
endif()

if(ACO_CONFIG_SHARE_FPU_MXCSR_ENV)
    add_flags("-DACO_CONFIG_SHARE_FPU_MXCSR_ENV")
    set(OUTPUT_SUFFIX ${OUTPUT_SUFFIX}.shareFPUenv)
else()
    set(OUTPUT_SUFFIX ${OUTPUT_SUFFIX}.standaloneFPUenv)  
endif()

# set(CMAKE_C_FLAGS_DEBUG "-O0")
# set(CMAKE_C_FLAGS_RELEASE "-O2 -DNDEBUG")
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/output)

string(TOUPPER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
message(STATUS "CXX_FLAGS = " ${CMAKE_CXX_FLAGS} " " ${CMAKE_CXX_FLAGS_${BUILD_TYPE}})
message(STATUS "C_FLAGS = " ${CMAKE_C_FLAGS} " " ${CMAKE_C_FLAGS_${BUILD_TYPE}})
message(STATUS "ASM_FLAGS = " ${CMAKE_ASM_FLAGS} " " ${CMAKE_ASM_FLAGS_${BUILD_TYPE}})

message(STATUS "OUTPUT_SUFFIX = " ${OUTPUT_SUFFIX})
message(STATUS "OUTPUT_DIR = " ${EXECUTABLE_OUTPUT_PATH})

# Macro for executable
macro(add_target TARGET SUFFIX)
    set(FULL_TARGET ${TARGET}.${OUTPUT_SUFFIX})
    add_executable(${FULL_TARGET} acosw.S aco.c ${TARGET}.${SUFFIX})
    if(${ARGC} GREATER 2)
        target_link_libraries("${FULL_TARGET}" ${ARGN})
    endif()
endmacro(add_target)

# Macro for executable
macro(add_c_target TARGET)
    add_target(${TARGET} "c" ${ARGN})
endmacro(add_c_target)

macro(add_cc_target TARGET)
    add_target(${TARGET} "cc" ${ARGN})
endmacro(add_cc_target)

macro(add_cxx_target TARGET)
    add_target(${TARGET} "cpp" ${ARGN})
endmacro(add_cxx_target)

# add_c_target(test_aco_tutorial_0)
# add_c_target(test_aco_tutorial_1)
# add_c_target(test_aco_tutorial_2)
# add_c_target(test_aco_tutorial_3 pthread) # the second arg is optional
# add_c_target(test_aco_tutorial_4)
# add_c_target(test_aco_tutorial_5)
# add_c_target(test_aco_tutorial_6)
add_c_target(test_aco_synopsis)
add_c_target(test_aco_benchmark)

find_package(benchmark)
if(benchmark_FOUND)
    message(STATUS "found google benchmark")
    message(STATUS "benchmark_Dir = " ${benchmark_DIR})
    add_cc_target(test_aco_benchmark2 benchmark pthread tcmalloc)
endif()
