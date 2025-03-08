#! /bin/bash

set -e

if test -z "${RISCV_PREFIX}" -o -z "${RISCV_TOOLCHAIN_ROOT}" -o -z "${RISCV_TOOLCHAIN_ROOT}"; then
  echo "Run this script in docker container: docker run -it --rm --name crossriscv-dyninst -v $(pwd):/dyninst -w /dyninst crossriscv-dyninst"
  exit 1
fi

function usage {
  echo "Usage: $0 src [-d] [-j] [-c] [-t] [-h] [-v] [-B] [-P]"
}

function show_help {
  usage
  echo "   src      Source directory"
  echo "    -d      Install directory"
  echo "    -j      Number of CMake build jobs (default: 1)"
  echo "    -c      CMake arguments (must be quoted: -c \"-D1 -D2\")"
  echo "    -t      Run tests"
  echo "    -v      Verbose outputs"
  echo "    -B      Build directory (default: /tmp/XXXXXX)"
  echo "    -P      Do not delete build directory after building"
}

src_dir=$1; shift
dest_dir="${RISCV_PREFIX}"
num_jobs=16
cmake_args=
verbose=
build_dir=$(mktemp -d "/tmp/XXXXXX")
persist_build_dir="N"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -j) num_jobs="$2"; shift 2;;
    -j*) num_jobs="${1#-j}"; shift;;
    -c) cmake_args="$2"; shift 2;;
    -h) show_help; exit;;
    -v) verbose="--verbose"; shift;;
    -B) rmdir ${build_dir}; build_dir="$2"; shift 2;;
    -P) persist_build_dir="Y"; shift;;
    -d) dest_dir="$2"; shift 2;;
     *) echo "Unknown arg '$1'"; exit;;
  esac
done

mkdir -p ${dest_dir}

cmake -S ${src_dir} -B ${build_dir} -DCMAKE_INSTALL_PREFIX=${dest_dir} -DCMAKE_TOOLCHAIN_FILE=${RISCV_TOOLCHAIN_ROOT}/riscv64.cmake -DCMAKE_FIND_ROOT_PATH=${RISCV_TOOLCHAIN_ROOT} -DDYNINST_FORCE_CROSS_COMPILE_ARCH=On -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=DEBUG -DUSE_OpenMP=Off -DDYNINST_ENABLE_TESTS=On ${cmake_args}
cmake --build ${build_dir} --parallel ${num_jobs} ${verbose}

cmake --install ${build_dir}

if test "${persist_build_dir}" = "N"; then
  rm -rf ${build_dir}
fi

# Build examples repository:
# cmake -S examples -B build_examples -DDyninst_DIR=${dest_dir}/lib/cmake/Dyninst -DCMAKE_TOOLCHAIN_FILE=${RISCV_TOOLCHAIN_ROOT}/riscv64.cmake -DCMAKE_FIND_ROOT_PATH=${RISCV_TOOLCHAIN_ROOT}
# cmake --build build_examples -j 16