if(NOT BUILD_EXAMPLES)
  return()
endif()

file(GLOB CPP_SRCS "*.cpp")
foreach(FILE_NAME IN LISTS CPP_SRCS)
  add_cpp_example(${FILE_NAME})
endforeach()

file(GLOB DOTNET_SRCS "*.cs")
foreach(FILE_NAME IN LISTS DOTNET_SRCS)
  add_dotnet_example(${FILE_NAME} ${EXAMPLE_TFM})
endforeach()
