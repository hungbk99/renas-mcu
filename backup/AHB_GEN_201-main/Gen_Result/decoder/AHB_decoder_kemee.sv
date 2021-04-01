////////////////////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_decoder_kemee.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       14/11/2020 Quang Hung  First Creation, this version does not support
//                                   hsplit & hretry
// v1.0       02/12/2020 Quang Hung  Simple Scheme Decoder for AHB 
//                                   This version still not support hsplit, hretry and hremap    
////////////////////////////////////////////////////////////////////////////////////////////////

//================================================================================
//#CONFIG_GEN#
//================================================================================

import AHB_package::*;

module AHB_decoder_kemee 
#(
//#PARAGEN#
	parameter AHB_ADDR_WIDTH = 32,
	parameter MASTER_X_SLAVE_NUM = 7
)
(
  input [AHB_ADDR_WIDTH-1:0]            haddr,   
  input htrans_type                     htrans,
//  input                               hremap,
//  input [MASTER_X_SLAVE_NUM-1:0]      hsplit,
  output logic                          default_slv_sel,
  output logic [MASTER_X_SLAVE_NUM-1:0] hreq,
  input                                 hreset_n,   
  input                                 hclk
);

//================================================================================
//Internal Signals 
  logic [MASTER_X_SLAVE_NUM-1:0]  slave_detect,
                                  hreq_buf;
  logic                           dec_error;
  
  logic [MASTER_X_SLAVE_NUM-1:0][AHB_ADDR_WIDTH-1:0] low_addr,
                                                     high_addr;

  logic [AHB_ADDR_WIDTH-1:0]      haddr_buf;  
  htrans_type                     htrans_buf;
//================================================================================
//ADDRESS MAP
//#ADDRMAPGEN#
//db	slave_7
	assign low_addr[0] = 32'h0000_5000;
	assign high_addr[0] = 32'h0000_5FFF;
//db	slave_6
	assign low_addr[1] = 32'h0000_4000;
	assign high_addr[1] = 32'h0000_4FFF;
//db	slave_5
	assign low_addr[2] = 32'h0000_2404;
	assign high_addr[2] = 32'h0000_24FF;
//db	slave_4
	assign low_addr[3] = 32'h0000_2000;
	assign high_addr[3] = 32'h0000_2403;
//db	slave_3
	assign low_addr[4] = 32'h0000_1000;
	assign high_addr[4] = 32'h0000_100F;
//db	slave_2
	assign low_addr[5] = 32'h0000_0400;
	assign high_addr[5] = 32'h0000_0CF0;
//db	slave_1
	assign low_addr[6] = 32'h0000_0000;
	assign high_addr[6] = 32'h0000_03FF;
//================================================================================
  assign haddr_buf = haddr; 
  assign htrans_buf = htrans; 
            
  genvar i;
  generate
    for(i = 0; i < MASTER_X_SLAVE_NUM; i++)
    begin: req_gen
      always_comb begin
        slave_detect[i] = 1'b0;
        //Hung db 2_1_2020 if((haddr_buf[AHB_ADDR_WIDTH-1:10] > low_addr[i])&&(haddr_buf[AHB_ADDR_WIDTH-1:10] < high_addr[i]))
        if((haddr_buf > low_addr[i])&&(haddr_buf < high_addr[i]))
          slave_detect[i] = 1'b1;  
      end
    end
  endgenerate
  
  assign  dec_error = (htrans_buf != IDLE) ? ~|slave_detect : 1'b0;  //Access undefine region

  assign  hreq_buf = (htrans_buf != IDLE) ?  slave_detect : '0;

  assign default_slv_sel = dec_error;
  assign hreq = hreq_buf;

endmodule: AHB_decoder_kemee

