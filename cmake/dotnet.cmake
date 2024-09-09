# Will need swig
set(CMAKE_SWIG_FLAGS)
find_package(SWIG REQUIRED)
include(UseSWIG)

#if(${SWIG_VERSION} VERSION_GREATER_EQUAL 4)
#  list(APPEND CMAKE_SWIG_FLAGS "-doxygen")
#endif()

if(UNIX AND NOT APPLE)
  list(APPEND CMAKE_SWIG_FLAGS "-DSWIGWORDSIZE64")
endif()

# Find dotnet cli
find_program(DOTNET_EXECUTABLE NAMES dotnet)
if(NOT DOTNET_EXECUTABLE)
  message(FATAL_ERROR "Check for dotnet Program: not found")
else()
  message(STATUS "Found dotnet Program: ${DOTNET_EXECUTABLE}")
endif()

# Needed by dotnet/CMakeLists.txt
set(DOTNET_PACKAGE ${COMPANY_NAME}.${PROJECT_NAME})
set(DOTNET_PACKAGES_DIR "${PROJECT_BINARY_DIR}/dotnet/packages")

# Runtime IDentifier
# see: https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)")
  set(DOTNET_PLATFORM arm64)
else()
  set(DOTNET_PLATFORM x64)
endif()

if(APPLE)
  set(DOTNET_RID osx-${DOTNET_PLATFORM})
elseif(UNIX)
  set(DOTNET_RID linux-${DOTNET_PLATFORM})
elseif(WIN32)
  set(DOTNET_RID win-${DOTNET_PLATFORM})
else()
  message(FATAL_ERROR "Unsupported system !")
endif()
message(STATUS ".Net RID: ${DOTNET_RID}")

set(DOTNET_NATIVE_PROJECT ${DOTNET_PACKAGE}.runtime.${DOTNET_RID})
message(STATUS ".Net runtime project: ${DOTNET_NATIVE_PROJECT}")
set(DOTNET_NATIVE_PROJECT_DIR ${PROJECT_BINARY_DIR}/dotnet/${DOTNET_NATIVE_PROJECT})
message(STATUS ".Net runtime project build path: ${DOTNET_NATIVE_PROJECT_DIR}")

# Targeted Framework Moniker
# see: https://docs.microsoft.com/en-us/dotnet/standard/frameworks
# see: https://learn.microsoft.com/en-us/dotnet/standard/net-standard
if(USE_DOTNET_STD_20)
  list(APPEND TFM "netstandard2.0")
endif()
if(USE_DOTNET_STD_21)
  list(APPEND TFM "netstandard2.1")
endif()

if(USE_DOTNET_46)
  list(APPEND TFM "net46")
endif()
if(USE_DOTNET_461)
  list(APPEND TFM "net461")
endif()
if(USE_DOTNET_462)
  list(APPEND TFM "net462")
endif()
if(USE_DOTNET_47)
  list(APPEND TFM "net47")
endif()
if(USE_DOTNET_48)
  list(APPEND TFM "net48")
endif()

if(USE_DOTNET_CORE_31)
  list(APPEND TFM "netcoreapp3.1")
endif()
if(USE_DOTNET_6)
  list(APPEND TFM "net6.0")
endif()
if(USE_DOTNET_7)
  list(APPEND TFM "net7.0")
endif()
if(USE_DOTNET_8)
  list(APPEND TFM "net8.0")
endif()

list(LENGTH TFM TFM_LENGTH)
if(TFM_LENGTH EQUAL "0")
  message(FATAL_ERROR "No .Net SDK selected !")
endif()

string(JOIN ";" DOTNET_TFM ${TFM})
message(STATUS ".Net TFM: ${DOTNET_TFM}")
if(TFM_LENGTH GREATER "1")
  string(CONCAT DOTNET_TFM "<TargetFrameworks>" "${DOTNET_TFM}" "</TargetFrameworks>")
else()
  string(CONCAT DOTNET_TFM "<TargetFramework>" "${DOTNET_TFM}" "</TargetFramework>")
endif()


set(DOTNET_PROJECT ${DOTNET_PACKAGE})
message(STATUS ".Net project: ${DOTNET_PROJECT}")
set(DOTNET_PROJECT_DIR ${PROJECT_BINARY_DIR}/dotnet/${DOTNET_PROJECT})
message(STATUS ".Net project build path: ${DOTNET_PROJECT_DIR}")

