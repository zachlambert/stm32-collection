cmake_minimum_required(VERSION 3.3)

project(stm32-collection)

set(MCU_NAME stm32f103x8)
set(USE_FREERTOS TRUE)
set(USE_NANOPRINTF TRUE)
set(FreeRTOS_CONFIG_DIR ${CMAKE_CURRENT_LIST_DIR}/FreeRTOSConfig/stm32f103x8)

set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_AR arm-none-eabi-ar)
set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
set(CMAKE_SIZE arm-none-eabi-size)

set(opencm3_PATH ${CMAKE_CURRENT_LIST_DIR}/libopencm3)
set(DEVICES_DATA ${opencm3_PATH}/ld/devices.data)
execute_process(COMMAND
    python3
    ${opencm3_PATH}/scripts/genlink.py ${DEVICES_DATA} ${MCU_NAME} FAMILY
    OUTPUT_VARIABLE genlink_family)
execute_process(COMMAND
    python3
    ${opencm3_PATH}/scripts/genlink.py ${DEVICES_DATA} ${MCU_NAME} SUBFAMILY
    OUTPUT_VARIABLE genlink_subfamily)
execute_process(COMMAND
    python3
    ${opencm3_PATH}/scripts/genlink.py ${DEVICES_DATA} ${MCU_NAME} CPU
    OUTPUT_VARIABLE genlink_cpu)
execute_process(COMMAND
    python3
    ${opencm3_PATH}/scripts/genlink.py ${DEVICES_DATA} ${MCU_NAME} FPU
    OUTPUT_VARIABLE genlink_fpu)
execute_process(COMMAND
    python3
    ${opencm3_PATH}/scripts/genlink.py ${DEVICES_DATA} ${MCU_NAME} CPPFLAGS
    OUTPUT_VARIABLE genlink_cpp_flags)
execute_process(COMMAND
    python3
    ${opencm3_PATH}/scripts/genlink.py ${DEVICES_DATA} ${MCU_NAME} DEFS
    OUTPUT_VARIABLE genlink_defs_str)
separate_arguments(genlink_defs UNIX_COMMAND ${genlink_defs_str})

set(LINKER_SCRIPT ${PROJECT_BINARY_DIR}/linker.ld)
add_custom_command(
    OUTPUT ${LINKER_SCRIPT}
    COMMAND ${CMAKE_CXX_COMPILER} ${genlink_defs} -P -E ${opencm3_PATH}/ld/linker.ld.S -o ${LINKER_SCRIPT}
    COMMAND python3 ${CMAKE_CURRENT_LIST_DIR}/scripts/fix_linker.py ${ENABLE_ERROR_HANDLING} ${PROJECT_BINARY_DIR}/linker.ld
    DEPENDS ${opencm3_PATH}/ld/linker.ld.S ${DEVICES_DATA} ${CMAKE_CURRENT_LIST_DIR}/scripts/fix_linker.py
    COMMENT "Generating linker script"
)
add_custom_target(linker_script ALL DEPENDS ${LINKER_SCRIPT})

set(ARCH_FLAGS -mcpu=${genlink_cpu})

set(MTHUMB_LIST "cortex-m0;cortex-m0plus;cortex-m3;cortex-m4;cortex-m7")
if(${genlink_cpu} IN_LIST MTHUMB_LIST)
    list(APPEND ARCH_FLAGS -mthumb)
endif()

if(${genlink_fpu} STREQUAL "soft")
    list(APPEND ARCH_FLAGS -msoft-float)
elseif(${genlink_fpu} STREQUAL "hard-fpv4-sp-d16")
    list(APPEND ARCH_FLAGS -mfloat-abi=hard -mfpu=fpv4-sp-d16)
elseif(${genlink_fpu} STREQUAL "hard-fpv5-sp-d16")
    list(APPEND ARCH_FLAGS -mfloat-abi=hard -mfpu=fpv5-sp-d16)
else()
    message(FATAL_ERROR "Unrecognised fpu type ${genlink_fpu}")
endif()

set(opencm3_LIB ${opencm3_PATH}/lib/libopencm3_${genlink_family}.a)
if(NOT EXISTS ${opencm3_LIB})
    set(opencm3_LIB ${opencm3_PATH}/lib/libopencm3_${genlink_subfamily}.a)
endif()
if(NOT EXISTS ${opencm3_LIB})
    message(FATAL_ERROR "No library exists for ${genlink_family} or ${genlink_subfamily}")
endif()

add_library(opencm3 STATIC IMPORTED)
set_target_properties(opencm3 PROPERTIES IMPORTED_LOCATION ${opencm3_LIB})
target_include_directories(opencm3 INTERFACE ${opencm3_PATH}/include)

set(OPT -Os)


