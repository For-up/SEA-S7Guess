`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/16 18:09:57
// Design Name: 
// Module Name: Trigger_Generator
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

//触发信号发生器
module Trigger_Generator(
    input i_clk,
    input i_rst,
    input i_en,         //使能信号，上升沿有效
    input i_out_level,  //控制输出电平
    input [3:0]i_width,
    output o_trig
    );
    
    localparam ST_WAIT=2'd0;
    localparam ST_START=2'd1;
    localparam ST_HOLD=2'd2;
    localparam ST_END=2'd3;
    
    //状态机
    reg [1:0]state_current=0;
    reg [1:0]state_next=0;
    
    //变量
    reg [3:0]reg_hold_cnt=0;
    reg [1:0]reg_en_rise=0;
    
    reg reg_trig=0;     //输出
    
    //标志
    wire flg_en;       //使能信号有效
    reg flg_hold=0;    //保持达到时间
    
    //缓存
    reg buffer_out_level=1;//默认输出高电平
    
    assign flg_en=(reg_en_rise==2'b01);
    assign o_trig=reg_trig;
    
    //输入信号缓存
    always@(posedge i_clk or negedge i_rst)begin
        //低电平复位
        if(!i_rst)begin
            buffer_out_level<=1;
        end
        else begin
            buffer_out_level<=i_out_level;
        end
    end
    
    //状态执行
    always@(posedge i_clk or negedge i_rst)begin
        //低电平复位
        if(!i_rst)begin
            reg_trig<=0;
        end
        else if(state_current==ST_HOLD)begin
            reg_trig<=buffer_out_level;
        end
        else begin
            reg_trig<=!buffer_out_level;
        end
    end
    
    //状态机控制
    always@(*) begin
        case(state_current)
        
            ST_WAIT:begin
                if(flg_en)begin
                    state_next<=ST_START;
                end
                else begin
                    state_next<=ST_WAIT;
                end
            end
            
            ST_START:begin
                state_next<=ST_HOLD;
            end
            
            ST_HOLD:begin
                if(flg_hold)begin
                    state_next<=ST_END;
                end
                else begin
                    state_next<=ST_HOLD;
                end
            end
            
            ST_END:begin
                if(!flg_en)begin
                    state_next<=ST_WAIT;
                end
                else begin
                    state_next<=ST_END;
                end
            end
        endcase
    end
    
    //状态机赋值
    always@(posedge i_clk or negedge i_rst)begin
        //低电平复位
        if(!i_rst)begin
            state_current<=ST_WAIT;
        end
        else begin
            state_current<=state_next;
        end
    end
    
    //使能信号上升沿检测
    always@(posedge i_clk or negedge i_rst)begin
        //低电平复位
        if(!i_rst)begin
            reg_en_rise<=0;
        end
        else begin
            reg_en_rise<={reg_en_rise[0],i_en};
        end
    end
    
    //保持检测
    always@(posedge i_clk or negedge i_rst)begin
        //低电平复位
        if(!i_rst)begin
            flg_hold<=0;
            reg_hold_cnt<=0;
        end
        else if(state_current==ST_HOLD)begin
            if(reg_hold_cnt<i_width)reg_hold_cnt<=reg_hold_cnt+1;
            else begin
                flg_hold<=1;
                reg_hold_cnt<=i_width;
            end
        end
        else begin
            flg_hold<=0;
            reg_hold_cnt<=0;
        end
    end
endmodule
