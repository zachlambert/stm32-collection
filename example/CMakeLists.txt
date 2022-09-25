cmake_minimum_required(VERSION 3.13)

project(blink)

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_CURRENT_LIST_DIR}/../)
set(FreeRTOS_CONFIG_DIR ${CMAKE_CURRENT_LIST_DIR}/config)
find_package(stm32-collection COMPONENTS stm32f103c8t6 freertos nanoprintf REQUIRED)

stm32_setup_toolchain()
set(CMAKE_CXX_STANDARD 20)

add_executable(blink
    src/main.cpp
    src/usb.cpp
)
stm32_configure_executable(blink)
target_include_directories(blink PRIVATE include)
target_link_libraries(blink freertos)
target_link_libraries(blink nanoprintf)
