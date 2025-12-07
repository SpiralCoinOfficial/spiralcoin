cmake_minimum_required(VERSION 3.10)
project(SpiralCoinCore LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
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
    ${CMAKE_SOURCE_DIR}/src
    /usr/local/include
    /usr/include
)

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

# Collect libraries only if they were actually found (not set to <VAR>-NOTFOUND)
set(THIRD_PARTY_LIBS "")
if(DEFINED LEVELDB_LIB AND NOT LEVELDB_LIB MATCHES "NOTFOUND$")
    list(APPEND THIRD_PARTY_LIBS ${LEVELDB_LIB})
endif()
if(DEFINED SSL_LIB AND NOT SSL_LIB MATCHES "NOTFOUND$")
    list(APPEND THIRD_PARTY_LIBS ${SSL_LIB})
endif()
if(DEFINED CRYPTO_LIB AND NOT CRYPTO_LIB MATCHES "NOTFOUND$")
    list(APPEND THIRD_PARTY_LIBS ${CRYPTO_LIB})
endif()
if(DEFINED PTHREAD_LIB AND NOT PTHREAD_LIB MATCHES "NOTFOUND$")
    list(APPEND THIRD_PARTY_LIBS ${PTHREAD_LIB})
endif()
if(DEFINED EVMC_LOADER_LIB AND NOT EVMC_LOADER_LIB MATCHES "NOTFOUND$")
    list(APPEND THIRD_PARTY_LIBS ${EVMC_LOADER_LIB})
endif()
if(DEFINED EVMC_INSTRUCTIONS_LIB AND NOT EVMC_INSTRUCTIONS_LIB MATCHES "NOTFOUND$")
    list(APPEND THIRD_PARTY_LIBS ${EVMC_INSTRUCTIONS_LIB})
endif()

# Link only the libraries we found
target_link_libraries(${EXECUTABLE_NAME} ${THIRD_PARTY_LIBS})

# Print build summary
message(STATUS "==== SpiralCoin Build Configuration ====")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "EVMC Loader: ${EVMC_LOADER_LIB}")
message(STATUS "EVMC Instructions: ${EVMC_INSTRUCTIONS_LIB}")
message(STATUS "=======================================")
