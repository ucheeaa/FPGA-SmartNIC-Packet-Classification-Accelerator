/*
 * File Name  : packet_parser_rule_classifier_area_top.v
 * Module Name: smart_nic_area_optimized_top
 * Author     : Ben Narmer
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * Integrates the packet parser and the area-optimized rule classifier
 * into a complete packet classification pipeline. The parser extracts
 * relevant header fields from the input packet, and the classifier
 * sequentially evaluates the parsed fields against a rule table to
 * determine the corresponding action.
 *
 * Architecture:
 *   - Stage 1: Packet parsing
 *   - Stage 2: Area-optimized rule classification using resource sharing
 *
 * Notes:
 *   - This module implements the low-area SmartNIC architecture.
 *   - The classifier evaluates one rule per clock cycle to minimize hardware usage.
 *   - Includes packet-valid handshaking and packet ID tracking for simulation.
 *   - Used in simulation, synthesis, and implementation analysis.
 *   - Instantiated alongside the async_fifo_top_area module in the CDC testbench.
 */

module smart_nic_area_optimized_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [75:0] ip_packet,
    input  wire        i_packet_valid,
    input  wire [7:0]  i_packet_id,
    output wire        valid,
    output wire [3:0]  matched_rule_id,
    output wire        o_ready_for_packet,
    output wire        o_result_done,
    output wire [7:0]  o_packet_id
);

    wire [3:0]  version;
    wire [7:0]  protocol;
    wire [31:0] src_address;
    wire [31:0] dest_addr;

    packet_parser parser_inst (
        .ip_packet(ip_packet),
        .version(version),
        .protocol(protocol),
        .src_address(src_address),
        .dest_addr(dest_addr)
    );

    rule_classifier_area_optimized classifier_inst (
        .clk(clk),
        .rst(rst),
        .dest_addr_in(dest_addr),
        .protocol_in(protocol),
        .i_packet_valid(i_packet_valid),
        .i_packet_id(i_packet_id),
        .valid(valid),
        .matched_rule_id(matched_rule_id),
        .o_ready_for_packet(o_ready_for_packet),
        .o_result_done(o_result_done),
        .o_packet_id(o_packet_id)
    );

endmodule
