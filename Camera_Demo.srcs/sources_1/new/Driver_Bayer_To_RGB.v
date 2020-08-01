`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/09 11:33:05
// Design Name: 
// Module Name: Driver_Bayer_To_RGB
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


module Driver_Bayer_To_RGB(
    input i_clk,
    input [7:0]i_vid_data,
    input i_vsync,
    input i_vde,
    input [10:0]i_hdata,
    input [9:0]i_vdata,
    output o_hsync,
    output o_vsync,
    output o_vde,
    output [10:0]o_set_x,
    output [9:0]o_set_y,
    output [23:0]o_rgb_data
);
    
    //图像参数
    localparam WIDTH = 12;
    localparam HSIZE = 1280;
    localparam HFP = 1390;
    localparam HSP = 1430;
    localparam HMAX = 1650;
    localparam VSIZE = 720;
    localparam VFP = 725;
    localparam VSP = 730;
    localparam VMAX = 750;
    localparam HSPP = 0;
    localparam VSPP = 0;
    localparam DELAY_LINE=2;
    
    //状态参数
    localparam ST_IDLE = 3'd0;
    localparam ST_IDLE_START = 3'd1;
    localparam ST_PATTERN0 = 3'd2;
    localparam ST_PATTERN1 = 3'd3;
    localparam ST_IDLE_GR  = 3'd4;
    localparam ST_PATTERN2 = 3'd5;
    localparam ST_PATTERN3 = 3'd6;
    
    //状态
    reg [3:0]state_current=0;
    
    //数据
    reg [7:0] line0[2:0];
    reg [7:0] line1[2:0];
    reg [7:0] line2[2:0];
    reg [9:0] rgb_data_r = 0;
    reg [9:0] rgb_data_g = 0;
    reg [9:0] rgb_data_b = 0;
    reg [10:0]addr_bram=0;
    wire [7:0]line_buff_0;
    wire [7:0]line_buff_1;
    wire [7:0]line_buff_2;
    
    //延时信号
    reg [5:0]hsync_delay=0;
    reg [5:0]vsync_delay=0;
    reg [5:0]vde_delay=0;
    reg [54:0]hdata_delay=0;
    reg [49:0]vdata_delay=0;
    
    //缓存
    reg [23:0]vid_data_i=0;
    reg [2:0]vsync_i=0;
    reg [3:0]vde_i=0;
    reg [10:0]hdata_i=0;
    reg [9:0]vdata_i=0;
    
    //标志
    reg flg_pos_vsync=0;
    reg [2:0]flg_pos_vde=0;
    reg [2:0]flg_neg_vde=0;
    
    //使能
    reg [2:0]en_ram=3'b001;
    reg en_ram_0=0;
    reg en_ram_1=0;
    reg en_ram_2=0;
    
    //输出
    reg hsync_o=0;
    reg vsync_o=0;
    reg vde_o=0;
    reg [10:0]set_x_o=0;
    reg [9:0]set_y_o=0;
    reg [23:0]rgb_data_o=0;
    
    //输出连线
    assign o_hsync=hsync_o;
    assign o_vsync=vsync_o;
    assign o_vde=vde_o;
    assign o_set_x=set_x_o;
    assign o_set_y=set_y_o;
    assign o_rgb_data=rgb_data_o;
    
    //数据输出
    always@(posedge i_clk)begin
        rgb_data_o<={rgb_data_r[9:2],rgb_data_b[9:2],rgb_data_g[9:2]};
        hsync_o<=hsync_delay[5];
        vsync_o<=vsync_delay[5];
        vde_o<=vde_delay[5];
        set_x_o<=hdata_delay[54:44];
        set_y_o<=vdata_delay[49:40];
    end
    
    //状态机
    always@(posedge i_clk)begin
        case(state_current)
            ST_IDLE:begin
                if(flg_pos_vde[2])state_current<=ST_IDLE_START;
                else state_current<=ST_IDLE;
            end
            ST_IDLE_START:begin
                if(flg_pos_vsync)state_current<=ST_IDLE;
                else if(flg_pos_vde[2])state_current<=ST_PATTERN0;
                else state_current<=ST_IDLE_START;
            end
            ST_PATTERN0:begin
                if(flg_pos_vsync)state_current<=ST_IDLE;
                else state_current<=ST_PATTERN1;
            end
            ST_PATTERN1:begin
                if(flg_pos_vsync)state_current<=ST_IDLE;
                else if(flg_neg_vde[2])state_current<=ST_IDLE_GR;
                else state_current<=ST_PATTERN0;
            end
            ST_IDLE_GR:begin
                if(flg_pos_vsync)state_current<=ST_IDLE;
                else if(flg_pos_vde[2])state_current<=ST_PATTERN2;
                else state_current<=ST_IDLE_GR;
            end
            ST_PATTERN2:begin
                if(flg_pos_vsync)state_current<=ST_IDLE;
                else state_current<=ST_PATTERN3;
            end
            ST_PATTERN3:begin
                if(flg_pos_vsync)state_current<=ST_IDLE;
                else if(flg_neg_vde[2])state_current<=ST_IDLE_START;
                else state_current<=ST_PATTERN2;
            end
            default:begin
                state_current<=ST_IDLE;
            end
        endcase
    end
    //rgb数据
    always@(posedge i_clk)begin
        case(state_current)
            ST_PATTERN0:begin
                rgb_data_r <= line0[0] + line0[2] + line2[0] + line2[2];
                rgb_data_g <= line0[1] + line1[0] + line1[2] + line2[1];
                rgb_data_b <= {line1[1],2'b0};
            end
            ST_PATTERN1:begin
                rgb_data_r <= {1'b0,line0[1],1'b0} + {1'b0,line2[1],1'b0};
                rgb_data_g <= {line1[1],2'b0};
                rgb_data_b <= {1'b0,line1[0],1'b0} + {1'b0,line1[2],1'b0};
            end
            ST_PATTERN2:begin
                rgb_data_r <= {1'b0,line1[0],1'b0} + {1'b0,line1[2],1'b0};
                rgb_data_g <= {line1[1],2'b0};
                rgb_data_b <= {1'b0,line0[1],1'b0} + {1'b0,line2[1],1'b0};
            end
            ST_PATTERN3:begin
                rgb_data_r <= {line1[1],2'b0};
                rgb_data_g <= line0[1] + line1[0] + line1[2] + line2[1];
                rgb_data_b <= line0[0] + line0[2] + line2[0] + line2[2];
            end
            default:begin
                rgb_data_r<=rgb_data_r;
                rgb_data_g<=rgb_data_g;
                rgb_data_b<=rgb_data_b;
            end
        endcase
    end
    //行数据
    always@(posedge i_clk)begin
        if(en_ram_0)begin
            line0[0]<=line_buff_1;
            line1[0] <= line_buff_2;
            line2[0] <= vid_data_i[23:16];
        end
        else if(en_ram_1)begin
            line0[0]<=line_buff_2;
            line1[0] <= line_buff_0;
            line2[0] <= vid_data_i[23:16];
        end
        else begin
            line0[0]<=line_buff_0;
            line1[0] <= line_buff_1;
            line2[0] <= vid_data_i[23:16];
        end
        line0[2] <= line0[1];
        line0[1] <= line0[0];
        line1[2] <= line1[1];
        line1[1] <= line1[0];
        line2[2] <= line2[1];
        line2[1] <= line2[0];
    end
    
    //bram的地址产生
    always@(posedge i_clk)begin
        if(flg_pos_vsync)addr_bram<=11'd0;
        else if(flg_neg_vde[0])addr_bram<=11'd0;
        else if(vde_i[0]|vde_delay)addr_bram<=addr_bram+1;
        else addr_bram<=addr_bram;
    end
    
    //bram选择
    always@(posedge i_clk)begin
        if(flg_pos_vsync)en_ram<=3'b001;
        else if(flg_neg_vde[0])en_ram<={en_ram[1:0],en_ram[2]};
        else en_ram<=en_ram;
    end
    
    //信号使能
    always@(posedge i_clk)begin
        en_ram_0<=en_ram[0]&vde_i[0];
        en_ram_1<=en_ram[1]&vde_i[0];
        en_ram_2<=en_ram[2]&vde_i[0];
    end
    
    //信号检测
    always@(posedge i_clk)begin
        flg_pos_vsync<=vsync_i[1]&(~vsync_i[2]);
        flg_pos_vde<={flg_pos_vde[1:0],(vde_i[2]&(~vde_i[3]))};
        flg_neg_vde<={flg_neg_vde[1:0],(vde_i[3]&(~vde_i[2]))};
    end
    
    //图像行信号延迟
    always@(posedge i_clk)begin
        if(hdata_i>=HFP&hdata_i<HSP)hsync_delay<={hsync_delay[4:0],1'b0};
        else hsync_delay<={hsync_delay[4:0],1'b1};
    end
    
    //图像场信号延迟
    always@(posedge i_clk)begin
        if(vdata_i>=VFP + DELAY_LINE&vdata_i<VSP + DELAY_LINE)vsync_delay<={vsync_delay[4:0],1'b0};
        else vsync_delay<={vsync_delay[4:0],1'b1};
    end
    
    //图像有效信号延迟
    always@(posedge i_clk)begin
        vde_delay<={vde_delay[4:0],(hdata_i<HSIZE)&(vdata_i<VSIZE + DELAY_LINE) & (vdata_i > DELAY_LINE - 1)};
        hdata_delay<={hdata_delay[43:0],hdata_i};
        vdata_delay<={vdata_delay[39:0],vdata_i};
    end
    
    RAM_Line RAM_Line_Buff0 (
        .clka(i_clk),           // input wire clka
        .wea(en_ram_0),         // input wire [0 : 0] wea
        .addra(addr_bram),      // input wire [10 : 0] addra
        .dina(vid_data_i[7:0]), // input wire [7 : 0] dina
        .clkb(i_clk),           // input wire clkb
        .addrb(addr_bram),      // input wire [10 : 0] addrb
        .doutb(line_buff_0)     // output wire [7 : 0] doutb
    );
    
    RAM_Line RAM_Line_Buff1 (
        .clka(i_clk),           // input wire clka
        .wea(en_ram_1),         // input wire [0 : 0] wea
        .addra(addr_bram),      // input wire [10 : 0] addra
        .dina(vid_data_i[7:0]), // input wire [7 : 0] dina
        .clkb(i_clk),           // input wire clkb
        .addrb(addr_bram),      // input wire [10 : 0] addrb
        .doutb(line_buff_1)     // output wire [7 : 0] doutb
    );
    
    RAM_Line RAM_Line_Buff2 (
        .clka(i_clk),           // input wire clka
        .wea(en_ram_2),         // input wire [0 : 0] wea
        .addra(addr_bram),      // input wire [10 : 0] addra
        .dina(vid_data_i[7:0]), // input wire [7 : 0] dina
        .clkb(i_clk),           // input wire clkb
        .addrb(addr_bram),      // input wire [10 : 0] addrb
        .doutb(line_buff_2)     // output wire [7 : 0] doutb
    );
           
    //输入缓存
    always@(posedge i_clk)begin
        vid_data_i<={vid_data_i[15:0],i_vid_data};
        vsync_i<={vsync_i[1:0],i_vsync};
        vde_i<={vde_i[2:0],i_vde};
        hdata_i<=i_hdata;
        vdata_i<=i_vdata;
    end
       
endmodule