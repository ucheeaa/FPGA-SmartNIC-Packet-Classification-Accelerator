`timescale 1ns/1ps
/*
 * File Name  : snic_throughput_cdc_testbench.v
 * Module Name: cdc_high_tp_tb
 * Author     : Uchenna Obikwelu
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * Testbench for the high-throughput SmartNIC design with asynchronous FIFO-
 * based clock domain crossing. This testbench feeds packets from memory into
 * the FIFO write domain and verifies packet classification in the read domain.
 *
 * Architecture:
 *   - Write domain: packet injection into async_fifo_top
 *   - Read domain : packet parsing and high-throughput classification
 *
 * Notes:
 *   - Uses separate write and read clocks to verify CDC behavior.
 *   - Instantiates async_fifo_top and smart_nic_high_throughput_top.
 *   - Used for functional simulation and verification.
 */

module cdc_high_tp_tb;

  parameter PTR_SIZE = 5;
  parameter WIDTH    = 76;
  parameter DEPTH    = 32;
  parameter NUM_PKTS = 124;

  // Clock and reset signals
  reg clk_write;
  reg clk_read;
  reg rstn;

  // Write-side stimulus signals
  reg wr_en;
  reg [WIDTH-1:0] ip_packet_in;

  // FIFO outputs
  wire [WIDTH-1:0] fifo_dout;
  wire os_fifo_full;
  wire os_fifo_empty;
  wire [PTR_SIZE:0] ov_wr_pointer;
  wire [PTR_SIZE:0] ov_rd_pointer;
  wire [PTR_SIZE:0] ov_wr_pointer_gry;
  wire [PTR_SIZE:0] ov_rd_pointer_gry;

  // SmartNIC outputs
  wire valid;
  wire [3:0] matched_rule_id;

  // Packet memory loaded from pck_stream.mem
  reg [WIDTH-1:0] packet_mem [0:NUM_PKTS-1];
  integer i;

  // FIFO DUT
  async_fifo_top #(
    .PTR_SIZE(PTR_SIZE),
    .WIDTH   (WIDTH),
    .DEPTH   (DEPTH)
  ) fifo_dut (
    .clk_write(clk_write),
    .clk_read (clk_read),
    .rstn     (rstn),
    .wr_en    (wr_en),
    .ip_packet_in(ip_packet_in),
    .ov_dout  (fifo_dout),
    .os_fifo_full(os_fifo_full),
    .os_fifo_empty(os_fifo_empty),
    .ov_wr_pointer(ov_wr_pointer),
    .ov_rd_pointer(ov_rd_pointer),
    .ov_wr_pointer_gry(ov_wr_pointer_gry),
    .ov_rd_pointer_gry(ov_rd_pointer_gry)
  );


  // SmartNIC DUT operating in the read clock domain
  smart_nic_high_throughput_top smartnic_dut (
    .clk(clk_read),          // classifier runs in read domain
    .rst(~rstn),             // smartnic uses active-high reset
    .ip_packet(fifo_dout),
    .valid(valid),
    .matched_rule_id(matched_rule_id)
  );

  // Clocks
  // write clock = 250 MHz (4 ns period)
  // read clock  = 200 MHz (5 ns period)
  initial begin
    clk_write = 0;
    forever #2 clk_write = ~clk_write;
  end

  initial begin
    clk_read = 0;
    forever #2.5 clk_read = ~clk_read;
  end


  // Load packet memory
  initial begin
    $readmemh("pck_stream.mem", packet_mem);
  end

  // Reset sequence and packet injection stimulus
  initial begin
    rstn = 0;
    wr_en = 0;
    ip_packet_in = 0;
    i = 0;

    #20;
    rstn = 1;

    // feed packets into FIFO
    while (i < NUM_PKTS) begin
      @(negedge clk_write);
      if (!os_fifo_full) begin
        wr_en = 1'b1;
        ip_packet_in = packet_mem[i];
        i = i + 1;
      end
      else begin
        wr_en = 1'b0;
      end
    end

    @(negedge clk_write);
    wr_en = 1'b0;

    // Allow FIFO contents to drain and classifier pipeline to settle
    #500;
    $finish;
  end
  
    integer cyc;
  initial cyc = 0;

  always @(posedge clk_read) begin
    if (rstn) begin
      cyc = cyc + 1;
      $display("time=%0t | cycle=%0d | fifo_empty=%0d | fifo_full=%0d | fifo_dout=%h | valid=%0d | rule=%0d | wr_ptr=%0d | rd_ptr=%0d",
               $time, cyc, os_fifo_empty, os_fifo_full, fifo_dout, valid, matched_rule_id,
               ov_wr_pointer, ov_rd_pointer);
    end
  end

endmodule