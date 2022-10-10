cmake_minimum_required(VERSION 3.13)

project(example)

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_CURRENT_LIST_DIR}/../)
set(FreeRTOS_CONFIG_DIR ${CMAKE_CURRENT_LIST_DIR}/config)
set(FreeRTOS_HEAP 1)
find_package(stm32-collection COMPONENTS
    stm32f103x8
    freertos
    nanoprintf
    enable-error-handling
REQUIRED)

add_executable(example
    src/main.cpp
    src/usb.cpp
)
stm32_set_compile_options_cxx(example)
stm32_configure_executable(example)
target_include_directories(example PRIVATE include)
target_link_libraries(example freertos)
target_link_libraries(example nanoprintf)
