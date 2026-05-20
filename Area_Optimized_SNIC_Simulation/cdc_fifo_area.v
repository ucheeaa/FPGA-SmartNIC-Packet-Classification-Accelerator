`timescale 1ns/1ps
/*
 * File Name  : cdc_fifo_area.v
 * Modules    : rd_ctrl, wr_ctrl, sync_3ff, fifo_mem, async_fifo_top_area
 * Author     : Ben Narmer
 * Course     : SYSC 4320 – Case Studies in Computer Systems
 * Project    : SmartNIC Packet Classification Accelerator
 * Created    : April 2026
 *
 * Description:
 * Implements the asynchronous FIFO used for clock domain crossing in the
 * area-optimized SmartNIC design. This file includes the read controller,
 * write controller, pointer synchronizers, FIFO memory, and the top-level
 * FIFO integration module.
 *
 * Notes:
 *   - Uses Gray-coded pointers and 3-stage synchronizers for safe CDC.
 *   - Prevents invalid reads and writes using empty/full detection logic.
 *   - Includes consumer-ready gating on the read side for controlled packet release.
 *   - Used in simulation, synthesis, and implementation analysis.
 */

// Read controller module
module rd_ctrl #(parameter PTR_SIZE = 5)
  (
    output wire os_fifo_empty,
    output wire os_rd_en,
    output reg [PTR_SIZE:0] ov_rd_pointer,
    output wire [PTR_SIZE:0] ov_rd_pointer_gry,
    input wire [PTR_SIZE:0] iv_wr_pointer_sync,
    input wire is_consumer_ready,
    input wire clk_read,
    input wire rstn
  );
  
  reg [PTR_SIZE:0] wr_pointer_sync_bin;

  //Gray to Binary for synchronized write pointer for fifo empty logic
  integer i;
  always @(*) begin
      wr_pointer_sync_bin[PTR_SIZE] = iv_wr_pointer_sync[PTR_SIZE];
      for (i = PTR_SIZE-1; i >= 0; i = i-1) begin
        wr_pointer_sync_bin[i] = wr_pointer_sync_bin[i+1] ^ iv_wr_pointer_sync[i];
      end
  end

  //fifo empty logic to avoid reading when empty
  assign os_fifo_empty = wr_pointer_sync_bin == ov_rd_pointer;

  //Read pointer increment when data is available
  always @(posedge clk_read or negedge rstn) begin
    if(!rstn) ov_rd_pointer <= 0;
    else if (os_rd_en) ov_rd_pointer <= ov_rd_pointer + 1'b1; 
  end
  
  //Read enable logic
  assign os_rd_en = !os_fifo_empty && is_consumer_ready;
  
  //Binary to Gray for read pointer crossing to write side 
  assign ov_rd_pointer_gry = (ov_rd_pointer >> 1) ^ ov_rd_pointer;
  
endmodule
  

// Write controller module
module wr_ctrl #(parameter PTR_SIZE = 5) 
  (
    output wire os_fifo_full,
    input  wire is_wr_en,
    output reg  [PTR_SIZE:0] ov_wr_pointer,
    output wire [PTR_SIZE:0] ov_wr_pointer_gry,
    input  wire [PTR_SIZE:0] iv_rd_pointer_sync,
    input  wire rstn,
    input  wire clk_write
  );
  
  reg [PTR_SIZE:0] rd_pointer_sync_bin;
  
   //Gray to Binary for synchronized read pointer for fifo full logic
  integer i;
  always @(*) begin
    rd_pointer_sync_bin[PTR_SIZE] = iv_rd_pointer_sync[PTR_SIZE];
      for (i = PTR_SIZE-1; i >= 0; i = i-1) begin
        rd_pointer_sync_bin[i] = rd_pointer_sync_bin[i+1] ^ iv_rd_pointer_sync[i];
      end
  end
  
  //fifo full logic to avoid writing when full
  assign os_fifo_full = (ov_wr_pointer[PTR_SIZE-1:0] == rd_pointer_sync_bin[PTR_SIZE-1:0]) && (ov_wr_pointer[PTR_SIZE] !=  
                                                                                                    rd_pointer_sync_bin[PTR_SIZE]);
  
  //Binary to Grey for write pointer crossing to read domain
  assign ov_wr_pointer_gry = (ov_wr_pointer >> 1) ^ ov_wr_pointer;
  
  
  // Write pointer increment when write_en & !os_fifo_full
  always @ (posedge clk_write or negedge rstn) begin
    if (!rstn) begin
      ov_wr_pointer <= 0;
    end  
    else begin
      if (is_wr_en && !os_fifo_full) begin
        ov_wr_pointer <= ov_wr_pointer + 1; 
      end
    end
  end
endmodule


// 3-FF synchronizers
module sync_3ff #(parameter PTR_SIZE = 5)
  
  // inputs and outputs
  (
    output reg [PTR_SIZE:0] ov_dout_sync,
    input wire [PTR_SIZE:0] iv_din_gry,
    input wire sync_clk,
    input wire rstn
  );
  
  reg [PTR_SIZE:0] sig_meta1, sig_meta2;
  
  always @(posedge sync_clk or negedge rstn) begin
    if (!rstn)begin
      sig_meta1 <= 0;
      sig_meta2 <= 0;
      ov_dout_sync <= 0;
    end else begin
      sig_meta1 <= iv_din_gry;
      sig_meta2 <= sig_meta1;
      ov_dout_sync <= sig_meta2;
  	end
  end
endmodule
  
  
module fifo_mem # (
  parameter PTR_SIZE = 5,
  parameter WIDTH = 160,
  parameter DEPTH = 32
)(
  output reg [WIDTH-1:0] ov_dout,
  input clk_read,
  input clk_write,
  input rstn,
  input wr_en,
  input rd_en,
  input [WIDTH - 1:0] ip_packet,
  input [PTR_SIZE -1 :0] iv_rd_pointer,
  input [PTR_SIZE-1:0] iv_wr_pointer
);
  
  reg [WIDTH-1:0] mem [DEPTH - 1:0];
  integer i;
  
  //write logic
  always @(posedge clk_write or negedge rstn)begin
    if (!rstn) begin
      for (i=0; i<DEPTH; i=i+1) begin
        mem[i] <= {WIDTH{1'b0}};
      end
    end

    else begin
      if (wr_en) begin
        mem[iv_wr_pointer] <= ip_packet;
      end
    end
  end
  
  
  //read logic
  always @(posedge clk_read or negedge rstn) begin
    if(!rstn) begin
      ov_dout <= {WIDTH{1'b0}};
    end
    else begin
      if (rd_en) begin
        ov_dout <= mem[ iv_rd_pointer];
      end
    end    
  end
endmodule


module async_fifo_top_area #(
  parameter PTR_SIZE = 5,
  parameter WIDTH    = 160,
  parameter DEPTH    = 32
)(
  input wire clk_write,
  input wire clk_read,
  input wire rstn,
  input wire i_consumer_ready,

  // write side
  input wire wr_en,
  input wire [WIDTH-1:0] ip_packet_in,

  // read side
  output wire [WIDTH-1:0] ov_dout,

  // status
  output wire os_fifo_full,
  output wire os_fifo_empty,

  // setting these as output for debug
  output wire [PTR_SIZE:0]  ov_wr_pointer,
  output wire [PTR_SIZE:0]  ov_rd_pointer,
  output wire [PTR_SIZE:0]  ov_wr_pointer_gry,
  output wire [PTR_SIZE:0]  ov_rd_pointer_gry
);

  // Internal synchronized Gray pointers
  wire [PTR_SIZE:0] w_rd_pointer_gry_sync_to_wr;
  wire [PTR_SIZE:0] w_wr_pointer_gry_sync_to_rd;

  // Internal enables
  wire rd_en;
  wire w_wr_en_mem;

  // Write controller
  wr_ctrl #(.PTR_SIZE(PTR_SIZE)) wr_ctrl_inst 
  (
    .os_fifo_full(os_fifo_full),
    .is_wr_en(wr_en),
    .ov_wr_pointer(ov_wr_pointer),
    .ov_wr_pointer_gry(ov_wr_pointer_gry),
    .iv_rd_pointer_sync(w_rd_pointer_gry_sync_to_wr),
    .rstn(rstn),
    .clk_write (clk_write)
  );


  // Read controller
  rd_ctrl #(.PTR_SIZE(PTR_SIZE)) rd_ctrl_inst
  (
    .os_fifo_empty(os_fifo_empty),
    .os_rd_en(rd_en),
    .ov_rd_pointer(ov_rd_pointer),
    .ov_rd_pointer_gry (ov_rd_pointer_gry),
    .iv_wr_pointer_sync(w_wr_pointer_gry_sync_to_rd),
    .is_consumer_ready(i_consumer_ready),
    .clk_read(clk_read),
    .rstn(rstn)
  );

  // Synchronize read Gray pointer from read side into write domain
  sync_3ff #(.PTR_SIZE(PTR_SIZE)) sync_r2w_inst 
  (
    .ov_dout_sync(w_rd_pointer_gry_sync_to_wr),
    .iv_din_gry(ov_rd_pointer_gry), //ov_rd_pointer_gry -> output from read module
    .sync_clk(clk_write),
    .rstn(rstn)
  );

  // Synchronize write Gray pointer from write side into read domain
  sync_3ff #(.PTR_SIZE(PTR_SIZE)) sync_w2r_inst 
  (
    .ov_dout_sync(w_wr_pointer_gry_sync_to_rd),
    .iv_din_gry(ov_wr_pointer_gry),  //ov_wr_pointer_gry -> output from write module
    .sync_clk(clk_read),
    .rstn(rstn)
  );

  // Actual memory write enable to ensure not writing when fifo full
  assign w_wr_en_mem = wr_en && !os_fifo_full;


  // FIFO memory
  fifo_mem #(
    .PTR_SIZE(PTR_SIZE),
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) fifo_mem_inst 
  (
    .ov_dout(ov_dout),
    .clk_read(clk_read),
    .clk_write(clk_write),
    .rstn(rstn),
    .wr_en(w_wr_en_mem),
    .rd_en(rd_en),
    .ip_packet(ip_packet_in),
    .iv_rd_pointer(ov_rd_pointer[PTR_SIZE-1:0]),
    .iv_wr_pointer(ov_wr_pointer[PTR_SIZE-1:0])
  );

endmodule













