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
//////////////////////////////////////////////////////////////////////////////////

//`include"renas_user_define.h"
//`include "D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/DualPort_SRAM.sv"	
import 	renas_package::*;
import  AHB_package::*;
import	renas_user_parameters::*;
module	renas_memory
(
  //DATA-ITF
  input                                   dmem_hsel,
  input   mas_send_type                   dmem_in_1,
  input   mas_send_type                   dmem_in_2,
  output  slv_send_type                   dmem_out_1,
  output  slv_send_type                   dmem_out_2,
  //INST-ITF
  input                                   imem_hsel,
  input   mas_send_type                   imem_in_1,
  input   mas_send_type                   imem_in_2,
  output  slv_send_type                   imem_out_1,
  output  slv_send_type                   imem_out_2,
  //Write buffer
  input   [2*DATA_LENGTH-BYTE_OFFSET-1:0] wb_data,	
	input	        								          wb_req,
	output logic 												    wb_ack,	
	output logic 												    full_flag,
  input                                   cache_clk,
                                          mem_clk,
                                          rst_n
);
  //--------------------------------------------------------------------	
  logic [DATA_LENGTH-1:0]	MEM1	[MEM_LINE/2-1:0];
  logic [DATA_LENGTH-1:0]	MEM2	[MEM_LINE/2-1:0];
  logic [2*DATA_LENGTH-BYTE_OFFSET-1:0] wb_reg;
  logic                                 wb_ready,
                                        wb_req_mask,
                                        wb_coherent,
                                        data_coherent;
                            
  logic [DATA_LENGTH-1:0]               wb_mem_write;
  logic [DATA_LENGTH-BYTE_OFFSET-1:0]   wb_ptr;
	
  logic [DATA_LENGTH-1-2:0]	            p_D_Word1,
										                    p_I_Word1;
										
	logic [1:0]							              p_D_Byte1,
											                  p_I_Byte1;
	
 logic [DATA_LENGTH-1-2:0]	            p_D_Word2,
										                    p_I_Word2;
										
	logic [1:0]							              p_D_Byte2,
											                  p_I_Byte2;

  logic                                 inst_req,
                                        data_req,
                                        inst_ack,
                                        data_ack,
                                        data_write_en1,
                                        data_write_en2,
                                        wb_done;
                                      
  logic [DATA_LENGTH-1:0]               inst_addr_sync1,
                                        inst_addr_sync2,
                                        data_addr_sync1,
                                        data_addr_sync2,
				                                data_mem_read1,
				                                data_mem_read2,
			                                  inst_mem_read1,
			                                  inst_mem_read2,
                                        data_mem_write_sync1,
                                        data_mem_write_sync2,
                                        wb_dirty_data;

  //--------------------------------------------------------------------
  assign wb_req_mask = wb_req & wb_ready;
  assign full_flag = ~wb_ready;
  
  always_ff @(posedge cache_clk, negedge rst_n)
  begin
    if(!rst_n)
    begin
      wb_reg <= '0;
      wb_ready <= 1'b1;
      wb_ack <= 1'b0;
    end
    else if(wb_req_mask) 
    begin
      wb_reg <= wb_data;
      wb_ready <= 1'b0;
      wb_ack <= 1'b1;
    end 
    else if(wb_done)
      wb_ready <= 1'b1;
    else 
      wb_ack <= 1'b0;
  end

	assign 	p_I_Word1 = inst_addr_sync1[31:2];
	assign 	p_I_Byte1 = inst_addr_sync1[1:0];	

	assign 	p_D_Word1 = (wb_done) ? wb_ptr : data_addr_sync1[31:2];  //DEBUG
	assign 	p_D_Byte1 = data_addr_sync1[1:0];	

	assign 	p_I_Word2 = inst_addr_sync2[31:2];
	assign 	p_I_Byte2 = inst_addr_sync2[1:0];	

	assign 	p_D_Word2 = data_addr_sync2[31:2];
	assign 	p_D_Byte2 = data_addr_sync2[1:0];	
  
  //assign wb_done = ~wb_ready;
  assign wb_ptr = wb_reg[DATA_LENGTH-BYTE_OFFSET-1:0];
  assign wb_mem_write = wb_reg[2*DATA_LENGTH-BYTE_OFFSET-1:DATA_LENGTH+BYTE_OFFSET];

  always_ff @(posedge cache_clk, negedge rst_n)
  begin
    if(!rst_n) begin
      inst_req <= 1'b0;
      data_req <= 1'b0;
    end
    else begin
      if(imem_hsel && !inst_ack)
        inst_req <= 1'b1;
      else if(inst_ack)
        inst_req <= 1'b0;

      if(dmem_hsel && !data_ack)
        data_req <= 1'b1;
      else if(data_ack)
        data_req <= 1'b0;
    end
  end

  always_ff @(posedge cache_clk, negedge rst_n)
  begin
    if(!rst_n)
    begin
      imem_out_1 <= '0;
      imem_out_2 <= '0;
      dmem_out_1 <= '0;
      dmem_out_2 <= '0;
    end
    else begin
      if(inst_ack && inst_req) begin
        imem_out_1.hreadyout <= 1'b1;
        imem_out_1.hrdata <= inst_mem_read1;
        imem_out_2.hreadyout <= 1'b1;
        imem_out_2.hrdata <= inst_mem_read2;
      end
      else begin
        imem_out_1 <= 1'b0;
        imem_out_2 <= 1'b0;
      end

      if(data_ack && data_req) begin
        dmem_out_1.hreadyout <= 1'b1;
        dmem_out_1.hrdata <= data_mem_read1;
        dmem_out_2.hreadyout <= 1'b1;
        dmem_out_2.hrdata <= data_mem_read2;
      end
      else begin
        dmem_out_1 <= 1'b0;
        dmem_out_2 <= 1'b0;
      end
    end
  end

  always_ff @(posedge mem_clk, negedge rst_n)
  begin
    if(!rst_n)
    begin
      inst_ack <= 1'b0;
      data_ack <= 1'b0;
      data_write_en1 <= 1'b0;
      data_write_en2 <= 1'b0;
      wb_done <= 1'b0;
    end
    else begin
      if(inst_req)
        inst_ack <= 1'b1;
      else
        inst_ack <= 1'b0;

      if(data_req)
        data_ack <= 1'b1;
      else
        data_ack <= 1'b0;
     
      if(!wb_ready && !data_req)
        wb_done <= 1'b1;

      if(data_req && dmem_in_1.hwrite) begin
        data_write_en1 <= 1'b1;
        data_write_en2 <= 1'b1;
      end
    end
  end

  always_ff @(posedge mem_clk, negedge rst_n)
  begin
    if(!rst_n)
    begin
      inst_addr_sync1 <= '0;
      inst_addr_sync2 <= '0;

      data_addr_sync1 <= '0;
      data_addr_sync2 <= '0;

      data_mem_write_sync1 <= '0;
      data_mem_write_sync2 <= '0;
    end
    else 
    begin
      inst_addr_sync1 <= imem_in_1.haddr - 32'h400;
      inst_addr_sync2 <= imem_in_2.haddr - 32'h400;

      data_addr_sync1 <= dmem_in_1.haddr - 32'h400;
      data_addr_sync2 <= dmem_in_2.haddr - 32'h400;
        
      data_mem_write_sync1 <= dmem_in_1.hwdata;
      data_mem_write_sync2 <= dmem_in_2.hwdata;
    end
  end

  assign wb_dirty_data = wb_done ? wb_mem_write : data_mem_write_sync1;

	//always_ff @(posedge mem_clk or negedge rst_n)
	//begin
	//	if(!rst_n)
	//	begin
	//		data_mem_read1 <= '0;
	//		inst_mem_read1 <= '0;
	//		data_mem_read2 <= '0;
	//		inst_mem_read2 <= '0;
	//	end
	//	else begin
	//		if((data_write_en1 || wb_done) && (p_D_Byte1 == '0))  //DEBUG
	//		begin
	//			MEM[p_D_Word1] <= wb_dirty_data;   
	//			data_mem_read1 <= wb_dirty_data; 
	//		end
	//		else
	//			data_mem_read1 <= MEM[p_D_Word1];
	//		
	//		if((data_write_en2) && (p_D_Byte2 == '0))
	//		begin
	//			MEM[p_D_Word2] <= data_mem_write_sync2;
	//			data_mem_read2 <= data_mem_write_sync2;	
	//		end
	//		else
	//			data_mem_read2 <= MEM[p_D_Word2];
	//		
  //    //if(!wb_ready)
  //    //  MEM[wb_ptr] <= wb_mem_write;

	//		inst_mem_read1 <= MEM[p_I_Word1];
	//		inst_mem_read2 <= MEM[p_I_Word2];
	//	end
	//end
	
  always_ff @(posedge mem_clk)
	begin
			if((data_write_en1 || wb_done) && (p_D_Byte1 == '0))  //DEBUG
			begin
				MEM1[p_D_Word1] <= wb_dirty_data;   
				data_mem_read1 <= wb_dirty_data; 
			end
			else
				data_mem_read1 <= MEM1[p_D_Word1];
			
			inst_mem_read1 <= MEM1[p_I_Word1];
	end
	
  always_ff @(posedge mem_clk)
	begin
			if((data_write_en2) && (p_D_Byte2 == '0))
			begin
				MEM2[p_D_Word2] <= data_mem_write_sync2;
				data_mem_read2 <= data_mem_write_sync2;	
			end
			else
				data_mem_read2 <= MEM2[p_D_Word2];
			
      inst_mem_read2 <= MEM2[p_I_Word2];
	end
		//DualPort_SRAM
		//#(
		//.SRAM_LENGTH(DATA_LENGTH), 
		//.SRAM_DEPTH(MEM_LINE/2)
		//)
		//SLOT1DATA
		//(
		//.data_out1(data_mem_read1), 
		//.data_out2(inst_mem_read1),	
		//.data_in1(wb_dirty_data),
		//.data_in2('0),	
		//.addr1(p_D_Word1),
		//.addr2(p_I_Word1),
		//.wen1((data_write_en1 || wb_done) && (p_D_Byte1 == '0)), 
		//.wen2(1'b0),
		//.clk(mem_clk)
		//);

		//DualPort_SRAM
		//#(
		//.SRAM_LENGTH(DATA_LENGTH), 
		//.SRAM_DEPTH(MEM_LINE/2)
		//)
		//SLOT2DATA
		//(
		//.data_out1(data_mem_read2), 
		//.data_out2(inst_mem_read2),	
		//.data_in1(wb_dirty_data),
		//.data_in2('0),	
		//.addr1(p_D_Word2),
		//.addr2(p_I_Word2),
		//.wen1((data_write_en2) && (p_D_Byte2 == '0)), 
		//.wen2(1'b0),
		//.clk(mem_clk)
		//);
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
	//initial begin
	//	$readmemh(INST, MEM, 32'h0000_0400 - 32'h400, 32'h0000_07ff - 32'h400);
	//	$readmemh("D:/Project/renas-mcu/RISC-V/renas_cpu/src/rtl/data_memory_file.txt", MEM, 32'h0000_0800 -32'h400, 32'h0001_03ff - 32'h400);
	//end
`endif

endmodule: renas_memory
