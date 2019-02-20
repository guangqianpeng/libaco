cmake_minimum_required(VERSION 2.6)

project(libaco C ASM)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

set(OUTPUT_SUFFIX "")

option(ACO_BUILD_M32 "Build with i386 binary output" OFF)
option(ACO_CONFIG_SHARE_FPU_MXCSR_ENV "Build libaco with share fpu and mxcsr environment" OFF)
option(ACO_USE_VALGRIND "Build libaco with valgrind" OFF)

set(C_FLAGS -g -Wall -Werror)
 
if(ACO_BUILD_M32)
    list(APPEND C_FLAGS "-m32")
    set(OUTPUT_SUFFIX ${OUTPUT_SUFFIX}.m32)
endif()

if(ACO_USE_VALGRIND)
    list(APPEND C_FLAGS "-DACO_USE_VALGRIND")
    set(OUTPUT_SUFFIX ${OUTPUT_SUFFIX}.valgrind)
else()
    set(OUTPUT_SUFFIX ${OUTPUT_SUFFIX}.no_valgrind)  
endif()

if(ACO_CONFIG_SHARE_FPU_MXCSR_ENV)
    list(APPEND C_FLAGS "-DACO_CONFIG_SHARE_FPU_MXCSR_ENV")
    set(OUTPUT_SUFFIX ${OUTPUT_SUFFIX}.shareFPUenv)
else()
    set(OUTPUT_SUFFIX ${OUTPUT_SUFFIX}.standaloneFPUenv)  
endif()

string(REPLACE ";" " " CMAKE_C_FLAGS "${C_FLAGS}")

# use the same flags for acosw.S
set(CMAKE_ASM_FLAGS ${CMAKE_C_FLAGS})

set(CMAKE_C_FLAGS_DEBUG "-O0")
set(CMAKE_C_FLAGS_RELEASE "-O2 -DNDEBUG")
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/output)

string(TOUPPER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
message(STATUS "C_FLAGS = " ${CMAKE_C_FLAGS} " " ${CMAKE_C_FLAGS_${BUILD_TYPE}})

message(STATUS "OUTPUT_SUFFIX = " ${OUTPUT_SUFFIX})
message(STATUS "OUTPUT_DIR = " ${EXECUTABLE_OUTPUT_PATH})

# Macro for executable
macro(add_c_target TARGET)
    set(FULL_TARGET ${TARGET}.${OUTPUT_SUFFIX})
    add_executable(${FULL_TARGET} acosw.S aco.c ${TARGET}.c)
    if(${ARGC} GREATER 1)
        target_link_libraries("${FULL_TARGET}" ${ARGN})
    endif()
endmacro(add_c_target)

add_c_target(test_aco_tutorial_0)
add_c_target(test_aco_tutorial_1)
add_c_target(test_aco_tutorial_2)
add_c_target(test_aco_tutorial_3 pthread) # the second arg is optional
add_c_target(test_aco_tutorial_4)
add_c_target(test_aco_tutorial_5)
add_c_target(test_aco_tutorial_6)
add_c_target(test_aco_synopsis)
add_c_target(test_aco_benchmark)
