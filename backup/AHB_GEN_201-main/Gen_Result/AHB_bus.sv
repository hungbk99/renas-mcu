//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_bus.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

//================================================================================
//#CONFIG_GEN#
//================================================================================

import AHB_package::*;
module AHB_bus
(
//#INTERFACEGEN#
//#SI#
	input  mas_send_type  master_1_in,
	input  [2-1:0]  hprior_master_1,
	output  slv_send_type  master_1_out,
	input  mas_send_type  master_2_in,
	input  [2-1:0]  hprior_master_2,
	output  slv_send_type  master_2_out,
	input  mas_send_type  master_3_in,
	input  [2-1:0]  hprior_master_3,
	output  slv_send_type  master_3_out,
	input  mas_send_type  kemee_in,
	input  [2-1:0]  hprior_kemee,
	output  slv_send_type  kemee_out,
//#MI#
	input  slv_send_type  slave_1_in,
	output hsel_slave_1,
	output mas_send_type  slave_1_out,
	input  slv_send_type  slave_2_in,
	output hsel_slave_2,
	output mas_send_type  slave_2_out,
	input  slv_send_type  slave_3_in,
	output hsel_slave_3,
	output mas_send_type  slave_3_out,
	input  slv_send_type  slave_4_in,
	output hsel_slave_4,
	output mas_send_type  slave_4_out,
	input  slv_send_type  slave_5_in,
	output hsel_slave_5,
	output mas_send_type  slave_5_out,
	input  slv_send_type  slave_6_in,
	output hsel_slave_6,
	output mas_send_type  slave_6_out,
	input  slv_send_type  slave_7_in,
	output hsel_slave_7,
	output mas_send_type  slave_7_out,
	input					 hclk,
	input					 hreset_n
);

  parameter SI_PAYLOAD = 78;
  parameter MI_PAYLOAD = 34;
//================================================================================
//#SIGGEN# 
	logic [4-1:0][MI_PAYLOAD-1:0] payload_master_1_in;
	slv_send_type payload_master_1_out;
	logic default_slv_sel_master_1;
	logic [4-1:0] hreq_master_1;
	logic [3-1:0][MI_PAYLOAD-1:0] payload_master_2_in;
	slv_send_type payload_master_2_out;
	logic default_slv_sel_master_2;
	logic [3-1:0] hreq_master_2;
	logic [2-1:0][MI_PAYLOAD-1:0] payload_master_3_in;
	slv_send_type payload_master_3_out;
	logic default_slv_sel_master_3;
	logic [2-1:0] hreq_master_3;
	logic [7-1:0][MI_PAYLOAD-1:0] payload_kemee_in;
	slv_send_type payload_kemee_out;
	logic default_slv_sel_kemee;
	logic [7-1:0] hreq_kemee;

	logic [3-1:0] hreq_slave_1;
	logic [3-1:0][SI_PAYLOAD-1:0] payload_slave_1_in;
	mas_send_type payload_slave_1_out;
	logic [3-1:0] hgrant_slave_1;
	logic [3-1:0][2-1:0] hprior_slave_1;
	logic hgrant_slave_1_master_1;
	logic hgrant_slave_1_master_2;
	logic hgrant_slave_1_kemee;
	logic [2-1:0] hreq_slave_2;
	logic [2-1:0][SI_PAYLOAD-1:0] payload_slave_2_in;
	mas_send_type payload_slave_2_out;
	logic [2-1:0] hgrant_slave_2;
	logic [2-1:0][2-1:0] hprior_slave_2;
	logic hgrant_slave_2_master_1;
	logic hgrant_slave_2_kemee;
	logic [2-1:0] hreq_slave_3;
	logic [2-1:0][SI_PAYLOAD-1:0] payload_slave_3_in;
	mas_send_type payload_slave_3_out;
	logic [2-1:0] hgrant_slave_3;
	logic [2-1:0][2-1:0] hprior_slave_3;
	logic hgrant_slave_3_master_2;
	logic hgrant_slave_3_kemee;
	logic [2-1:0] hreq_slave_4;
	logic [2-1:0][SI_PAYLOAD-1:0] payload_slave_4_in;
	mas_send_type payload_slave_4_out;
	logic [2-1:0] hgrant_slave_4;
	logic [2-1:0][2-1:0] hprior_slave_4;
	logic hgrant_slave_4_master_3;
	logic hgrant_slave_4_kemee;
	logic [4-1:0] hreq_slave_5;
	logic [4-1:0][SI_PAYLOAD-1:0] payload_slave_5_in;
	mas_send_type payload_slave_5_out;
	logic [4-1:0] hgrant_slave_5;
	logic [4-1:0][2-1:0] hprior_slave_5;
	logic hgrant_slave_5_master_1;
	logic hgrant_slave_5_master_2;
	logic hgrant_slave_5_master_3;
	logic hgrant_slave_5_kemee;
	logic [1-1:0] hreq_slave_6;
	logic [1-1:0][SI_PAYLOAD-1:0] payload_slave_6_in;
	mas_send_type payload_slave_6_out;
	logic [1-1:0] hgrant_slave_6;
	logic [1-1:0][2-1:0] hprior_slave_6;
	logic hgrant_slave_6_kemee;
	logic [2-1:0] hreq_slave_7;
	logic [2-1:0][SI_PAYLOAD-1:0] payload_slave_7_in;
	mas_send_type payload_slave_7_out;
	logic [2-1:0] hgrant_slave_7;
	logic [2-1:0][2-1:0] hprior_slave_7;
	logic hgrant_slave_7_master_1;
	logic hgrant_slave_7_kemee;
