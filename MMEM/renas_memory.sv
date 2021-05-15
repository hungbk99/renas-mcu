//////////////////////////////////////////////////////////////////////////////////
// File Name: 		renas_memory.sv
// Function:		  Main memory for renas mcu
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.0   17.04.2021  hungbk99  Modify from RVS192 cpu
// v0.1   19.04.2021  hungbk99  Modify from Single-RAM => Dual RAM
// v0.2   26.04.2021  hungbk99  Modify to map with RVS192 cpu
//////////////////////////////////////////////////////////////////////////////////
`define MEM_SIM
`ifndef TEST
  `ifndef TOP
    `include "D:/Project/renas-mcu/RISC-V/RVS192/DualPort_SRAM.sv"  
    `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/AHB_package.sv"
    `include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_user_define.h"
    `include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_user_parameters.sv"
    `include "D:/Project/renas-mcu/RISC-V/RVS192/RVS192_package.sv"
  `endif
`endif
import 	RVS192_package::*;
import  AHB_package::*;
import	RVS192_user_parameters::*;
module  renas_memory 
(
  //I-AHB-ITF
  input                   imem_hsel,
  input   mas_send_type   imem_in,
  output  slv_send_type   imem_out,
  //D-AHB-ITF
  input                   dmem_hsel,
  input   mas_send_type   dmem_in,
  output  slv_send_type   dmem_out,

  //	System
  input                   clk_l2,
	input                   clk_mem,
	input	                  rst_n
);
//--------------------------------------------------------------------------------
logic dmem_wen;
logic [DATA_LENGTH-1:0]   syn_imem_rdata;
logic [DATA_LENGTH-1:0]   syn_dmem_rdata;
logic [DATA_LENGTH-1:0]   syn_dmem_wdata;
logic [PC_LENGTH-1:0]     syn_imem_addr;
logic [DATA_LENGTH-1:0]   syn_dmem_addr;
logic                     imem_req;
logic                     imem_ack;
logic                     imem_ack_dl;
logic                     dmem_req;
logic                     dmem_ack;
logic                     dmem_ack_dl;
//--------------------------------------------------------------------------------
always_ff @(posedge clk_l2, negedge rst_n)
begin
  if(!rst_n)    
  begin
    imem_out <= '0;
    dmem_out <= '0;    
  end
  else begin
    if(imem_req && imem_ack)
    begin
      imem_out.hreadyout <= 1'b1;
      imem_out.hrdata <= syn_imem_rdata;
    end
    else
      imem_out.hreadyout <= 1'b0;

    if(dmem_req && dmem_ack)
    begin
      dmem_out.hreadyout <= 1'b1;
      dmem_out.hrdata <= syn_dmem_rdata;
    end
    else
      dmem_out.hreadyout <= 1'b0;
  end
end

always_ff @(posedge clk_l2, negedge rst_n)
begin
  if(!rst_n) begin
    imem_req <= 1'b0;
    dmem_req <= 1'b0;
    //Hung_mod imem_ack_dl <= 1'b0;
    //Hung_mod dmem_ack_dl <= 1'b0;
  end
  else begin
    //Hung_mod imem_ack_dl <= imem_ack;
    if(imem_hsel && !imem_ack && !imem_ack_dl)
      imem_req <= 1'b1;
    else if(imem_ack)
      imem_req <= 1'b0;

    //Hung_mod dmem_ack_dl <= dmem_ack;
    if(dmem_hsel && !dmem_ack && !dmem_ack_dl)
      dmem_req <= 1'b1;
    else if(dmem_ack)
      dmem_req <= 1'b0;
  end
end
//--------------------------------------------------------------------------------

always_ff @(posedge clk_mem, negedge rst_n)
begin
  if(!rst_n)    
  begin
    syn_imem_addr <= '0;
    syn_dmem_addr <= '0;
    syn_dmem_wdata <= '0;
    //Hung_add
    imem_ack_dl <= 1'b0;
    dmem_ack_dl <= 1'b0;
    //Hung_add
  end
  else begin
    //if(imem_req)
      syn_imem_addr <= imem_in.haddr;
      //Hung_add
      imem_ack_dl <= imem_ack;
      //Hung_add

    //if(dmem_req) begin
      syn_dmem_addr <= dmem_in.haddr;
      syn_dmem_wdata <= dmem_in.hwdata;
      //Hung_add
      dmem_ack_dl <= dmem_ack;
      //Hung_add
    //end
  end
end

always_ff @(posedge clk_mem, negedge rst_n)
begin
  if(!rst_n)    
  begin
    imem_ack <= 1'b0;
    dmem_ack <= 1'b0;
  end
  else begin
    if(imem_req)
      imem_ack <= 1'b1;
    else 
      imem_ack <= 1'b0;
        
    if(dmem_req)
      dmem_ack <= 1'b1;
    else 
      dmem_ack <= 1'b0;
  end
end

assign dmem_wen = dmem_ack & dmem_in.hwrite;

//--------------------------------------------------------------------------------
DualPort_SRAM
#(
.SRAM_LENGTH(DATA_LENGTH), 
.SRAM_DEPTH(MEM_LINE)
)
MEM
(
.data_out1(syn_imem_rdata), 
.data_out2(syn_dmem_rdata),	
.data_in1('0),
.data_in2(syn_dmem_wdata),	
.addr1(syn_imem_addr[31:2]),
.addr2(syn_dmem_addr[31:2]),
.wen1(1'b0), 
.wen2(dmem_wen), 
.clk(clk_mem)
);
//-------------------------------------------------------------------------------
  `ifdef MEM_SIM
	  //  //parameter INST = "D:/RISC-V/testbench/pipeline_test1.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/pipeline_test2.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/pipeline_test3.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/pipeline_test4.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/pipeline_test5.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/pipeline_test6.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/pipeline_test7.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/forwarding_test.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/factorial_test.txt";		// maximum factorial = 12!
	  //  //parameter INST = "D:/RISC-V/testbench/factorial_opt.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/arrangment.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/arrangement_fix.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/inner_loop.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/larger_inner_loop.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/inner_loop1.txt";
	  //  //parameter INST = "D:/RISC-V/testbench/larger_inner_loop1.txt";
    //  parameter INST = "D:/RISC-V/testbench/arrangement_cache_test1.txt";
    //  initial begin
    //  	$readmemh(INST, MEM.SRAM, 32'h0000_2000, 32'h0000_3fff);
    //  	$readmemh("D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/data_memory_file.txt", MEM.SRAM, 32'h0000_0000, 32'h0000_1fff);
    //  end
  `endif
endmodule
