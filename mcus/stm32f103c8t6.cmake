
set(OPENCM3_MCU_LIB stm32f1)
set(OPENCM3_MCU_FLAG -DSTM32F1)
set(MCU_ROM_ADDRESS 0x08000000)
set(CPU_PARAMETERS
    -mcpu=cortex-m3
    -mfloat-abi=soft
)
set(ARM_MATH_CM3 1)
set(FreeRTOS_ARCH ARM_CM3)
