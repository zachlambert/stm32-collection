# stm32-collection

Collection of libraries useful for stm32 development, setup for use with cmake.  
Currently only tested for stm32f103c8t6, but should work for other boards.

Uses libopencm3, an arm firmware library that I prefer to the standard stm32 HAL.  
The makefiles provided by libopencm3 automatically provide appropriate compiler defines, architecture flags, etc, and generate a linker script.  
This has been ported to cmake.

To use, append the directory of stm32-collection to CMAKE_PREFIX_PATH as shown in the example:
- Call `find_package(stm32-collection COMPONENTS <mcu name> [<other libraries/options>])`
  This will also setup the toolchain
- Call `stm32_set_compile_options_c(<target>)` to set the compile options for a C library or executable
- Call `stm32_set_compile_options_cxx(<target>)` to set the compile options for a C++ library or executable
- Call `stm32_configure_executable(<target>)` to setup the linker options (including a generated linker script) for the executable, and add post-build targets (bin, hex).

Optional libraries specified as find_package components:
- `freertos`: FreeRTOS
- `nanoprintf`: A printf/snprintf/etc implementation with a smaller binary size

Options specified as find_package components:
- `specs-nano`: Uses the linker flag '-specs=nano.specs' instead of the default '-specs=nosys.specs'
- `nostartfiles`: Uses the linker flag '-nostartfiles' which is omitted by default.
- `enable-error-handling`: Adjusted the generated linker script to allow error handling, which although increases the binary size, is required for certain C++ feature (eg: pure virtual classes).
