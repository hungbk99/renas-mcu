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

`include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_user_define.h"
`include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_result/AHB_bus.sv"
`include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192.sv"
`include "D:/Project/renas-mcu/MMEM/renas_memory.sv"
module renas_mcu_top
(
  input                                 clk,
	                                      clk_l1, //Delay clock used for Cache
			                                  clk_l2,
                                        clk_mem,
                                        rst_n

);
  //==============================================================================
  //-------------------------------------------------------------------
  //CPU 
  //-------------------------------------------------------------------
  	mas_send_type                           iahb_out;
  	slv_send_type                           iahb_in;
  	//Interrupt Handler
  	logic                                   inst_dec_err;
  	//D-AHB-ITF
  	mas_send_type                           dahb_out;
  	slv_send_type                           dahb_in;
  	//Interrupt Handler
  	logic                                   data_dec_err,
	 											                    external_halt;
  //-------------------------------------------------------------------
  //logic                                   peri_dec_err;
  //==============================================================================
  //-------------------------------------------------------------------
  //AHB-Bus: AHB-lite -> single slave-single master only
  //-------------------------------------------------------------------
  logic [1:0]   hprior_master_peri,
                hprior_master_inst_1,
                hprior_master_inst_2,
                hprior_master_data_1,
                hprior_master_data_2;
  
  logic         dmem_hsel,
                imem_hsel,
                peri_hsel;
 
  logic         hsel_slave_peri,
                hsel_slave_inst_1,
                hsel_slave_inst_2,
                hsel_slave_data_1,
                hsel_slave_data_2;

  mas_send_type dmem_in;
  slv_send_type dmem_out;

  mas_send_type imem_in;
  slv_send_type imem_out;
  
  mas_send_type peri_apb_out;
  slv_send_type peri_apb_in;
  //==============================================================================
  //Connection
  //==============================================================================
 
  assign external_halt = 1'b0;

  //-------------------------------------------------------------------
  //Floating signals of AHB bus
  assign hprior_master_peri = '0;
  assign hprior_master_inst = '0;
  assign hprior_master_data = '0;
  //-------------------------------------------------------------------

  RVS192 renas_cpu_202
  (
  	output  mas_send_type                           iahb_out,
  	input   slv_send_type                           iahb_in,
  	//Interrupt Handler
  	output logic                                    inst_dec_err,
  	//D-AHB-ITF
  	output  mas_send_type                           dahb_out,
  	input   slv_send_type                           dahb_in,
  	//Interrupt Handler
  	output logic                                    data_dec_err,
	//Hung_add_25.04.2021

	input 											external_halt,
			    									clk,
			    									clk_l1,
			    									clk_l2,
			    									mem_clk,
			    									rst_n
    .*
  );
  AHB_bus ahb_matrix
  (
  //#INTERFACEGEN#
  //#SI#
  	.master_peri_in(),
  	.hprior_master_peri(),
  	.master_peri_out(),
  	.master_inst_in(),
  	.hprior_master_inst(),
  	.master_inst_out(),
  	.master_data_in(),
  	.hprior_master_data(),
  	.master_data_out(),
  //#MI#
  	.slave_peri_in(),
  	.hsel_slave_peri(peri_hsel),
  	.slave_peri_out(),
  	.slave_isnt_in(),
  	.hsel_slave_isnt(imem_hsel),
  	.slave_isnt_out(),
  	.slave_data_in(),
  	.hsel_slave_data(dmem_hsel),
  	.slave_data_out(),
  	.hclk(clk_l2),
  	.hreset_n(rst_n)
  (

  renas_memory  mmem
  (
    .imem_in(),
    .imem_out(),
    
    .dmem_in(),
    .dmem_out(),
	  .*
  );
endmodule: renas_mcu_top
