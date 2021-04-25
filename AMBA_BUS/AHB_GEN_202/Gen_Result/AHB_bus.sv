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
	input  mas_send_type  master_peri_in,
	input  [2-1:0]  hprior_master_peri,
	output  slv_send_type  master_peri_out,
	input  mas_send_type  master_inst_in,
	input  [2-1:0]  hprior_master_inst,
	output  slv_send_type  master_inst_out,
	input  mas_send_type  master_data_in,
	input  [2-1:0]  hprior_master_data,
	output  slv_send_type  master_data_out,
//#MI#
	input  slv_send_type  slave_peri_in,
	output hsel_slave_peri,
	output mas_send_type  slave_peri_out,
	input  slv_send_type  slave_isnt_in,
	output hsel_slave_isnt,
	output mas_send_type  slave_isnt_out,
	input  slv_send_type  slave_data_in,
	output hsel_slave_data,
	output mas_send_type  slave_data_out,
	input					 hclk,
	input					 hreset_n
);

  parameter SI_PAYLOAD = 78;
  parameter MI_PAYLOAD = 34;
//================================================================================
//#SIGGEN# 
	logic [1-1:0][MI_PAYLOAD-1:0] payload_master_peri_in;
	slv_send_type payload_master_peri_out;
	logic default_slv_sel_master_peri;
	logic [1-1:0] hreq_master_peri;
	slv_send_type payload_dec_error_master_peri;
	logic	dec_error_sel_master_peri;
	logic [1-1:0][MI_PAYLOAD-1:0] payload_master_inst_in;
	slv_send_type payload_master_inst_out;
	logic default_slv_sel_master_inst;
	logic [1-1:0] hreq_master_inst;
	slv_send_type payload_dec_error_master_inst;
	logic	dec_error_sel_master_inst;
	logic [1-1:0][MI_PAYLOAD-1:0] payload_master_data_in;
	slv_send_type payload_master_data_out;
	logic default_slv_sel_master_data;
	logic [1-1:0] hreq_master_data;
	slv_send_type payload_dec_error_master_data;
	logic	dec_error_sel_master_data;

	logic [1-1:0] hreq_slave_peri;
	logic [1-1:0][SI_PAYLOAD-1:0] payload_slave_peri_in;
	mas_send_type payload_slave_peri_out;
	logic [1-1:0] hgrant_slave_peri;
	logic [1-1:0][2-1:0] hprior_slave_peri;
	logic hgrant_slave_peri_master_peri;
	logic [1-1:0] hreq_slave_isnt;
	logic [1-1:0][SI_PAYLOAD-1:0] payload_slave_isnt_in;
	mas_send_type payload_slave_isnt_out;
	logic [1-1:0] hgrant_slave_isnt;
	logic [1-1:0][2-1:0] hprior_slave_isnt;
	logic [1-1:0] hreq_slave_data;
	logic [1-1:0][SI_PAYLOAD-1:0] payload_slave_data_in;
	mas_send_type payload_slave_data_out;
	logic [1-1:0] hgrant_slave_data;
	logic [1-1:0][2-1:0] hprior_slave_data;
	logic hgrant_slave_data_master_data;
//================================================================================
//#DECGEN# 
	AHB_decoder_master_peri DEC_master_peri	(
		.haddr(master_peri_in.haddr),
		.htrans(master_peri_in.htrans),
		.default_slv_sel(default_slv_sel_master_peri),
		.hreq(hreq_master_peri),
		.*
	);


	AHB_mux_master_peri MUX_master_peri
	(
		.payload_in(payload_master_peri_in),
		.payload_out(payload_master_peri_out),
		.sel(hreq_master_peri)
	);

	default_slave DS_master_peri
	(
		.default_slv_sel(default_slv_sel_master_peri),
		.hreadyout(payload_dec_error_master_peri.hreadyout),
		.hresp(payload_dec_error_master_peri.hresp),
		.error_sel(dec_error_sel_master_peri),
		.*
	);

	assign payload_dec_error_master_peri.hrdata = '0;

	AHB_decoder_master_inst DEC_master_inst	(
		.haddr(master_inst_in.haddr),
		.htrans(master_inst_in.htrans),
		.default_slv_sel(default_slv_sel_master_inst),
		.hreq(hreq_master_inst),
		.*
	);


	AHB_mux_master_inst MUX_master_inst
	(
		.payload_in(payload_master_inst_in),
		.payload_out(payload_master_inst_out),
		.sel(hreq_master_inst)
	);

	default_slave DS_master_inst
	(
		.default_slv_sel(default_slv_sel_master_inst),
		.hreadyout(payload_dec_error_master_inst.hreadyout),
		.hresp(payload_dec_error_master_inst.hresp),
		.error_sel(dec_error_sel_master_inst),
		.*
	);

	assign payload_dec_error_master_inst.hrdata = '0;

	AHB_decoder_master_data DEC_master_data	(
		.haddr(master_data_in.haddr),
		.htrans(master_data_in.htrans),
		.default_slv_sel(default_slv_sel_master_data),
		.hreq(hreq_master_data),
		.*
	);


	AHB_mux_master_data MUX_master_data
	(
		.payload_in(payload_master_data_in),
		.payload_out(payload_master_data_out),
		.sel(hreq_master_data)
	);

	default_slave DS_master_data
	(
		.default_slv_sel(default_slv_sel_master_data),
		.hreadyout(payload_dec_error_master_data.hreadyout),
		.hresp(payload_dec_error_master_data.hresp),
		.error_sel(dec_error_sel_master_data),
		.*
	);

	assign payload_dec_error_master_data.hrdata = '0;

