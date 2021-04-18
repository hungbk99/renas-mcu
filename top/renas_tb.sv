`timescale 10ps/1ps
//////////////////////////////////////////////////////////////////////////////////
// File Name: 		renas_tb.sv
// Function:		  Top env for renas mcu
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.0   18.04.2021  hungbk99  First Creation
//////////////////////////////////////////////////////////////////////////////////

module Testbench();
	
	logic 	rst_n;
	logic	  clk;
	logic 	cache_clk;
	logic 	mem_clk;

  renas_mcu_top dut
  (
    .* 
  );

	initial begin
		clk = 1;	
		cache_clk = 1'b1;
		mem_clk = 1'b1;
		rst_n = 0;
		#42
		rst_n = 1;
	end

//	Clock Gen		
	always #10 clk = !clk; 
	
  initial begin	
		#1
		forever #10 cache_clk = !cache_clk;
	end
	
	initial begin
		#1
		forever #30	mem_clk = !mem_clk;			
	end	

endmodule	
