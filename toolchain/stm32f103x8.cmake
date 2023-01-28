
# Set to 'Generic' for systems that don't have an OS (eg: embedded)
set(CMAKE_SYSTEM_NAME Generic)
# Custom argument, used to select build options from:
# ${CMAKE_SYSTEM_NAME}-COMPILER_ID-${CMAKE_SYSTEM_PROCESSOR}
set(CMAKE_SYSTEM_PROCESSOR stm32f103x8)

set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_AR arm-none-eabi-ar)
set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
set(CMAKE_SIZE arm-none-eabi-size)

# Whenever you call 'find_package' or other 'find_...' commands, it will
# prepend with this path. Install target-specific libraries to here.
# Will search for libraries in 'path/lib' and 'path/usr/lib'
set(CMAKE_FIND_ROOT_PATH  /opt/stm32-collection/stm32f103x8)

# Never search for programs on the host
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Search headers and libraries in the target environment
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
