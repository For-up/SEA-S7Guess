`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/08/01 11:37:03
// Design Name: 
// Module Name: D_Uart
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

module D_Uart(
     input          clk,
     input          rst,
     input   [1:0]  led,
     input  [10:0]  cnt,
     input   [7:0]  in_data,
     input          in_data_done,
     output reg [7:0]  out_data,
     output reg        out_data_en
    );
    reg   [4:0]    count=0;
    reg   [23:0]  clk_10HZ=0;
    reg  [7:0]      flag;
    reg   [2:0]    flag_s =3'b000;
    parameter   flag_led  =3'b100;
    parameter   flag_cnt  =3'b010;
    parameter   flag_win  =3'b001;
    parameter   flag_n  =3'b000;
    parameter   QUAN   = 10;    
    parameter   JIAN   = 20;
    parameter   BU     = 30;
    always@(posedge clk or negedge rst) begin
        if(!rst)
            clk_10HZ<=23'b0;
        else
           begin 
            if(clk_10HZ==23'd100_0)
                clk_10HZ<=23'b0;
            else
                clk_10HZ<=clk_10HZ+1'b1;
          end
    end
    
    always@(posedge clk or negedge rst)begin
        if(!rst)
            begin
            flag_s<=3'b0;
            end 
       else begin
           // if(in_data_done)
                    if(in_data==8'h1)
                        flag_s<=flag_led;
                    else if(in_data==8'h2)
                        flag_s<=flag_cnt;
                    else if(in_data==8'h3)
                        flag_s<=flag_win;
                    else 
                        flag_s<=flag_s;
                end
       end 
       
       always@(posedge clk_10HZ or negedge rst)
         begin
            if(!rst)
               out_data_en<=1'b0;
            else
                case(flag_s)
                    flag_led: begin
                        out_data<=led;
                    end
                    flag_cnt: begin
                        out_data <=cnt[10:2];
                    end                
                    flag_win: begin
                        out_data<=flag;
                    end                    
                endcase
         end
         
   always@(posedge clk or negedge rst)
   begin 
        if(!rst)
           count <=0;
        else begin
            if(count==30)
                count=0;
            else
            count<=count+1'b1;
        end
   end
   
always@(posedge clk_10HZ or negedge rst)begin
   if(!rst)
        flag<=8'h0;
   else begin
        if(led==2'b11)//剪刀
            begin
            if(count<=QUAN)//输
                flag<=8'hCF;
            else if(count<=JIAN&&count>QUAN)
                flag<=8'hCC;//平
            else 
                flag<=8'hFC;//赢
            end 
         else if(led==2'b00)//石头
            begin
            if(count<=QUAN)
                flag<=8'hCC;//平
         else if(count<=JIAN&&count>QUAN)
                flag<=8'hFC;//赢
            else 
                flag<=8'hCF;//输
            end   
            else if(led==2'b01)
            begin
            if(count<=QUAN)//布
                flag<=8'hFC;//赢
            else if(count<=JIAN&&count>QUAN)
                flag<=8'hCF;//输
            else 
                flag<=8'hCC;//平
            end 
       else ;
   end
 end
endmodule
