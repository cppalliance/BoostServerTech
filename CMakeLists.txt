# ---- Project ----

cmake_minimum_required(VERSION 3.14)

if(NOT DEFINED BOOST_ROOT)
    set(BOOST_ROOT $ENV{BOOST_ROOT})
endif()

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(
            FATAL_ERROR
            "In-source builds are not supported. "
            "Please read the BUILDING document before trying to build this project. "
            "You may need to delete 'CMakeCache.txt' and 'CMakeFiles/' first."
    )
endif()

project(
        BoostServerTech
        VERSION 0.1.0
        DESCRIPTION "Boost Server Technology demonstration"
        HOMEPAGE_URL "https://github.com/CPPAlliance/BoostServerTech"
        LANGUAGES CXX
)

string(
        COMPARE EQUAL
        "${CMAKE_SOURCE_DIR}" "${PROJECT_SOURCE_DIR}"
        PROJECT_IS_TOP_LEVEL
)

set(BOOST_SERVER_TECH_IGNORE_ME ${CMAKE_C_COMPILER})

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# ---- Declare library ----

#add_library(
#        boost_server_tech_lib OBJECT
#        source/lib.cpp
#)
#
#target_include_directories(
#        boost_server_tech_lib
#        PUBLIC
#        "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/source>"
#)
#
#target_compile_features(boost_server_tech_lib PUBLIC cxx_std_14)

# ---- Dependencies ----

set(CMAKE_FOLDER Dependencies)
set(BOOST_INCLUDE_LIBRARIES
    buffers
    http_proto
    http_io
    )
add_subdirectory(${BOOST_ROOT} bin64/boost)
unset(CMAKE_FOLDER)

#target_link_libraries(boost_server_tech_lib PUBLIC Boost::headers)

find_package(fmt REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)

# ---- Executable ----

add_executable(BoostServerTech source/main.cpp)

target_compile_definitions(
    BoostServerTech
    PUBLIC
    )

set_property(TARGET BoostServerTech PROPERTY OUTPUT_NAME BoostServerTech)

target_compile_features(BoostServerTech PRIVATE cxx_std_14)

target_link_libraries(
    BoostServerTech
    PUBLIC
    fmt::fmt
    OpenSSL::SSL
    OpenSSL::Crypto
    ZLIB::ZLIB
    PRIVATE
    #boost_server_tech_lib
    Boost::asio
    Boost::headers
    Boost::buffers
    Boost::http_proto
    Boost::http_io
    )

# ---- Install rules ----

if(NOT CMAKE_SKIP_INSTALL_RULES)
    install(
            TARGETS BoostServerTech
            RUNTIME COMPONENT BoostServerTech_Runtime
    )

    if(PROJECT_IS_TOP_LEVEL)
        include(CPack)
    endif()
endif()

# ---- Developer targets ----

#include(CTest)
#if(BUILD_TESTING)
#    add_subdirectory(test)
#endif()

option(ENABLE_COVERAGE "Enable coverage support separate from CTest's" OFF)
if(ENABLE_COVERAGE)
    include(cmake/coverage.cmake)
endif()
