`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/24 11:09:13
// Design Name: 
// Module Name: Driver_OV5647
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


module OV5647_Init(
    input i_clk,
    input i_rst,
    input i_iic_busy,
    output o_iic_mode,           //IIC模式,1代表双地址位,0代表单地址位,低位地址有效
    output [7:0]o_slave_addr,    //IIC从机地址
    output [7:0]o_reg_addr_h,    //寄存器地址,高8位
    output [7:0]o_reg_addr_l,    //寄存器地址,低8位
    output [7:0]o_data_w,        //需要传输的数据
    output o_iic_write,          //IIC写信号
    output o_ack                 //摄像头初始化完成信号,高电平完成
    );
    parameter SLAVE_ADDRESS=8'h6c;      //从机地址,最终的
    parameter INITIAL_NUM=8'd88;        //初始化数据总数
    parameter REG_ADDR2_EN=1'b1;        //双地址位
    parameter WR_HOLD_T=4'd10;          //写使能保持时间
    parameter WR_VALID=1'b1;            //写使能输出有效位
    parameter WAIT_DELAY=20'd100000;    //起始等待时间
    
    localparam IDLE=2'd00;
    localparam START=2'd01;
    localparam WAIT=2'd02;
    localparam END=2'd03;
    
    //计数变量
    reg [6:0]initial_cnt=0;
    reg [19:0]delay_cnt=0;
    
    //状态机
    reg [1:0]state_current=0;
    reg [1:0]state_next=0;
    
    //标志
    reg flg_delay=0;
    reg flg_initial=0;
    reg flg_data_ok=0;
    reg flg_iic_ok=0;
    
    //使能
    reg en_rd_rom=0;
    
    //Buffer缓存
    reg iic_busy=0;
    reg [1:0]iic_busy_down=0;
    
    //输出信号
    reg iic_mode=0;           //IIC模式,1代表双地址位,0代表单地址位,低位地址有效
    reg [7:0]slave_addr=0;    //IIC从机地址
    reg [7:0]reg_addr_h=0;    //寄存器地址,高8位
    reg [7:0]reg_addr_l=0;    //寄存器地址,低8位
    reg [7:0]data_w=0;        //需要传输的数据
    
    //数据
    wire [23:0]initial_data;
    
    //输出赋值
    assign o_iic_mode=iic_mode;
    assign o_slave_addr=slave_addr;     //IIC从机地址
    assign o_reg_addr_h=reg_addr_h;     //寄存器地址,高8位
    assign o_reg_addr_l=reg_addr_l;     //寄存器地址,低8位
    assign o_data_w=data_w;             //需要传输的数据
    assign o_ack=(state_current==END);   //摄像头初始化完成信号,高电平完成
    
    always@(*)begin
        case(state_current)
            IDLE:begin
                if(flg_delay)begin
                    state_next<=WAIT;
                end
                else begin
                    state_next<=IDLE;
                end
            end
            WAIT:begin
                if(flg_data_ok)begin
                    state_next<=START;
                end
                else begin
                    state_next<=WAIT;
                end
            end
            START:begin
                if(flg_initial)begin
                    state_next<=END;
                end
                else if(flg_iic_ok)begin
                    state_next<=WAIT;
                end
                else begin
                    state_next<=START;
                end
            end 
            END:begin
                state_next<=END;
            end
        endcase
    end
    
    //状态赋值
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            state_current<=0;
        end
        else begin
            state_current<=state_next;
        end
    end
    //使能信号
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            en_rd_rom<=1;
        end
        else if(state_current==END)begin
            en_rd_rom<=0;
        end
        else begin
            en_rd_rom<=1;
        end
    end
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            flg_iic_ok<=0;
        end
        else if(iic_busy_down==2'b10)begin
            flg_iic_ok<=1;
        end
        else if(state_current==WAIT)begin
            flg_iic_ok<=0;
        end
        else begin
            flg_iic_ok<=flg_iic_ok;
        end
    end
    //初始化标志
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            flg_initial<=0;
        end
        else if(initial_cnt==INITIAL_NUM)begin
            flg_initial<=1;
        end
        else begin
            flg_initial<=0;
        end
    end
    //地址、数据赋值
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            iic_mode<=0;
            slave_addr<=0;  
            reg_addr_h<=0;    
            reg_addr_l<=0;   
            data_w<=0;    
            flg_data_ok<=0;
        end
        else if(state_current==WAIT)begin
            iic_mode<=REG_ADDR2_EN;
            slave_addr<=SLAVE_ADDRESS;  
            reg_addr_h<=initial_data[23:16];    
            reg_addr_l<=initial_data[15:8];   
            data_w<=initial_data[7:0];   
            flg_data_ok<=1;
        end
        else begin
            flg_data_ok<=0;
        end
    end
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            initial_cnt<=0;
        end
        else if(state_next==WAIT&state_current!=WAIT)begin
            initial_cnt<=initial_cnt+1;
        end
    end
    //延时
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            delay_cnt<=0;
            flg_delay<=0;
        end
        else if(delay_cnt==WAIT_DELAY)begin
            delay_cnt<=WAIT_DELAY;
            flg_delay<=1;
        end
        else begin
            delay_cnt<=delay_cnt+1;
            flg_delay<=0;
        end
    end
    
    //OV5647初始化数据读取
    ROM_OV5647 OV5647(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_addr(initial_cnt),
        .o_data(initial_data) 
    );
    
    //写使能信号产生
    Trigger_Generator Trigger_Write(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(flg_data_ok),         //使能信号，上升沿有效
        .i_out_level(WR_VALID),  //控制输出电平
        .i_width(WR_HOLD_T),
        .o_trig(o_iic_write)
    );
    //信号缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            iic_busy_down<=0;
        end
        else begin
            iic_busy_down[1]<=iic_busy_down[0];
            iic_busy_down[0]<=i_iic_busy;
        end
    end
endmodule

module ROM_OV5647(
    input i_clk,
    input i_rst,
    input [6:0]i_addr,
    output[23:0]o_data 
);
    //存储单元
    reg [23:0]rom[89:0];
    
    //缓存
    reg [6:0]addr_i=0;
    
    //输出
    reg [23:0]data_o=0;
    
    //输出连线
    assign o_data=data_o;
    
    //输出数据
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            data_o<=24'd0;
        end
        else begin
            data_o<=rom[addr_i];
        end
    end
    
    //输入缓存
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            addr_i<=7'd0;
        end
        else begin
            addr_i<=i_addr;
        end
    end
    //初始化ROM
    initial begin
        rom[0]<=24'h010000;rom[1]<=24'h010301;rom[2]<=24'h300000;rom[3]<=24'h300100;rom[4]<=24'h300200;
        rom[5]<=24'h301608;rom[6]<=24'h3017e0;rom[7]<=24'h301844;rom[8]<=24'h301cf8;rom[9]<=24'h301df0;
        rom[10]<=24'h30340a;rom[11]<=24'h303521;rom[12]<=24'h303690;rom[13]<=24'h303c11;rom[14]<=24'h3106f5;
        rom[15]<=24'h360037;rom[16]<=24'h361259;rom[17]<=24'h361800;rom[18]<=24'h36302e;rom[19]<=24'h3632e2;
        rom[20]<=24'h363323;rom[21]<=24'h363444;rom[22]<=24'h363606;rom[23]<=24'h362064;rom[24]<=24'h3621e0;
        rom[25]<=24'h37035a;rom[26]<=24'h3704a0;rom[27]<=24'h37051a;rom[28]<=24'h370864;rom[29]<=24'h370952;
        rom[30]<=24'h370b60;rom[31]<=24'h370c0f;rom[32]<=24'h371578;rom[33]<=24'h371701;rom[34]<=24'h373102;
        rom[35]<=24'h380100;rom[36]<=24'h380200;rom[37]<=24'h3803fa;rom[38]<=24'h38040a;rom[39]<=24'h38053f;
        rom[40]<=24'h380606;rom[41]<=24'h3807a9;rom[42]<=24'h380805;rom[43]<=24'h380900;rom[44]<=24'h380a02;
        rom[45]<=24'h380bd0;rom[46]<=24'h380c0a;rom[47]<=24'h380d50;rom[48]<=24'h380e02;rom[49]<=24'h380fee;
        rom[50]<=24'h381110;rom[51]<=24'h381304;rom[52]<=24'h381431;rom[53]<=24'h381531;rom[54]<=24'h382107;
        rom[55]<=24'h382041;rom[56]<=24'h3827ec;rom[57]<=24'h3a0801;rom[58]<=24'h3a0927;rom[59]<=24'h3a0a00;
        rom[60]<=24'h3a0bf6;rom[61]<=24'h3a0d04;rom[62]<=24'h3a0e03;rom[63]<=24'h3a0f58;rom[64]<=24'h3a1050;
        rom[65]<=24'h3a1b58;rom[66]<=24'h3a1e50;rom[67]<=24'h3a1160;rom[68]<=24'h3a1f28;rom[69]<=24'h3a1800;
        rom[70]<=24'h3a19f8;rom[71]<=24'h3b070c;rom[72]<=24'h3c0180;rom[73]<=24'h3f0502;rom[74]<=24'h3f0610;
        rom[75]<=24'h3f010a;rom[76]<=24'h400102;rom[77]<=24'h400402;rom[78]<=24'h400009;rom[79]<=24'h40506e;
        rom[80]<=24'h40518f;rom[81]<=24'h483724;rom[82]<=24'h500006;rom[83]<=24'h500101;rom[84]<=24'h500241;
        rom[85]<=24'h500308;rom[86]<=24'h5a0008;rom[87]<=24'h010001;rom[88]<=24'h000000;rom[89]<=24'h000000;
    end
endmodule