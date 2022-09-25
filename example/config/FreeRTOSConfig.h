#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

#include <stdint.h>

#define configUSE_PREEMPTION			1
#define configCPU_CLOCK_HZ				( (unsigned long) 72000000 )
#define configTICK_RATE_HZ				( ( portTickType ) 1000 )
#define configMAX_PRIORITIES			( 5 )
#define configMINIMAL_STACK_SIZE		( ( unsigned short ) 128 )
#define configMAX_TASK_NAME_LEN			( 16 )
#define configUSE_16_BIT_TICKS			0
#define configIDLE_SHOULD_YIELD			1
#define configUSE_MUTEXES			    1
#define configUSE_RECURSIVE_MUTEXES		1
#define configUSE_COUNTING_SEMAPHORES	1
#define configQUEUE_REGISTRY_SIZE		8
#define configUSE_APPLICATION_TASK_TAG	0
#define configUSE_PORT_OPTIMISED_TASK_SELECTION 0

#define configENABLE_STATIC_ALLOCATION  1
#define configENABLE_DYNAMIC_ALLOCATION 1
#define configTOTAL_HEAP_SIZE ( ( size_t ) (17 * 1024) )

#define configUSE_IDLE_HOOK				0
#define configUSE_TICK_HOOK				0
#define configUSE_MALLOC_FAILED_HOOK	0
#define configCHECK_FOR_STACK_OVERFLOW	0

#define configGENERATE_RUN_TIME_STATS	0
#define configUSE_TRACE_FACILITY		1

#define configUSE_CO_ROUTINES 			0
#define configMAX_CO_ROUTINE_PRIORITIES ( 2 )

#define configMAX_SYSCALL_INTERRUPT_PRIORITY 255

#define configUSE_TIMERS				1
#define configTIMER_TASK_PRIORITY		( 2 )
#define configTIMER_QUEUE_LENGTH		10
#define configTIMER_TASK_STACK_DEPTH	( 256 )

#define INCLUDE_vTaskPrioritySet		0
#define INCLUDE_uxTaskPriorityGet		0
#define INCLUDE_vTaskDelete				0
#define INCLUDE_vTaskCleanUpResources	0
#define INCLUDE_vTaskSuspend			1
#define INCLUDE_vTaskDelayUntil			1
#define INCLUDE_vTaskDelay				1

/* Normal assert() semantics without relying on the provision of an assert.h
header file. */
#define configASSERT( x ) if( ( x ) == 0 ) { taskDISABLE_INTERRUPTS(); for( ;; ); }

#define vPortSVCHandler sv_call_handler
#define xPortPendSVHandler pend_sv_handler
#define xPortSysTickHandler sys_tick_handler

#define configLIBRARY_KERNEL_INTERRUPT_PRIORITY	15

#endif
