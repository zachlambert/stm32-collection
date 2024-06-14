# stm32-collection

Collection of libraries useful for stm32 development, setup for use with cmake.
Currently only tested for stm32f103c8t6 and building on linux.

Uses libopencm3, an arm firmware library that I prefer to the standard stm32 HAL.
The makefiles provided by libopencm3 automatically provide appropriate compiler defines, architecture flags, etc, and generate a linker script.
This has been ported to cmake.

## Dependencies

`sudo apt install -y gcc-arm-none-eabi`

## Installation

`git clone git@github.com:zachlambert/stm32-collection.git`
`make build MCU=stm32f103x8`
`sudo make install MCU=stm32f103x8`

This will build libraries for the stm32f103x8 target under build/stm32f103x8, then install libraries to `/opt/stm32-collection/lib/stm32f103x8/` and a toolchain file to `/opt/stm32-collection/toolchain/stm32f103x8.cmake`.

## Usage

See the example. Need to do the following two things:
- Add `-DCMAKE_TOOLCHAIN_FILE=/opt/stm32-collection/toolchain/stm32f103x8.cmake` when configuring the project.
Note, that if the toolchain file changes for whatever reason, a full rebuild is needed.
- Tell cmake where to find `stm32-collection-config.cmake`.

Can then include the libraries `opencm3`, `freertos`, `nanoprintf`.

## Things to improve

- Better handle the installation, haven't worked out how to do it with proper project config files.
- Install the library cmake file to a location that cmake knows where to look, to avoid having to specify the location.
- Have cmake automatically pick the correct library config cmake file based off the toolchain.
- Have the `FreeRTOSConfig.h` files be configured automatically for a given microcontroller instead of having to create a new version for each microcontroller.
- Test on other microcontrollers.

Another potential issue is that currently freertos is compiled for a predefined `FreeRTOSConfig.h` file. If a project wants to change this, it would have to compile freertos itself. It might be worth adding the option for this. However I also like the idea of specifying a reasonable config file for each microcontroller, to make it easier for the library user to get started.
