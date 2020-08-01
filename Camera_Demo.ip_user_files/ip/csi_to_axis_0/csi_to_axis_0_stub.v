// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Thu Jul 30 16:01:21 2020
// Host        : LAPTOP-EJ7V6R4H running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/FPGA/Camera_Demo2/Camera_Demo/Camera_Demo.srcs/sources_1/ip/csi_to_axis_0/csi_to_axis_0_stub.v
// Design      : csi_to_axis_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s15ftgb196-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "csi_to_axis_v1_0,Vivado 2018.3" *)
module csi_to_axis_0(enable_in, rxbyteclkhs, cl_enable, 
  cl_stopstate, cl_rxclkactivehs, dl0_enable, dl0_rxactivehs, dl0_rxvalidhs, dl0_rxsynchs, 
  dl0_datahs, dl1_enable, dl1_rxactivehs, dl1_rxvalidhs, dl1_rxsynchs, dl1_datahs, trig_req, 
  trig_ack, m_axis_tdata, m_axis_tuser, m_axis_tlast, m_axis_tvalid, m_axis_tready, 
  m_axis_aclk, m_axis_aresetn)
/* synthesis syn_black_box black_box_pad_pin="enable_in,rxbyteclkhs,cl_enable,cl_stopstate,cl_rxclkactivehs,dl0_enable,dl0_rxactivehs,dl0_rxvalidhs,dl0_rxsynchs,dl0_datahs[7:0],dl1_enable,dl1_rxactivehs,dl1_rxvalidhs,dl1_rxsynchs,dl1_datahs[7:0],trig_req,trig_ack,m_axis_tdata[15:0],m_axis_tuser,m_axis_tlast,m_axis_tvalid,m_axis_tready,m_axis_aclk,m_axis_aresetn" */;
  input enable_in;
  input rxbyteclkhs;
  output cl_enable;
  input cl_stopstate;
  input cl_rxclkactivehs;
  output dl0_enable;
  input dl0_rxactivehs;
  input dl0_rxvalidhs;
  input dl0_rxsynchs;
  input [7:0]dl0_datahs;
  output dl1_enable;
  input dl1_rxactivehs;
  input dl1_rxvalidhs;
  input dl1_rxsynchs;
  input [7:0]dl1_datahs;
  output trig_req;
  input trig_ack;
  output [15:0]m_axis_tdata;
  output m_axis_tuser;
  output m_axis_tlast;
  output m_axis_tvalid;
  input m_axis_tready;
  input m_axis_aclk;
  input m_axis_aresetn;
endmodule
