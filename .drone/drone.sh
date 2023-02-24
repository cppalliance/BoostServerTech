#!/bin/bash

#
# Copyright (c) 2023 Alan de Freitas (alandefreitas@gmail.com)
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
# Official repository: https://github.com/CppAlliance/BoostServerTech
#

set -xe

echo "==================================> ENVIRONMENT"

export TRAVIS_BUILD_DIR=$(pwd)
export DRONE_BUILD_DIR=$(pwd)
export TRAVIS_BRANCH=$DRONE_BRANCH
export TRAVIS_EVENT_TYPE=$DRONE_BUILD_EVENT
export VCS_COMMIT_ID=$DRONE_COMMIT
export GIT_COMMIT=$DRONE_COMMIT
export REPO_NAME=$DRONE_REPO
export USER=$(whoami)
export CC=${CC:-gcc}
export PATH=~/.local/bin:/usr/local/bin:$PATH

echo "==================================> FINAL ENVIRONMENT"

printenv

echo "==================================> CURRENT DIR"

ls

if [ "$DRONE_JOB_BUILDTYPE" == "boost" ]; then

  echo '==================================> VCPKG INSTALL'

  # Triplets
  export CI_ARCH=$(uname -m)
  if [ "$TRAVIS_OS_NAME" == "osx" ]; then
    if [ "$CI_ARCH" == "x86_64" ]; then
      export VCPKG_TRIPLET=:x64-osx
    elif [ "$CI_ARCH" == "arm64" ]; then
      export VCPKG_TRIPLET=:arm64-osx
    fi
  elif [ "$TRAVIS_OS_NAME" == "linux" ]; then
    if [ "$CI_ARCH" == "x86_64" ]; then
      export VCPKG_TRIPLET=:x64-linux
    elif [ "$CI_ARCH" == "arm64" ]; then
      export VCPKG_TRIPLET=:arm64-linux
    fi
  elif [ "$TRAVIS_OS_NAME" == "freebsd" ]; then
    if [ "$CI_ARCH" == "x86_64" ]; then
      export VCPKG_TRIPLET=:x64-freebsd
    elif [ "$CI_ARCH" == "arm64" ]; then
      export VCPKG_TRIPLET=:arm64-freebsd
    fi
  fi

  # System deps
  if [ "$TRAVIS_OS_NAME" == "osx" ]; then
    # https://github.com/microsoft/vcpkg#installing-macos-developer-tools
    xcode-select --install
    export PATH=/opt/homebrew/bin:$PATH
  elif [ "$TRAVIS_OS_NAME" == "linux" ]; then
    # https://github.com/microsoft/vcpkg#installing-linux-developer-tools
    sudo apt-get install -y build-essential tar curl zip unzip
    apt install linux-libc-dev
    if [ "$CI_ARCH" == "arm64" ]; then
      apt-get install -y ninja-build
      export VCPKG_FORCE_SYSTEM_BINARIES=1
    elif [ "$CI_ARCH" == "aarch64" ]; then
      apt-get install -y ninja-build
      export VCPKG_FORCE_SYSTEM_BINARIES=1
    elif [ "$CI_ARCH" == "s390x" ]; then
      apt-get install -y ninja-build
      export VCPKG_FORCE_SYSTEM_BINARIES=1
    fi
  elif [ "$TRAVIS_OS_NAME" == "freebsd" ]; then
    pkg install curl zip unzip tar
  fi

  # vcpkg install
  pwd
  git clone https://github.com/microsoft/vcpkg.git -b master vcpkg
  ./vcpkg/bootstrap-vcpkg.sh
  cd vcpkg
  ./vcpkg install fmt$VCPKG_TRIPLET
  ./vcpkg install openssl$VCPKG_TRIPLET
  ./vcpkg install zlib$VCPKG_TRIPLET
  cd ..

  echo '==================================> CLONE BOOST'

  pwd
  git clone https://github.com/boostorg/boost.git -b $TRAVIS_BRANCH boost
  cd boost
  # git submodule update --init --recursive

  echo '==================================> PATCH BOOST'

  pwd
  cd libs
  git clone https://github.com/CppAlliance/buffers.git -b $TRAVIS_BRANCH buffers
  git clone https://github.com/CppAlliance/http_proto.git -b $TRAVIS_BRANCH http_proto
  git clone https://github.com/CppAlliance/http_io.git -b $TRAVIS_BRANCH http_io
  cd ..

  echo '==================================> BOOST SUBMODULES'

  if command -v python &> /dev/null; then
    python_executable="python"
  elif command -v python3 &> /dev/null; then
    python_executable="python3"
  elif command -v python2 &> /dev/null; then
    python_executable="python2"
  else
    echo "Please install Python!" >&2
    false
  fi

  pwd
  git submodule update -q --init tools/boostdep
  git submodule update -q --init libs/url
  $python_executable tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools --include source url
  $python_executable tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools --include source ../../../BoostServerTech
  cd ..

  echo '==================================> CMAKE'

  if [ -f "/proc/cpuinfo" ]; then
      CORES=$(grep -c ^processor /proc/cpuinfo)
  else
      CORES=$($python_executable -c 'import multiprocessing as mp; print(mp.cpu_count())')
  fi

  for CXXSTD in ${B2_CXXSTD//,/ }
  do
    echo "==================================> CMAKE + C++$CXXSTD"
    cmake -S . -B "build-$CXXSTD" -D CMAKE_BUILD_TYPE=Release -D CMAKE_TOOLCHAIN_FILE="vcpkg/scripts/buildsystems/vcpkg.cmake" -D BOOST_ROOT=boost -D CMAKE_CXX_STANDARD=$CXXSTD -D CMAKE_INSTALL_PREFIX=.local/usr/ -D CMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX
    cmake --build "build-$CXXSTD" --config Release -j $CORES
    cmake --install "build-$CXXSTD" --config Release --prefix prefix
  done

elif [ "$DRONE_JOB_BUILDTYPE" == "docs" ]; then

  echo '==================================> SCRIPT: docs'

elif [ "$DRONE_JOB_BUILDTYPE" == "codecov" ]; then

  echo '==================================> SCRIPT: codecov'

elif [ "$DRONE_JOB_BUILDTYPE" == "valgrind" ]; then

  echo '==================================> SCRIPT: valgrind'

elif [ "$DRONE_JOB_BUILDTYPE" == "standalone" ]; then

  echo '==================================> SCRIPT: standalone'

elif [ "$DRONE_JOB_BUILDTYPE" == "coverity" ]; then

  echo '==================================> SCRIPT: coverity'

elif [ "$DRONE_JOB_BUILDTYPE" == "cmake-superproject" ]; then

  echo '==================================> SCRIPT: cmake-superproject'

elif [ "$DRONE_JOB_BUILDTYPE" == "cmake-install" ]; then

  echo '==================================> SCRIPT: cmake-install'

fi

