cmake_minimum_required(VERSION 3.10)
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules" ${CMAKE_MODULE_PATH})
project(SpiralCoinCore LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# FetchContent for header-only deps
include(FetchContent)

# Auto-detect MinGW make program
if(NOT CMAKE_MAKE_PROGRAM)
  if(MINGW OR CMAKE_CXX_COMPILER MATCHES "mingw")
    find_program(CMAKE_MAKE_PROGRAM mingw32-make REQUIRED)
    message(STATUS "Found MinGW make: ${CMAKE_MAKE_PROGRAM}")
  endif()
endif()

# Windows SDK version for httplib compatibility
if(WIN32)
    add_definitions(-D_WIN32_WINNT=0x0A00)
    if(MSVC)
        string(APPEND CMAKE_CXX_FLAGS_RELEASE " /MT")
    endif()
endif()

# Windows SDK version for httplib compatibility
if(WIN32)
    add_compile_definitions(_WIN32_WINNT=0x0A00)
    # Enable MSVC runtime static linking if using MSVC
    string(APPEND CMAKE_CXX_FLAGS_DEBUG " /MTd")
    string(APPEND CMAKE_CXX_FLAGS_RELEASE " /MT")
endif()

# Output binary
set(EXECUTABLE_NAME spiralcoind)

# Source files
file(GLOB SRC_FILES
    src/*.cpp
    include/*.h
)

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src
    /usr/local/include
    /usr/include
    /mingw64/include
    C:/msys64/mingw64/include
)

# Try to find nlohmann_json; if not found, fetch it
find_package(nlohmann_json QUIET)
if(NOT nlohmann_json_FOUND)
    message(STATUS "nlohmann_json not found; fetching via FetchContent")
    FetchContent_Declare(
        nlohmann_json
        URL https://github.com/nlohmann/json/releases/download/v3.11.2/json.tar.xz
    )
    FetchContent_MakeAvailable(nlohmann_json)
endif()

# Find system OpenSSL (optional for httplib HTTPS); build will proceed without it
find_package(OpenSSL QUIET)
if(OPENSSL_FOUND)
    message(STATUS "OpenSSL found: ${OPENSSL_INCLUDE_DIR}")
    include_directories(${OPENSSL_INCLUDE_DIR})
else()
    message(STATUS "OpenSSL not found; building without TLS support")
endif()

# Library directories
link_directories(
    /usr/local/lib
    /usr/lib
    /mingw64/lib
    C:/msys64/mingw64/lib
)

# Do not hard-require OpenSSL; optional linking is handled below

# Create executable
add_executable(${EXECUTABLE_NAME} ${SRC_FILES})

# Find libraries
find_library(LEVELDB_LIB leveldb HINTS /usr/local/lib /usr/lib)
find_library(SSL_LIB ssl HINTS /usr/local/lib /usr/lib)
find_library(CRYPTO_LIB crypto HINTS /usr/local/lib /usr/lib)
find_library(PTHREAD_LIB pthread)
find_library(EVMC_LOADER_LIB evmc-loader HINTS /usr/local/lib)
find_library(EVMC_INSTRUCTIONS_LIB evmc-instructions HINTS /usr/local/lib)

# Collect optional libs (only existing ones)
set(OPTIONAL_LIBS "")
if(LEVELDB_LIB)
    list(APPEND OPTIONAL_LIBS ${LEVELDB_LIB})
endif()
set(EVMC_LIBS "")
if(EVMC_LOADER_LIB)
    list(APPEND EVMC_LIBS ${EVMC_LOADER_LIB})
endif()
if(EVMC_INSTRUCTIONS_LIB)
    list(APPEND EVMC_LIBS ${EVMC_INSTRUCTIONS_LIB})
endif()

# Link everything
target_link_libraries(${EXECUTABLE_NAME}
    ${OPTIONAL_LIBS}
    ${EVMC_LIBS}
)

# Link OpenSSL if found
if(OPENSSL_FOUND)
    target_link_libraries(${EXECUTABLE_NAME} OpenSSL::SSL OpenSSL::Crypto)
endif()

# Link nlohmann_json target if available
if(TARGET nlohmann_json::nlohmann_json)
    target_link_libraries(${EXECUTABLE_NAME} nlohmann_json::nlohmann_json)
endif()

# Windows-specific libraries
if (WIN32)
    target_link_libraries(${EXECUTABLE_NAME} ws2_32 crypt32)
else()
    target_link_libraries(${EXECUTABLE_NAME} ${PTHREAD_LIB})
endif()

# Print build summary
message(STATUS "==== SpiralCoin Build Configuration ====")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "EVMC Loader: ${EVMC_LOADER_LIB}")
message(STATUS "EVMC Instructions: ${EVMC_INSTRUCTIONS_LIB}")
message(STATUS "=======================================")
