# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# Modified from the Apache Arrow project for the Terrier project.

# Check if the target architecture and compiler supports some special
# instruction sets that would boost performance.
include(CheckCXXCompilerFlag)

# compiler flags that are common across debug/release builds

# Common flags set below with warning level
set(CXX_COMMON_FLAGS "")

# Build warning level (CHECKIN, EVERYTHING, etc.)

# if no build warning level is specified, default to development warning level
if (NOT BUILD_WARNING_LEVEL)
  set(BUILD_WARNING_LEVEL Production)
endif(NOT BUILD_WARNING_LEVEL)

string(TOUPPER ${BUILD_WARNING_LEVEL} UPPERCASE_BUILD_WARNING_LEVEL)

set(CXX_ONLY_FLAGS "${CXX_ONLY_FLAGS} -std=c++17 -fPIC -mcx16 -march=native")

if ("${UPPERCASE_BUILD_WARNING_LEVEL}" STREQUAL "CHECKIN")
  # Pre-checkin builds
  if ("${COMPILER_FAMILY}" STREQUAL "clang")
    set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Weverything -Wno-c++98-compat \
-Wno-c++98-compat-pedantic -Wno-deprecated -Wno-weak-vtables -Wno-padded \
-Wno-comma -Wno-unused-parameter -Wno-unused-template -Wno-undef \
-Wno-shadow -Wno-switch-enum -Wno-exit-time-destructors \
-Wno-global-constructors -Wno-weak-template-vtables -Wno-undefined-reinterpret-cast \
-Wno-implicit-fallthrough -Wno-unreachable-code-return \
-Wno-float-equal -Wno-missing-prototypes \
-Wno-old-style-cast -Wno-covered-switch-default \
-Wno-cast-align -Wno-vla-extension -Wno-shift-sign-overflow \
-Wno-used-but-marked-unused -Wno-missing-variable-declarations \
-Wno-gnu-zero-variadic-macro-arguments -Wconversion -Wno-sign-conversion \
-Wno-disabled-macro-expansion")

    # Version numbers where warnings are introduced
    if ("${COMPILER_VERSION}" VERSION_GREATER "3.3")
      set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wno-gnu-folding-constant")
    endif()
    if ("${COMPILER_VERSION}" VERSION_GREATER "3.6")
      set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wno-reserved-id-macro")
      set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wno-range-loop-analysis")
    endif()
    if ("${COMPILER_VERSION}" VERSION_GREATER "3.7")
      set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wno-double-promotion")
    endif()
    if ("${COMPILER_VERSION}" VERSION_GREATER "3.8")
      set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wno-undefined-func-template")
    endif()

    if ("${COMPILER_VERSION}" VERSION_GREATER "4.0")
      set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wno-zero-as-null-pointer-constant")
    endif()

    # Treat all compiler warnings as errors
    set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wno-unknown-warning-option -Werror")
  elseif ("${COMPILER_FAMILY}" STREQUAL "gcc")
    set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wall \
-Wconversion -Wno-sign-conversion")

    # Treat all compiler warnings as errors
    set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Werror")
  else()
    message(FATAL_ERROR "Unknown compiler. Version info:\n${COMPILER_VERSION_FULL}")
  endif()
elseif ("${UPPERCASE_BUILD_WARNING_LEVEL}" STREQUAL "EVERYTHING")
  # Pedantic builds for fixing warnings
  if ("${COMPILER_FAMILY}" STREQUAL "clang")
    set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Weverything -Wno-c++98-compat -Wno-c++98-compat-pedantic")
    # Treat all compiler warnings as errors
    set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Werror")
  elseif ("${COMPILER_FAMILY}" STREQUAL "gcc")
    set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wall -Wpedantic -Wextra -Wno-unused-parameter")
    # Treat all compiler warnings as errors
    set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Werror")
  else()
    message(FATAL_ERROR "Unknown compiler. Version info:\n${COMPILER_VERSION_FULL}")
  endif()
