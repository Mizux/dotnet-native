# Will need swig
set(CMAKE_SWIG_FLAGS)
find_package(SWIG REQUIRED)
include(UseSWIG)

if(UNIX AND NOT APPLE)
  list(APPEND CMAKE_SWIG_FLAGS "-DSWIGWORDSIZE64")
endif()

# Find dotnet
find_program(DOTNET_EXECUTABLE dotnet)
if(NOT DOTNET_EXECUTABLE)
  message(FATAL_ERROR "Check for dotnet Program: not found")
else()
  message(STATUS "Found dotnet Program: ${DOTNET_EXECUTABLE}")
endif()

# Create the native library
add_library(mizux-dotnetnative-native SHARED "")
set_target_properties(mizux-dotnetnative-native PROPERTIES
  PREFIX ""
  POSITION_INDEPENDENT_CODE ON)
# note: macOS is APPLE and also UNIX !
if(APPLE)
  set_target_properties(mizux-dotnetnative-native PROPERTIES INSTALL_RPATH "@loader_path")
  # Xcode fails to build if library doesn't contains at least one source file.
  if(XCODE)
    file(GENERATE
      OUTPUT ${PROJECT_BINARY_DIR}/mizux-dotnetnative-native/version.cpp
      CONTENT "namespace {char* version = \"${PROJECT_VERSION}\";}")
    target_sources(mizux-dotnetnative-native PRIVATE ${PROJECT_BINARY_DIR}/mizux-dotnetnative-native/version.cpp)
  endif()
elseif(UNIX)
  set_target_properties(mizux-dotnetnative-native PROPERTIES INSTALL_RPATH "$ORIGIN")
endif()

# Needed by dotnet/CMakeLists.txt
set(DOTNET_PACKAGE Mizux.DotnetNative)
set(DOTNET_PACKAGES_DIR ${PROJECT_BINARY_DIR}/dotnet/packages)
if(APPLE)
  set(RUNTIME_IDENTIFIER osx-x64)
elseif(UNIX)
  set(RUNTIME_IDENTIFIER linux-x64)
elseif(WIN32)
  set(RUNTIME_IDENTIFIER win-x64)
else()
  message(FATAL_ERROR "Unsupported system !")
endif()
set(DOTNET_NATIVE_PROJECT ${DOTNET_PACKAGE}.runtime.${RUNTIME_IDENTIFIER})
set(DOTNET_PROJECT ${DOTNET_PACKAGE})

# Swig wrap all libraries
foreach(SUBPROJECT IN ITEMS Foo)
  add_subdirectory(${SUBPROJECT}/dotnet)
  target_link_libraries(mizux-dotnetnative-native PRIVATE dotnet_${SUBPROJECT})
endforeach()

file(COPY dotnet/logo.png DESTINATION dotnet)
file(COPY dotnet/Directory.Build.props DESTINATION dotnet)

##################################
##  .Net Native Nugget Package  ##
##################################
set(DOTNET_NATIVE_PATH ${PROJECT_BINARY_DIR}/dotnet/${DOTNET_NATIVE_PROJECT})
# *.csproj.in contains:
# CMake variable(s) (@PROJECT_NAME@) that configure_file() can manage and
# generator expression ($<TARGET_FILE:...>) that file(GENERATE) can manage.
configure_file(
  ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET_PACKAGE}.runtime.csproj.in
  ${DOTNET_NATIVE_PATH}/${DOTNET_NATIVE_PROJECT}.csproj.in
  @ONLY)
file(GENERATE
  OUTPUT ${DOTNET_NATIVE_PATH}/$<CONFIG>/${DOTNET_NATIVE_PROJECT}.csproj.in
  INPUT ${DOTNET_NATIVE_PATH}/${DOTNET_NATIVE_PROJECT}.csproj.in)

add_custom_command(
  OUTPUT ${DOTNET_NATIVE_PATH}/${DOTNET_NATIVE_PROJECT}.csproj
  DEPENDS ${DOTNET_NATIVE_PATH}/$<CONFIG>/${DOTNET_NATIVE_PROJECT}.csproj.in
  COMMAND ${CMAKE_COMMAND} -E copy ./$<CONFIG>/${DOTNET_NATIVE_PROJECT}.csproj.in ${DOTNET_NATIVE_PROJECT}.csproj
  WORKING_DIRECTORY ${DOTNET_NATIVE_PATH})

add_custom_target(dotnet_native_package
  DEPENDS ${DOTNET_NATIVE_PATH}/${DOTNET_NATIVE_PROJECT}.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory packages
  COMMAND ${DOTNET_EXECUTABLE} build -c Release ${DOTNET_NATIVE_PROJECT}/${DOTNET_NATIVE_PROJECT}.csproj
  COMMAND ${DOTNET_EXECUTABLE} pack -c Release ${DOTNET_NATIVE_PROJECT}/${DOTNET_NATIVE_PROJECT}.csproj
  WORKING_DIRECTORY dotnet)
add_dependencies(dotnet_native_package mizux-dotnetnative-native)

###########################
##  .Net Nugget Package  ##
###########################
set(DOTNET_PATH ${PROJECT_BINARY_DIR}/dotnet/${DOTNET_PROJECT})

