cmake_minimum_required(VERSION 3.10)
project(SpiralCoinCore LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

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
    /usr/local/include
    /usr/include
)

# Try to find nlohmann_json package, fall back to include path if not found
find_package(nlohmann_json QUIET)
if(NOT nlohmann_json_FOUND)
    # Assume header-only nlohmann/json is available in include path
    message(STATUS "nlohmann_json package not found, using header-only assumption")
endif()

# Library directories
link_directories(
    /usr/local/lib
    /usr/lib
)

# Create executable
add_executable(${EXECUTABLE_NAME} ${SRC_FILES})

# Find libraries
find_library(LEVELDB_LIB leveldb HINTS /usr/local/lib /usr/lib)
find_library(SSL_LIB ssl HINTS /usr/local/lib /usr/lib)
find_library(CRYPTO_LIB crypto HINTS /usr/local/lib /usr/lib)
find_library(PTHREAD_LIB pthread)
find_library(EVMC_LOADER_LIB evmc-loader HINTS /usr/local/lib)
find_library(EVMC_INSTRUCTIONS_LIB evmc-instructions HINTS /usr/local/lib)

# Collect EVMC libs (only existing ones)
set(EVMC_LIBS "")
if(EVMC_LOADER_LIB)
    list(APPEND EVMC_LIBS ${EVMC_LOADER_LIB})
endif()
if(EVMC_INSTRUCTIONS_LIB)
    list(APPEND EVMC_LIBS ${EVMC_INSTRUCTIONS_LIB})
endif()

# Link everything
target_link_libraries(${EXECUTABLE_NAME}
    ${LEVELDB_LIB}
    ${SSL_LIB}
    ${CRYPTO_LIB}
    ${EVMC_LIBS}
)

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
