cmake_minimum_required(VERSION 3.13)

project(example)

include(/opt/stm32-collection/toolchain/stm32f103x8.cmake)
list(APPEND CMAKE_PREFIX_PATH /opt/stm32-collection/stm32f103x8/lib)

find_package(stm32-collection)

add_executable(example
    src/main.cpp
    src/usb.cpp
)
# stm32_set_compile_options_cxx(example)
# stm32_configure_executable(example)
target_include_directories(example PRIVATE include)
target_link_libraries(example opencm3)
target_link_libraries(example freertos)
target_link_libraries(example nanoprintf)
