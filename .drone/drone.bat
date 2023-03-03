
@echo on
setlocal EnableExtensions EnableDelayedExpansion

set VCPKG_TRIPLET=x64-windows
set VCPKG_TRIPLET_SUFFIX=:%VCPKG_TRIPLET%

if "%DRONE_JOB_BUILDTYPE%" == "boost" (

    echo "==================================> ENVIRONMENT"

    set

    echo "==================================> VCPKG INSTALL"

    dir
    del VCPKG

    git clone https://github.com/microsoft/vcpkg.git -b master vcpkg
    .\vcpkg\bootstrap-vcpkg.bat
    cd vcpkg
    vcpkg install fmt%VCPKG_TRIPLET_SUFFIX%
    vcpkg install openssl%VCPKG_TRIPLET_SUFFIX%
    vcpkg install zlib%VCPKG_TRIPLET_SUFFIX%
    cd ..

    echo "==================================> CLONE BOOST"

    if "%DRONE_COMMIT_BRANCH%" == "master" (
        git clone https://github.com/boostorg/boost.git -b master boost
    ) else (
        git clone https://github.com/boostorg/boost.git -b develop boost
    )
    cd boost
    REM git submodule update --init --recursive

    echo "==================================> PATCH BOOST"

    cd libs
    if "%DRONE_COMMIT_BRANCH%" == "master" (
        git clone https://github.com/CppAlliance/buffers.git -b master buffers
        git clone https://github.com/CppAlliance/http_proto.git -b master http_proto
        git clone https://github.com/CppAlliance/http_io.git -b master http_io
    ) else (
        git clone https://github.com/CppAlliance/buffers.git -b develop buffers
        git clone https://github.com/CppAlliance/http_proto.git -b develop http_proto
        git clone https://github.com/CppAlliance/http_io.git -b develop http_io
    )

    cd ..

    echo "==================================> BOOST SUBMODULES"

    git submodule update -q --init tools/boostdep
    git submodule update -q --init libs/url
    python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools --include source url
    python tools/boostdep/depinst/depinst.py --include benchmark --include example --include examples --include tools --include source ../../../BoostServerTech
    cd ..

    echo "==================================> CMAKE"

    echo CXXSTD list = "%B2_CXXSTD%"
    for %%i in ("%B2_CXXSTD:,=" "%") do (
        cmake -S . -B "build-%%i" -D CMAKE_BUILD_TYPE=Release -D CMAKE_TOOLCHAIN_FILE=".\vcpkg\scripts\buildsystems\vcpkg.cmake" -D BOOST_ROOT=boost -D CMAKE_CXX_STANDARD=%%i -D CMAKE_INSTALL_PREFIX=.local/usr/ -D CMAKE_GENERATOR_PLATFORM=x64
        cmake --build "build-%%i" --config Release -j %NUMBER_OF_PROCESSORS%
        cmake --install "build-%%i" --config Release --prefix prefix
    )

) else if "%DRONE_JOB_BUILDTYPE%" == "standalone-windows" (

REM not used

)
