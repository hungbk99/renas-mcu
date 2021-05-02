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

`define TOP
`ifndef TEST
  `include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_user_define.h"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_result/AHB_bus.sv"
  `include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192.sv"
  `include "D:/Project/renas-mcu/MMEM/renas_memory.sv"
`endif

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
  	//I-AHB-ITF
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
  	//Peri-AHB-ITF
    mas_send_type                           peri_master_out;
  	slv_send_type                           peri_master_in;
  	//Interrupt Handler
  	logic                                   peri_dec_err;
  //-------------------------------------------------------------------
  //logic                                   peri_dec_err;
  //==============================================================================
  //-------------------------------------------------------------------
  //AHB-Bus: AHB-lite -> single slave-single master only
  //-------------------------------------------------------------------
  logic [1:0]   hprior_master_peri,
                hprior_master_inst,
                hprior_master_data;
  
  logic         dmem_hsel,
                imem_hsel,
                peri_hsel;

  mas_send_type dmem_in;
  slv_send_type dmem_out;

  mas_send_type imem_in;
  slv_send_type imem_out;
  
  //Peri-AHB-ITF
  mas_send_type peri_slave_in;
  slv_send_type peri_slave_out;
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
    .*
  );
  AHB_bus ahb_matrix
  (
  //#INTERFACEGEN#
  //#SI#
  	.master_peri_in(peri_master_out),
  	.hprior_master_peri(hprior_master_peri),
  	.master_peri_out(peri_master_in),
  	.master_inst_in(iahb_out),
  	.hprior_master_inst(hprior_master_inst),
  	.master_inst_out(iahb_in),
  	.master_data_in(dahb_out),
  	.hprior_master_data(hprior_master_data),
  	.master_data_out(dahb_in),
  //#MI#
  	.slave_peri_in(peri_slave_out),
  	.hsel_slave_peri(peri_hsel),
  	.slave_peri_out(peri_slave_in),
  	.slave_inst_in(imem_out),
  	.hsel_slave_inst(imem_hsel),
  	.slave_inst_out(imem_in),
  	.slave_data_in(dmem_out),
  	.hsel_slave_data(dmem_hsel),
  	.slave_data_out(dmem_in),
  	.hclk(clk_l2),
  	.hreset_n(rst_n)
  );

  renas_memory  mmem
  (
	  .*
  );
endmodule: renas_mcu_top
