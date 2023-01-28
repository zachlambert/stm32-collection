
# Set to 'Generic' for systems that don't have an OS (eg: embedded)
set(CMAKE_SYSTEM_NAME Generic)
# Custom argument, used to select build options from:
# ${CMAKE_SYSTEM_NAME}-COMPILER_ID-${CMAKE_SYSTEM_PROCESSOR}
set(CMAKE_SYSTEM_PROCESSOR @MCU_NAME@)

set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_AR arm-none-eabi-ar)
set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
set(CMAKE_SIZE arm-none-eabi-size)

# Whenever you call 'find_package' or other 'find_...' commands, it will
# prepend with this path. Install target-specific libraries to here.
# Will search for libraries in 'path/lib' and 'path/usr/lib'
set(CMAKE_FIND_ROOT_PATH  /opt/stm32-collection/@MCU_NAME@)

# Never search for programs on the host
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Search headers and libraries in the target environment
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

list(APPEND CMAKE_PREFIX_PATH {CMAKE_FIND_ROOT_PATH}/lib)

# When copying lists into configure_file, cmake converts them to strings,
# which put's ";" inside the list. Need to correct for this.
string(REPLACE ";" " " TGT_CPPFLAGS_LIST "@TGT_CPPFLAGS@")
string(REPLACE ";" " " TGT_CFLAGS_LIST "@TGT_CFLAGS@")
string(REPLACE ";" " " TGT_CXXFLAGS_LIST "@TGT_CXXFLAGS@")
string(REPLACE ";" " " TGT_LDFLAGS_LIST "@TGT_LDFLAGS@")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${TGT_CPPFLAGS_LIST} ${TGT_C_FLAGS_LIST}")
string(STRIP "${CMAKE_C_FLAGS}" CMAKE_C_FLAGS)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${TGT_CPPFLAGS_LIST} ${TGT_CXX_FLAGS}")
string(STRIP "${CMAKE_CXX_FLAGS}" CMAKE_CXX_FLAGS)
set(CMAKE_EXECUTABLE_SUFFIX ".elf")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${TGT_LDFLAGS_LIST}")
string(STRIP "${CMAKE_LD_FLAGS}" CMAKE_LD_FLAGS)

function(stm32_add_post_build target)
    add_custom_command(
        TARGET ${target}
        POST_BUILD
        COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${target}>
    )
    add_custom_command(
        TARGET ${target}
        POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -Obinary $<TARGET_FILE:${target}> ${target}.bin
        COMMAND ${CMAKE_OBJCOPY} -Oihex $<TARGET_FILE:${target}> ${target}.hex
        COMMAND ${CMAKE_OBJCOPY} -Osrec $<TARGET_FILE:${target}> ${target}.srec
        COMMAND ${CMAKE_OBJCOPY} -S $<TARGET_FILE:${target}> > ${target}.list
        COMMENT "Creating postbuild objects for ${target}"
    )
endfunction()
