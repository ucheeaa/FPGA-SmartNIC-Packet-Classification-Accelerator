/*
 * File Name  : packet_parser.v
 * Module Name: packet_parser
 * Author     : Uchenna Obikwelu
 * Course  : SYSC 4320 – Case Studies in Computer Systems
 * Project : SmartNIC Packet Classification Accelerator
 * Created : April 2026
 *
 * Description:
 * Parses a simplified 76-bit IPv4 packet header into its constituent fields.
 * The extracted fields include the IP version, protocol, source address,
 * and destination address. This module serves as the first stage in the
 * SmartNIC packet classification pipeline.
 *
 * Fields Extracted:
 *   - Version              : Bits [75:72]
 *   - Protocol             : Bits [71:64]
 *   - Source Address       : Bits [63:32]
 *   - Destination Address  : Bits [31:0]
 *
 * Notes:
 *   - This module implements purely combinational logic with zero latency.
 *   - Used in simulation, synthesis, and FPGA implementation.
 *   - Designed for both area-optimized and high-throughput SmartNIC architectures.
 */


module packet_parser(
  input [75:0] ip_packet,          // Simplified IPv4 header
  output reg [3:0] version,        // IP version (e.g., IPv4 = 4)
  output reg [7:0] protocol,       // Protocol number (e.g., TCP=6, UDP=17)
  output reg [31:0] src_address,   // Source IP address
  output reg [31:0] dest_addr      // Destination IP address
);

  // -------------------------------------------------------
  // Combinational logic to extract fields from the packet
  // -------------------------------------------------------
  always @(*) begin
    version = ip_packet[75:72]; 
    protocol = ip_packet[71:64];       
    src_address = ip_packet[63:32];
    dest_addr = ip_packet[31:0];    
  end
endmodule





