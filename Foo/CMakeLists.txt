add_library(Foo "")
target_sources(Foo
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include/foo/Foo.hpp>
  PRIVATE
    src/Foo.cpp
  )
target_include_directories(Foo
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
  )
target_compile_features(Foo PUBLIC cxx_std_11)
set_target_properties(Foo PROPERTIES
  VERSION ${PROJECT_VERSION}
  PUBLIC_HEADER $<TARGET_PROPERTY:Foo,INTERFACE_SOURCES>
  )
#target_link_libraries(Foo PUBLIC ...)
add_library(${PROJECT_NAMESPACE}::Foo ALIAS Foo)

if(BUILD_TESTING)
  add_subdirectory(test)
endif()

# Install
install(TARGETS Foo
  EXPORT ${PROJECT_NAME}Targets
  PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/foo
  )
