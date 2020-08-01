`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/27 16:33:55
// Design Name: 
// Module Name: UART_Top
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


module UART_TOP(
    //信号端口
    input           sys_clk,          //外部50M时钟
    input           sys_rst_n,        //外部复位信号，低有效
    //uart接口
    input           uart_rxd,         //UART接收端口
    output          uart_txd,         //UART发送端口
    
    //通信接口
    output          uart_done,       //UART接收一帧数据完成标志信号
    output  [7:0]   uart_data_r,     //请求传进UART数据
    
    input   [7:0]   uart_data_w,     //要求 UART 发送的数据
    input           uart_en_w       //要求发送使能信号
    
    );
  //parameter define
    parameter  CLK_FREQ = 100_000_000;       //定义系统时钟频率
    parameter  UART_BPS = 9600;         //定义串口波特率  
    //wire define   
//wire       uart_en_w;                 //UART发送使能
//wire [7:0] uart_data_w;               //UART发送数据
//wire       clk_1m_w;                  //1MHz时钟，用于Signaltap调试

//*****************************************************
//**                    main code
//*****************************************************
     
uart_recv #(                          //串口接收模块
    .CLK_FREQ       (CLK_FREQ),       //设置系统时钟频率
    .UART_BPS       (UART_BPS))       //设置串口接收波特率
u_uart_recv(                 
    .sys_clk        (sys_clk),               //系统时钟                   input		          
    .sys_rst_n      (sys_rst_n),             //系统复位，低电平有效        input    
    
    //硬件接口
    .uart_rxd       (uart_rxd),             //UART接收端口                input   
    //数据接口
    .uart_done      (uart_done),            //UART接收一帧数据完成标志信号 output  
    .uart_data      (uart_data_r)           //请求传进UART数据            output  
    );
    
uart_send #(                          //串口发送模块
    .CLK_FREQ       (CLK_FREQ),       //设置系统时钟频率
    .UART_BPS       (UART_BPS))       //设置串口发送波特率
u_uart_send(                 
    .sys_clk        (sys_clk),          //系统时钟                           input	
    .sys_rst_n      (sys_rst_n),      //系统复位，低电平有效                 input 
    
   //数据接口
    .uart_en        (uart_en_w),      //发送使能信号                         input 
    .uart_din       (uart_data_w),    //要求 UART 发送的数据                  input 
    //硬件接口
    .uart_txd       (uart_txd)        //UART发送端口                         output
    );                                       
    
    
    
    
endmodule
