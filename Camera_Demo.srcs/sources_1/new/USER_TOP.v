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
    //�źŶ˿�
    input           sys_clk,          //�ⲿ50Mʱ��
    input           sys_rst_n,        //�ⲿ��λ�źţ�����Ч
    //uart�ӿ�
    input           uart_rxd,         //UART���ն˿�
    output          uart_txd,         //UART���Ͷ˿�
    
    //ͨ�Žӿ�
    output          uart_done,       //UART����һ֡������ɱ�־�ź�
    output  [7:0]   uart_data_r,     //���󴫽�UART����
    
    input   [7:0]   uart_data_w,     //Ҫ�� UART ���͵�����
    input           uart_en_w       //Ҫ����ʹ���ź�
    
    );
  //parameter define
    parameter  CLK_FREQ = 100_000_000;       //����ϵͳʱ��Ƶ��
    parameter  UART_BPS = 9600;         //���崮�ڲ�����  
    //wire define   
//wire       uart_en_w;                 //UART����ʹ��
//wire [7:0] uart_data_w;               //UART��������
//wire       clk_1m_w;                  //1MHzʱ�ӣ�����Signaltap����

//*****************************************************
//**                    main code
//*****************************************************
     
uart_recv #(                          //���ڽ���ģ��
    .CLK_FREQ       (CLK_FREQ),       //����ϵͳʱ��Ƶ��
    .UART_BPS       (UART_BPS))       //���ô��ڽ��ղ�����
u_uart_recv(                 
    .sys_clk        (sys_clk),               //ϵͳʱ��                   input		          
    .sys_rst_n      (sys_rst_n),             //ϵͳ��λ���͵�ƽ��Ч        input    
    
    //Ӳ���ӿ�
    .uart_rxd       (uart_rxd),             //UART���ն˿�                input   
    //���ݽӿ�
    .uart_done      (uart_done),            //UART����һ֡������ɱ�־�ź� output  
    .uart_data      (uart_data_r)           //���󴫽�UART����            output  
    );
    
uart_send #(                          //���ڷ���ģ��
    .CLK_FREQ       (CLK_FREQ),       //����ϵͳʱ��Ƶ��
    .UART_BPS       (UART_BPS))       //���ô��ڷ��Ͳ�����
u_uart_send(                 
    .sys_clk        (sys_clk),          //ϵͳʱ��                           input	
    .sys_rst_n      (sys_rst_n),      //ϵͳ��λ���͵�ƽ��Ч                 input 
    
   //���ݽӿ�
    .uart_en        (uart_en_w),      //����ʹ���ź�                         input 
    .uart_din       (uart_data_w),    //Ҫ�� UART ���͵�����                  input 
    //Ӳ���ӿ�
    .uart_txd       (uart_txd)        //UART���Ͷ˿�                         output
    );                                       
    
    
    
    
endmodule
