#!/bin/bash
# 001-binutils.sh by pspdev developers

## Exit with code 1 when any command executed returns a non-zero exit code.
onerr()
{
  exit 1;
}
trap onerr ERR

if [[ "$(uname)" == "Darwin" ]]; then
#Darwin is special.
export CPATH="$(brew --prefix)/include":$(xcrun --sdk macosx --show-sdk-path)/usr/include:$CPATH
export LIBRARY_PATH="$(brew --prefix)/lib":$(xcrun --sdk macosx --show-sdk-path)/usr/lib:$LIBRARY_PATH #This may break Ubuntu
fi

## Read information from the configuration file.
source "$(dirname "$0")/../config/psptoolchain-allegrex-config.sh"

## Download the source code.
REPO_URL="$PSPTOOLCHAIN_ALLEGREX_BINUTILS_REPO_URL"
REPO_REF="$PSPTOOLCHAIN_ALLEGREX_BINUTILS_DEFAULT_REPO_REF"
REPO_FOLDER="$(s="$REPO_URL"; s=${s##*/}; printf "%s" "${s%.*}")"

# Checking if a specific Git reference has been passed in parameter $1
if test -n "$1"; then
  REPO_REF="$1"
  printf 'Using specified repo reference %s\n' "$REPO_REF"
fi

if test ! -d "$REPO_FOLDER"; then
  git clone --depth 1 -b "$REPO_REF" "$REPO_URL" "$REPO_FOLDER"
else
  git -C "$REPO_FOLDER" fetch origin
  git -C "$REPO_FOLDER" reset --hard "origin/$REPO_REF"
  git -C "$REPO_FOLDER" checkout "$REPO_REF"
fi

cd "$REPO_FOLDER"


TARGET="psp"

# Avoid using clang
if [[ $(uname) == "Darwin" ]]; then 
TARG_XTRA_OPTS="CC=gcc-13 CXX=g++-13"
else
TARG_XTRA_OPTS=""
fi

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Create and enter the toolchain/build directory
rm -rf build-$TARGET && mkdir build-$TARGET && cd build-$TARGET || { exit 1; }

## Build GDB without python support when built with a GitHub Action
## This makes the pre-build executable work on more systems
if [ -n "$CI" ]; then
  WITH_PYTHON="no"
else
  WITH_PYTHON="no"
fi

## Configure the build.
../configure \
  --quiet \
  --prefix="$PSPDEV" \
  --target="$TARGET" \
  --enable-plugins \
  --disable-initfini-array \
  --with-python="$WITH_PYTHON" \
  --disable-werror \
  $TARG_XTRA_OPTS || { exit 1; }

## Compile and install.
make --quiet -j $PROC_NR clean || { exit 1; }
make --quiet -j $PROC_NR || { exit 1; }
make --quiet -j $PROC_NR install-strip || { exit 1; }
make --quiet -j $PROC_NR clean || { exit 1; }
