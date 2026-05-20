`timescale 1ns / 1ps

/*
 * File Name  : smartnic_cdc_area_optimized_top_for_synthesis.v
 * Module Name: smartnic_cdc_area_optimized_top
 * Author     : Ben Narmer
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * Synthesis top wrapper for the area-optimized SmartNIC design with
 * asynchronous FIFO-based clock domain crossing. This module connects
 * the CDC FIFO and the area-optimized SmartNIC pipeline into a single
 * top-level design suitable for RTL elaboration, synthesis, and
 * implementation analysis in Vivado.
 *
 * Architecture:
 *   - Stage 1: Asynchronous FIFO for clock domain crossing
 *   - Stage 2: Packet-valid and packet-ID generation in the read domain
 *   - Stage 3: Area-optimized packet parsing and classification
 *
 * Notes:
 *   - This file was created as the synthesis-level top wrapper for the
 *     complete area-optimized CDC design.
 *   - It enables proper RTL elaboration, synthesis, and implementation
 *     analysis of the full design in Vivado.
 *   - Instantiates async_fifo_top_area and smart_nic_area_optimized_top.
 *   - Used in RTL elaboration, synthesis, and implementation analysis.
 *   - Not deployed on the physical FPGA board.
 */

module smartnic_cdc_area_optimized_top (
    input  wire        clk_write,
    input  wire        clk_read,
    input  wire        rstn,
    input  wire        wr_en,
    input  wire [75:0] ip_packet_in,

    output wire        valid,
    output wire [3:0]  matched_rule_id
);

    localparam PTR_SIZE = 5;
    localparam WIDTH    = 76;
    localparam DEPTH    = 32;

    reg        fifo_data_valid_d;
    reg [7:0]  packet_id_counter;
    reg [7:0]  packet_id_to_classifier;

    wire       consumer_ready;
    wire       result_done;
    wire [7:0] result_packet_id;

    wire [WIDTH-1:0] fifo_dout;
    wire             os_fifo_full;
    wire             os_fifo_empty;
    wire [PTR_SIZE:0] ov_wr_pointer;
    wire [PTR_SIZE:0] ov_rd_pointer;
    wire [PTR_SIZE:0] ov_wr_pointer_gry;
    wire [PTR_SIZE:0] ov_rd_pointer_gry;

    // FIFO instance
    async_fifo_top_area #(
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
        .ov_rd_pointer_gry(ov_rd_pointer_gry),
        .i_consumer_ready(consumer_ready)
    );

    // Generate packet-valid and packet-id signals in read domain
    always @(posedge clk_read or negedge rstn) begin
        if (!rstn) begin
            fifo_data_valid_d       <= 1'b0;
            packet_id_counter       <= 8'd0;
            packet_id_to_classifier <= 8'd0;
        end else begin
            fifo_data_valid_d <= (!os_fifo_empty && consumer_ready);

            if (!os_fifo_empty && consumer_ready) begin
                packet_id_to_classifier <= packet_id_counter;
                packet_id_counter <= packet_id_counter + 1'b1;
            end
        end
    end

    // SmartNIC area-optimized instance
    smart_nic_area_optimized_top smartnic_dut (
        .clk(clk_read),
        .rst(~rstn),
        .ip_packet(fifo_dout),
        .i_packet_valid(fifo_data_valid_d),
        .i_packet_id(packet_id_to_classifier),
        .valid(valid),
        .matched_rule_id(matched_rule_id),
        .o_ready_for_packet(consumer_ready),
        .o_result_done(result_done),
        .o_packet_id(result_packet_id)
    );

endmodule
