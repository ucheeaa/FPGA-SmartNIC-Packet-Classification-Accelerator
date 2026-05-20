/*
 * File Name  : rule_classifier_high_throughput.v
 * Module Name: rule_classifier_high_throughput
 * Author     : Uchenna Obikwelu
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * Implements a high-throughput packet classification engine using a
 * pipelined, parallel comparator architecture. The module evaluates
 * incoming packet fields against a predefined rule table and outputs
 * the corresponding action and matched rule identifier.
 *
 * Architecture:
 *   - Stage 1: Input latching
 *   - Stage 2: Parallel rule comparison (CAM-style)
 *   - Stage 3: Priority encoding and action selection
 *
 * Notes:
 *   - Optimized for maximum throughput using pipelining and parallelism.
 *   - Designed as the high-performance counterpart to the area-optimized version.
*    - Used in simulation, synthesis, and FPGA implementation.
 */

module rule_classifier_high_throughput (
    input wire clk,
    input wire rst,
    input wire [31:0] dest_addr_in,
    input wire [7:0] protocol_in,
    output reg valid,
    output reg [3:0] matched_rule_id
);

parameter NUM_RULES = 16;

// Rule format: {Destination IP [40:9], Protocol [8:1], Action [0]}
// Action (1 = allow, 0 = drop)
reg [40:0] mem [0:NUM_RULES-1];

// Load rule table on reset
always @(posedge clk) begin
    if (rst) begin
        mem[0] <= {32'hE00000FB, 8'd17, 1'b1}; // 224.0.0.251 UDP allow
        mem[1] <= {32'hE0000016, 8'd2, 1'b1}; // 224.0.0.22 IGMP allow
        mem[2] <= {32'h0A0000DE, 8'd17, 1'b1}; // 10.0.0.222 UDP allow
        mem[3] <= {32'h0A0000DE, 8'd6, 1'b1}; // 10.0.0.222 TCP allow
        mem[4] <= {32'hEFFFFFFA, 8'd17, 1'b0}; // 239.255.255.250 UDP drop
        mem[5] <= {32'hFFFFFFFF, 8'd17, 1'b0}; // 255.255.255.255 UDP drop
        mem[6] <= {32'h0A0000FF, 8'd17, 1'b0}; // 10.0.0.255 UDP drop
        mem[7] <= {32'hA29F86EA, 8'd6, 1'b1}; // 162.159.134.234 TCP allow
        mem[8] <= {32'h8E7EF477, 8'd6, 1'b1}; // 142.126.244.119 TCP allow
        mem[9] <= {32'hD8EF2215, 8'd6, 1'b1}; // 216.239.34.21 TCP allow
        mem[10] <= {32'h226BF35D, 8'd6, 1'b1}; // 34.107.243.93 TCP allow
        mem[11] <= {32'h4047FFCC, 8'd17, 1'b0}; // 64.71.255.204 UDP drop
        mem[12] <= {32'h0A0000F0, 8'd6, 1'b0}; // 10.0.0.240 TCP drop
        mem[13] <= {32'hE00000FB, 8'd6, 1'b0}; // 224.0.0.251 TCP drop
        mem[14] <= {32'hE0000016, 8'd17, 1'b0}; // 224.0.0.22 UDP drop
        mem[15] <= {32'hFFFFFFFF, 8'd6, 1'b0}; // 255.255.255.255 TCP drop
    end
end

// Stage 1 pipeline registers used to latch inputs
reg [31:0] dest_addr_s0;
reg [7:0] prtcl_s0;

// Stage 2 combinational registers
reg [NUM_RULES-1:0] rule_match_comb;
reg [NUM_RULES-1:0] action_comb;

// Stage 2 combinational logic 
// Parallel comparator outputs
// rule_match_comb and action_comb store the results of every rule in parallel.
// This enables high-throughput packet classification by evaluating all rules within a single clock cycle.
integer i;
always @(*) begin
    rule_match_comb = {NUM_RULES{1'b0}};
    action_comb = {NUM_RULES{1'b0}};
    
    for (i = 0; i < NUM_RULES; i = i + 1) begin
        rule_match_comb[i] = (dest_addr_s0 == mem[i][40:9]) &&
                             (prtcl_s0 == mem[i][8:1]);
        action_comb[i] = mem[i][0];
    end
end

// Stage 2 pipeline registers
reg [NUM_RULES-1:0] rule_match_s1;
reg [NUM_RULES-1:0] action_s1;

// Stage 3 combinational registers
reg match_found;
reg valid_comb;
reg [3:0] matched_rule_id_comb;

// Stage 3 combinational logic 
// Priority encoder: the first matching rule determines the output
integer k;
always @(*) begin
    match_found = 1'b0;
    valid_comb = 1'b0;
    matched_rule_id_comb = 4'b0;

    for (k = 0; k < NUM_RULES; k = k + 1) begin
        if (!match_found && rule_match_s1[k]) begin
        valid_comb = action_s1[k];
        matched_rule_id_comb = k[3:0];
        match_found = 1'b1;
        end
    end
end

// Sequential pipeline logic
always @(posedge clk) begin
    if (rst) begin
        dest_addr_s0 <= 32'd0;
        prtcl_s0 <= 8'd0;
        rule_match_s1 <= {NUM_RULES{1'b0}};
        action_s1 <= {NUM_RULES{1'b0}};
        valid <= 1'b0;
        matched_rule_id <= 4'd0;
    end else begin
        // Stage 1
        dest_addr_s0 <= dest_addr_in;
        prtcl_s0 <= protocol_in;
        
        // Stage 2
        rule_match_s1 <= rule_match_comb;
        action_s1 <= action_comb;
        
        // Stage 3
        valid <= valid_comb;
        matched_rule_id <= matched_rule_id_comb;
    end
end

endmodule
