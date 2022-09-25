

set(OPENCM3_LINKER_DIR ${CMAKE_CURRENT_LIST_DIR}/mcus)
set(USE_FREERTOS FALSE)
set(USE_NANOPRINTF FALSE)
foreach(component ${stm32-collection_FIND_COMPONENTS})
    if(${component} STREQUAL "freertos")
        set(USE_FREERTOS TRUE)
    elseif(${component} STREQUAL "nanoprintf")
        set(USE_NANOPRINTF TRUE)
    else()
        set(MCU_CONFIG ${CMAKE_CURRENT_LIST_DIR}/mcus/${component}.cmake)
        if(NOT EXISTS ${MCU_CONFIG})
            message(WARNING "Ignoring invalid component ${component}")
        elseif(DEFINED MCU_NAME)
            message(WARNING "Already specified a microcontroller, ignoring component ${component}")
        else()
            include(${MCU_CONFIG})
            set(MCU_NAME ${component})
        endif()
    endif()
endforeach()

if (NOT ${HAVE_MCU})
    message(FATAL_ERROR "No microcontroller specified")
endif()

add_library(opencm3 STATIC IMPORTED)
set_target_properties(opencm3 PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/libopencm3/lib/libopencm3_${OPENCM3_MCU_LIB}.a
)
target_include_directories(opencm3 INTERFACE ${CMAKE_CURRENT_LIST_DIR}/libopencm3/include)

function(stm32_setup_toolchain)
    set(CMAKE_C_COMPILER arm-none-eabi-gcc PARENT_SCOPE)
    set(CMAKE_CXX_COMPILER arm-none-eabi-g++ PARENT_SCOPE)
    set(CMAKE_ASM_COMPILER arm-none-eabi-gcc PARENT_SCOPE)
    set(CMAKE_AR arm-none-eabi-ar PARENT_SCOPE)
    set(CMAKE_OBJCOPY arm-none-eabi-objcopy PARENT_SCOPE)
    set(CMAKE_SIZE arm-none-eabi-size PARENT_SCOPE)
    unset(CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES PARENT_SCOPE)
    unset(CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES PARENT_SCOPE)
    unset(CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES PARENT_SCOPE)
    unset(CMAKE_C_IMPLICIT_LINK_DIRECTORIES PARENT_SCOPE)
endfunction()

function(stm32_configure_target target)
    target_compile_options(${target} PRIVATE
        ${CPU_PARAMETERS}
        ${OPENCM3_MCU_FLAG}
        -Wall
        -fno-common -ffunction-sections -fdata-sections
        $<$<CONFIG:Debug>:-Og -g3 -ggdb>
        $<$<CONFIG:Release>:-Og -g0>
    )
    target_link_options(${target} PRIVATE
        -T${OPENCM3_LINKER_DIR}/${MCU_NAME}.ld
        ${CPU_PARAMETERS}
        -nostartfiles --specs=nosys.specs
        -ggdb3
        -lnosys
        -Wl,--gc-sections
    )
endfunction()

function(stm32_configure_executable name)
    set_target_properties(${name} PROPERTIES SUFFIX ".elf")
    target_link_libraries(${name} opencm3)
    stm32_configure_target(${name})
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${name}>
    )
    add_custom_command(
        TARGET ${name}
        POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${name}>
        ${name}.hex
        COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${name}>
        ${name}.bin
        COMMENT "Creating ${name}.bin and ${name}.hex."
    )
endfunction()

if(${USE_FREERTOS})
    set(FreeRTOS_COMPILER GCC)
    if (NOT DEFINED FreeRTOS_HEAP)
        set(FreeRTOS_HEAP 2)
    endif()
    if(NOT DEFINED FreeRTOS_CONFIG_DIR)
        message(FATAL_ERROR "Must set FreeRTOS_CONFIG_DIR to the directory containing FreeRTOSConfig.h")
    endif()

    set(FreeRTOS_PATH ${CMAKE_CURRENT_LIST_DIR}/FreeRTOS/FreeRTOS/Source)
    add_library(freertos STATIC
        ${FreeRTOS_PATH}/tasks.c
        ${FreeRTOS_PATH}/queue.c
        ${FreeRTOS_PATH}/list.c
        ${FreeRTOS_PATH}/portable/MemMang/heap_${FreeRTOS_HEAP}.c
        ${FreeRTOS_PATH}/portable/${FreeRTOS_COMPILER}/${FreeRTOS_ARCH}/port.c
        ${FreeRTOS_PATH}/timers.c
        # ${FreeRTOS_PATH}/event_groups.c
        # ${FreeRTOS_PATH}/stream_buffer.c
    )
    target_include_directories(freertos
        PUBLIC
            ${FreeRTOS_PATH}/include
            ${FreeRTOS_PATH}/portable/${FreeRTOS_COMPILER}/${FreeRTOS_ARCH}
            ${FreeRTOS_CONFIG_DIR}
    )
    stm32_configure_target(freertos)
endif()

if(${USE_NANOPRINTF})
    set(nanoprintf_PATH ${CMAKE_CURRENT_LIST_DIR}/nanoprintf)
    add_library(nanoprintf STATIC
        ${nanoprintf_PATH}/nanoprintf.c
    )
    target_include_directories(nanoprintf PUBLIC
        ${nanoprintf_PATH}/include
    )
    stm32_configure_target(nanoprintf)
endif()
