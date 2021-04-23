//////////////////////////////////////////////////////////////////////////////////
// File Name: 		renas.sv
// Module Name:		Top Module for renas cpu
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
import 	renas_package::*;
import	renas_user_parameters::*;
module datagen
(
  input  	mem_type					        data_type,
  input 	[DATA_LENGTH-1:0]			    data_in,
  output 	logic 	[DATA_LENGTH-1:0]	data_out
 );

	always_comb begin
		data_out = '0;
		unique case(data_type)
        B:  data_out = {{24{data_in[7]}}, data_in[7:0]}; 
        H:  data_out = {{16{data_in[15]}}, data_in[15:0]};
        W:  data_out = data_in;
        BU: data_out = {24'b0, data_in[7:0]};
        HU: data_out = {16'b0, data_in[15:0]};
		endcase
	end
    
endmodule
