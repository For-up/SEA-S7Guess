`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/16 21:04:46
// Design Name: 
// Module Name: Driver_MIPI
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


module Driver_MIPI(
    input i_clk_200MHz,
    input i_clk_rx_data_n,
    input i_clk_rx_data_p,
    input [1:0]i_rx_data_n,
    input [1:0]i_rx_data_p,
    input i_data_n,
    input i_data_p,
    output reg o_camera_gpio=1,
    output [23:0]o_rgb_data,
    output o_rgb_hsync,
    output o_rgb_vsync,
    output o_rgb_vde,
    output [10:0]o_set_x,
    output [9:0]o_set_y,
    output o_clk_pixel
    );
   wire  [23:0] o_rgb_data0;
    
    //First level
    wire clk_out;
    wire trig_req;
    wire trig_ack;
    wire cl_enable;
    wire cl_stopstate;
    wire cl_rxclkactivehs;
    wire dl0_enable;
    wire dl0_rxactivehs;
    wire dl0_rxvalidhs;
    wire dl0_rxsynchs;
    wire [7:0]dl0_datahs;
    wire dl1_enable;
    wire dl1_rxactivehs;
    wire dl1_rxvalidhs;
    wire dl1_rxsynchs;
    wire [7:0]dl1_datahs;
    //Second level
    wire CSI_Axis_Last;      
    wire CSI_Axis_User;    
    wire CSI_Axis_Valid;     
    wire [15:0]CSI_Axis_Data;
    wire CSI_Axis_Ready;
    //Third level
    wire [7:0]DVP_Data;
    wire [10:0]DVP_HData;
    wire [9:0]DVP_VData;
    wire DVP_HSync;
    wire DVP_VSync;
    wire DVP_VDE;

    //assign o_clk_pixel=clk_out;
    clk_wiz_1 camera_clock(.clk_out1(o_clk_pixel),.clk_in1(clk_out));
   
    //First level data read instantiation
    csi2_d_phy_rx_0 Data_Read(
        .in_delay_clk(i_clk_200MHz),
        .clk_rxp(i_clk_rx_data_p),
        .clk_rxn(i_clk_rx_data_n),
        .data_rxp(i_rx_data_p),
        .data_rxn(i_rx_data_n),
        .data_lp_p(i_data_p),
        .data_lp_n(i_data_n),
        .trig_req(trig_req),
        .trig_ack(trig_ack),
        .rxbyteclkhs(clk_out),
        .cl_enable(cl_enable),
        .cl_stopstate(cl_stopstate),
        .cl_rxclkactivehs(cl_rxclkactivehs),
        .dl0_enable(dl0_enable),
        .dl0_rxactivehs(dl0_rxactivehs),
        .dl0_rxvalidhs(dl0_rxvalidhs),
        .dl0_rxsynchs(dl0_rxsynchs),
        .dl0_datahs(dl0_datahs),
        .dl1_enable(dl1_enable),
        .dl1_rxactivehs(dl1_rxactivehs),
        .dl1_rxvalidhs(dl1_rxvalidhs),
        .dl1_rxsynchs(dl1_rxsynchs),
        .dl1_datahs(dl1_datahs),
        .dl2_enable(1'b0),
        .dl3_enable(1'b0)
    );
    //The second level of data is converted into CSI instantiation
    csi_to_axis_0 Data_To_Csi(
        .enable_in(1),
        .rxbyteclkhs(clk_out),
        .cl_enable(cl_enable),
        .cl_stopstate(cl_stopstate),
        .cl_rxclkactivehs(cl_rxclkactivehs),
        .dl0_enable(dl0_enable),
        .dl0_rxactivehs(dl0_rxactivehs),
        .dl0_rxvalidhs(dl0_rxvalidhs),
        .dl0_rxsynchs(dl0_rxsynchs),
        .dl0_datahs(dl0_datahs),
        .dl1_enable(dl1_enable),
        .dl1_rxactivehs(dl1_rxactivehs),
        .dl1_rxvalidhs(dl1_rxvalidhs),
        .dl1_rxsynchs(dl1_rxsynchs),
        .dl1_datahs(dl1_datahs),
        .trig_req(trig_req),
        .trig_ack(trig_ack),
        .m_axis_tdata(CSI_Axis_Data),
        .m_axis_tuser(CSI_Axis_User),
        .m_axis_tlast(CSI_Axis_Last),
        .m_axis_tvalid(CSI_Axis_Valid),
        .m_axis_tready(CSI_Axis_Ready),
        .m_axis_aclk(clk_out),
        .m_axis_aresetn(1)
    );
    //Third level CSI2DVP instantiation
    Driver_Csi_To_Dvp Driver_Csi_To_Dvp0(
       .s_axis_aclk(clk_out),
       .s_axis_tlast(CSI_Axis_Last),
       .s_axis_tuser(CSI_Axis_User),
       .s_axis_tvalid(CSI_Axis_Valid),
       .s_axis_tdata(CSI_Axis_Data),
       .s_axis_tready(CSI_Axis_Ready),
       .i_vid_clk(o_clk_pixel),
       .o_vid_hsync(DVP_HSync),
       .o_vid_vsync(DVP_VSync),
       .o_vid_active_video(DVP_VDE),
       .o_vid_data(DVP_Data),
       .o_hdata(DVP_HData),
       .o_vdata(DVP_VData)
    );
    //Fourth level Bayer2RGB instantiation
    Driver_Bayer_To_RGB Driver_Bayer_To_RGB0(
        .i_clk(o_clk_pixel),
        .i_vid_data(DVP_Data),
        .i_vsync(DVP_VSync),
        .i_vde(DVP_VDE),
        .i_hdata(DVP_HData),
        .i_vdata(DVP_VData),
        .o_hsync(o_rgb_hsync),
        .o_vsync(o_rgb_vsync),
        .o_vde(o_rgb_vde),
        .o_set_x(o_set_x),
        .o_set_y(o_set_y),
        .o_rgb_data(o_rgb_data0)
    );
    
        assign o_rgb_data=((o_rgb_data0[23:16]>100 && o_rgb_data0[23:16]<255)&&
               (o_rgb_data0[15:8] >100 && o_rgb_data0[15:8] <255)&&   
                (o_rgb_data0[7:0] >100 && o_rgb_data0[7:0]<255))//µ÷ÕûÁÁ¶È·¶Î§
                ?  23'b0111_0000_0000_0000_0000_0000
                :  23'b0000_0000_0100_1000_1000_1111 ;
    
endmodule
