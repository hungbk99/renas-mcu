//////////////////////////////////////////////////////////////////////////////////
// File Name: 		register_file.sv
// Module Name:		Register File for renas cpu	
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.0   14.03.2021  hungbk99  Reused from renas cpu
//                              Remove L2 Cache 
//                              Remove support for inclusive cache
//        15.03.2021  hungbk99  Add support for AHB interface                      
//////////////////////////////////////////////////////////////////////////////////


//`include"renas_user_define.h"
//import 	renas_package::*;
//import	renas_user_parameters::*;
module	register_file
(
	output	logic	[DATA_LENGTH-1:0]	rs1_out,
										              rs2_out,
	input 	[DATA_LENGTH-1:0]			  data_wb,
	input 	[4:0]						        rs1,
										              rs2,
										              rd,
	input		 						            reg_wen,
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
  	