configure_file(
  ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET_PROJECT}.csproj.in
  ${DOTNET_PATH}/${DOTNET_PROJECT}.csproj.in
  @ONLY)

add_custom_command(
  OUTPUT ${DOTNET_PATH}/${DOTNET_PROJECT}.csproj
  DEPENDS ${DOTNET_PATH}/${DOTNET_PROJECT}.csproj.in
  COMMAND ${CMAKE_COMMAND} -E copy ${DOTNET_PROJECT}.csproj.in ${DOTNET_PROJECT}.csproj
  WORKING_DIRECTORY ${DOTNET_PATH})

add_custom_target(dotnet_package ALL
  DEPENDS ${DOTNET_PATH}/${DOTNET_PROJECT}.csproj
  COMMAND ${DOTNET_EXECUTABLE} build -c Release ${DOTNET_PROJECT}/${DOTNET_PROJECT}.csproj
  COMMAND ${DOTNET_EXECUTABLE} pack -c Release ${DOTNET_PROJECT}/${DOTNET_PROJECT}.csproj
  WORKING_DIRECTORY dotnet)
add_dependencies(dotnet_package dotnet_native_package)

#################
##  .Net Test  ##
#################
if(BUILD_TESTING)
  set(DOTNET_TEST_PROJECT ${DOTNET_PROJECT}.Tests)
  set(DOTNET_TEST_PATH ${PROJECT_BINARY_DIR}/dotnet/${DOTNET_TEST_PROJECT})

  add_custom_command(
    OUTPUT ${DOTNET_TEST_PATH}/FooTests.cs
    DEPENDS ${PROJECT_SOURCE_DIR}/dotnet/FooTests.cs
    COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/dotnet/FooTests.cs FooTests.cs
    WORKING_DIRECTORY ${DOTNET_TEST_PATH})

  configure_file(
    ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET_TEST_PROJECT}.csproj.in
    ${DOTNET_TEST_PATH}/${DOTNET_TEST_PROJECT}.csproj.in
    @ONLY)

  add_custom_command(
    OUTPUT ${DOTNET_TEST_PATH}/${DOTNET_TEST_PROJECT}.csproj
    DEPENDS ${DOTNET_TEST_PATH}/${DOTNET_TEST_PROJECT}.csproj.in
    COMMAND ${CMAKE_COMMAND} -E copy ${DOTNET_TEST_PROJECT}.csproj.in ${DOTNET_TEST_PROJECT}.csproj
    WORKING_DIRECTORY ${DOTNET_TEST_PATH})

  add_custom_target(FooTests ALL
    DEPENDS
      ${DOTNET_TEST_PATH}/FooTests.cs
      ${DOTNET_TEST_PATH}/${DOTNET_TEST_PROJECT}.csproj
    COMMAND ${DOTNET_EXECUTABLE} build -c Release ${DOTNET_TEST_PROJECT}/${DOTNET_TEST_PROJECT}.csproj
    WORKING_DIRECTORY dotnet)
  add_dependencies(FooTests dotnet_package)

  add_test(
    NAME dotnet_FooTests
    COMMAND ${DOTNET_EXECUTABLE} test -c Release ${DOTNET_TEST_PROJECT}.csproj
    WORKING_DIRECTORY ${DOTNET_TEST_PATH})
endif()

####################
##  Mizux.FooApp  ##
####################
set(DOTNET_APP_PROJECT ${DOTNET_PROJECT}.FooApp)
set(DOTNET_APP_PATH ${PROJECT_BINARY_DIR}/dotnet/${DOTNET_APP_PROJECT})

add_custom_command(
  OUTPUT ${DOTNET_APP_PATH}/FooApp.cs
  DEPENDS ${PROJECT_SOURCE_DIR}/dotnet/FooApp.cs
  COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/dotnet/FooApp.cs FooApp.cs
  WORKING_DIRECTORY ${DOTNET_APP_PATH})

configure_file(
  ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET_APP_PROJECT}.csproj.in
  ${DOTNET_APP_PATH}/${DOTNET_APP_PROJECT}.csproj.in
  @ONLY)

add_custom_command(
  OUTPUT ${DOTNET_APP_PATH}/${DOTNET_APP_PROJECT}.csproj
  DEPENDS ${DOTNET_APP_PATH}/${DOTNET_APP_PROJECT}.csproj.in
  COMMAND ${CMAKE_COMMAND} -E copy ${DOTNET_APP_PROJECT}.csproj.in ${DOTNET_APP_PROJECT}.csproj
  WORKING_DIRECTORY ${DOTNET_APP_PATH})

add_custom_target(FooApp ALL
  DEPENDS
    ${DOTNET_APP_PATH}/FooApp.cs
    ${DOTNET_APP_PATH}/${DOTNET_APP_PROJECT}.csproj
  COMMAND ${DOTNET_EXECUTABLE} build -c Release ${DOTNET_APP_PROJECT}/${DOTNET_APP_PROJECT}.csproj
  WORKING_DIRECTORY dotnet)
add_dependencies(FooApp dotnet_package)

if(BUILD_TESTING)
  add_test(NAME dotnet_FooApp
    COMMAND ${DOTNET_EXECUTABLE} run -c Release --project ${DOTNET_APP_PROJECT}.csproj
    WORKING_DIRECTORY ${DOTNET_APP_PATH})
endif()
