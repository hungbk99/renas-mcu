//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_mux#NUM#.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       3/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////


import AHB_package::*;
module AHB_mux#NUM#
//================================================================================
//#CONFIG_GEN#
//================================================================================
#(
    parameter CHANNEL_NUM = #CHNUM#,
    `ifdef SLV#NUM#
    parameter PAYLOAD = 78 
    `elsif MAS#NUM#
    parameter PAYLOAD = 34 
    `endif
)
(
    input  [CHANNEL_NUM-1:0][PAYLOAD-1:0] payload_in,
    input  [CHANNEL_NUM-1:0]              sel,                
    output logic [PAYLOAD-1:0]            payload_out   
);

    
//================================================================================
//================================================================================
    always_comb begin
        payload_out = '0;
        for(int i = 0; i < CHANNEL_NUM; i++)
        begin
            if(sel == (1 << i))
                payload_out = payload_in[i];
        end
    end

endmodule: AHB_mux#NUM#