//================================================================================
//#DECGEN# 
	AHB_decoder_master_1 DEC_master_1	(
		.haddr(master_1_in.haddr),
		.htrans(master_1_in.htrans),
		.default_slv_sel(default_slv_sel_master_1),
		.hreq(hreq_master_1),
		.*
	);


	AHB_mux_master_1 MUX_master_1
	(
		.payload_in(payload_master_1_in),
		.payload_out(payload_master_1_out),
		.sel(hreq_master_1)
	);

	AHB_decoder_master_2 DEC_master_2	(
		.haddr(master_2_in.haddr),
		.htrans(master_2_in.htrans),
		.default_slv_sel(default_slv_sel_master_2),
		.hreq(hreq_master_2),
		.*
	);


	AHB_mux_master_2 MUX_master_2
	(
		.payload_in(payload_master_2_in),
		.payload_out(payload_master_2_out),
		.sel(hreq_master_2)
	);

	AHB_decoder_master_3 DEC_master_3	(
		.haddr(master_3_in.haddr),
		.htrans(master_3_in.htrans),
		.default_slv_sel(default_slv_sel_master_3),
		.hreq(hreq_master_3),
		.*
	);


	AHB_mux_master_3 MUX_master_3
	(
		.payload_in(payload_master_3_in),
		.payload_out(payload_master_3_out),
		.sel(hreq_master_3)
	);

	AHB_decoder_kemee DEC_kemee	(
		.haddr(kemee_in.haddr),
		.htrans(kemee_in.htrans),
		.default_slv_sel(default_slv_sel_kemee),
		.hreq(hreq_kemee),
		.*
	);


	AHB_mux_kemee MUX_kemee
	(
		.payload_in(payload_kemee_in),
		.payload_out(payload_kemee_out),
		.sel(hreq_kemee)
	);

