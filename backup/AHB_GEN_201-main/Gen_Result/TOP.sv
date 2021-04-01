//////////////////////////////////////////////////////////////////////////////////
// File Name: 		TOP.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

import AHB_package::*;
module TOP
( 
  input hclk,
  input  hreset_n
);
	
  mas_send_type  master_1_in;
	logic [$clog2(2)-1:0]  hprior_master_1;
	slv_send_type  master_1_out;
	mas_send_type  master_2_in;
	logic [$clog2(2)-1:0]  hprior_master_2;
	slv_send_type  master_2_out;
	mas_send_type  master_3_in;
	logic [$clog2(2)-1:0]  hprior_master_3;
	slv_send_type  master_3_out;
	mas_send_type  kemee_in;
	logic [$clog2(2)-1:0]  hprior_kemee;
  slv_send_type  kemee_out;
//#MI#
	slv_send_type  slave_1_in;
	logic hsel_slave_1;
	mas_send_type  slave_1_out;
	slv_send_type  slave_2_in;
	logic hsel_slave_2;
	mas_send_type  slave_2_out;
	slv_send_type  slave_3_in;
	logic hsel_slave_3;
	mas_send_type  slave_3_out;
	slv_send_type  slave_4_in;
	logic hsel_slave_4;
	mas_send_type  slave_4_out;
	slv_send_type  slave_5_in;
	logic hsel_slave_5;
	mas_send_type  slave_5_out;
	slv_send_type  slave_6_in;
	logic hsel_slave_6;
	mas_send_type  slave_6_out;
	slv_send_type  slave_7_in;
	logic hsel_slave_7;
	mas_send_type  slave_7_out;

  AHB_bus DUT(.*);

endmodule
