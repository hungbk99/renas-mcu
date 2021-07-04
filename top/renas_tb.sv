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
// v0.1   30.06.2021  hungbk99  Modify to support CPI test
//////////////////////////////////////////////////////////////////////////////////

module renas_testbench();
	
	logic 	rst_n;
	logic	  clk;
  logic   clk_l1;
  logic   clk_l2;
  logic   clk_mem;
  logic   clk_peri;
  // SPI interface
  logic   mosi_somi,
          ss_0,
          ss_1,
          ss_2,
          ss_3;
  logic   miso_simo;
  wire    sclk;    

  logic   gen_data, gen_data_1, gen_data_2;

  wire    hit;
  wire    DCC_halt;
  wire    ICC_halt;
  wire    peri_halt;
  wire    FW_halt;
  wire    external_halt;
  wire    pc_halt;
  wire    dec_ex_flush;
  wire    ex_mem_flush;
  logic   wrong, wrong_dl;
  wire    inst;
  real    hit_num;
  real    inst_num;
 
  assign  ICC_halt = renas_testbench.dut.renas_cpu_202.ICC_halt;
  assign  DCC_halt = renas_testbench.dut.renas_cpu_202.DCC_halt;
  assign  peri_halt = renas_testbench.dut.renas_cpu_202.peri_halt;
  assign  FW_halt = renas_testbench.dut.renas_cpu_202.FW_halt;
  assign  external_halt = renas_testbench.dut.renas_cpu_202.external_halt;
  assign  pc_halt = renas_testbench.dut.renas_cpu_202.pc_halt;
  assign  dec_ex_flush = renas_testbench.dut.renas_cpu_202.dec_ex_flush;
  assign  ex_mem_flush = renas_testbench.dut.renas_cpu_202.ex_mem_flush;
  assign  wrong = renas_testbench.dut.renas_cpu_202.br_update_ex.wrong;
  assign  wrong_dl = renas_testbench.dut.renas_cpu_202.wrong_dl;

  always @(posedge clk_l1) begin
    if(!rst_n) begin
      hit_num <= 0;
      inst_num <= 0;
    end else begin
      if(~(ICC_halt || DCC_halt)) begin
        inst_num <= inst_num + 1;
        if(~(wrong || wrong_dl))
          hit_num <= hit_num + 1;
      end
    end
  end

  initial begin
    $monitor("hit = %d inst = %d cpi = %2.2f", hit_num, inst_num, real'(hit_num/inst_num));
    //$monitor("ICC_halt = %d DCC_halt = %d dec_ex_flush = %d ex_mem_flush = %d", ICC_halt, DCC_halt, dec_ex_flush, ex_mem_flush); 
  end

  initial begin
    gen_data_1 = 0;
    forever @(negedge sclk) gen_data_1 = $urandom_range(0,1);
  end
  
  initial begin
    gen_data_2 = 0;
    forever @(posedge sclk) gen_data_2 = $urandom_range(0,1);
  end
  
  assign gen_data = (renas_testbench.dut.spi.cpha) ? gen_data_2 : gen_data_1;

  renas_mcu_top dut
  (
    .miso_simo(gen_data),
    .*
  );

	initial begin
		clk = 1;	
		clk_l1 = 1'b1;
		clk_l2 = 1'b1;
		clk_mem = 1'b1;
    clk_peri = 1'b1;
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
		forever #25	clk_peri = !clk_peri;	
	end
	
	initial begin
		#1
		forever #30	clk_mem = !clk_mem;			
	end	

endmodule	
