/*
 * File Name  : rule_classifier_area_optimized.v
 * Module Name: rule_classifier_area_optimized
 * Author     : Ben Narmer
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * Implements the area-optimized rule classifier for the SmartNIC design.
 * Instead of comparing all rules in parallel, this module checks one rule
 * per cycle using shared comparison logic and outputs the corresponding
 * decision when a match is found.
 *
 * Architecture:
 *   - Sequential rule scanning using a shared comparator
 *   - One rule evaluated per clock cycle
 *
 * Notes:
 *   - Optimized for reduced hardware cost through resource sharing.
 *   - Uses a packet-valid handshake and packet ID tracking for simulation.
 *   - Used in simulation, synthesis, and implementation analysis.
 */

module rule_classifier_area_optimized (
  input  wire        clk,
  input  wire        rst,
  input  wire [31:0] dest_addr_in,
  input  wire [7:0]  protocol_in,
  input  wire        i_packet_valid,   // tells classifier a fresh packet arrived
  input  wire [7:0]  i_packet_id,      // packet tag from TB top
  output reg         valid,
  output reg [3:0]   matched_rule_id,
  output wire        o_ready_for_packet,
  output reg         o_result_done,    // 1-cycle pulse when decision is ready
  output reg [7:0]   o_packet_id       // packet id associated with decision
);
  
  // Internal state for sequential rule checking
  reg [39:0] key_reg;
  reg [3:0]  rule_idx;
  reg        busy;

  // Current rule selected by rule_idx
  reg [39:0] rule_key;
  reg        rule_action;
  reg [7:0] packet_id_reg;

  // Rule table implemented as combinational selection logic
  always @(*) begin
    case (rule_idx)
      4'd0:  begin rule_key = {32'hE00000FB, 8'd17}; rule_action = 1'b1; end // 224.0.0.251   UDP allow
      4'd1:  begin rule_key = {32'hE0000016, 8'd2 }; rule_action = 1'b1; end // 224.0.0.22    IGMP allow
      4'd2:  begin rule_key = {32'h0A0000DE, 8'd17}; rule_action = 1'b1; end // 10.0.0.222    UDP allow
      4'd3:  begin rule_key = {32'h0A0000DE, 8'd6 }; rule_action = 1'b1; end // 10.0.0.222    TCP allow
      4'd4:  begin rule_key = {32'hEFFFFFFA, 8'd17}; rule_action = 1'b0; end // 239.255.255.250 UDP drop
      4'd5:  begin rule_key = {32'hFFFFFFFF, 8'd17}; rule_action = 1'b0; end // 255.255.255.255 UDP drop
      4'd6:  begin rule_key = {32'h0A0000FF, 8'd17}; rule_action = 1'b0; end // 10.0.0.255      UDP drop
      4'd7:  begin rule_key = {32'hA29F86EA, 8'd6 }; rule_action = 1'b1; end // 162.159.134.234 TCP allow
      4'd8:  begin rule_key = {32'h8E7EF477, 8'd6 }; rule_action = 1'b1; end // 142.126.244.119 TCP allow
      4'd9:  begin rule_key = {32'hD8EF2215, 8'd6 }; rule_action = 1'b1; end // 216.239.34.21   TCP allow
      4'd10: begin rule_key = {32'h226BF35D, 8'd6 }; rule_action = 1'b1; end // 34.107.243.93   TCP allow
      4'd11: begin rule_key = {32'h4047FFCC, 8'd17}; rule_action = 1'b0; end // 64.71.255.204   UDP drop
      4'd12: begin rule_key = {32'h0A0000F0, 8'd6 }; rule_action = 1'b0; end // 10.0.0.240      TCP drop
      4'd13: begin rule_key = {32'hE00000FB, 8'd6 }; rule_action = 1'b0; end // 224.0.0.251     TCP drop
      4'd14: begin rule_key = {32'hE0000016, 8'd17}; rule_action = 1'b0; end // 224.0.0.22       UDP drop
      default: begin rule_key = {32'hFFFFFFFF, 8'd6 }; rule_action = 1'b0; end // 255.255.255.255 TCP drop
    endcase
  end

  // Compare the current packet key against the selected rule
  wire match;
  assign match = (key_reg == rule_key);

  // Indicates whether the classifier can accept a new packet
  assign o_ready_for_packet = !busy;


  // Sequential control logic for packet acceptance, rule scanning, and result generation
  always @(posedge clk) begin
    if (rst) begin
      key_reg         <= 40'd0;
      packet_id_reg   <= 8'd0;
      rule_idx        <= 4'd0;
      busy            <= 1'b0;
      valid           <= 1'b0;
      matched_rule_id <= 4'd0;
      o_result_done   <= 1'b0;
      o_packet_id     <= 8'd0;
    end else begin
      
      o_result_done <= 1'b0;    // Keep done low unless classification completes this cycle

      if (!busy) begin
        valid           <= 1'b0;
        matched_rule_id <= 4'd0;

        // only start when a fresh packet really arrived
        if (i_packet_valid) begin
          key_reg       <= {dest_addr_in, protocol_in};
          packet_id_reg <= i_packet_id;
          rule_idx      <= 4'd0;
          busy          <= 1'b1;
        end
      end else if (match) begin
        valid           <= rule_action;
        matched_rule_id <= rule_idx;
        o_packet_id     <= packet_id_reg;
        o_result_done   <= 1'b1;
        busy            <= 1'b0;
      end else if (rule_idx == 4'd15) begin
        valid           <= 1'b0;
        matched_rule_id <= 4'd0;
        o_packet_id     <= packet_id_reg;
        o_result_done   <= 1'b1;
        busy            <= 1'b0;
      end else begin
        rule_idx        <= rule_idx + 4'd1;
      end
    end
  end
endmodule
