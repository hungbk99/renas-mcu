//////////////////////////////////////////////////////////////////////////////////
// File Name: 		Register_File.sv
// Module Name:		Register File for RVS192 cpu	
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
// Copyright (C) 	Le Quang Hung 
// Email: 			quanghungbk1999@gmail.com  
//////////////////////////////////////////////////////////////////////////////////


//`include"RVS192_user_define.h"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module	Register_File
(
	output	logic	[DATA_LENGTH-1:0]	rs1_out,
										rs2_out,
	input 	[DATA_LENGTH-1:0]			data_wb,
	input 	[4:0]						rs1,
										rs2,
										rd,
	input		 						reg_wen,
										clk
);

	logic 	[DATA_LENGTH-1:0] register [0:REGISTER_FILE_DEPTH-1];

//-------------------------------Construction----------------------------------
	always_ff @(posedge clk) begin
		if((reg_wen == 1'b1)&&(rd != 0))
			register[rd] <= data_wb;
		else 
			register[0] <= 32'b0;
	end	
			
	always_ff @(negedge clk) begin
		rs1_out <= register[rs1];
		rs2_out <= register[rs2];
	end

`ifdef SIMULATE
	parameter	DATA = "D:/RISC-V/testbench/register_test.txt";
	
	initial begin	
		$readmemh(DATA, register);
	end
`endif

endmodule
  	

