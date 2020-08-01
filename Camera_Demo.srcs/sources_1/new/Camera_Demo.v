`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/06/25 09:56:56
// Design Name: 
// Module Name: Camera_Demo
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


module Camera_Demo(
    input i_clk,
    input i_rst,
    input i_clk_rx_data_n,
    input i_clk_rx_data_p,
    input [1:0]i_rx_data_n,
    input [1:0]i_rx_data_p,
    input i_data_n,
    input i_data_p,
    inout i_camera_iic_sda,
    output o_camera_iic_scl,
    output o_camera_gpio,
    output TMDS_Tx_Clk_N,
    output TMDS_Tx_Clk_P,
    output [2:0]TMDS_Tx_Data_N,
    output [2:0]TMDS_Tx_Data_P,
    
    output [1:0]  led,
    input           uart_rxd,         //UART接收端口
    output          uart_txd         //UART发送端口
    );
    //猜拳范围可自行修改（在总数0~30内）
    parameter   QUAN   = 10;
    parameter   JIAN   = 20;
    parameter   BU     = 30;
    //波特率设置
     parameter  UART_BPS = 9600;         //定义串口波特率  
    
    //时钟信号
    wire clk_100MHz_system;
    wire clk_200MHz;
    
    //HDMI信号
    wire [23:0]rgb_data_src;
    wire rgb_hsync_src;
    wire rgb_vsync_src;
    wire rgb_vde_src;
    wire clk_pixel;
    wire clk_serial;
    
    wire [10:0] cnt;
    wire  o_rgb_hsync1   ; 
    wire  o_rgb_vsync1    ; 
    wire  o_rgb_vde1     ;  
    wire   [10:0]     o_set_x;
    wire   [9:0]      o_set_y;
    wire   [23:0]    rgb_data_out;
    
  //UART  
  wire        uart_en_w;
  wire        uart_done;
  wire [7:0] uart_data_r;
  wire [7:0] uart_data_w;
    //系统时钟
    clk_wiz_0 clk_10(.clk_out1(clk_100MHz_system),.clk_out2(clk_200MHz),.clk_in1(i_clk));
    
    //HDMI驱动
    rgb2dvi_0 Mini_HDMI_Driver(
      .TMDS_Clk_p(TMDS_Tx_Clk_P),     // output wire TMDS_Clk_p
      .TMDS_Clk_n(TMDS_Tx_Clk_N),     // output wire TMDS_Clk_n
      .TMDS_Data_p(TMDS_Tx_Data_P),      // output wire [2 : 0] TMDS_Data_p
      .TMDS_Data_n(TMDS_Tx_Data_N),      // output wire [2 : 0] TMDS_Data_n
      .aRst_n(i_rst),                   // input wire aRst_n
      .vid_pData(rgb_data_out),         // input wire [23 : 0] vid_pData
      .vid_pVDE(o_rgb_vde1),           // input wire vid_pVDE
      .vid_pHSync(o_rgb_hsync1),       // input wire vid_pHSync
      .vid_pVSync(o_rgb_vsync1),       // input wire vid_pVSync
      .PixelClk(clk_pixel)
    );
    USER u_USER(

.        clk                     (clk_200MHz)    ,                                 //   input                 
.        set_x                   (o_set_x)    ,                               //   input       [10:0]    
.        set_y                   (o_set_y)   ,                               //   input       [9:0]     
.        rgb_data                (rgb_data_src)   ,                            //   input       [23:0]    
.         cntm                   (cnt)   ,                               //   output      [10:0]    
.        rgb_data_out            (rgb_data_out)   ,                        //   output      [23:0]    
.        led                        (led)  ,                       //   output      [1:0]     

//同步信号
 .        o_rgb_hsync1                        (o_rgb_hsync1),
 .        o_rgb_vsync1                        (o_rgb_vsync1),
 .        o_rgb_vde1                          (o_rgb_vde1),
 .        o_rgb_hsync                         (rgb_hsync_src),
 .        o_rgb_vsync                         (rgb_vsync_src),
 .        o_rgb_vde                           (rgb_vde_src)
   
    );
    //图像MIPI信号转RGB
    Driver_MIPI MIPI_Trans_Driver(
        .i_clk_200MHz(clk_200MHz),
        .i_clk_rx_data_n(i_clk_rx_data_n),
        .i_clk_rx_data_p(i_clk_rx_data_p),
        .i_rx_data_n(i_rx_data_n),
        .i_rx_data_p(i_rx_data_p),
        .i_data_n(i_data_n),
        .i_data_p(i_data_p),
        .o_camera_gpio(o_camera_gpio),
        .o_rgb_data(rgb_data_src),
        .o_rgb_hsync(rgb_hsync_src),
        .o_rgb_vsync(rgb_vsync_src),
        .o_rgb_vde(rgb_vde_src),
        .o_set_x(o_set_x),
        .o_set_y(o_set_y),
        .o_clk_pixel(clk_pixel)
    );
    
    //摄像头IIC的SDA线的三态节点
    wire camera_iic_sda_i;
    wire camera_iic_sda_o;
    wire camera_iic_sda_t;
    
    //Tri-state gate
    IOBUF Camera_IIC_SDA_IOBUF
       (.I(camera_iic_sda_o),
        .IO(i_camera_iic_sda),
        .O(camera_iic_sda_i),
        .T(~camera_iic_sda_t));
    
    //摄像头IIC驱动信号
    wire iic_busy;
    wire iic_mode;
    wire [7:0]slave_addr;
    wire [7:0]reg_addr_h;
    wire [7:0]reg_addr_l;
    wire [7:0]data_w;
    wire [7:0]data_r;
    wire iic_write;
    wire iic_read;
    wire ov5647_ack;
    
    //摄像头驱动
    OV5647_Init MIPI_Camera_Driver(
        .i_clk(clk_100MHz_system),
        .i_rst(i_rst),
        .i_iic_busy(iic_busy),
        .o_iic_mode(iic_mode),          
        .o_slave_addr(slave_addr),    
        .o_reg_addr_h(reg_addr_h),   
        .o_reg_addr_l(reg_addr_l),   
        .o_data_w(data_w),      
        .o_iic_write(iic_write),
        .o_ack(ov5647_ack)                 
    );
    
    //摄像头IIC驱动
    Driver_IIC MIPI_Camera_IIC(
        .i_clk(clk_100MHz_system),
        .i_rst(i_rst),
        .i_iic_sda(camera_iic_sda_i),
        .i_iic_write(iic_write),                //IIC写信号,上升沿有效
        .i_iic_read(iic_read),                  //IIC读信号,上升沿有效
        .i_iic_mode(iic_mode),                  //IIC模式,1代表双地址位,0代表单地址位,低位地址有效
        .i_slave_addr(slave_addr),              //IIC从机地址
        .i_reg_addr_h(reg_addr_h),              //寄存器地址,高8位
        .i_reg_addr_l(reg_addr_l),              //寄存器地址,低8位
        .i_data_w(data_w),                      //需要传输的数据
        .o_data_r(data_r),                      //IIC读到的数据
        .o_iic_busy(iic_busy),                  //IIC忙信号,在工作时忙,低电平忙
        .o_iic_scl(o_camera_iic_scl),           //IIC时钟线
        .o_sda_dir(camera_iic_sda_t),           //IIC数据线方向,1代表输出
        .o_iic_sda(camera_iic_sda_o)            //IIC数据线
    );
    
 // wire  uart_en_w=(cntm[10:3]==0)?1'b0:1'b1;

     UART_TOP#
     (
     . UART_BPS     (UART_BPS)
     )
      u_UART_TOP
   (
    //信号端口
. sys_clk                (clk_100MHz_system) ,          //外部50M时钟                                input          
. sys_rst_n              (i_rst)     ,        //外部复位信号，低有效                             input          
   //uart接口       
. uart_rxd               (uart_rxd)     ,         //UART接收端口                               input          
. uart_txd               (uart_txd)     ,         //UART发送端口                               output         
                      
 //通信接口        ()                                                
. uart_done              (uart_done)     ,       //UART接收一帧数据完成标志信号                        output         
. uart_data_r            (uart_data_r)     ,     //请求传进UART数据                              output  [7:0]  
                         
. uart_data_w            (uart_data_w)     ,     //要求 UART 发送的数据                           input   [7:0]  
. uart_en_w              (uart_done)            //要求发送使能信号                                 input                                                                    
    );
    
    
D_Uart #(
 .  QUAN   (QUAN),    
 .  JIAN   (JIAN),
 .  BU     (BU)

)u_D_Uart(
    .   clk             (clk_100MHz_system),                           // input            
    .   rst             (i_rst),                           // input            
    .   led             (led),                           // input   [1:0]    
    .   cnt             (cnt),                           // input  [10:0]    
    .  in_data          (uart_data_r),                        // input   [7:0]    
    .  in_data_done     (uart_done),                   // input            
    . out_data          (uart_data_w),                        // output reg [7:0] 
    . out_data_en       (uart_en_w)                      // output reg       
    );
endmodule