//================================================================================
//#ARBGEN#
	AHB_arbiter_slave_peri ARB_slave_peri
	(
		.hreq(hreq_slave_peri),
		.hburst(payload_slave_peri_out.hburst),
		.hwait(~slave_peri_in.hreadyout),
		.hgrant(hgrant_slave_peri),
		.hsel(hsel_slave_peri),
		.*
	);


	AHB_mux_slave_peri MUX_slave_peri
	(
		.payload_in(payload_slave_peri_in),
		.payload_out(payload_slave_peri_out),
		.sel(hgrant_slave_peri)
	);

	AHB_arbiter_slave_isnt ARB_slave_isnt
	(
		.hreq(hreq_slave_isnt),
		.hburst(payload_slave_isnt_out.hburst),
		.hwait(~slave_isnt_in.hreadyout),
		.hgrant(hgrant_slave_isnt),
		.hsel(hsel_slave_isnt),
		.*
	);


	AHB_mux_slave_isnt MUX_slave_isnt
	(
		.payload_in(payload_slave_isnt_in),
		.payload_out(payload_slave_isnt_out),
		.sel(hgrant_slave_isnt)
	);

	AHB_arbiter_slave_data ARB_slave_data
	(
		.hreq(hreq_slave_data),
		.hburst(payload_slave_data_out.hburst),
		.hwait(~slave_data_in.hreadyout),
		.hgrant(hgrant_slave_data),
		.hsel(hsel_slave_data),
		.*
	);


	AHB_mux_slave_data MUX_slave_data
	(
		.payload_in(payload_slave_data_in),
		.payload_out(payload_slave_data_out),
		.sel(hgrant_slave_data)
	);

//================================================================================
//#CROSSGEN#
	assign slave_peri_out = payload_slave_peri_out;

	assign hreq_slave_peri = { hreq_master_peri[0]};
	assign { hgrant_slave_peri_master_peri} = hgrant_slave_peri;
	assign hprior_slave_peri = { hprior_master_peri};
	assign payload_slave_peri_in[0] = master_peri_in;
	assign slave_isnt_out = payload_slave_isnt_out;
	assign slave_data_out = payload_slave_data_out;

	assign hreq_slave_data = { hreq_master_data[0]};
	assign { hgrant_slave_data_master_data} = hgrant_slave_data;
	assign hprior_slave_data = { hprior_master_data};
	assign payload_slave_data_in[0] = master_data_in;

	assign master_peri_out = (dec_error_sel_master_peri) ? payload_dec_error_master_peri : payload_master_peri_out;

	assign payload_master_peri_in[0] = {slave_peri_in.hreadyout & hgrant_slave_peri_master_peri, slave_peri_in.hrdata, slave_peri_in.hresp};
	assign master_inst_out = (dec_error_sel_master_inst) ? payload_dec_error_master_inst : payload_master_inst_out;

	assign payload_master_inst_in[0] = {slave_inst_in.hreadyout & hgrant_slave_inst_master_inst, slave_inst_in.hrdata, slave_inst_in.hresp};
	assign master_data_out = (dec_error_sel_master_data) ? payload_dec_error_master_data : payload_master_data_out;

	assign payload_master_data_in[0] = {slave_data_in.hreadyout & hgrant_slave_data_master_data, slave_data_in.hrdata, slave_data_in.hresp};

endmodule: AHB_bus