else()
  # Production builds (warning are not treated as errors)
  if ("${COMPILER_FAMILY}" STREQUAL "clang")
    set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wall")
  elseif ("${COMPILER_FAMILY}" STREQUAL "gcc")
    set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wall")
  else()
    message(FATAL_ERROR "Unknown compiler. Version info:\n${COMPILER_VERSION_FULL}")
  endif()
endif()

# Clang options for all builds
if ("${COMPILER_FAMILY}" STREQUAL "clang")
  # Using Clang with ccache causes a bunch of spurious warnings that are
  # purportedly fixed in the next version of ccache. See the following for details:
  #
  #   http://petereisentraut.blogspot.com/2011/05/ccache-and-clang.html
  #   http://petereisentraut.blogspot.com/2011/09/ccache-and-clang-part-2.html
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Qunused-arguments")

  # Avoid clang error when an unknown warning flag is passed
  set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -Wno-unknown-warning-option")
endif()

# if build warning flags is set, add to CXX_COMMON_FLAGS
if (BUILD_WARNING_FLAGS)
  # Use BUILD_WARNING_FLAGS with BUILD_WARNING_LEVEL=everything to disable
  # warnings (use with Clang's -Weverything flag to find potential errors)
  set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} ${BUILD_WARNING_FLAGS}")
endif(BUILD_WARNING_FLAGS)

# color diagnostics
if("${COMPILER_FAMILY}" STREQUAL "clang")
  set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -fcolor-diagnostics")
elseif("${COMPILER_FAMILY}" STREQUAL "gcc")
  set(CXX_COMMON_FLAGS "${CXX_COMMON_FLAGS} -fdiagnostics-color=auto")
endif()

# compiler flags for different build types (run 'cmake -DCMAKE_BUILD_TYPE=<type> .')
# For all builds:
# For CMAKE_BUILD_TYPE=Debug
#   -ggdb: Enable gdb debugging
# For CMAKE_BUILD_TYPE=FastDebug
#   Same as DEBUG, except with some optimizations on.
# For CMAKE_BUILD_TYPE=Release
#   -O3: Enable all compiler optimizations
#   Debug symbols are stripped for reduced binary size. Add
#   -DTERRIER_CXXFLAGS="-g" to add them
# For CMAKE_BUILD_TYPE=RelWithDebInfo
#   -O2: Some compiler optimizations
#   -ggdb: Enable gdb debugging
set(CXX_FLAGS_DEBUG "-ggdb -O0 -fno-omit-frame-pointer -fno-optimize-sibling-calls")
set(CXX_FLAGS_FASTDEBUG "-ggdb -O1 -fno-omit-frame-pointer -fno-optimize-sibling-calls")
set(CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CXX_FLAGS_RELWITHDEBINFO "-ggdb -O2 -DNDEBUG")

# if no build build type is specified, default to debug builds
if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug)
endif(NOT CMAKE_BUILD_TYPE)

string (TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE)

# Set compile flags based on the build type.
message("Configured for ${CMAKE_BUILD_TYPE} build (set with cmake -DCMAKE_BUILD_TYPE={release,debug,fastdebug,relwithdebinfo})")
if ("${CMAKE_BUILD_TYPE}" STREQUAL "DEBUG")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_FLAGS_DEBUG}")
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "FASTDEBUG")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_FLAGS_FASTDEBUG}")
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "RELEASE")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_FLAGS_RELEASE}")
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "RELWITHDEBINFO")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_FLAGS_RELWITHDEBINFO}")
else()
  message(FATAL_ERROR "Unknown build type: ${CMAKE_BUILD_TYPE}")
endif ()

if ("${CMAKE_CXX_FLAGS}" MATCHES "-DNDEBUG")
  set(TERRIER_DEFINITION_FLAGS "-DNDEBUG")
else()
  set(TERRIER_DEFINITION_FLAGS "")
endif()

message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")