cmake_minimum_required(VERSION 3.13)
project(example)

find_package(stm32-collection)

add_executable(example
    src/main.cpp
    src/usb.cpp
)
target_include_directories(example PRIVATE include)
target_link_libraries(example opencm3)
target_link_libraries(example freertos)
target_link_libraries(example nanoprintf)
