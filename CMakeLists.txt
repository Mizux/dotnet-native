# This file is just an orchestration
cmake_minimum_required(VERSION 3.18)

# UseSWIG use library name conventions for CSharp language.
if (POLICY CMP0122)
  cmake_policy(SET CMP0122 NEW)
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

option(CMAKE_EXPORT_COMPILE_COMMANDS "Export compile command" TRUE)

set(COMPANY_NAME Mizux)
project(DotnetNative VERSION 1.0 LANGUAGES CXX C)
set(PROJECT_NAMESPACE dn)
message(STATUS "${PROJECT_NAME} version: ${PROJECT_VERSION}")
#message(STATUS "major: ${PROJECT_VERSION_MAJOR}")
#message(STATUS "minor: ${PROJECT_VERSION_MINOR}")
#message(STATUS "patch: ${PROJECT_VERSION_PATCH}")

if(MSVC)
  set(CMAKE_CXX_STANDARD 20)
else()
  set(CMAKE_CXX_STANDARD 17)
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Set max os target version.
set(CMAKE_OSX_DEPLOYMENT_TARGET 10.15)

get_property(isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(isMultiConfig)
  if(NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_CONFIGURATION_TYPES "Release;Debug" CACHE STRING
    "Choose the type of builds, options are: Debug Release RelWithDebInfo MinSizeRel. (default: Release;Debug)"
    FORCE)
  endif()
  message(STATUS "Configuration types: ${CMAKE_CONFIGURATION_TYPES}")
else()
  if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING
    "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel. (default: Release)"
    FORCE)
  endif()
  message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
endif()

# Layout build dir like install dir
include(GNUInstallDirs)
if(UNIX)
  option(BUILD_SHARED_LIBS "Build shared libraries (.so or .dyld)." ON)
  set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})
  # for multi-config build system (e.g. Xcode, Ninja Multi-Config)
  foreach(OutputConfig IN LISTS CMAKE_CONFIGURATION_TYPES)
    string(TOUPPER ${OutputConfig} OUTPUTCONFIG)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${OutputConfig}/${CMAKE_INSTALL_LIBDIR})
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${OutputConfig}/${CMAKE_INSTALL_LIBDIR})
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${OutputConfig}/${CMAKE_INSTALL_BINDIR})
  endforeach()
else()
  # Currently Only support static build for windows
  option(BUILD_SHARED_LIBS "Build shared libraries (.dll)." OFF)
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})
  # for multi-config builds (e.g. msvc)
  foreach(OutputConfig IN LISTS CMAKE_CONFIGURATION_TYPES)
    string(TOUPPER ${OutputConfig} OUTPUTCONFIG)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${OutputConfig}/${CMAKE_INSTALL_BINDIR})
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${OutputConfig}/${CMAKE_INSTALL_BINDIR})
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${OutputConfig}/${CMAKE_INSTALL_BINDIR})
  endforeach()
endif()
if(BUILD_SHARED_LIBS AND MSVC)
  set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()
message(STATUS "Build shared libs: ${BUILD_SHARED_LIBS}")

# Disable CTest targets
set_property(GLOBAL PROPERTY CTEST_TARGETS_ADDED 1)
include(CTest)

include(cpp)

if(WIN32)
  message(STATUS "Getting SWIG: ...")
  include(swig)
  message(STATUS "Getting SWIG: ...DONE")
endif()

# Language Version
# see: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version
set(DOTNET_LANG "8.0" CACHE STRING "Specify the C# language version (default \"8.0\")")
message(STATUS ".Net C# language version: ${DOTNET_LANG}")

# Targeted Framework Moniker
# see: https://learn.microsoft.com/en-us/dotnet/standard/frameworks
# see: https://learn.microsoft.com/en-us/dotnet/standard/net-standard

## .Net Standard
option(USE_DOTNET_STD_20 "Use .Net Standard 2.0 support" OFF)
message(STATUS ".Net: Use .Net Standard 2.0 support: ${USE_DOTNET_STD_20}")
option(USE_DOTNET_STD_21 "Use .Net Standard 2.1 support" OFF)
message(STATUS ".Net: Use .Net Standard 2.1 support: ${USE_DOTNET_STD_21}")

## .Net Framework
# see: https://learn.microsoft.com/en-us/lifecycle/products/microsoft-net-framework
option(USE_DOTNET_46 "Use .Net Framework 4.6 support" OFF) # EOL: 2022-04-22
message(STATUS ".Net: Use .Net Framework 4.6 support: ${USE_DOTNET_46}")
option(USE_DOTNET_461 "Use .Net Framework 4.6.1 support" OFF) # EOL: 2022-04-22
message(STATUS ".Net: Use .Net Framework 4.6.1 support: ${USE_DOTNET_461}")
option(USE_DOTNET_462 "Use .Net Framework 4.6.2 support" OFF) # EOL: 2027-01-12
message(STATUS ".Net: Use .Net Framework 4.6.2 support: ${USE_DOTNET_462}")

option(USE_DOTNET_47 "Use .Net Framework 4.7 support" OFF) # EOL: NA
message(STATUS ".Net: Use .Net Framework 4.7 support: ${USE_DOTNET_47}")

option(USE_DOTNET_48 "Use .Net Framework 4.8 support" OFF) # EOL: NA
message(STATUS ".Net: Use .Net Framework 4.8 support: ${USE_DOTNET_48}")

## .Net and .Net Core
# see: https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core
# .Net Core 3.1 LTS is not available for osx arm64
if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)")
  set(USE_DOTNET_CORE_31 OFF)
else()
  option(USE_DOTNET_CORE_31 "Use .Net Core 3.1 support" OFF) # EOL: 2022-12-13
endif()
message(STATUS ".Net: Use .Net Core 3.1 support: ${USE_DOTNET_CORE_31}")

option(USE_DOTNET_6 "Use .Net 6 LTS support" ON) # EOL: 2024-11-12
message(STATUS ".Net: Use .Net 6 LTS support: ${USE_DOTNET_6}")

option(USE_DOTNET_7 "Use .Net 7.0 support" OFF) # EOL: 2024-05-14
message(STATUS ".Net: Use .Net 7.0 support: ${USE_DOTNET_7}")

option(USE_DOTNET_8 "Use .Net 8.0 LTS support" OFF) # EOL: 2026-11-10
message(STATUS ".Net: Use .Net 8.0 support: ${USE_DOTNET_8}")

include(dotnet)

add_subdirectory(tests)

option(BUILD_EXAMPLES "Build examples" ON)
message(STATUS "Build examples: ${BUILD_EXAMPLES}")

if(USE_DOTNET_8)
  set(EXAMPLE_DEFAULT_TFM "net8.0")
elseif(USE_DOTNET_7)
  set(EXAMPLE_DEFAULT_TFM "net7.0")
elseif(USE_DOTNET_6)
  set(EXAMPLE_DEFAULT_TFM "net6.0")
elseif(USE_DOTNET_48)
  set(EXAMPLE_DEFAULT_TFM "net48")
elseif(USE_DOTNET_47)
  set(EXAMPLE_DEFAULT_TFM "net47")
elseif(USE_DOTNET_462)
  set(EXAMPLE_DEFAULT_TFM "net462")
else()
  message(WARNING "Default TFM for examples is set to net6.0 which is not enable")
  set(EXAMPLE_DEFAULT_TFM "net6.0")
endif()

set(EXAMPLE_TFM ${EXAMPLE_DEFAULT_TFM} CACHE STRING "TFM use in sample")
message(STATUS ".Net: TFM for examples: ${EXAMPLE_TFM}")

add_subdirectory(examples)

