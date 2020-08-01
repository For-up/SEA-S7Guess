`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/30 16:11:18
// Design Name: 
// Module Name: USER
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module USER(

    input                         clk,
    input       [10:0]            set_x,
    input       [9:0]             set_y,
    input       [23:0]            rgb_data,
    output      [10:0]             cntm,
    output      [23:0]            rgb_data_out,
    output      [1:0]             led,
    
     input                       o_rgb_hsync,
     input                       o_rgb_vsync,
     input                       o_rgb_vde,
    output     reg               o_rgb_hsync1,
    output     reg               o_rgb_vsync1,
    output     reg               o_rgb_vde1
      
    );
   always@(posedge clk)
    begin
          o_rgb_hsync1      <=        o_rgb_hsync;
          o_rgb_vsync1      <=        o_rgb_vsync;
          o_rgb_vde1        <=        o_rgb_vde  ;
     
    end
    
    
    assign rgb_data_out = (set_y==265&&rgb_data==23'b0000_0000_0100_1000_1000_1111)?23'b0000_0000_0000_0000_0000_0000:rgb_data;

    count u_count(
.      clk                (clk)   ,
.      set_x              (set_x)  ,
.      set_y              (set_y)  ,
.      rgb_data           (rgb_data_out)  ,
.      led                (led),
.       cnt              (cntm)
    );
endmodule
