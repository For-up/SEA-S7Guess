// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Thu Jul 30 16:01:34 2020
// Host        : LAPTOP-EJ7V6R4H running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/FPGA/Camera_Demo2/Camera_Demo/Camera_Demo.runs/AXIS_Data_RAM_synth_1/AXIS_Data_RAM_stub.v
// Design      : AXIS_Data_RAM
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s15ftgb196-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_2,Vivado 2018.3" *)
module AXIS_Data_RAM(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[9:0],dina[15:0],clkb,addrb[10:0],doutb[7:0]" */;
  input clka;
  input [0:0]wea;
  input [9:0]addra;
  input [15:0]dina;
  input clkb;
  input [10:0]addrb;
  output [7:0]doutb;
endmodule