//================================================================================
//#ARBGEN#
	AHB_arbiter_slave_1 ARB_slave_1
	(
		.hreq(hreq_slave_1),
		.hburst(payload_slave_1_out.hburst),
		.hwait(~slave_1_in.hreadyout),
		.hgrant(hgrant_slave_1),
		.hsel(hsel_slave_1),
		.*
	);


	AHB_mux_slave_1 MUX_slave_1
	(
		.payload_in(payload_slave_1_in),
		.payload_out(payload_slave_1_out),
		.sel(hgrant_slave_1)
	);

	AHB_arbiter_slave_2 ARB_slave_2
	(
		.hreq(hreq_slave_2),
		.hburst(payload_slave_2_out.hburst),
		.hwait(~slave_2_in.hreadyout),
		.hgrant(hgrant_slave_2),
		.hsel(hsel_slave_2),
		.hprior(hprior_slave_2),
		.*
	);


	AHB_mux_slave_2 MUX_slave_2
	(
		.payload_in(payload_slave_2_in),
		.payload_out(payload_slave_2_out),
		.sel(hgrant_slave_2)
	);

	AHB_arbiter_slave_3 ARB_slave_3
	(
		.hreq(hreq_slave_3),
		.hburst(payload_slave_3_out.hburst),
		.hwait(~slave_3_in.hreadyout),
		.hgrant(hgrant_slave_3),
		.hsel(hsel_slave_3),
		.*
	);


	AHB_mux_slave_3 MUX_slave_3
	(
		.payload_in(payload_slave_3_in),
		.payload_out(payload_slave_3_out),
		.sel(hgrant_slave_3)
	);

	AHB_arbiter_slave_4 ARB_slave_4
	(
		.hreq(hreq_slave_4),
		.hburst(payload_slave_4_out.hburst),
		.hwait(~slave_4_in.hreadyout),
		.hgrant(hgrant_slave_4),
		.hsel(hsel_slave_4),
		.*
	);


	AHB_mux_slave_4 MUX_slave_4
	(
		.payload_in(payload_slave_4_in),
		.payload_out(payload_slave_4_out),
		.sel(hgrant_slave_4)
	);

	AHB_arbiter_slave_5 ARB_slave_5
	(
		.hreq(hreq_slave_5),
		.hburst(payload_slave_5_out.hburst),
		.hwait(~slave_5_in.hreadyout),
		.hgrant(hgrant_slave_5),
		.hsel(hsel_slave_5),
		.hprior(hprior_slave_5),
		.*
	);


	AHB_mux_slave_5 MUX_slave_5
	(
		.payload_in(payload_slave_5_in),
		.payload_out(payload_slave_5_out),
		.sel(hgrant_slave_5)
	);

	AHB_arbiter_slave_6 ARB_slave_6
	(
		.hreq(hreq_slave_6),
		.hburst(payload_slave_6_out.hburst),
		.hwait(~slave_6_in.hreadyout),
		.hgrant(hgrant_slave_6),
		.hsel(hsel_slave_6),
		.*
	);


	AHB_mux_slave_6 MUX_slave_6
	(
		.payload_in(payload_slave_6_in),
		.payload_out(payload_slave_6_out),
		.sel(hgrant_slave_6)
	);

	AHB_arbiter_slave_7 ARB_slave_7
	(
		.hreq(hreq_slave_7),
		.hburst(payload_slave_7_out.hburst),
		.hwait(~slave_7_in.hreadyout),
		.hgrant(hgrant_slave_7),
		.hsel(hsel_slave_7),
		.*
	);


	AHB_mux_slave_7 MUX_slave_7
	(
		.payload_in(payload_slave_7_in),
		.payload_out(payload_slave_7_out),
		.sel(hgrant_slave_7)
	);

