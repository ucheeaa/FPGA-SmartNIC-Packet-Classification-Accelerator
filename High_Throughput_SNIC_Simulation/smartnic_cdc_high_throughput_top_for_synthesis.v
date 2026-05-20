/*
 * File Name  : smartnic_cdc_high_throughput_top_for_synthesis.v
 * Module Name: smartnic_cdc_high_throughput_top
 * Author     : Uchenna Obikwelu
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * Synthesis top wrapper for the high-throughput SmartNIC design with
 * asynchronous FIFO-based clock domain crossing. This module integrates
 * the CDC FIFO and SmartNIC classification pipeline into a single top-level
 * design suitable for RTL elaboration and synthesis in Vivado.
 *
 * Architecture:
 *   - Stage 1: Asynchronous FIFO for clock domain crossing
 *   - Stage 2: High-throughput packet parsing and classification
 *
 * Notes:
 *   - Instantiates async_fifo_top and smart_nic_high_throughput_top.
 *   - Used in RTL elaboration, synthesis, and implementation analysis in Vivado.
 *   - Not deployed on the physical FPGA board.
 */

module smartnic_cdc_high_throughput_top (
    input  wire        clk_write,
    input  wire        clk_read,
    input  wire        rstn,
    input  wire        wr_en,
    input  wire [75:0] ip_packet_in,
    output wire        valid,
    output wire [3:0]  matched_rule_id
);

    wire        os_fifo_full;
    wire        os_fifo_empty;
    wire [5:0]  ov_wr_pointer;
    wire [5:0]  ov_rd_pointer;
    wire [5:0]  ov_wr_pointer_gry;
    wire [5:0]  ov_rd_pointer_gry;
    wire [75:0] fifo_dout;

    localparam PTR_SIZE = 5;
    localparam WIDTH    = 76;
    localparam DEPTH    = 32;

    async_fifo_top #(
        .PTR_SIZE(PTR_SIZE),
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) fifo_dut (
        .clk_write(clk_write),
        .clk_read(clk_read),
        .rstn(rstn),
        .wr_en(wr_en),
        .ip_packet_in(ip_packet_in),
        .ov_dout(fifo_dout),
        .os_fifo_full(os_fifo_full),
        .os_fifo_empty(os_fifo_empty),
        .ov_wr_pointer(ov_wr_pointer),
        .ov_rd_pointer(ov_rd_pointer),
        .ov_wr_pointer_gry(ov_wr_pointer_gry),
        .ov_rd_pointer_gry(ov_rd_pointer_gry)
    );

    smart_nic_high_throughput_top smartnic_dut (
        .clk(clk_read),
        .rst(~rstn),
        .ip_packet(fifo_dout),
        .valid(valid),
        .matched_rule_id(matched_rule_id)
    );

endmodule
