//////////////////////////////////////////////////////////////////////////////////
// File Name: 		RVS192.sv
// Module Name:		Top Module for RVS192 cpu
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
// Copyright (C) 	Le Quang Hung 
// Email: 			quanghungbk1999@gmail.com  
//////////////////////////////////////////////////////////////////////////////////

`include"RVS192_user_define.h"
import 	RVS192_package::*;
import	RVS192_user_parameters::*;
module DataGen
(
  input  	mem_type					data_type,
  input 	[DATA_LENGTH-1:0]			data_in,
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
