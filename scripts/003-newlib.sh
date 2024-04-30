#!/bin/bash
# 003-newlib.sh by pspdev developers
if [[ $(uname) == "Darwin" ]]; then
export CPATH="$(brew --prefix)/include"
export LIBRARY_PATH="$(brew --prefix)/lib" 
TARG_XTRA_OPTS="CC=gcc-13 CXX=g++-13"
else
TARG_XTRA_OPTS=""
fi

## Exit with code 1 when any command executed returns a non-zero exit code.
onerr()
{
  exit 1;
}
trap onerr ERR

## Read information from the configuration file.
source "$(dirname "$0")/../config/psptoolchain-allegrex-config.sh"

## Download the source code.
REPO_URL="$PSPTOOLCHAIN_ALLEGREX_NEWLIB_REPO_URL"
REPO_REF="$PSPTOOLCHAIN_ALLEGREX_NEWLIB_DEFAULT_REPO_REF"
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


## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

# Create and enter the toolchain/build directory
rm -rf build-$TARGET && mkdir build-$TARGET && cd build-$TARGET || { exit 1; }

# Configure the build.
../configure \
	--prefix="$PSPDEV" \
	--target="$TARGET" \
	--enable-newlib-retargetable-locking \
	--enable-newlib-multithread \
	--enable-newlib-io-c99-formats \
	$TARG_XTRA_OPTS || { exit 1; }

## Compile and install.
make --quiet -j $PROC_NR clean          || { exit 1; }
make --quiet -j $PROC_NR all            || { exit 1; }
make --quiet -j $PROC_NR install-strip  || { exit 1; }
make --quiet -j $PROC_NR clean          || { exit 1; }
