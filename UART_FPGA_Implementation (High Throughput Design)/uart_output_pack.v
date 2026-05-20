`timescale 1ns / 1ps

/*
 * File Name  : uart_output_pack.v
 * Module Name: result_pack
 * Author     : Uchenna Obikwelu
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * Packs the SmartNIC classification outputs into a single bus for UART or
 * AXI GPIO monitoring. The output bus combines the valid flag and matched
 * rule identifier into one compact value for transmission or observation.
 *
 * Notes:
 *   - Bit [4] stores the valid signal.
 *   - Bits [3:0] store the matched rule ID.
 *   - Used in the UART-based FPGA implementation of the high-throughput design.
 */
 
module result_pack (
    input  wire       valid,
    input  wire [3:0] matched_rule_id,
    output wire [4:0] gpio_bus
);
    assign gpio_bus = {valid, matched_rule_id};
endmodule

