# Copyright 2018 Sen Han <00hnes@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SOURCE_DIR=`pwd`
BUILD_DIR=${SOURCE_DIR}/build

gl_opt_no_m32=""
gl_opt_no_valgrind=""

cmd_m32=""
cmd_share_fpu_mxcsr_env=""
cmd_use_valgrind=""

gl_trap_str=""

function error(){
    >&2 echo "error: $*"
}

function assert(){
    if [ "0" -ne "$?" ]
    then
        error "$0:""$*"
        exit 1
    fi
}

function tra(){
    gl_trap_str="$gl_trap_str""$1"
    trap "$gl_trap_str exit 1;" INT
    assert "$LINENO:trap failed:$gl_trap_str:$1"
}

function untra(){
    trap - INT
    assert "$LINENO:untrap failed:$gl_trap_str:$1"
}

function build_f(){
    declare build_cmd
    declare skip_flag

    build_cmd="cmake $ACO_EXTRA_CFLAGS $SOURCE_DIR"

    skip_flag=""
    if [ "$gl_opt_no_m32" ]
    then
        if [ "$cmd_m32" ]
        then
            skip_flag="true"
        fi
    fi
    if [ "$gl_opt_no_valgrind" ]
    then
        if [ "$cmd_use_valgrind" ]
        then
            skip_flag="true"
        fi
    fi
    if [ "$skip_flag" ]
    then
        echo "skip    $build_cmd"
    else
        echo "        $build_cmd"
        $build_cmd && make
        assert "build fail"
    fi
    assert "exit"
}

function usage() {
    echo "Usage: $0 [-o <no-m32|no-valgrind>] [-h]" 1>&2
    echo '''
Example:
    # clean build directory
    bash make.sh clean
    # default build
    bash make.sh
    # build without the i386 binary output
    bash make.sh -o no-m32
    # build without the valgrind supported binary output
    bash make.sh -o no-valgrind
    # build without the valgrind supported and i386 binary output
    bash make.sh -o no-valgrind -o no-m32
''' 1>&2
}

gl_opt_value=""
while getopts ":o:h" o; do
    case "${o}" in
        o)
            gl_opt_value=${OPTARG}
            if [ "$gl_opt_value" = "no-m32" ]
            then
                gl_opt_no_m32="true"
            elif [ "$gl_opt_value" = "no-valgrind" ]
            then
                gl_opt_no_valgrind="true"
            else
                usage
                error unknow option value of '-o'
                exit 1
            fi
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            error unknow option
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

subcommand=$1; shift
case "$subcommand" in
    clean)
        rm -rf $BUILD_DIR
        exit 0
        ;;
esac

#echo "o = $gl_opt_value"
#echo "gl_opt_no_valgrind:$gl_opt_no_valgrind"
#echo "gl_opt_no_m32:$gl_opt_no_m32"

tra "echo;echo build has been interrupted"

mkdir -p $BUILD_DIR && cd $BUILD_DIR

# the matrix of the build config for later testing
# -m32 -DACO_CONFIG_SHARE_FPU_MXCSR_ENV -DACO_USE_VALGRIND
# 0 0 0
cmd_m32="" cmd_share_fpu_mxcsr_env="" cmd_use_valgrind=""
ACO_EXTRA_CFLAGS="-DACO_BUILD_M32=OFF -DACO_CONFIG_SHARE_FPU_MXCSR_ENV=OFF -DACO_USE_VALGRIND=OFF" build_f
# 0 0 1
cmd_m32="" cmd_share_fpu_mxcsr_env="" cmd_use_valgrind="true"
ACO_EXTRA_CFLAGS="-DACO_BUILD_M32=OFF -DACO_CONFIG_SHARE_FPU_MXCSR_ENV=OFF -DACO_USE_VALGRIND=ON" build_f
# 0 1 0
cmd_m32="" cmd_share_fpu_mxcsr_env="true" cmd_use_valgrind=""
ACO_EXTRA_CFLAGS="-DACO_BUILD_M32=OFF -DACO_CONFIG_SHARE_FPU_MXCSR_ENV=ON -DACO_USE_VALGRIND=OFF" build_f

# 0 1 1
cmd_m32="" cmd_share_fpu_mxcsr_env="true" cmd_use_valgrind="true"
ACO_EXTRA_CFLAGS="-DACO_BUILD_M32=OFF -DACO_CONFIG_SHARE_FPU_MXCSR_ENV=ON -DACO_USE_VALGRIND=ON" build_f

# 1 0 0
cmd_m32="true" cmd_share_fpu_mxcsr_env="" cmd_use_valgrind=""
ACO_EXTRA_CFLAGS="-DACO_BUILD_M32=ON -DACO_CONFIG_SHARE_FPU_MXCSR_ENV=OFF -DACO_USE_VALGRIND=OFF" build_f

# 1 0 1
cmd_m32="true" cmd_share_fpu_mxcsr_env="" cmd_use_valgrind="true"
ACO_EXTRA_CFLAGS="-DACO_BUILD_M32=ON -DACO_CONFIG_SHARE_FPU_MXCSR_ENV=OFF -DACO_USE_VALGRIND=ON" build_f

# 1 1 0
cmd_m32="true" cmd_share_fpu_mxcsr_env="true" cmd_use_valgrind=""
ACO_EXTRA_CFLAGS="-DACO_BUILD_M32=ON -DACO_CONFIG_SHARE_FPU_MXCSR_ENV=ON -DACO_USE_VALGRIND=OFF" build_f

# 1 1 1
cmd_m32="true" cmd_share_fpu_mxcsr_env="true" cmd_use_valgrind="true"
ACO_EXTRA_CFLAGS="-DACO_BUILD_M32=ON -DACO_CONFIG_SHARE_FPU_MXCSR_ENV=ON -DACO_USE_VALGRIND=ON" build_f