# Create the native library
string(TOLOWER "${COMPANY_NAME}_${PROJECT_NAME}_native" DOTNET_NATIVE_LIBRARY)
message(STATUS ".Net runtime library: ${DOTNET_NATIVE_LIBRARY}")
add_library(${DOTNET_NATIVE_LIBRARY} SHARED "")
set_target_properties(${DOTNET_NATIVE_LIBRARY} PROPERTIES
  PREFIX ""
  POSITION_INDEPENDENT_CODE ON)
# note: macOS is APPLE and also UNIX !
if(APPLE)
  set_target_properties(${DOTNET_NATIVE_LIBRARY} PROPERTIES
    INSTALL_RPATH "@loader_path")
  # Xcode fails to build if library doesn't contains at least one source file.
  if(XCODE)
    file(GENERATE
      OUTPUT ${PROJECT_BINARY_DIR}/${DOTNET_NATIVE_LIBRARY}/version.cpp
      CONTENT "namespace {char* version = \"${PROJECT_VERSION}\";}")
    target_sources(${DOTNET_NATIVE_LIBRARY} PRIVATE ${PROJECT_BINARY_DIR}/${DOTNET_NATIVE_LIBRARY}/version.cpp)
  endif()
elseif(UNIX)
  set_target_properties(${DOTNET_NATIVE_LIBRARY} PROPERTIES
    INSTALL_RPATH "$ORIGIN")
endif()

#################
##  .Net Test  ##
#################
# add_dotnet_tfm_test()
# CMake function to generate and build dotnet test for a specific TFM.
# warning: only net6.0, net7.0 and net8.0 are supported
# Parameters:
#  the dotnet filename
# e.g.:
# add_dotnet_test(FooTests.cs net8.0)
function(add_dotnet_tfm_test FILE_NAME TEST_TFM)
  message(STATUS "  Configuring test ${FILE_NAME} (${TEST_TFM}) ...")
  get_filename_component(TEST_NAME ${FILE_NAME} NAME_WE)
  get_filename_component(COMPONENT_DIR ${FILE_NAME} DIRECTORY)
  get_filename_component(COMPONENT_NAME ${COMPONENT_DIR} NAME)

  set(DOTNET_TEST_DIR ${PROJECT_BINARY_DIR}/dotnet/${COMPONENT_NAME}/${TEST_NAME})

  if(TEST_TFM STREQUAL "net6.0")
    set(TEST_SUFFIX net60)
  elseif(TEST_TFM STREQUAL "net7.0")
    set(TEST_SUFFIX net70)
  elseif(TEST_TFM STREQUAL "net8.0")
    set(TEST_SUFFIX net80)
  else()
    message(FATAL_ERROR "TFM: ${TEST_TFM} is not supported.")
  endif()

  add_custom_command(
    OUTPUT ${DOTNET_TEST_DIR}/timestamp_${TEST_SUFFIX}
    COMMAND ${CMAKE_COMMAND} -E env --unset=TARGETNAME
    ${DOTNET_EXECUTABLE} build --nologo --framework ${TEST_TFM} -c Release ${TEST_NAME}.csproj
    COMMAND ${CMAKE_COMMAND} -E touch ${DOTNET_TEST_DIR}/timestamp
    DEPENDS
      ${DOTNET_TEST_DIR}/${TEST_NAME}.csproj
      ${DOTNET_TEST_DIR}/${TEST_NAME}.cs
      dotnet_package
    BYPRODUCTS
      ${DOTNET_TEST_DIR}/bin
      ${DOTNET_TEST_DIR}/obj
    VERBATIM
    COMMENT "Compiling .Net ${COMPONENT_NAME}/${TEST_NAME}.cs (${TEST_TFM})"
    WORKING_DIRECTORY ${DOTNET_TEST_DIR})

  add_custom_target(dotnet_${COMPONENT_NAME}_${TEST_NAME}_${TEST_SUFFIX} ALL
    DEPENDS
    ${DOTNET_TEST_DIR}/timestamp_${TEST_SUFFIX}
    WORKING_DIRECTORY ${DOTNET_TEST_DIR})

  if(BUILD_TESTING)
      add_test(
        NAME dotnet_${COMPONENT_NAME}_${TEST_NAME}_${TEST_SUFFIX}
        COMMAND ${CMAKE_COMMAND} -E env --unset=TARGETNAME
        ${DOTNET_EXECUTABLE} test --nologo --framework ${TEST_TFM} -c Release
          WORKING_DIRECTORY ${DOTNET_TEST_DIR})
  endif()
  message(STATUS "  Configuring test ${FILE_NAME} (${TEST_TFM}) ...DONE")