# C and CXX
separate_arguments(TGT_CPPFLAGS UNIX_COMMAND ${genlink_cpp_flags})
list(APPEND TGT_CPPFLAGS ${ARCH_FLAGS})
list(APPEND TGT_CPPFLAGS -MD -Wall -Wundef)
# C
set(TGT_CFLAGS ${OS} -std=c99 -ggdb3 ${ARCH_FLAGS})
list(APPEND TGT_CFLAGS -fno-common)
list(APPEND TGT_CFLAGS -ffunction-sections -fdata-sections)
list(APPEND TGT_CFLAGS -Wextra -Wno-unused-variables -Wimplicit-function-declaration)
list(APPEND TGT_CFLAGS -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes)
# C++
set(TGT_CXXFLAGS ${OS} -ggdb3 ${ARCH_FLAGS})
list(APPEND TGT_CXXFLAGS -fno-common)
list(APPEND TGT_CXXFLAGS -ffunction-sections -fdata-sections)
list(APPEND TGT_CXXFLAGS -Wextra -Wredundant-decls)

set(TGT_LDFLAGS -T${LINKER_SCRIPT} ${ARCH_FLAGS})
list(APPEND TGT_LDFLAGS -specs=${SPECS} -Wl,--gc-sections)

function(stm32_set_compile_options_c target)
    target_compile_options(${target} PRIVATE ${TGT_CPPFLAGS} ${TGT_CFLAGS})
endfunction()
function(stm32_set_compile_options_cxx target)
    target_compile_options(${target} PRIVATE ${TGT_CPPFLAGS} ${TGT_CXXFLAGS})
endfunction()

set(FreeRTOS_COMPILER GCC)
if(NOT DEFINED FreeRTOS_CONFIG_DIR)
    message(FATAL_ERROR "Must set FreeRTOS_CONFIG_DIR to the directory containing FreeRTOSConfig.h")
endif()
set(FreeRTOS_CONFIG ${FreeRTOS_CONFIG_DIR}/FreeRTOSConfig.h)
if(NOT EXISTS ${FreeRTOS_CONFIG})
    message(FATAL_ERROR "File ${FreeRTOS_CONFIG} doesn't exist")
endif()
add_custom_target(freertos_config ALL DEPENDS ${FreeRTOS_CONFIG})

execute_process(COMMAND
    python3
    ${CMAKE_CURRENT_LIST_DIR}/scripts/freertos_arch.py ${genlink_cpu}
    OUTPUT_VARIABLE FreeRTOS_ARCH)
if (FreeRTOS_ARCH STREQUAL "")
    message(FATAL_ERROR "Failed to get freertos architecture")
endif()

set(FreeRTOS_PATH ${CMAKE_CURRENT_LIST_DIR}/FreeRTOS/FreeRTOS/Source)
set(FreeRTOS_SOURCE
    ${FreeRTOS_PATH}/tasks.c
    ${FreeRTOS_PATH}/queue.c
    ${FreeRTOS_PATH}/list.c
    ${FreeRTOS_PATH}/portable/${FreeRTOS_COMPILER}/${FreeRTOS_ARCH}/port.c
    ${FreeRTOS_PATH}/timers.c
    ${FreeRTOS_PATH}/event_groups.c
    ${FreeRTOS_PATH}/stream_buffer.c
)
if(DEFINED FreeRTOS_HEAP)
    list(APPEND FreeRTOS_SOURCE ${FreeRTOS_PATH}/portable/MemMang/heap_${FreeRTOS_HEAP}.c)
endif()
add_library(freertos STATIC ${FreeRTOS_SOURCE})
target_include_directories(freertos
    PUBLIC
        ${FreeRTOS_PATH}/include
        ${FreeRTOS_PATH}/portable/${FreeRTOS_COMPILER}/${FreeRTOS_ARCH}
        ${FreeRTOS_CONFIG_DIR}
)
add_dependencies(freertos freertos_config)
stm32_set_compile_options_c(freertos)

set(nanoprintf_PATH ${CMAKE_CURRENT_LIST_DIR}/nanoprintf)
add_library(nanoprintf STATIC
    ${nanoprintf_PATH}/nanoprintf.c
)
target_include_directories(nanoprintf PUBLIC
    ${nanoprintf_PATH}/include
)
stm32_set_compile_options_c(nanoprintf)

install(
    TARGETS
        freertos
        nanoprintf
    DESTINATION
        /opt/stm32-collection/stm32f103x8
)
install(
    FILES
        ${opencm3_LIB}
    DESTINATION
        /opt/stm32-collection/stm32f103x8
)
install(
    FILES
        toolchain/${MCU_NAME}.cmake
    DESTINATION
        /opt/stm32-collection/toolchain
)
