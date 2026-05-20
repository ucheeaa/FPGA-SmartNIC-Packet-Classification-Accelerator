/******************************************************************************
 * File Name  : main.c
 * Author     : Uchenna Obikwelu
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * UART-based monitoring application for the SmartNIC FPGA implementation.
 * This program reads classification results from the AXI GPIO peripheral
 * and prints them to the serial terminal using xil_printf. It enables
 * real-time observation of packet classification outputs.
 *
 * Functionality:
 *   - Initializes the AXI GPIO peripheral.
 *   - Configures GPIO Channel 1 as input.
 *   - Continuously reads classification results.
 *   - Displays the results via UART once per second.
 *
 * Notes:
 *   - Designed for execution on the Zynq Processing System (PS).
 *   - Requires the AXI GPIO IP to be connected to the SmartNIC output.
 *   - Used in the UART-based FPGA demonstration of the high-throughput design.
 ******************************************************************************/

#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "sleep.h"

#define GPIO_DEVICE_ID XPAR_AXI_GPIO_0_DEVICE_ID

int main()
{
    XGpio Gpio;
    u32 data;
    int status;

    xil_printf("SmartNIC AXI GPIO Monitor Started\r\n");

    // Initialize GPIO
    status = XGpio_Initialize(&Gpio, GPIO_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("GPIO Initialization Failed\r\n");
        return XST_FAILURE;
    }

    // Configure GPIO Channel 1 as input
    XGpio_SetDataDirection(&Gpio, 1, 0xFFFFFFFF);

    while (1)
    {
        // Read GPIO value
        data = XGpio_DiscreteRead(&Gpio, 1);

        // Extract signals
        u32 valid = data & 0x1;
        u32 matched_rule_id = (data >> 1) & 0x7; // Bits [3:1]

        // Print decoded results
        xil_printf("Valid: %lu | Matched Rule ID: %lu\r\n",
                   valid, matched_rule_id);

        sleep(1); // Delay for readability
    }

    return 0;
}