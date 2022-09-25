# stm32-collection

Collection of libraries useful for stm32 development, setup for use with cmake.  
Currently only setup for stm32f103c8t6, but is trivial to extend to other microcontrollers (including non-stm32 microcontrollers).

Contains:
- libopencm3, an arm firmware library that I prefer to the standard stm32 HAL
- FreeRTOS
- nanoprintf, a printf/snprintf/etc implementation with a smaller binary size

To use, append the directory of stm32-collection to CMAKE_PREFIX_PATH as shown in the example:
- Call `find_package(stm32-collection COMPONENTS <mcu name> [<other libraries>])`
- Call `stm32_setup_toolchain()` to set the compilers
- Call `stm32_configure_executable(<target>)` to add appropriate compiler/linker flags and setup post-build targets
- Call `stm32_configure_target(<target>)` on libraries to add appropriate compiler/linker flags
