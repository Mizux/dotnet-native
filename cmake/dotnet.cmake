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

file(GENERATE OUTPUT dotnet/$<CONFIG>/replace_runtime.cmake
  CONTENT
  "FILE(READ ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET}.runtime.csproj.in input)
  STRING(REPLACE \"@PROJECT_VERSION@\" \"${PROJECT_VERSION}\" input \"\${input}\")
  STRING(REPLACE \"@RUNTIME_IDENTIFIER@\" \"${RUNTIME_IDENTIFIER}\" input \"\${input}\")
  STRING(REPLACE \"@DOTNET@\" \"${DOTNET}\" input \"\${input}\")
  STRING(REPLACE \"@DOTNET_NATIVE@\" \"${DOTNET_NATIVE}\" input \"\${input}\")
  STRING(REPLACE \"@Foo@\" \"$<TARGET_FILE:Foo>\" input \"\${input}\")
  STRING(REPLACE \"@native@\" \"$<TARGET_FILE:mizux-foo-native>\" input \"\${input}\")
  FILE(WRITE ${DOTNET_NATIVE}/${DOTNET_NATIVE}.csproj \"\${input}\")"
  )

add_custom_command(
  OUTPUT dotnet/${DOTNET_NATIVE}/${DOTNET_NATIVE}.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET_NATIVE}
  COMMAND ${CMAKE_COMMAND} -P ./$<CONFIG>/replace_runtime.cmake
  WORKING_DIRECTORY dotnet
  )

add_custom_target(dotnet_native_package
  DEPENDS
  mizux-foo-native
  dotnet/${DOTNET_NATIVE}/${DOTNET_NATIVE}.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory packages
  COMMAND ${DOTNET_EXECUTABLE} build -c Release /p:Platform=x64 ${DOTNET_NATIVE}/${DOTNET_NATIVE}.csproj
  COMMAND ${DOTNET_EXECUTABLE} pack -c Release ${DOTNET_NATIVE}/${DOTNET_NATIVE}.csproj
  WORKING_DIRECTORY dotnet
  )

#################
##  Mizux.Foo  ##
#################
file(GENERATE OUTPUT dotnet/$<CONFIG>/replace.cmake
  CONTENT
  "FILE(READ ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET}.csproj.in input)
  STRING(REPLACE \"@PROJECT_VERSION@\" \"${PROJECT_VERSION}\" input \"\${input}\")
  STRING(REPLACE \"@DOTNET@\" \"${DOTNET}\" input \"\${input}\")
  STRING(REPLACE \"@DOTNET_PACKAGES_DIR@\" \"${PROJECT_BINARY_DIR}/dotnet/packages\" input \"\${input}\")
  FILE(WRITE ${DOTNET}/${DOTNET}.csproj \"\${input}\")"
  )

add_custom_command(
  OUTPUT dotnet/${DOTNET}/${DOTNET}.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET}
  COMMAND ${CMAKE_COMMAND} -P ./$<CONFIG>/replace.cmake
  WORKING_DIRECTORY dotnet
  )

add_custom_target(dotnet_package ALL
  DEPENDS
    dotnet_native_package
    dotnet/${DOTNET}/${DOTNET}.csproj
  COMMAND ${DOTNET_EXECUTABLE} build -c Release /p:Platform=x64 ${DOTNET}/${DOTNET}.csproj
  COMMAND ${DOTNET_EXECUTABLE} pack -c Release ${DOTNET}/${DOTNET}.csproj
  WORKING_DIRECTORY dotnet
  )

######################
##  Mizux.FooTests  ##
######################
add_custom_command(
  OUTPUT dotnet/${DOTNET}Tests/FooTests.cs
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET}Tests
  COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_SOURCE_DIR}/dotnet/FooTests.cs ${DOTNET}Tests/FooTests.cs
  WORKING_DIRECTORY dotnet
  )

file(GENERATE OUTPUT dotnet/$<CONFIG>/replace_FooTests.cmake
  CONTENT
  "FILE(READ ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET}Tests.csproj.in input)
  STRING(REPLACE \"@PROJECT_VERSION@\" \"${PROJECT_VERSION}\" input \"\${input}\")
  STRING(REPLACE \"@DOTNET@\" \"${DOTNET}\" input \"\${input}\")
  STRING(REPLACE \"@DOTNET_PACKAGES_DIR@\" \"${PROJECT_BINARY_DIR}/dotnet/packages\" input \"\${input}\")
  FILE(WRITE ${DOTNET}Tests/${DOTNET}Tests.csproj \"\${input}\")"
  )

add_custom_command(
  OUTPUT dotnet/${DOTNET}Tests/${DOTNET}Tests.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET}Tests
  COMMAND ${CMAKE_COMMAND} -P ./$<CONFIG>/replace_FooTests.cmake
  WORKING_DIRECTORY dotnet
  )

add_custom_target(FooTests ALL
  DEPENDS
    dotnet_package
    dotnet/${DOTNET}Tests/FooTests.cs
    dotnet/${DOTNET}Tests/${DOTNET}Tests.csproj
  COMMAND ${DOTNET_EXECUTABLE} build -c Release /p:Platform=x64 ${DOTNET}Tests/${DOTNET}Tests.csproj
  WORKING_DIRECTORY dotnet
  )

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
  WORKING_DIRECTORY dotnet
  )

file(GENERATE OUTPUT dotnet/$<CONFIG>/replace_FooApp.cmake
  CONTENT
  "FILE(READ ${PROJECT_SOURCE_DIR}/dotnet/${DOTNET}App.csproj.in input)
  STRING(REPLACE \"@PROJECT_VERSION@\" \"${PROJECT_VERSION}\" input \"\${input}\")
  STRING(REPLACE \"@DOTNET@\" \"${DOTNET}\" input \"\${input}\")
  STRING(REPLACE \"@DOTNET_PACKAGES_DIR@\" \"${PROJECT_BINARY_DIR}/dotnet/packages\" input \"\${input}\")
  FILE(WRITE ${DOTNET}App/${DOTNET}App.csproj \"\${input}\")"
  )

add_custom_command(
  OUTPUT dotnet/${DOTNET}App/${DOTNET}App.csproj
  COMMAND ${CMAKE_COMMAND} -E make_directory ${DOTNET}App
  COMMAND ${CMAKE_COMMAND} -P ./$<CONFIG>/replace_FooApp.cmake
  WORKING_DIRECTORY dotnet
  )

add_custom_target(FooApp ALL
  DEPENDS
    dotnet_package
    dotnet/${DOTNET}App/FooApp.cs
    dotnet/${DOTNET}App/${DOTNET}App.csproj
  COMMAND ${DOTNET_EXECUTABLE} build -c Release /p:Platform=x64 ${DOTNET}App/${DOTNET}App.csproj
  WORKING_DIRECTORY dotnet
  )

if(BUILD_TESTING)
  add_test(NAME FooAppUT
    COMMAND ${DOTNET_EXECUTABLE} run -c Release --project ${DOTNET}App/${DOTNET}App.csproj
    WORKING_DIRECTORY dotnet)
endif()
