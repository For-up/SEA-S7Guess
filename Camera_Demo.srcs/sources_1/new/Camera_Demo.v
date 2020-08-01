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
    input           uart_rxd,         //UART���ն˿�
    output          uart_txd         //UART���Ͷ˿�
    );
    //��ȭ��Χ�������޸ģ�������0~30�ڣ�
    parameter   QUAN   = 10;
    parameter   JIAN   = 20;
    parameter   BU     = 30;
    //����������
     parameter  UART_BPS = 9600;         //���崮�ڲ�����  
    
    //ʱ���ź�
    wire clk_100MHz_system;
    wire clk_200MHz;
    
    //HDMI�ź�
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
    //ϵͳʱ��
    clk_wiz_0 clk_10(.clk_out1(clk_100MHz_system),.clk_out2(clk_200MHz),.clk_in1(i_clk));
    
    //HDMI����
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

//ͬ���ź�
 .        o_rgb_hsync1                        (o_rgb_hsync1),
 .        o_rgb_vsync1                        (o_rgb_vsync1),
 .        o_rgb_vde1                          (o_rgb_vde1),
 .        o_rgb_hsync                         (rgb_hsync_src),
 .        o_rgb_vsync                         (rgb_vsync_src),
 .        o_rgb_vde                           (rgb_vde_src)
   
    );
    //ͼ��MIPI�ź�תRGB
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
    
    //����ͷIIC��SDA�ߵ���̬�ڵ�
    wire camera_iic_sda_i;
    wire camera_iic_sda_o;
    wire camera_iic_sda_t;
    
    //Tri-state gate
    IOBUF Camera_IIC_SDA_IOBUF
       (.I(camera_iic_sda_o),
        .IO(i_camera_iic_sda),
        .O(camera_iic_sda_i),
        .T(~camera_iic_sda_t));
    
    //����ͷIIC�����ź�
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
    
    //����ͷ����
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
    
    //����ͷIIC����
    Driver_IIC MIPI_Camera_IIC(
        .i_clk(clk_100MHz_system),
        .i_rst(i_rst),
        .i_iic_sda(camera_iic_sda_i),
        .i_iic_write(iic_write),                //IICд�ź�,��������Ч
        .i_iic_read(iic_read),                  //IIC���ź�,��������Ч
        .i_iic_mode(iic_mode),                  //IICģʽ,1����˫��ַλ,0������ַλ,��λ��ַ��Ч
        .i_slave_addr(slave_addr),              //IIC�ӻ���ַ
        .i_reg_addr_h(reg_addr_h),              //�Ĵ�����ַ,��8λ
        .i_reg_addr_l(reg_addr_l),              //�Ĵ�����ַ,��8λ
        .i_data_w(data_w),                      //��Ҫ���������
        .o_data_r(data_r),                      //IIC����������
        .o_iic_busy(iic_busy),                  //IICæ�ź�,�ڹ���ʱæ,�͵�ƽæ
        .o_iic_scl(o_camera_iic_scl),           //IICʱ����
        .o_sda_dir(camera_iic_sda_t),           //IIC�����߷���,1�������
        .o_iic_sda(camera_iic_sda_o)            //IIC������
    );
    
 // wire  uart_en_w=(cntm[10:3]==0)?1'b0:1'b1;

     UART_TOP#
     (
     . UART_BPS     (UART_BPS)
     )
      u_UART_TOP
   (
    //�źŶ˿�
. sys_clk                (clk_100MHz_system) ,          //�ⲿ50Mʱ��                                input          
. sys_rst_n              (i_rst)     ,        //�ⲿ��λ�źţ�����Ч                             input          
   //uart�ӿ�       
. uart_rxd               (uart_rxd)     ,         //UART���ն˿�                               input          
. uart_txd               (uart_txd)     ,         //UART���Ͷ˿�                               output         
                      
 //ͨ�Žӿ�        ()                                                
. uart_done              (uart_done)     ,       //UART����һ֡������ɱ�־�ź�                        output         
. uart_data_r            (uart_data_r)     ,     //���󴫽�UART����                              output  [7:0]  
                         
. uart_data_w            (uart_data_w)     ,     //Ҫ�� UART ���͵�����                           input   [7:0]  
. uart_en_w              (uart_done)            //Ҫ����ʹ���ź�                                 input                                                                    
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
