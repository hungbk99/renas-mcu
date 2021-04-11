//////////////////////////////////////////////////////////////////////////////////
// File Name: 		renas_mcu_top.sv
// Function:		  Top Module for renas mcu
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.0   10.04.2021  hungbk99  First Creation
//////////////////////////////////////////////////////////////////////////////////

`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/renas_cpu.sv"
module renas_mcu_top
(
  input                                 clk,
	                                      cache_clk, //Delay clock used for Cache
			                                          //Hung_mod_14_03 clk_l2,
			                                          //Hung_mod_14_03 mem_clk,
			                                  rst_n

);
  //-------------------------------------------------------------------
  //INST-AHB bus
  mas_send_type           iahb_out_1;
  mas_send_type           iahb_out_2;
  slv_send_type           iahb_in_1;
  slv_send_type           iahb_in_2;
  //Interrupt Handler
  logic                    inst_dec_err;
  //-------------------------------------------------------------------
  //DATA-AHB bus
  mas_send_type                         dahb_out_1;
  mas_send_type                         dahb_out_2;
  mas_send_type                         peri_ahb_out;
  slv_send_type                         dahb_in_1;
  slv_send_type                         dahb_in_2;
  slv_send_type                         peri_ahb_in;
  //Interrupt Handler
  logic                                  data_dec_err;
  //-------------------------------------------------------------------
	//WB Buffer
  logic [2*DATA_LENGTH-BYTE_OFFSET-1:0] wb_data;	
	logic 											          wb_req,
												                wb_ack,	
												                full_flag,
	                                      external_halt;

  renas_cpu renas_cpu_202
  (
    .*
  );

endmodule: renas_mcu_top
