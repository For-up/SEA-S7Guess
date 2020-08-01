`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/09 11:30:13
// Design Name: 
// Module Name: Driver_Csi_To_Dvp
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


module Driver_Csi_To_Dvp
(
    input s_axis_aclk,
    input s_axis_tlast,
    input s_axis_tuser,
    input s_axis_tvalid,
    input [15:0] s_axis_tdata,
    output s_axis_tready,
    
    input i_vid_clk,

    output o_vid_hsync,
    output o_vid_vsync,
    output o_vid_active_video,
    output [7:0]o_vid_data,
    
    output [10:0]o_hdata,
    output [9:0]o_vdata
    );
    
    //参数
    localparam Default_AXIS_TREADY=1'b1;
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
    
    //数据
    reg frame_start=0;
    reg [1:0]frame_start_buff=0;
    reg [10:0]hdata=0;
    reg [9:0]vdata=0;
    reg [9:0]addra=0;
    reg [10:0]addrb=0;
    wire [7:0]video_data_buff;
    
    //缓存
    reg [2:0]axis_tvalid_i=0;
    reg axis_tlast_i=0;
    reg axis_tuser_i=0;
    reg [15:0]axis_tdata_i=0;
    
    //标志
    reg flg_down_valid=0;
    reg flg_rise_frame=0;
    
    //计数
    reg [3:0]unpack_cnt = 0;
    
    //输出
    reg vid_hsync_o=0;
    reg vid_vsync_o=0;
    reg vid_active_video_o=0;
    reg [7:0]vid_data_o=0;
    reg [10:0]hdata_o=0;
    reg [9:0]vdata_o=0;

    //输出连线
    assign s_axis_tready = Default_AXIS_TREADY;
    assign o_vid_hsync=vid_hsync_o;
    assign o_vid_vsync=vid_vsync_o;
    assign o_vid_active_video=vid_active_video_o;
    assign o_vid_data=vid_data_o;
    assign o_hdata=hdata_o;
    assign o_vdata=vdata_o;
    
    //输出数据
    always@(posedge i_vid_clk)begin
        vid_active_video_o<=(hdata<HSIZE&vdata<VSIZE);
        vid_data_o<=video_data_buff;
        hdata_o<=hdata;
        vdata_o<=vdata;
    end
    
    //行信号
    always@(posedge i_vid_clk)begin
        if(hdata>=HFP&hdata<HSP)vid_hsync_o<=1'b0;
        else vid_hsync_o<=1'b1;
    end
    
    //场信号
    always@(posedge i_vid_clk)begin
        if(vdata>=VFP&vdata<VSP)vid_vsync_o<=1'b0;
        else vid_vsync_o<=1'b1;
    end
    
    //行数据
    always@(posedge i_vid_clk)begin
        if(flg_rise_frame)hdata<=11'd0;
        else if(hdata==HMAX-1)hdata<=11'd0;
        else hdata<=hdata+1;
    end
    
    //场数据
    always@(posedge i_vid_clk)begin
        if(flg_rise_frame)vdata<=10'd0;
        else if(hdata==HMAX-1&vdata==VMAX-1)vdata<=10'd0;
        else if(hdata==HMAX-1)vdata<=vdata+1;
        else vdata<=vdata;
    end
    
    //帧开始信号上升沿检测
    always@(posedge i_vid_clk)begin
        frame_start_buff<={frame_start_buff[0],frame_start};
        flg_rise_frame<=frame_start_buff[0]&(~frame_start_buff[1]);
    end
    
    //解包计数
    always@(posedge i_vid_clk)begin
        if(hdata==HSIZE)unpack_cnt<=4'd0;
        else if(hdata<HSIZE&vdata<VSIZE&unpack_cnt==4'd3)unpack_cnt<=4'd0;
        else if(hdata<HSIZE&vdata<VSIZE)unpack_cnt<=unpack_cnt+1;
        else unpack_cnt<=unpack_cnt;
    end
    
    //读地址
    always@(posedge i_vid_clk)begin
        if(hdata==HSIZE)addrb<=11'd0;
        else if(hdata<HSIZE&vdata<VSIZE&unpack_cnt==4'd3)addrb<=addrb+11'd2;
        else if(hdata<HSIZE&vdata<VSIZE)addrb<=addrb+1;
        else addrb<=addrb;
    end

    //写地址
    always@(posedge s_axis_aclk)begin
        if(flg_down_valid)addra<=10'd0;
        else if(axis_tvalid_i[0])addra<=addra+1;
        else addra<=addra;
    end
 
    //帧头帧尾
    always@(posedge s_axis_aclk)begin
        if(axis_tuser_i)frame_start<=1'b1;
        else if(axis_tlast_i)frame_start<=1'b0;
        else frame_start<=frame_start;
    end
    
    //信号检测
    always@(posedge s_axis_aclk)begin
        flg_down_valid<=axis_tvalid_i[2]&(~axis_tvalid_i[1]);
    end
    //输入AXIS缓存
    always@(posedge s_axis_aclk)begin
        axis_tvalid_i<={axis_tvalid_i[1:0],s_axis_tvalid};
        axis_tlast_i<=s_axis_tlast;
        axis_tuser_i<=s_axis_tuser;
        axis_tdata_i<=s_axis_tdata;
    end
   
    //帧数据缓存
    AXIS_Data_RAM RAM_AXIS (
      .clka(s_axis_aclk),           // input wire clka
      .wea(axis_tvalid_i[0]),       // input wire [0 : 0] wea
      .addra(addra),                // input wire [9 : 0] addra
      .dina(axis_tdata_i),          // input wire [15 : 0] dina
      .clkb(i_vid_clk),             // input wire clkb
      .addrb(addrb),                // input wire [10 : 0] addrb
      .doutb(video_data_buff)       // output wire [7 : 0] doutb
    );
endmodule
