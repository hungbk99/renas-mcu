//////////////////////////////////////////////////////////////////////////////////
// File Name: 		Memory.sv
// Module Name:		Memory
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
// Copyright (C) 	Le Quang Hung 
// Email: 			quanghungbk1999@gmail.com  
//////////////////////////////////////////////////////////////////////////////////

//`include"RVS192_user_define.h"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	Memory
(
	output 	logic [INST_LENGTH-1:0]			inst_mem_read,
	output 	logic [DATA_LENGTH-1:0]			data_mem_read,
	output 	logic							inst_res,		//	Use for synchoronous
											data_res,
	input 	[DATA_LENGTH-1:0]				data_mem_write,
											data_addr,
	input 	[PC_LENGTH-1:0]					inst_addr,
	input 									inst_read_req,
											data_read_req,
											data_write_req,
											mem_clk,
											rst_n
);
//================================================================================	
//	Internal Signals
	logic									inst_read_req_sync,
											data_read_req_sync,
											data_write_req_sync,
											inst_read_ena,
											data_read_ena,
											data_write_ena,
											inst_read_samp,
											data_read_samp,
											data_write_samp;

	logic	[DATA_LENGTH-1:0]				data_addr_sync,
											data_mem_write_sync;
	
	logic 	[DATA_LENGTH-1-2:0]				p_D_Word,
											p_I_Word;
											
	logic 	[1:0]							p_D_Byte,
											p_I_Byte;
	
	logic 	[PC_LENGTH-1:0]					inst_addr_sync;
	
//	MEM	
	logic 	[DATA_LENGTH-1:0]	MEM	[MEM_LINE-1:0];

//================================================================================	
//	L2 Cache Interface
	always_ff @(posedge mem_clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_read_req_sync <= 1'b0;
			data_read_req_sync <= 1'b0;
			data_write_req_sync <= 1'b0;
			inst_read_ena <= 1'b0;
			data_read_ena <= 1'b0;
			data_write_ena <= 1'b0;
		end
		else begin
			inst_read_req_sync <= inst_read_req;
			data_read_req_sync <= data_read_req;
			data_write_req_sync <= data_write_req;		
			inst_read_ena <= inst_read_samp;
			data_read_ena <= data_read_samp;
			data_write_ena <= data_write_samp;			
		end
	end
	
	assign	inst_read_samp = inst_read_req && !inst_read_req_sync;
	assign 	data_read_samp = data_read_req && !data_read_req_sync;
	assign 	data_write_samp = data_write_req && !data_write_req_sync;
	
	always_ff @(posedge mem_clk)
	begin
		if(data_write_samp)
			data_mem_write_sync <= data_mem_write;	
		else 
			data_mem_write_sync <= data_mem_write_sync;
	end

	always_ff @(posedge mem_clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_addr_sync <= '0;
			data_addr_sync <= '0;
		end
		else begin
			if(inst_read_samp)	
				inst_addr_sync <= inst_addr;
			else 	
				inst_addr_sync <= inst_addr_sync;
			
			if(data_read_samp || data_write_samp)	
				data_addr_sync <= data_addr;
			else 
				data_addr_sync <= data_addr_sync;
		end
	end	
	
	assign 	p_I_Word = inst_addr_sync[31:2];
	assign 	p_I_Byte = inst_addr_sync[1:0];	

	assign 	p_D_Word = data_addr_sync[31:2];
	assign 	p_D_Byte = data_addr_sync[1:0];	
	
	always_ff @(posedge mem_clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			data_mem_read <= '0;
			inst_mem_read <= '0;
		end
		else begin
			if((data_write_ena) && (p_D_Byte == '0))
			begin
				MEM[p_D_Word] <= data_mem_write_sync;
				data_mem_read <= data_mem_write_sync;	
			end
			else
				data_mem_read <= MEM[p_D_Word];
				
			inst_mem_read <= MEM[p_I_Word];
		end
	end
	
	always_ff @(posedge mem_clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			inst_res <= 1'b0;
			data_res <= 1'b0;
		end
		else 
		begin
			inst_res <= inst_read_ena;
			data_res <= data_read_ena || data_write_ena;
		end
	end
	
//================================================================================	
//	Simulate
`ifdef 	SIMULATE
//	parameter INST = "D:/RISC-V/testbench/pipeline_test1.txt";
//	parameter INST = "D:/RISC-V/testbench/pipeline_test2.txt";
//	parameter INST = "D:/RISC-V/testbench/pipeline_test3.txt";
//	parameter INST = "D:/RISC-V/testbench/pipeline_test4.txt";
//	parameter INST = "D:/RISC-V/testbench/pipeline_test5.txt";
//	parameter INST = "D:/RISC-V/testbench/pipeline_test6.txt";
//	parameter INST = "D:/RISC-V/testbench/pipeline_test7.txt";
//	parameter INST = "D:/RISC-V/testbench/forwarding_test.txt";
//	parameter INST = "D:/RISC-V/testbench/factorial_test.txt";		// maximum factorial = 12!
//	parameter INST = "D:/RISC-V/testbench/factorial_opt.txt";
//	parameter INST = "D:/RISC-V/testbench/arrangment.txt";
//	parameter INST = "D:/RISC-V/testbench/arrangement_fix.txt";
//	parameter INST = "D:/RISC-V/testbench/inner_loop.txt";
//	parameter INST = "D:/RISC-V/testbench/larger_inner_loop.txt";
//	parameter INST = "D:/RISC-V/testbench/inner_loop1.txt";
//	parameter INST = "D:/RISC-V/testbench/larger_inner_loop1.txt";
	parameter INST = "D:/RISC-V/testbench/arrangement_cache_test1.txt";
	parameter DATA = "D:/RISC-V/testbench/data_memory_file.txt";
	initial begin
		$readmemh(INST, MEM, 32'h0000_0400, 32'h0000_07ff);
		$readmemh(DATA, MEM, 32'h0000_0000, 32'h0000_03ff);
	end
`endif
		
endmodule	
