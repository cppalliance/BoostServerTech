# ---- Project ----

cmake_minimum_required(VERSION 3.14)

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

# ---- Declare library ----

add_library(
        boost_server_tech_lib OBJECT
        source/lib.cpp
)

target_include_directories(
        boost_server_tech_lib
        PUBLIC
        "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/source>"
)

target_compile_features(boost_server_tech_lib PUBLIC cxx_std_14)

# ---- Dependencies ----

find_package(Boost REQUIRED)
target_link_libraries(boost_server_tech_lib PUBLIC Boost::boost)

find_package(fmt REQUIRED)
target_link_libraries(boost_server_tech_lib PUBLIC fmt::fmt)

find_package(OpenSSL REQUIRED)
target_link_libraries(boost_server_tech_lib PUBLIC OpenSSL::SSL OpenSSL::Crypto)

find_package(ZLIB REQUIRED)
target_link_libraries(boost_server_tech_lib PUBLIC ZLIB::ZLIB)

# ---- Executable ----

add_executable(BoostServerTech_exe source/main.cpp)
add_executable(BoostServerTech::exe ALIAS BoostServerTech_exe)

set_property(TARGET BoostServerTech_exe PROPERTY OUTPUT_NAME BoostServerTech)

target_compile_features(BoostServerTech_exe PRIVATE cxx_std_14)

target_link_libraries(BoostServerTech_exe PRIVATE boost_server_tech_lib)

# ---- Install rules ----

if(NOT CMAKE_SKIP_INSTALL_RULES)
    install(
            TARGETS BoostServerTech_exe
            RUNTIME COMPONENT BoostServerTech_Runtime
    )

    if(PROJECT_IS_TOP_LEVEL)
        include(CPack)
    endif()
endif()

# ---- Developer targets ----

include(cmake/folders.cmake)

#include(CTest)
#if(BUILD_TESTING)
#    add_subdirectory(test)
#endif()

option(ENABLE_COVERAGE "Enable coverage support separate from CTest's" OFF)
if(ENABLE_COVERAGE)
    include(cmake/coverage.cmake)
endif()

add_folders(Project)