//================================================================================
//#CROSSGEN#
	assign slave_1_out = payload_slave_1_out;

	assign hreq_slave_1 = { hreq_master_1[3], hreq_master_2[2], hreq_kemee[6]};
	assign { hgrant_slave_1_master_1, hgrant_slave_1_master_2, hgrant_slave_1_kemee} = hgrant_slave_1;
	assign hprior_slave_1 = { hprior_master_1, hprior_master_2, hprior_kemee};
	assign payload_slave_1_in[2] = master_1_in;
	assign payload_slave_1_in[1] = master_2_in;
	assign payload_slave_1_in[0] = kemee_in;
	assign slave_2_out = payload_slave_2_out;

	assign hreq_slave_2 = { hreq_master_1[2], hreq_kemee[5]};
	assign { hgrant_slave_2_master_1, hgrant_slave_2_kemee} = hgrant_slave_2;
	assign hprior_slave_2 = { hprior_master_1, hprior_kemee};
	assign payload_slave_2_in[1] = master_1_in;
	assign payload_slave_2_in[0] = kemee_in;
	assign slave_3_out = payload_slave_3_out;

	assign hreq_slave_3 = { hreq_master_2[1], hreq_kemee[4]};
	assign { hgrant_slave_3_master_2, hgrant_slave_3_kemee} = hgrant_slave_3;
	assign hprior_slave_3 = { hprior_master_2, hprior_kemee};
	assign payload_slave_3_in[1] = master_2_in;
	assign payload_slave_3_in[0] = kemee_in;
	assign slave_4_out = payload_slave_4_out;

	assign hreq_slave_4 = { hreq_master_3[1], hreq_kemee[3]};
	assign { hgrant_slave_4_master_3, hgrant_slave_4_kemee} = hgrant_slave_4;
	assign hprior_slave_4 = { hprior_master_3, hprior_kemee};
	assign payload_slave_4_in[1] = master_3_in;
	assign payload_slave_4_in[0] = kemee_in;
	assign slave_5_out = payload_slave_5_out;

	assign hreq_slave_5 = { hreq_master_1[1], hreq_master_2[0], hreq_master_3[0], hreq_kemee[2]};
	assign { hgrant_slave_5_master_1, hgrant_slave_5_master_2, hgrant_slave_5_master_3, hgrant_slave_5_kemee} = hgrant_slave_5;
	assign hprior_slave_5 = { hprior_master_1, hprior_master_2, hprior_master_3, hprior_kemee};
	assign payload_slave_5_in[3] = master_1_in;
	assign payload_slave_5_in[2] = master_2_in;
	assign payload_slave_5_in[1] = master_3_in;
	assign payload_slave_5_in[0] = kemee_in;
	assign slave_6_out = payload_slave_6_out;

	assign hreq_slave_6 = { hreq_kemee[1]};
	assign { hgrant_slave_6_kemee} = hgrant_slave_6;
	assign hprior_slave_6 = { hprior_kemee};
	assign payload_slave_6_in[0] = kemee_in;
	assign slave_7_out = payload_slave_7_out;

	assign hreq_slave_7 = { hreq_master_1[0], hreq_kemee[0]};
	assign { hgrant_slave_7_master_1, hgrant_slave_7_kemee} = hgrant_slave_7;
	assign hprior_slave_7 = { hprior_master_1, hprior_kemee};
	assign payload_slave_7_in[1] = master_1_in;
	assign payload_slave_7_in[0] = kemee_in;

	assign master_1_out = payload_master_1_out;

	assign payload_master_1_in[3] = {slave_1_in.hreadyout & hgrant_slave_1_master_1, slave_1_in.hrdata, slave_1_in.hresp};
	assign payload_master_1_in[2] = {slave_2_in.hreadyout & hgrant_slave_2_master_1, slave_2_in.hrdata, slave_2_in.hresp};
	assign payload_master_1_in[1] = {slave_5_in.hreadyout & hgrant_slave_5_master_1, slave_5_in.hrdata, slave_5_in.hresp};
	assign payload_master_1_in[0] = {slave_7_in.hreadyout & hgrant_slave_7_master_1, slave_7_in.hrdata, slave_7_in.hresp};
	assign master_2_out = payload_master_2_out;

	assign payload_master_2_in[2] = {slave_1_in.hreadyout & hgrant_slave_1_master_2, slave_1_in.hrdata, slave_1_in.hresp};
	assign payload_master_2_in[1] = {slave_3_in.hreadyout & hgrant_slave_3_master_2, slave_3_in.hrdata, slave_3_in.hresp};
	assign payload_master_2_in[0] = {slave_5_in.hreadyout & hgrant_slave_5_master_2, slave_5_in.hrdata, slave_5_in.hresp};
	assign master_3_out = payload_master_3_out;

	assign payload_master_3_in[1] = {slave_4_in.hreadyout & hgrant_slave_4_master_3, slave_4_in.hrdata, slave_4_in.hresp};
	assign payload_master_3_in[0] = {slave_5_in.hreadyout & hgrant_slave_5_master_3, slave_5_in.hrdata, slave_5_in.hresp};
	assign kemee_out = payload_kemee_out;

	assign payload_kemee_in[6] = {slave_1_in.hreadyout & hgrant_slave_1_kemee, slave_1_in.hrdata, slave_1_in.hresp};
	assign payload_kemee_in[5] = {slave_2_in.hreadyout & hgrant_slave_2_kemee, slave_2_in.hrdata, slave_2_in.hresp};
	assign payload_kemee_in[4] = {slave_3_in.hreadyout & hgrant_slave_3_kemee, slave_3_in.hrdata, slave_3_in.hresp};
	assign payload_kemee_in[3] = {slave_4_in.hreadyout & hgrant_slave_4_kemee, slave_4_in.hrdata, slave_4_in.hresp};
	assign payload_kemee_in[2] = {slave_5_in.hreadyout & hgrant_slave_5_kemee, slave_5_in.hrdata, slave_5_in.hresp};
	assign payload_kemee_in[1] = {slave_6_in.hreadyout & hgrant_slave_6_kemee, slave_6_in.hrdata, slave_6_in.hresp};
	assign payload_kemee_in[0] = {slave_7_in.hreadyout & hgrant_slave_7_kemee, slave_7_in.hrdata, slave_7_in.hresp};

endmodule: AHB_bus
