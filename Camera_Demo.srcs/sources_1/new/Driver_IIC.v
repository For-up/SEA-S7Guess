`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/16 20:57:24
// Design Name: 
// Module Name: Driver_IIC
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
// Copyright by SouthEast University,Erie.
//////////////////////////////////////////////////////////////////////////////////

module Driver_IIC(
    input i_clk,
    input i_rst,
    input i_iic_sda,
    input i_iic_write,          //IIC写信号,上升沿有效
    input i_iic_read,           //IIC读信号,上升沿有效
    input i_iic_mode,           //IIC模式,1代表双地址位,0代表单地址位,低位地址有效
    input [7:0]i_slave_addr,    //IIC从机地址
    input [7:0]i_reg_addr_h,    //寄存器地址,高8位
    input [7:0]i_reg_addr_l,    //寄存器地址,低8位
    input [7:0]i_data_w,        //需要传输的数据
    output [7:0]o_data_r,       //IIC读到的数据
    output o_iic_busy,          //IIC忙信号,在工作时忙,低电平忙
    output o_iic_scl,           //IIC时钟线
    output o_sda_dir,           //IIC数据线方向,1代表输出
    output o_iic_sda            //IIC数据线
    );
    //参数
    parameter System_Clk_MHz=13'd100;
    parameter Set_IIC_SCL_kHz=13'd100;
    
    //SCL节点参数
    localparam  SCL_Divider=System_Clk_MHz/Set_IIC_SCL_kHz;
    localparam  SCL_SUM = (SCL_Divider<<10)-(SCL_Divider<<4)-(SCL_Divider<<3);        //SCL分频系数
    localparam  SCL_H_START=0;                                          //SCL高电平起始点
    localparam  SCL_H_CENTER=(SCL_SUM >> 1)-(SCL_SUM >> 2)-1;           //SCL高电平中点
    localparam  SCL_L_START=(SCL_SUM >> 1)-1;                           //SCL低电平起始点
    localparam  SCL_L_CENTER=(SCL_SUM >> 1)+(SCL_SUM >> 2)-1;           //SCL低电平中点
    
    //状态参数
    localparam ST_IDLE=5'd0;
    localparam ST_START=5'd1;
    localparam ST_W_SADDR=5'd2;
    localparam ST_ACK_0=5'd3;
    localparam ST_W_ADDR_H=5'd4;
    localparam ST_ACK_1=5'd5;
    localparam ST_W_ADDR_L=5'd6;
    localparam ST_ACK_2=5'd7;
    localparam ST_W_DATA=5'd8;
    localparam ST_ACK_3=5'd9;
    localparam ST_START_R=5'd10;
    localparam ST_W_SADDR_R=5'd11;
    localparam ST_ACK_4=5'd12;
    localparam ST_R_DATA=5'd13;
    localparam ST_NACK=5'd14;
    localparam ST_STOP=5'd15;
    
    //变量
    reg [13:0]reg_scl_cnt=0;
    reg [2:0]reg_byte_cnt=0;
    
    //状态变量
    reg [4:0]state_current=0;                                      //当前状态
    reg [4:0]state_next=0;                                         //下一个状态
    
    //级间缓存
    reg buf_iic_write=0;                                                //写信号缓存
    reg buf_iic_read=0;                                                 //读信号缓存
    reg buf_iic_mode=0;                                                 //IIC模式,1代表双地址位,0代表单地址位,低位地址有效
    reg [7:0]buf_slave_addr_r=0;                                        //IIC从机地址,读
    reg [7:0]buf_slave_addr_w=0;                                        //IIC从机地址,写
    reg [7:0]buf_reg_addr_h=0;                                          //寄存器地址,高8位
    reg [7:0]buf_reg_addr_l=0;                                          //寄存器地址,低8位
    reg [7:0]buf_data=0;                                                //需要传输的数据
    reg buff_iic_sda=0;                                                 //SDA
    
    //信号检测
    reg [1:0]iic_write_req_rise=0;                                      //IIC写请求上升沿检测
    reg [1:0]iic_read_req_rise=0;                                       //IIC读请求上升沿检测
    
    //标志
    wire flg_write_rise=(iic_write_req_rise==2'b01);                    //IIC写上升沿标志
    wire flg_read_rise=(iic_read_req_rise==2'b01);                      //IIC读上升沿标志
    wire flg_scl_hs = (reg_scl_cnt == SCL_H_START);                     //SCL高起始标志
    wire flg_scl_hc = (reg_scl_cnt == SCL_H_CENTER);                    //SCL高中心标志
    wire flg_scl_ls = (reg_scl_cnt == SCL_L_START);                     //SCL低起始标志
    wire flg_scl_lc = (reg_scl_cnt == SCL_L_CENTER);                    //SCL低中心标志
    
    //使能
    reg iic_write_req=0;                                                //写使能
    reg iic_read_req=0;                                                 //读使能
    
    //输出信号
    reg [7:0]data_r_o=0;                                                //IIC读到的数据
    reg iic_busy_o=0;                                                   //IIC忙信号,在工作时忙
    reg iic_scl_o=1;                                                    //IIC时钟线
    reg sda_dir_o=0;                                                    //IIC数据线方向,1代表输出
    reg iic_sda_o=1;                                                    //IIC数据线
    
    //输出连线
    assign o_data_r=data_r_o;       //IIC读到的数据
    assign o_iic_busy=iic_busy_o;   //IIC忙信号,在工作时忙
    assign o_iic_scl=iic_scl_o;     //IIC时钟线
    assign o_sda_dir=sda_dir_o;     //IIC数据线方向,1代表输出
    assign o_iic_sda=iic_sda_o;     //IIC数据线
    
    //主状态机
    always@(*)begin
        case(state_current)
            
            //等待状态
            ST_IDLE:begin
                if((iic_write_req||iic_read_req)&flg_scl_hc)begin
                    state_next<=ST_START;
                end
                else begin
                    state_next<=ST_IDLE;
                end
            end
            
            //起始信号
            ST_START:begin
                if(flg_scl_lc)begin
                    state_next<=ST_W_SADDR;
                end
                else begin
                    state_next<=ST_START;
                end
            end
            
            //写从机地址
            ST_W_SADDR:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_ACK_0;
                end
                else begin
                    state_next<=ST_W_SADDR;
                end
            end
            
            //应答信号0
            ST_ACK_0:begin
                if(flg_scl_lc&buf_iic_mode)begin
                    state_next<=ST_W_ADDR_H;
                end
                else if(flg_scl_lc&!buf_iic_mode)begin
                    state_next<=ST_W_ADDR_L;
                end
                else begin
                    state_next<=ST_ACK_0;
                end
            end
            
            //写寄存器高位地址
            ST_W_ADDR_H:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_ACK_1;
                end
                else begin
                    state_next<=ST_W_ADDR_H;
                end
            end
            
            //应答信号1
            ST_ACK_1:begin
                if(flg_scl_lc)begin
                    state_next<=ST_W_ADDR_L;
                end
                else begin
                    state_next<=ST_ACK_1;
                end
            end
            
            //写寄存器低位地址
            ST_W_ADDR_L:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_ACK_2;
                end
                else begin
                    state_next<=ST_W_ADDR_L;
                end
            end
            
            //应答信号2
            ST_ACK_2:begin
                if(flg_scl_lc&iic_write_req)begin
                    state_next<=ST_W_DATA;
                end
                else if(flg_scl_lc&iic_read_req)begin
                    state_next<=ST_START_R;
                end
                else begin
                    state_next<=ST_ACK_2;
                end
            end
            
            //写数据
            ST_W_DATA:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_ACK_3;
                end
                else begin
                    state_next<=ST_W_DATA;
                end
            end
            
            //应答信号3
            ST_ACK_3:begin
                if(flg_scl_lc)begin
                    state_next<=ST_STOP;
                end
                else begin
                    state_next<=ST_ACK_3;
                end
            end

            //读起始信号
            ST_START_R:begin
                if(flg_scl_lc)begin
                    state_next<=ST_W_SADDR_R;
                end
                else begin
                    state_next<=ST_START_R;
                end
            end
            
            //写从机地址
            ST_W_SADDR_R:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_ACK_4;
                end
                else begin
                    state_next<=ST_W_SADDR_R;
                end
            end
            
            //应答信号4
            ST_ACK_4:begin
                if(flg_scl_lc)begin
                    state_next<=ST_R_DATA;
                end
                else begin
                    state_next<=ST_ACK_4;
                end
            end
            
            //读数据
            ST_R_DATA:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_NACK;
                end
                else begin
                    state_next<=ST_R_DATA;
                end
            end

            //无应答信号
            ST_NACK:begin
                if(flg_scl_lc)begin
                    state_next<=ST_STOP;
                end
                else begin
                    state_next<=ST_NACK;
                end
            end
            
            //停止信号
            ST_STOP:begin
                if(flg_scl_lc)begin
                    state_next<=ST_IDLE;
                end
                else begin
                    state_next<=ST_STOP;
                end
            end
            
            default:begin
                state_next<=ST_IDLE;
            end
        endcase
    end
    
    //scl计数
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            reg_scl_cnt <= 13'd0;
        end
        else if(reg_scl_cnt== SCL_SUM - 1)
            reg_scl_cnt <= 13'd0;
        else
            reg_scl_cnt <= reg_scl_cnt + 1;
    end
    
    //时钟输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            iic_scl_o<=0;
        end
        else if(reg_scl_cnt<=SCL_L_START-1)begin
            iic_scl_o<=1;
        end
        else if(reg_scl_cnt==SCL_SUM - 1)begin
            iic_scl_o<=1;
        end
        else begin
            iic_scl_o<=0;
        end
    end
    //写请求信号
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            iic_write_req<=0;
        end
        else if(flg_write_rise)begin
            iic_write_req<=1;
        end
        else if(state_current==ST_STOP)begin
            iic_write_req<=0;
        end
    end
    //写请求信号
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            iic_read_req<=0;
        end
        else if(flg_read_rise)begin
            iic_read_req<=1;
        end
        else if(state_current==ST_STOP)begin
            iic_read_req<=0;
        end
    end
    
    //IIC忙信号输出
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            iic_busy_o<=0;
        end
        else if(state_current==ST_IDLE)begin
            iic_busy_o<=0;
        end
        else begin
            iic_busy_o<=1;
        end
    end
    //读写间隔8个时钟计数
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            reg_byte_cnt<=0;
        end
        else begin
            case(state_next)
                ST_W_SADDR,ST_W_ADDR_H,ST_W_ADDR_L,ST_W_DATA,ST_W_SADDR_R:begin
                    if(flg_scl_lc)begin
                        reg_byte_cnt<=reg_byte_cnt+1;
                    end
                end
                ST_R_DATA:begin
                    if(flg_scl_hc)begin
                        reg_byte_cnt<=reg_byte_cnt+1;
                    end
                end
                default:begin
                    reg_byte_cnt<=0;
                end
            endcase
        end
    end
    
    //数据输出控制
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            sda_dir_o<=1;
            iic_sda_o<=1;
        end
        else begin
            case(state_next)
                ST_IDLE:begin
                    sda_dir_o<=1;
                    iic_sda_o<=1;
                end
                ST_START,ST_NACK:begin
                    sda_dir_o<=1;
                    iic_sda_o<=0;
                end
                ST_START_R:begin
                    sda_dir_o<=1;
                    if(flg_scl_lc)iic_sda_o<=1;
                    else if(flg_scl_hc)iic_sda_o<=0;
                end
                ST_W_SADDR:begin
                    sda_dir_o<=1;
                    if(flg_scl_lc)begin
                        iic_sda_o<=buf_slave_addr_w[7-reg_byte_cnt];
                    end
                end
                ST_W_SADDR_R:begin
                    sda_dir_o<=1;
                    if(flg_scl_lc)begin
                        iic_sda_o<=buf_slave_addr_r[7-reg_byte_cnt];
                    end
                end
                ST_ACK_0,ST_ACK_1,ST_ACK_2,ST_ACK_3,ST_ACK_4:begin
                    sda_dir_o<=0;
                end
                ST_W_ADDR_H:begin
                    sda_dir_o<=1;
                    if(flg_scl_lc)begin
                        iic_sda_o<=buf_reg_addr_h[7-reg_byte_cnt];
                    end
                end
                ST_W_ADDR_L:begin
                    sda_dir_o<=1;
                    if(flg_scl_lc)begin
                        iic_sda_o<=buf_reg_addr_l[7-reg_byte_cnt];
                    end
                end
                ST_W_DATA:begin
                    sda_dir_o<=1;
                    if(flg_scl_lc)begin
                        iic_sda_o<=buf_data[7-reg_byte_cnt];
                    end
                end
                ST_R_DATA:begin
                    sda_dir_o<=0;
                    if(flg_scl_hc&!sda_dir_o)begin
                        data_r_o[7-reg_byte_cnt]<=buff_iic_sda;
                    end
                end
                ST_STOP:begin
                    sda_dir_o<=1;
                    if(flg_scl_lc)begin
                        iic_sda_o<=0;
                    end
                    else if(flg_scl_hc)begin
                        iic_sda_o<=1;
                    end
                end
            endcase
        end
    end
    //状态转换
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            state_current<=ST_IDLE;
        end
        else begin
            state_current<=state_next;
        end
    end
    //信号检测
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            iic_write_req_rise<=0;
            iic_read_req_rise<=0;
        end
        else begin
            iic_write_req_rise<={iic_write_req_rise[0],buf_iic_write};
            iic_read_req_rise<={iic_read_req_rise[0],buf_iic_read};
        end
    end
    
    //输入信号缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            buf_iic_write<=0;
            buf_iic_read<=0;
            buf_iic_mode<=0;
            buf_slave_addr_w<=0;
            buf_slave_addr_r<=0;
            buf_reg_addr_h<=0;
            buf_reg_addr_l<=0;
            buf_data<=0;
            buff_iic_sda<=0;
        end
        else begin
            buf_iic_write<=i_iic_write;
            buf_iic_read<=i_iic_read;
            buf_iic_mode<=i_iic_mode;
            buf_slave_addr_w<=i_slave_addr;
            buf_slave_addr_r<=i_slave_addr|8'h01;
            buf_reg_addr_h<=i_reg_addr_h;
            buf_reg_addr_l<=i_reg_addr_l;
            buf_data<=i_data_w;
            buff_iic_sda<=i_iic_sda;
        end
    end
endmodule
