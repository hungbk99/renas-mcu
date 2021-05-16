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
  `include "D:/Project/renas-mcu/AMBA_BUS/APB_GEN_202/Sample/apb_package.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/APB_GEN_202/Sample/h2p_top.sv"
  `include "D:/Project/renas-mcu/SPI/rtl/spi_top.sv"
`endif

module renas_mcu_top
(
  // SPI interface
  output                      mosi_somi,
                              ss_0,
                              ss_1,
                              ss_2,
                              ss_3,
  input                       miso_simo,
  inout                       sclk,    
  // Clock 
  input                       clk,
	                            clk_l1, //Delay clock used for Cache
			                        clk_l2,
                              clk_peri,
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
  	logic                                   data_dec_err;
    
    //PERI-ITF
    mas_send_type                           peri_out;
    slv_send_type                           peri_in;
  	//Interrupt Handler
    logic                                   peri_dec_err;
  //-------------------------------------------------------------------
	 	logic								                    external_halt;
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
  slv_send_type slave_peri_in;
  mas_send_type slave_peri_out;
  //-------------------------------------------------------------------
  //SPI-APB
  //-------------------------------------------------------------------
  apb_package::slave_s_type   apb_slave_out;
  apb_package::master_s_type  apb_slave_in;
  logic                       spi_psel;
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
  	.master_peri_in(peri_out),
  	.hprior_master_peri(hprior_master_peri),
  	.master_peri_out(peri_in),
  	.master_inst_in(iahb_out),
  	.hprior_master_inst(hprior_master_inst),
  	.master_inst_out(iahb_in),
  	.master_data_in(dahb_out),
  	.hprior_master_data(hprior_master_data),
  	.master_data_out(dahb_in),
  //#MI#
  	.slave_peri_in(slave_peri_in),
  	.hsel_slave_peri(peri_hsel),
  	.slave_peri_out(slave_peri_out),
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

  x2p_top x2p 
  (
    //AHB interface
    .hsel_slave_peri(peri_hsel),  
    //.slave_peri_out(),
    //.slave_peri_in(),
    //APB interface
    .apb_spi_out(apb_slave_in),
    //.spi_psel(),
    .apb_spi_in(apb_slave_out),
    .ahb_clk(clk),
    .apb_clk(clk_peri),
    .*
  );

  spi_top
  (
  //// spi APB interface
  //  .apb_slave_out,
  //  .apb_slave_in,
  //// SPI interface
  //  .mosi_somi,
  //  .ss_0,
  //  .ss_1,
  //  .ss_2,
  //  .ss_3,
  //  .miso_simo,
  //  .sclk                   
    .psel(spi_psel),
    .pclk(clk_peri), 
    .preset_n(rst_n),
    .*
  );
endmodule: renas_mcu_top
