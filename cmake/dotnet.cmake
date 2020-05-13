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
add_library(mizux-foo-native SHARED "")
set_target_properties(mizux-foo-native PROPERTIES
  PREFIX ""
  POSITION_INDEPENDENT_CODE ON)
# note: macOS is APPLE and also UNIX !
if(APPLE)
  set_target_properties(mizux-foo-native PROPERTIES INSTALL_RPATH "@loader_path")
  # Xcode fails to build if library doesn't contains at least one source file.
  if(XCODE)
    file(GENERATE
      OUTPUT ${PROJECT_BINARY_DIR}/mizux-foo-native/version.cpp
      CONTENT "namespace {char* version = \"${PROJECT_VERSION}\";}")
    target_sources(mizux-foo-native PRIVATE ${PROJECT_BINARY_DIR}/mizux-foo-native/version.cpp)
  endif()
elseif(UNIX)
  set_target_properties(mizux-foo-native PROPERTIES INSTALL_RPATH "$ORIGIN")
endif()

# Swig wrap all libraries
set(DOTNET Mizux.Foo)
foreach(SUBPROJECT IN ITEMS Foo)
  add_subdirectory(${SUBPROJECT}/dotnet)
  target_link_libraries(mizux-foo-native PRIVATE dotnet_${SUBPROJECT})
endforeach()

file(COPY dotnet/logo.png DESTINATION dotnet)
file(COPY dotnet/Directory.Build.props DESTINATION dotnet)

###############################
##  Mizux.Foo.runtime.<RID>  ##
###############################
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
set(DOTNET_NATIVE ${DOTNET}.runtime.${RUNTIME_IDENTIFIER})

# pom*.xml.in contains:
# CMake variable(s) (@PROJECT_NAME@) that configure_file() can manage and
# generator expression ($<TARGET_FILE:...>) that file(GENERATE) can manage.
configure_file(
  ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET}.runtime.csproj.in
  ${PROJECT_BINARY_DIR}/dotnet/${DOTNET}.runtime.csproj.in
  @ONLY)
file(GENERATE
  OUTPUT ${PROJECT_BINARY_DIR}/dotnet/$<CONFIG>/${DOTNET}.runtime.csproj.in
  INPUT ${PROJECT_BINARY_DIR}/dotnet/${DOTNET}.runtime.csproj.in)

add_custom_command(
  OUTPUT dotnet/${DOTNET_NATIVE}/${DOTNET_NATIVE}.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET_NATIVE}
  COMMAND ${CMAKE_COMMAND} -E copy ./$<CONFIG>/${DOTNET}.runtime.csproj.in ${DOTNET_NATIVE}/${DOTNET_NATIVE}.csproj
  WORKING_DIRECTORY dotnet)

add_custom_target(dotnet_native_package
  DEPENDS
  mizux-foo-native
  dotnet/${DOTNET_NATIVE}/${DOTNET_NATIVE}.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory packages
  COMMAND ${DOTNET_EXECUTABLE} build -c Release ${DOTNET_NATIVE}/${DOTNET_NATIVE}.csproj
  COMMAND ${DOTNET_EXECUTABLE} pack -c Release ${DOTNET_NATIVE}/${DOTNET_NATIVE}.csproj
  WORKING_DIRECTORY dotnet)

#################
##  Mizux.Foo  ##
#################
configure_file(
  ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET}.csproj.in
  ${PROJECT_BINARY_DIR}/dotnet/${DOTNET}.csproj.in
  @ONLY)

add_custom_command(
  OUTPUT dotnet/${DOTNET}/${DOTNET}.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET}
	COMMAND ${CMAKE_COMMAND} -E copy ./${DOTNET}.csproj.in ${DOTNET}/${DOTNET}.csproj
  WORKING_DIRECTORY dotnet)

add_custom_target(dotnet_package ALL
  DEPENDS
    dotnet_native_package
    dotnet/${DOTNET}/${DOTNET}.csproj
  COMMAND ${DOTNET_EXECUTABLE} build -c Release ${DOTNET}/${DOTNET}.csproj
  COMMAND ${DOTNET_EXECUTABLE} pack -c Release ${DOTNET}/${DOTNET}.csproj
  WORKING_DIRECTORY dotnet)

######################
##  Mizux.FooTests  ##
######################
add_custom_command(
  OUTPUT dotnet/${DOTNET}Tests/FooTests.cs
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET}Tests
  COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/dotnet/FooTests.cs ${DOTNET}Tests/FooTests.cs
  WORKING_DIRECTORY dotnet)

configure_file(
  ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET}Tests.csproj.in
  ${PROJECT_BINARY_DIR}/dotnet/${DOTNET}Tests.csproj.in
  @ONLY)

add_custom_command(
  OUTPUT dotnet/${DOTNET}Tests/${DOTNET}Tests.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET}Tests
	COMMAND ${CMAKE_COMMAND} -E copy ./${DOTNET}Tests.csproj.in ${DOTNET}Tests/${DOTNET}Tests.csproj
  WORKING_DIRECTORY dotnet)

add_custom_target(FooTests ALL
  DEPENDS
    dotnet_package
    dotnet/${DOTNET}Tests/FooTests.cs
    dotnet/${DOTNET}Tests/${DOTNET}Tests.csproj
  COMMAND ${DOTNET_EXECUTABLE} build -c Release ${DOTNET}Tests/${DOTNET}Tests.csproj
  WORKING_DIRECTORY dotnet)

if(BUILD_TESTING)
  add_test(NAME FooTestsUT
    COMMAND ${DOTNET_EXECUTABLE} test -c Release ${DOTNET}Tests/${DOTNET}Tests.csproj
    WORKING_DIRECTORY dotnet)
endif()

####################
##  Mizux.FooApp  ##
####################
add_custom_command(
  OUTPUT dotnet/${DOTNET}App/FooApp.cs
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET}App
  COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/dotnet/FooApp.cs ${DOTNET}App/FooApp.cs
  WORKING_DIRECTORY dotnet)

configure_file(
	${PROJECT_SOURCE_DIR}/dotnet/${DOTNET}App.csproj.in
	${PROJECT_BINARY_DIR}/dotnet/${DOTNET}App.csproj.in
  @ONLY)

add_custom_command(
  OUTPUT dotnet/${DOTNET}App/${DOTNET}App.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET}App
	COMMAND ${CMAKE_COMMAND} -E copy ./${DOTNET}App.csproj.in ${DOTNET}App/${DOTNET}App.csproj
  WORKING_DIRECTORY dotnet)

add_custom_target(FooApp ALL
  DEPENDS
    dotnet_package
    dotnet/${DOTNET}App/FooApp.cs
    dotnet/${DOTNET}App/${DOTNET}App.csproj
  COMMAND ${DOTNET_EXECUTABLE} build -c Release ${DOTNET}App/${DOTNET}App.csproj
  WORKING_DIRECTORY dotnet)

if(BUILD_TESTING)
  add_test(NAME FooAppUT
    COMMAND ${DOTNET_EXECUTABLE} run -c Release --project ${DOTNET}App/${DOTNET}App.csproj
    WORKING_DIRECTORY dotnet)
endif()
