
#include <string.h>
#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/timer.h>

#include "usb.h"

#include <FreeRTOS.h>
#include <task.h>

#include <nanoprintf.h>


void clock_setup(void)
{
	rcc_clock_setup_pll(&rcc_hse_configs[RCC_CLOCK_HSE16_72MHZ]);
}

void gpio_setup(void)
{
	rcc_periph_clock_enable(RCC_GPIOA);
	gpio_set_mode(
        GPIOA,
        GPIO_MODE_OUTPUT_2_MHZ,
		GPIO_CNF_OUTPUT_PUSHPULL,
        GPIO4 | GPIO5
    );
}

void delay_setup(void)
{
	rcc_periph_clock_enable(RCC_TIM2);
	timer_set_prescaler(TIM2, rcc_apb1_frequency / 500000 - 1);
	timer_one_shot_mode(TIM2);
}

void delay_us(uint16_t us)
{
    timer_set_period(TIM2, us);
    timer_enable_update_event(TIM2);
	timer_enable_counter(TIM2);
	while (TIM_CR1(TIM2) & TIM_CR1_CEN);
}

void delay_ms(uint16_t ms)
{
    for (uint16_t i = 0; i < ms; i++) {
        delay_us(1000);
    }
}

void main_task(void* args)
{
    gpio_set(GPIOA, GPIO5);

    auto usbd_dev = init_usb();

    float time = 0;
    char message[32] = "hello\n";
    int i = 0;
    int delay_ms = 1;
    int ticks_per_write = 50;
    while (true) {
		usbd_poll(usbd_dev);
        if (i == 0) {
            npf_snprintf(message, sizeof(message), "Time: %f\n", time);
            time += ((float)delay_ms * ticks_per_write) * 1e-3;
            usbd_ep_write_packet(usbd_dev, 0x82, message, strnlen(message, sizeof(message)));
            gpio_set(GPIOA, GPIO4);
        }
        i++;
        if (i == ticks_per_write / 2) {
            gpio_clear(GPIOA, GPIO4);
        }
        if (i == ticks_per_write) {
            i = 0;
        }
        vTaskDelay(delay_ms);
    }
}

int main(void)
{
    clock_setup();
    gpio_setup();
    delay_setup();

    xTaskCreate(main_task, "main_task", 256 * 4, NULL, 1, NULL);
    vTaskStartScheduler();

    while (true) {}
    return 0;
}
