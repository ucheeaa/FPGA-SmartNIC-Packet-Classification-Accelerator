`timescale 1ns / 1ps

/*
 * File Name  : packet_rom.v
 * Module Name: packet_rom
 * Author     : Uchenna Obikwelu
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * ROM module used to supply packet data to the FPGA implementation.
 * Packet contents are initialized from the pck_stream.mem file and
 * accessed using the input address.
 *
 * Notes:
 *   - Implements a read-only packet source for hardware testing.
 *   - Used in the LED FPGA implementation of the high-throughput design.
 *   - Packet data is loaded using the Verilog $readmemh system task.
 */


module packet_rom (
    input  wire [6:0]  addr,
    output wire [75:0] packet
);

    reg [75:0] mem [0:127];

    initial begin
        $readmemh("pck_stream.mem", mem);
    end

    assign packet = mem[addr];

endmodule