endfunction()

# add_dotnet_test()
# CMake function to generate and build dotnet test.
# Currently only net6.0, net7.0 and net8.0 are supported
# Parameters:
#  the dotnet filename
# e.g.:
# add_dotnet_test(FooTests.cs)
function(add_dotnet_test FILE_NAME)
  message(STATUS "Configuring test ${FILE_NAME} ...")
  get_filename_component(TEST_NAME ${FILE_NAME} NAME_WE)
  get_filename_component(COMPONENT_DIR ${FILE_NAME} DIRECTORY)
  get_filename_component(COMPONENT_NAME ${COMPONENT_DIR} NAME)

  set(DOTNET_TEST_DIR ${PROJECT_BINARY_DIR}/dotnet/${COMPONENT_NAME}/${TEST_NAME})
  message(STATUS "build path: ${DOTNET_TEST_DIR}")

  configure_file(
    ${PROJECT_SOURCE_DIR}/dotnet/Test.csproj.in
    ${DOTNET_TEST_DIR}/${TEST_NAME}.csproj
    @ONLY)

  add_custom_command(
    OUTPUT ${DOTNET_TEST_DIR}/${TEST_NAME}.cs
    COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET_TEST_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy
      ${FILE_NAME}
      ${DOTNET_TEST_DIR}/
    MAIN_DEPENDENCY ${FILE_NAME}
    VERBATIM
    WORKING_DIRECTORY ${DOTNET_TEST_DIR})

  if(USE_DOTNET_6)
    add_dotnet_tfm_test(${FILE_NAME} net6.0)
  endif()
  if(USE_DOTNET_7)
    add_dotnet_tfm_test(${FILE_NAME} net7.0)
  endif()
  if(USE_DOTNET_8)
    add_dotnet_tfm_test(${FILE_NAME} net8.0)
  endif()
  message(STATUS "Configuring test ${FILE_NAME} ...DONE")
endfunction()

#######################
##  DOTNET WRAPPERS  ##
#######################
list(APPEND CMAKE_SWIG_FLAGS ${FLAGS} "-I${PROJECT_SOURCE_DIR}")

# Swig wrap all libraries
foreach(SUBPROJECT IN ITEMS
 Foo
 Bar
 FooBar)
  add_subdirectory(${SUBPROJECT}/dotnet)
  target_link_libraries(${DOTNET_NATIVE_LIBRARY} PRIVATE dotnet_${SUBPROJECT})
endforeach()

file(COPY ${PROJECT_SOURCE_DIR}/dotnet/logo.png DESTINATION ${PROJECT_BINARY_DIR}/dotnet)
set(DOTNET_LOGO_DIR "${PROJECT_BINARY_DIR}/dotnet")

configure_file(
  ${PROJECT_SOURCE_DIR}/dotnet/README.dotnet.md
  ${PROJECT_BINARY_DIR}/dotnet/README.md
  COPYONLY)
set(DOTNET_README_DIR "${PROJECT_BINARY_DIR}/dotnet")

configure_file(
  ${PROJECT_SOURCE_DIR}/dotnet/Directory.Build.props.in
  ${PROJECT_BINARY_DIR}/dotnet/Directory.Build.props)

file(MAKE_DIRECTORY ${DOTNET_PACKAGES_DIR})
############################
##  .Net Runtime Package  ##
############################
# *.csproj.in contains:
# CMake variable(s) (@PROJECT_NAME@) that configure_file() can manage and
# generator expression ($<TARGET_FILE:...>) that file(GENERATE) can manage.
configure_file(
  ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET_PACKAGE}.runtime.csproj.in
  ${DOTNET_NATIVE_PROJECT_DIR}/${DOTNET_NATIVE_PROJECT}.csproj.in
  @ONLY)
file(GENERATE
  OUTPUT ${DOTNET_NATIVE_PROJECT_DIR}/$<CONFIG>/${DOTNET_NATIVE_PROJECT}.csproj.in
  INPUT ${DOTNET_NATIVE_PROJECT_DIR}/${DOTNET_NATIVE_PROJECT}.csproj.in)

