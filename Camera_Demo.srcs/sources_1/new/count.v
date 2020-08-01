`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/30 16:27:39
// Design Name: 
// Module Name: count
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


module count(
    input                         clk,
    input       [10:0]            set_x,
    input       [9:0]             set_y,
    input       [23:0]            rgb_data,
    output  reg [1:0]             led=0,
    output  reg [10:0]          cnt
    );
    //reg [10:0] cnt=0;
    
       always@(posedge clk)
   begin
    if(set_y==720&&set_x==1080)
           cnt<=0;
     else
        if(rgb_data==23'b0000_0000_0000_0000_0000_0000)
          cnt<=cnt+1'b1;
        else
          cnt<=cnt;
   end
    
   always@(posedge clk)
   begin
        if(cnt>=0&&cnt<=350)//Ê¯Í·
        begin
             led<=2'b00;
       end  
        else if (cnt>340&&cnt<1700)//²¼
        begin
              led<=2'b01;
       end  
        else if (cnt>=1700)//¼ôµ¶1250
        begin
                led<=2'b11;
       end     
       else 
            led<=led;
   end
    
    
    
endmodule
