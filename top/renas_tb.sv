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

module renas_testbench();
	
	logic 	rst_n;
	logic	  clk;
  logic   clk_l1;
  logic   clk_l2;
  logic   clk_mem;

  renas_mcu_top dut
  (
    .*
  );

	initial begin
		clk = 1;	
		clk_l1 = 1'b1;
		clk_l2 = 1'b1;
		clk_mem = 1'b1;
		rst_n = 0;
		#42
		rst_n = 1;
	end

//	Clock Gen		
	always #10 clk = !clk; 
	initial begin	
		#1
		forever #10 clk_l1 = !clk_l1;
	end

	initial begin
		#1
		forever #20	clk_l2 = !clk_l2;	
	end
	
	initial begin
		#1
		forever #30	clk_mem = !clk_mem;			
	end	

endmodule	
