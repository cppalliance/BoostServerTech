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

if [ "$TRAVIS_BRANCH" == "master" ]; then
  BOOST_BRANCH=master
else
  BOOST_BRANCH=develop
fi

echo "==================================> FINAL ENVIRONMENT"

printenv

echo "==================================> CURRENT DIR"

ls

echo "==================================> CACHE HASHES"

# Common vars in cache keys
os_name=$(uname -s)
ci_os_name=$TRAVIS_OS_NAME
arch_name=$(uname -m)

# Calculate boost cache key
boost_hash=$(git ls-remote https://github.com/boostorg/boost.git $BOOST_BRANCH | awk '{ print $1 }')
os_name=$(uname -s)
boost_cache_key=$os_name-boost-$boost_hash
modules=url,../../../BoostServerTech
for module in ${modules//,/ }; do
  module_filename=${module##*/}
  boost_cache_key=$boost_cache_key-$module_filename
done
patches=https://github.com/CppAlliance/buffers.git,https://github.com/CppAlliance/http_proto.git,https://github.com/CppAlliance/http_io.git
for patch in ${patches//,/ }; do
  patch_hash=$(git ls-remote $patch $BOOST_BRANCH | awk '{ print $1 }')
  patch_filename=${patch##*/}
  boost_cache_key=$boost_cache_key-$patch_filename-$patch_hash
done
echo "boost_cache_key=$boost_cache_key"

# Calculate vcpkg cache key
vcpkg_hash="$(git ls-remote https://github.com/microsoft/vcpkg.git master | awk '{ print $1 }')"
if [ "$ci_os_name" == "osx" ]; then
  if [ "$arch_name" == "x86_64" ]; then
    triplet=x64-osx
    triplet_suffix=:$triplet
  elif [ "$arch_name" == "arm64" ]; then
    triplet=arm64-osx
    triplet_suffix=:$triplet
  fi
elif [ "$ci_os_name" == "linux" ]; then
  if [ "$arch_name" == "x86_64" ]; then
    triplet=x64-linux
    triplet_suffix=:$triplet
  elif [ "$arch_name" == "arm64" ]; then
    triplet=arm64-linux
    triplet_suffix=:$triplet
  fi
elif [ "$ci_os_name" == "freebsd" ]; then
  if [ "$arch_name" == "x86_64" ]; then
    triplet=x64-freebsd
    triplet_suffix=:$triplet
  elif [ "$arch_name" == "arm64" ]; then
    triplet=arm64-freebsd
    triplet_suffix=:$triplet
  fi
fi
vcpkg_cache_key=$os_name-$vcpkg_hash$triplet_suffix
vcpkg_packages=fmt,openssl,zlib
for package in ${vcpkg_packages//,/ }; do
  vcpkg_cache_key=$vcpkg_cache_key-$package
done
echo "vcpkg_cache_key=$vcpkg_cache_key"

if [ ! -d "cache" ]; then
  mkdir "cache"
  boost_cache_hit=false
  vcpkg_cache_hit=false
else
  # validate boost cache
  if [ -d "cache/boost" ]; then
    if [ -f "cache/boost_cache_key.txt" ]; then
      boost_cached_key=$(cat cache/boost_cache_key.txt)
      if [ "$boost_cache_key" == "$boost_cached_key" ]; then
        boost_cache_hit=true
      else
        echo "boost_cached_key=$boost_cached_key (expected $boost_cache_key)"
        rm -rf "cache/boost"
        boost_cache_hit=false
      fi
    else
      echo "Logic error: cache/boost stored without boost_cache_key.txt"
      rm -rf "cache/boost"
      boost_cache_hit=false
    fi
  else
    boost_cache_hit=false
  fi

  # validate vcpkg cache
  if [ -d "cache/vcpkg" ]; then
    if [ -f "cache/vcpkg_cache_key.txt" ]; then
      vcpkg_cached_key=$(cat cache/vcpkg_cache_key.txt)
      if [ "$vcpkg_cache_key" == "$vcpkg_cached_key" ]; then
        vcpkg_cache_hit=true
      else
        echo "vcpkg_cached_key=$vcpkg_cached_key (expected $vcpkg_cache_key)"
        rm -rf "cache/vcpkg"
        vcpkg_cache_hit=false
      fi
    else
      echo "Logic error: cache/vcpkg stored without vcpkg_cache_key.txt"
      rm -rf "cache/vcpkg"
      vcpkg_cache_hit=false
    fi
  else
    vcpkg_cache_hit=false
  fi
fi

echo '==================================> APT INSTALL'

# Install vcpkg system dependencies
if [ "$TRAVIS_OS_NAME" == "osx" ]; then
  # https://github.com/microsoft/vcpkg#installing-macos-developer-tools
  xcode-select --install
  export PATH=/opt/homebrew/bin:$PATH
elif [ "$TRAVIS_OS_NAME" == "linux" ]; then
  # https://github.com/microsoft/vcpkg#installing-linux-developer-tools
  sudo apt-get install -y build-essential tar curl zip unzip
  apt install linux-libc-dev
  if [ "$arch_name" == "arm64" ]; then
    apt-get install -y ninja-build
    export VCPKG_FORCE_SYSTEM_BINARIES=1
  elif [ "$arch_name" == "aarch64" ]; then
    apt-get install -y ninja-build
    export VCPKG_FORCE_SYSTEM_BINARIES=1
  elif [ "$arch_name" == "s390x" ]; then
    apt-get install -y ninja-build
    export VCPKG_FORCE_SYSTEM_BINARIES=1
  fi
elif [ "$TRAVIS_OS_NAME" == "freebsd" ]; then
  pkg install curl zip unzip tar
fi

if [ "$DRONE_JOB_BUILDTYPE" == "boost" ]; then

  echo '==================================> VCPKG INSTALL'
  if [ "$vcpkg_cache_hit" != true ]; then
    pwd
    ls
    cd cache
    git clone https://github.com/microsoft/vcpkg.git -b master vcpkg
    ./vcpkg/bootstrap-vcpkg.sh
    cd vcpkg
    ./vcpkg install fmt$triplet_suffix
    ./vcpkg install openssl$triplet_suffix
    ./vcpkg install zlib$triplet_suffix
    cd ..
    cd ..
    echo $vcpkg_cache_key >"cache/vcpkg_cache_key.txt"
  else
    echo "Reusing cache vcpkg_cache_key=$vcpkg_cache_key"
  fi

  echo '==================================> BOOST INSTALL'
  if [ "$boost_cache_hit" != true ]; then
    pwd
    cd cache
    git clone https://github.com/boostorg/boost.git -b $BOOST_BRANCH boost
    cd boost
    # git submodule update --init --recursive

    echo '==================================> PATCH BOOST SUPER-PROJECT'

    pwd
    cd libs
    git clone https://github.com/CppAlliance/buffers.git -b $BOOST_BRANCH buffers
    git clone https://github.com/CppAlliance/http_proto.git -b $BOOST_BRANCH http_proto
    git clone https://github.com/CppAlliance/http_io.git -b $BOOST_BRANCH http_io
    cd ..

    echo '==================================> CLONE BOOST SUPER-PROJECT SUBMODULES'

    if command -v python &>/dev/null; then
      python_executable="python"
    elif command -v python3 &>/dev/null; then
      python_executable="python3"
    elif command -v python2 &>/dev/null; then
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
    cd ..

    echo $boost_cache_key >"cache/boost_cache_key.txt"
  else
    echo "Reusing cache boost_cache_key=$boost_cache_key"
  fi

  echo '==================================> CMAKE'

  if [ -f "/proc/cpuinfo" ]; then
    CORES=$(grep -c ^processor /proc/cpuinfo)
  else
    CORES=$($python_executable -c 'import multiprocessing as mp; print(mp.cpu_count())')
  fi

  for CXXSTD in ${B2_CXXSTD//,/ }; do
    echo "==================================> CMAKE + C++$CXXSTD"
    cmake -S . -B "build-$CXXSTD" -D CMAKE_BUILD_TYPE=Release -D CMAKE_TOOLCHAIN_FILE="cache/vcpkg/scripts/buildsystems/vcpkg.cmake" -D BOOST_ROOT=cache/boost -D CMAKE_CXX_STANDARD=$CXXSTD -D CMAKE_INSTALL_PREFIX=.local/usr/ -D CMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX
    cmake --build "build-$CXXSTD" --config Release -j $CORES
    cmake --install "build-$CXXSTD" --config Release --prefix prefix
  done

elif [ "$DRONE_JOB_BUILDTYPE" == "docs" ]; then

  echo '==================================> SCRIPT: docs job is not implemented for BoostServerTech'

elif [ "$DRONE_JOB_BUILDTYPE" == "codecov" ]; then

  echo '==================================> SCRIPT: codecov job is not implemented for BoostServerTech'

elif [ "$DRONE_JOB_BUILDTYPE" == "valgrind" ]; then

  echo '==================================> SCRIPT: valgrind job is not implemented for BoostServerTech'

elif [ "$DRONE_JOB_BUILDTYPE" == "standalone" ]; then

  echo '==================================> SCRIPT: standalone job is not implemented for BoostServerTech'

elif [ "$DRONE_JOB_BUILDTYPE" == "coverity" ]; then

  echo '==================================> SCRIPT: coverity job is not implemented for BoostServerTech'

elif [ "$DRONE_JOB_BUILDTYPE" == "cmake-superproject" ]; then

  echo '==================================> SCRIPT: cmake-superproject job is not implemented for BoostServerTech'

elif [ "$DRONE_JOB_BUILDTYPE" == "cmake-install" ]; then

  echo '==================================> SCRIPT: cmake-install job is not implemented for BoostServerTech'

fi
