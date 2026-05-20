`timescale 1ns / 1ps
/*
 * File Name  : throughput_fpga_top_level.v
 * Module Name: smartnic_throughput_fpga_top
 * Author     : Uchenna Obikwelu
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * FPGA top-level wrapper for the LED-based hardware demonstration of the
 * high-throughput SmartNIC design. This module instantiates the SmartNIC
 * processing pipeline and slows the displayed output so that valid and
 * matched rule values can be observed on the board LEDs.
 *
 * Architecture:
 *   - Stage 1: High-throughput SmartNIC packet classification
 *   - Stage 2: Slow sampled LED display for human-visible output
 *
 * Notes:
 *   - This wrapper was created specifically for the LED FPGA implementation.
 *   - The SmartNIC core runs at full speed while the LED output is sampled slowly.
 *   - Used in FPGA implementation of the high-throughput design.
 */

module smartnic_throughput_fpga_top(
    input  wire sysclk,      // System clock from the Zynq PS
    input  wire rst,         // Active-high reset
    output reg  [3:0] led    // LED display output
);

    // SmartNIC classifier outputs
    wire        valid;
    wire [3:0]  matched_rule_id;

    // Slow display sampling registers
    reg [27:0] slow_ctr;
    reg        sampled_valid;
    reg [3:0]  sampled_rule;

    // High-throughput SmartNIC core
    smartnic_throughput_pl_top top_dut (
        .sysclk(sysclk),
        .rst(rst),
        .valid(valid),
        .matched_rule_id(matched_rule_id)
    );

    // Slow down the displayed output so classification results are visible on LEDs
    always @(posedge sysclk or posedge rst) begin
        if (rst) begin
            slow_ctr       <= 28'd0;
            sampled_valid  <= 1'b0;
            sampled_rule   <= 4'd0;
            led            <= 4'b0000;
        end else begin
            slow_ctr <= slow_ctr + 1'b1;

            // Sample classifier outputs periodically for human-visible LED display
            if (slow_ctr == 28'd0) begin
                sampled_valid <= valid;
                sampled_rule  <= matched_rule_id;

                led[0] <= valid;
                led[1] <= matched_rule_id[0];
                led[2] <= matched_rule_id[1];
                led[3] <= matched_rule_id[2];
            end
        end
    end

endmodule