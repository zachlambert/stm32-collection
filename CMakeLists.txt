cmake_minimum_required(VERSION 3.3)

project(stm32-collection)

cmake_policy(SET CMP0076 NEW)

# Need to compile for a specific microcontroller
# Stop if this isn't specified

if (NOT DEFINED MCU_NAME)
    message(FATAL_ERROR "Must set microcontroller name with -DMCU_NAME=...")
endif()

set(LIB_PATH /opt/stm32-collection/${MCU_NAME}/lib)
set(CMAKE_CONFIG_PATH /opt/stm32-collection/${MCU_NAME}/cmake)
set(INCLUDE_PATH /opt/stm32-collection/${MCU_NAME}/include)
set(TOOLCHAIN_PATH /opt/stm32-collection/toolchain)

set(SPECS nosys.specs)
set(NOSTARTFILES TRUE)
set(ENABLE_ERROR_HANDLING FALSE)
set(FreeRTOS_HEAP 1)

# === 1. COLLECT INFORMATION ABOUT MICROCONTROLLER ===
# Used to generate compiler flags, etc

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

# Also get the architecture for FreeRTOS
execute_process(COMMAND
    python3
    ${CMAKE_CURRENT_LIST_DIR}/scripts/freertos_arch.py ${genlink_cpu}
    OUTPUT_VARIABLE FreeRTOS_ARCH)
if (FreeRTOS_ARCH STREQUAL "")
    message(FATAL_ERROR "Failed to get freertos architecture")
endif()


# 2. === GENERATE LINKER SCRIPT ===
# Required when compiling the final executable, such that the linker knows
# where to put things in memory.

set(LINKER_SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/linker.ld)
set(INSTALL_LINKER_SCRIPT ${TOOLCHAIN_PATH}/ld/${MCU_NAME}.ld)
add_custom_command(
    OUTPUT ${LINKER_SCRIPT}
    COMMAND ${CMAKE_CXX_COMPILER} ${genlink_defs} -P -E ${opencm3_PATH}/ld/linker.ld.S -o ${LINKER_SCRIPT}
    COMMAND python3 ${CMAKE_CURRENT_LIST_DIR}/scripts/fix_linker.py ${ENABLE_ERROR_HANDLING} ${PROJECT_BINARY_DIR}/linker.ld
    DEPENDS ${opencm3_PATH}/ld/linker.ld.S ${DEVICES_DATA} ${CMAKE_CURRENT_LIST_DIR}/scripts/fix_linker.py
    COMMENT "Generating linker script"
)
add_custom_target(linker_script ALL DEPENDS ${LINKER_SCRIPT})


# 3. === GENERATE TOOLCHAIN FILE AND INCLUDE THIS ===
# Use the collected information to generate a toolchain file.
# This is required to build the following libraries and also for
# any executable that is built.
# In this CMakeLists.txt, the toolchain will be included.
# When building an executable (or external libraries), these will use
# the toolchain file with -DCMAKE_TOOLCHAIN=...

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

set(TGT_LDFLAGS ${ARCH_FLAGS})
list(APPEND TGT_LDFLAGS -specs=${SPECS} -Wl,--gc-sections)
list(APPEND TGT_LDFLAGS -Wl,-Map=${target}.map -Wl,--start-group)
list(APPEND TGT_LDFLAGS -lc -lgcc -Wl,--end-group)
if(${NOSTARTFILES})
    list(APPEND TGT_LDFLAGS -nostartfiles)
endif()
list(APPEND TGT_LDFLAGS -T${INSTALL_LINKER_SCRIPT})

set(TOOLCHAIN_FILE ${CMAKE_CURRENT_BINARY_DIR}/toolchain.cmake)
configure_file(template/toolchain.cmake ${TOOLCHAIN_FILE} @ONLY)
include(${TOOLCHAIN_FILE})

# 2. Build libraries

# 2a) opencm3
# This is already built, so created an IMPORTED library

add_library(opencm3 STATIC IMPORTED)
set_target_properties(opencm3 PROPERTIES IMPORTED_LOCATION ${opencm3_LIB})
target_include_directories(opencm3 INTERFACE
    ${opencm3_PATH}/include
)
# Technically, an executable depends on the linker script, but convenient
# to attach to opencm3, to make sure it is generated when installing opencm3.
add_dependencies(opencm3 linker_script)


# 2b) FreeRTOS

set(FreeRTOS_COMPILER GCC)
set(FreeRTOS_CONFIG_DIR ${CMAKE_CURRENT_LIST_DIR}/FreeRTOSConfig/${MCU_NAME})
set(FreeRTOS_CONFIG ${FreeRTOS_CONFIG_DIR}/FreeRTOSConfig.h)

# Add the config as a target to force a rebuild when this changes
add_custom_target(freertos_config ALL DEPENDS ${FreeRTOS_CONFIG})

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
target_include_directories(freertos PUBLIC
    ${FreeRTOS_PATH}/include
    ${FreeRTOS_PATH}/portable/${FreeRTOS_COMPILER}/${FreeRTOS_ARCH}
    ${FreeRTOS_CONFIG_DIR}
)
add_dependencies(freertos freertos_config)

# 2c) nanoprintf

set(nanoprintf_PATH ${CMAKE_CURRENT_LIST_DIR}/nanoprintf)
add_library(nanoprintf STATIC
    ${nanoprintf_PATH}/nanoprintf.c
)
target_include_directories(nanoprintf PUBLIC
    ${nanoprintf_PATH}/nanoprintf
)


# 3. Setup installation


# 3a) Install headers to ${INSTALL_PATH}

install(
    DIRECTORY ${opencm3_PATH}/include/
    DESTINATION ${INCLUDE_PATH}/opencm3
)
install(
    DIRECTORY ${FreeRTOS_PATH}/include/
    DESTINATION ${INCLUDE_PATH}/freertos
)
install(
    DIRECTORY ${FreeRTOS_PATH}/portable/${FreeRTOS_COMPILER}/${FreeRTOS_ARCH}/
    DESTINATION ${INCLUDE_PATH}/freertos_portable
)
install(
    DIRECTORY ${FreeRTOS_CONFIG_DIR}/
    DESTINATION ${INCLUDE_PATH}/freertos_config
)
install(
    FILES ${nanoprintf_PATH}/nanoprintf/nanoprintf.h
    DESTINATION ${INCLUDE_PATH}
)

# 3b) Install library files

install(
    FILES ${opencm3_LIB}
    DESTINATION ${LIB_PATH}
    RENAME libopencm3.a
)
install(
    TARGETS freertos nanoprintf
    LIBRARY DESTINATION ${LIB_PATH}
    ARCHIVE DESTINATION ${LIB_PATH}
)

# 3c) Generate and install cmake config file

set(CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/stm32-collection-config.cmake)
configure_file(template/stm32-collection.cmake ${CONFIG_FILE})
install(
    FILES ${CONFIG_FILE}
    DESTINATION ${CMAKE_CONFIG_PATH}
)

# 3d) Install toolchain file

install(
    FILES ${TOOLCHAIN_FILE}
    DESTINATION ${TOOLCHAIN_PATH}
    RENAME ${MCU_NAME}.cmake
)

# 3e) Install linker script

install(
    FILES ${LINKER_SCRIPT}
    DESTINATION ${TOOLCHAIN_PATH}/ld
    RENAME ${MCU_NAME}.ld
)
