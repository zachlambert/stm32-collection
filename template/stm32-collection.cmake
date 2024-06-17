
cmake_minimum_required(VERSION 3.3)

set(INCLUDE_PATH /opt/stm32-collection/${MCU_NAME}/include)
set(LIB_PATH /opt/stm32-collection/${MCU_NAME}/lib)

add_library(opencm3 STATIC IMPORTED)
set_target_properties(opencm3 PROPERTIES IMPORTED_LOCATION ${LIB_PATH}/libopencm3.a)
target_include_directories(opencm3 INTERFACE ${INCLUDE_PATH}/opencm3)

add_library(freertos STATIC IMPORTED)
set_target_properties(freertos PROPERTIES IMPORTED_LOCATION ${LIB_PATH}/libfreertos.a)
target_include_directories(freertos INTERFACE
    ${INCLUDE_PATH}/freertos
    ${INCLUDE_PATH}/freertos_portable
    ${INCLUDE_PATH}/freertos_config
)

add_library(nanoprintf STATIC IMPORTED)
set_target_properties(nanoprintf PROPERTIES IMPORTED_LOCATION ${LIB_PATH}/libnanoprintf.a)
target_include_directories(nanoprintf INTERFACE ${INCLUDE_PATH})
