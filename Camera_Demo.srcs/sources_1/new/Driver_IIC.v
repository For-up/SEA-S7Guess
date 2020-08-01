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
    input i_iic_write,          //IICд�ź�,��������Ч
    input i_iic_read,           //IIC���ź�,��������Ч
    input i_iic_mode,           //IICģʽ,1����˫��ַλ,0������ַλ,��λ��ַ��Ч
    input [7:0]i_slave_addr,    //IIC�ӻ���ַ
    input [7:0]i_reg_addr_h,    //�Ĵ�����ַ,��8λ
    input [7:0]i_reg_addr_l,    //�Ĵ�����ַ,��8λ
    input [7:0]i_data_w,        //��Ҫ���������
    output [7:0]o_data_r,       //IIC����������
    output o_iic_busy,          //IICæ�ź�,�ڹ���ʱæ,�͵�ƽæ
    output o_iic_scl,           //IICʱ����
    output o_sda_dir,           //IIC�����߷���,1�������
    output o_iic_sda            //IIC������
    );
    //����
    parameter System_Clk_MHz=13'd100;
    parameter Set_IIC_SCL_kHz=13'd100;
    
    //SCL�ڵ����
    localparam  SCL_Divider=System_Clk_MHz/Set_IIC_SCL_kHz;
    localparam  SCL_SUM = (SCL_Divider<<10)-(SCL_Divider<<4)-(SCL_Divider<<3);        //SCL��Ƶϵ��
    localparam  SCL_H_START=0;                                          //SCL�ߵ�ƽ��ʼ��
    localparam  SCL_H_CENTER=(SCL_SUM >> 1)-(SCL_SUM >> 2)-1;           //SCL�ߵ�ƽ�е�
    localparam  SCL_L_START=(SCL_SUM >> 1)-1;                           //SCL�͵�ƽ��ʼ��
    localparam  SCL_L_CENTER=(SCL_SUM >> 1)+(SCL_SUM >> 2)-1;           //SCL�͵�ƽ�е�
    
    //״̬����
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
    
    //����
    reg [13:0]reg_scl_cnt=0;
    reg [2:0]reg_byte_cnt=0;
    
    //״̬����
    reg [4:0]state_current=0;                                      //��ǰ״̬
    reg [4:0]state_next=0;                                         //��һ��״̬
    
    //���仺��
    reg buf_iic_write=0;                                                //д�źŻ���
    reg buf_iic_read=0;                                                 //���źŻ���
    reg buf_iic_mode=0;                                                 //IICģʽ,1����˫��ַλ,0������ַλ,��λ��ַ��Ч
    reg [7:0]buf_slave_addr_r=0;                                        //IIC�ӻ���ַ,��
    reg [7:0]buf_slave_addr_w=0;                                        //IIC�ӻ���ַ,д
    reg [7:0]buf_reg_addr_h=0;                                          //�Ĵ�����ַ,��8λ
    reg [7:0]buf_reg_addr_l=0;                                          //�Ĵ�����ַ,��8λ
    reg [7:0]buf_data=0;                                                //��Ҫ���������
    reg buff_iic_sda=0;                                                 //SDA
    
    //�źż��
    reg [1:0]iic_write_req_rise=0;                                      //IICд���������ؼ��
    reg [1:0]iic_read_req_rise=0;                                       //IIC�����������ؼ��
    
    //��־
    wire flg_write_rise=(iic_write_req_rise==2'b01);                    //IICд�����ر�־
    wire flg_read_rise=(iic_read_req_rise==2'b01);                      //IIC�������ر�־
    wire flg_scl_hs = (reg_scl_cnt == SCL_H_START);                     //SCL����ʼ��־
    wire flg_scl_hc = (reg_scl_cnt == SCL_H_CENTER);                    //SCL�����ı�־
    wire flg_scl_ls = (reg_scl_cnt == SCL_L_START);                     //SCL����ʼ��־
    wire flg_scl_lc = (reg_scl_cnt == SCL_L_CENTER);                    //SCL�����ı�־
    
    //ʹ��
    reg iic_write_req=0;                                                //дʹ��
    reg iic_read_req=0;                                                 //��ʹ��
    
    //����ź�
    reg [7:0]data_r_o=0;                                                //IIC����������
    reg iic_busy_o=0;                                                   //IICæ�ź�,�ڹ���ʱæ
    reg iic_scl_o=1;                                                    //IICʱ����
    reg sda_dir_o=0;                                                    //IIC�����߷���,1�������
    reg iic_sda_o=1;                                                    //IIC������
    
    //�������
    assign o_data_r=data_r_o;       //IIC����������
    assign o_iic_busy=iic_busy_o;   //IICæ�ź�,�ڹ���ʱæ
    assign o_iic_scl=iic_scl_o;     //IICʱ����
    assign o_sda_dir=sda_dir_o;     //IIC�����߷���,1�������
    assign o_iic_sda=iic_sda_o;     //IIC������
    
    //��״̬��
    always@(*)begin
        case(state_current)
            
            //�ȴ�״̬
            ST_IDLE:begin
                if((iic_write_req||iic_read_req)&flg_scl_hc)begin
                    state_next<=ST_START;
                end
                else begin
                    state_next<=ST_IDLE;
                end
            end
            
            //��ʼ�ź�
            ST_START:begin
                if(flg_scl_lc)begin
                    state_next<=ST_W_SADDR;
                end
                else begin
                    state_next<=ST_START;
                end
            end
            
            //д�ӻ���ַ
            ST_W_SADDR:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_ACK_0;
                end
                else begin
                    state_next<=ST_W_SADDR;
                end
            end
            
            //Ӧ���ź�0
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
            
            //д�Ĵ�����λ��ַ
            ST_W_ADDR_H:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_ACK_1;
                end
                else begin
                    state_next<=ST_W_ADDR_H;
                end
            end
            
            //Ӧ���ź�1
            ST_ACK_1:begin
                if(flg_scl_lc)begin
                    state_next<=ST_W_ADDR_L;
                end
                else begin
                    state_next<=ST_ACK_1;
                end
            end
            
            //д�Ĵ�����λ��ַ
            ST_W_ADDR_L:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_ACK_2;
                end
                else begin
                    state_next<=ST_W_ADDR_L;
                end
            end
            
            //Ӧ���ź�2
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
            
            //д����
            ST_W_DATA:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_ACK_3;
                end
                else begin
                    state_next<=ST_W_DATA;
                end
            end
            
            //Ӧ���ź�3
            ST_ACK_3:begin
                if(flg_scl_lc)begin
                    state_next<=ST_STOP;
                end
                else begin
                    state_next<=ST_ACK_3;
                end
            end

            //����ʼ�ź�
            ST_START_R:begin
                if(flg_scl_lc)begin
                    state_next<=ST_W_SADDR_R;
                end
                else begin
                    state_next<=ST_START_R;
                end
            end
            
            //д�ӻ���ַ
            ST_W_SADDR_R:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_ACK_4;
                end
                else begin
                    state_next<=ST_W_SADDR_R;
                end
            end
            
            //Ӧ���ź�4
            ST_ACK_4:begin
                if(flg_scl_lc)begin
                    state_next<=ST_R_DATA;
                end
                else begin
                    state_next<=ST_ACK_4;
                end
            end
            
            //������
            ST_R_DATA:begin
                if(flg_scl_lc&reg_byte_cnt==0)begin
                    state_next<=ST_NACK;
                end
                else begin
                    state_next<=ST_R_DATA;
                end
            end

            //��Ӧ���ź�
            ST_NACK:begin
                if(flg_scl_lc)begin
                    state_next<=ST_STOP;
                end
                else begin
                    state_next<=ST_NACK;
                end
            end
            
            //ֹͣ�ź�
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
    
    //scl����
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            reg_scl_cnt <= 13'd0;
        end
        else if(reg_scl_cnt== SCL_SUM - 1)
            reg_scl_cnt <= 13'd0;
        else
            reg_scl_cnt <= reg_scl_cnt + 1;
    end
    
    //ʱ�����
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
    //д�����ź�
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
    //д�����ź�
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
    
    //IICæ�ź����
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
    //��д���8��ʱ�Ӽ���
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
    
    //�����������
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
    //״̬ת��
    always@(posedge i_clk or negedge i_rst)begin
        if(!i_rst)begin
            state_current<=ST_IDLE;
        end
        else begin
            state_current<=state_next;
        end
    end
    //�źż��
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
    
    //�����źŻ���
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
