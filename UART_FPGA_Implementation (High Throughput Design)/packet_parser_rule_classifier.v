/*
 * File Name  : packet_parser_rule_classifier.v
 * Module Name: smart_nic_high_throughput_top
 * Author     : Uchenna Obikwelu
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * Integrates the packet parser and the high-throughput rule classifier
 * into a complete packet classification pipeline. The parser extracts
 * relevant header fields from the input packet, and the classifier
 * matches the parsed fields against the rule table.
 *
 * Architecture:
 *   - Stage 1: Packet parsing
 *   - Stage 2: High-throughput rule classification
 *
 * Notes:
 *   - This file is an integration module for the parser and classifier.
 *   - It is used as part of the high-throughput SmartNIC design hierarchy.
 *   - Used in simulation, synthesis, and FPGA implementation.
 */

module smart_nic_high_throughput_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [75:0] ip_packet,
    output wire        valid,
    output wire [3:0]  matched_rule_id
);

    // packet_parser outputs
    wire [3:0]  version;
    wire [7:0]  protocol;
    wire [31:0] src_address;
    wire [31:0] dest_addr;

    // Packet parsing stage
    packet_parser parser_inst (
        .ip_packet(ip_packet),
        .version(version),
        .protocol(protocol),
        .src_address(src_address),
        .dest_addr(dest_addr)
    );

    // High-throughput rule classification stage 
    rule_classifier_high_throughput classifier_inst (
        .clk(clk),
        .rst(rst),
        .dest_addr_in(dest_addr),
        .protocol_in(protocol),
        .valid(valid),
        .matched_rule_id(matched_rule_id)
    );

endmodule