add_custom_command(
  OUTPUT ${DOTNET_NATIVE_PROJECT_DIR}/${DOTNET_NATIVE_PROJECT}.csproj
  COMMAND ${CMAKE_COMMAND} -E copy ./$<CONFIG>/${DOTNET_NATIVE_PROJECT}.csproj.in ${DOTNET_NATIVE_PROJECT}.csproj
  DEPENDS
    ${DOTNET_NATIVE_PROJECT_DIR}/$<CONFIG>/${DOTNET_NATIVE_PROJECT}.csproj.in
  WORKING_DIRECTORY ${DOTNET_NATIVE_PROJECT_DIR})

add_custom_command(
  OUTPUT ${DOTNET_NATIVE_PROJECT_DIR}/timestamp
  COMMAND ${CMAKE_COMMAND} -E env --unset=TARGETNAME
    ${DOTNET_EXECUTABLE} build --nologo -c Release -p:Platform=${DOTNET_PLATFORM} ${DOTNET_NATIVE_PROJECT}.csproj
  COMMAND ${CMAKE_COMMAND} -E env --unset=TARGETNAME
    ${DOTNET_EXECUTABLE} pack --nologo -c Release -p:Platform=${DOTNET_PLATFORM} ${DOTNET_NATIVE_PROJECT}.csproj
  COMMAND ${CMAKE_COMMAND} -E touch ${DOTNET_NATIVE_PROJECT_DIR}/timestamp
  DEPENDS
    ${PROJECT_BINARY_DIR}/dotnet/Directory.Build.props
    ${DOTNET_NATIVE_PROJECT_DIR}/${DOTNET_NATIVE_PROJECT}.csproj
    ${DOTNET_NATIVE_LIBRARY}
  BYPRODUCTS
    ${DOTNET_NATIVE_PROJECT_DIR}/bin
    ${DOTNET_NATIVE_PROJECT_DIR}/obj
  VERBATIM
  COMMENT "Generate .Net native package ${DOTNET_NATIVE_PROJECT} (${DOTNET_NATIVE_PROJECT_DIR}/timestamp)"
  WORKING_DIRECTORY ${DOTNET_NATIVE_PROJECT_DIR})

add_custom_target(dotnet_native_package
  DEPENDS
    ${DOTNET_NATIVE_PROJECT_DIR}/timestamp
  WORKING_DIRECTORY ${DOTNET_NATIVE_PROJECT_DIR})

####################
##  .Net Package  ##
####################
configure_file(
  ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET_PROJECT}.csproj.in
  ${DOTNET_PROJECT_DIR}/${DOTNET_PROJECT}.csproj.in
  @ONLY)

add_custom_command(
  OUTPUT ${DOTNET_PROJECT_DIR}/${DOTNET_PROJECT}.csproj
  COMMAND ${CMAKE_COMMAND} -E copy ${DOTNET_PROJECT}.csproj.in ${DOTNET_PROJECT}.csproj
  DEPENDS
    ${DOTNET_PROJECT_DIR}/${DOTNET_PROJECT}.csproj.in
  WORKING_DIRECTORY ${DOTNET_PROJECT_DIR})

add_custom_command(
  OUTPUT ${DOTNET_PROJECT_DIR}/timestamp
  COMMAND ${CMAKE_COMMAND} -E env --unset=TARGETNAME
    ${DOTNET_EXECUTABLE} build --nologo -c Release -p:Platform=${DOTNET_PLATFORM} ${DOTNET_PROJECT}.csproj
  COMMAND ${CMAKE_COMMAND} -E env --unset=TARGETNAME
    ${DOTNET_EXECUTABLE} pack --nologo -c Release -p:Platform=${DOTNET_PLATFORM} ${DOTNET_PROJECT}.csproj
  COMMAND ${CMAKE_COMMAND} -E touch ${DOTNET_PROJECT_DIR}/timestamp
  DEPENDS
    ${DOTNET_PROJECT_DIR}/${DOTNET_PROJECT}.csproj
    dotnet_native_package
  BYPRODUCTS
    ${DOTNET_PROJECT_DIR}/bin
    ${DOTNET_PROJECT_DIR}/obj
  VERBATIM
  COMMENT "Generate .Net package ${DOTNET_PROJECT} (${DOTNET_PROJECT_DIR}/timestamp)"
  WORKING_DIRECTORY ${DOTNET_PROJECT_DIR})

add_custom_target(dotnet_package ALL
  DEPENDS
    ${DOTNET_PROJECT_DIR}/timestamp
  WORKING_DIRECTORY ${DOTNET_PROJECT_DIR})

####################
##  .Net Example  ##
####################
# add_dotnet_example()
# CMake function to generate and build dotnet example.
# Parameters:
#  the dotnet filename
# e.g.:
# add_dotnet_example(Foo.cs net48)
function(add_dotnet_example FILE_NAME EXAMPLE_TFM)
  message(STATUS "Configuring example ${FILE_NAME} (${EXAMPLE_TFM}) ...")
  get_filename_component(EXAMPLE_NAME ${FILE_NAME} NAME_WE)
  get_filename_component(COMPONENT_DIR ${FILE_NAME} DIRECTORY)
  get_filename_component(COMPONENT_NAME ${COMPONENT_DIR} NAME)

  set(DOTNET_EXAMPLE_DIR
    ${PROJECT_BINARY_DIR}/dotnet/${COMPONENT_NAME}/${EXAMPLE_NAME}_${EXAMPLE_TFM})
  message(STATUS "build path: ${DOTNET_EXAMPLE_DIR}")

  configure_file(
    ${PROJECT_SOURCE_DIR}/dotnet/Example.csproj.in
    ${DOTNET_EXAMPLE_DIR}/${EXAMPLE_NAME}.csproj
    @ONLY)

  add_custom_command(
    OUTPUT ${DOTNET_EXAMPLE_DIR}/${EXAMPLE_NAME}.cs
    COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET_EXAMPLE_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy
      ${FILE_NAME}
      ${DOTNET_EXAMPLE_DIR}/
    MAIN_DEPENDENCY ${FILE_NAME}
    VERBATIM
    WORKING_DIRECTORY ${DOTNET_EXAMPLE_DIR})

  add_custom_command(
    OUTPUT ${DOTNET_EXAMPLE_DIR}/timestamp
    COMMAND ${CMAKE_COMMAND} -E env --unset=TARGETNAME
    ${DOTNET_EXECUTABLE} build --nologo --framework ${EXAMPLE_TFM} -c Release ${EXAMPLE_NAME}.csproj
    COMMAND ${CMAKE_COMMAND} -E env --unset=TARGETNAME
      ${DOTNET_EXECUTABLE} pack --nologo -c Release ${EXAMPLE_NAME}.csproj
    COMMAND ${CMAKE_COMMAND} -E touch ${DOTNET_EXAMPLE_DIR}/timestamp
    DEPENDS
      ${DOTNET_EXAMPLE_DIR}/${EXAMPLE_NAME}.csproj
      ${DOTNET_EXAMPLE_DIR}/${EXAMPLE_NAME}.cs
      dotnet_package
    BYPRODUCTS
      ${DOTNET_EXAMPLE_DIR}/bin
      ${DOTNET_EXAMPLE_DIR}/obj
    VERBATIM
    COMMENT "Compiling .Net ${COMPONENT_NAME}/${EXAMPLE_NAME}.cs for ${EXAMPLE_TFM} (${DOTNET_EXAMPLE_DIR}/timestamp)"
    WORKING_DIRECTORY ${DOTNET_EXAMPLE_DIR})

  add_custom_target(dotnet_${COMPONENT_NAME}_${EXAMPLE_NAME}_${EXAMPLE_TFM} ALL
    DEPENDS
      ${DOTNET_EXAMPLE_DIR}/timestamp
    WORKING_DIRECTORY ${DOTNET_EXAMPLE_DIR})

  if(BUILD_TESTING)
    add_test(
      NAME dotnet_${COMPONENT_NAME}_${EXAMPLE_NAME}_${EXAMPLE_TFM}
      COMMAND ${CMAKE_COMMAND} -E env --unset=TARGETNAME
      ${DOTNET_EXECUTABLE} run --no-build --framework ${EXAMPLE_TFM} -c Release ${EXAMPLE_NAME}.csproj
      WORKING_DIRECTORY ${DOTNET_EXAMPLE_DIR})
  endif()
  message(STATUS "Configuring example ${FILE_NAME} (${EXAMPLE_TFM}) done")
endfunction()
