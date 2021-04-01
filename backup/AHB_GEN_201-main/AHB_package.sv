//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_package.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       14/11/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

package AHB_package;
  typedef enum packed logic [1:0]
  {
    IDLE = 2'b00,
    BUSY = 2'b01,
    NONSEQ = 2'b10,
    SEQ = 2'b11
  } htrans_type;


//  interface arbiter_itf (input clk)
//    logic   [SLAVE_X_MASTER_NUM-1:0]                      hreq,
//                                                          hlast;
//    logic                                                 hwait;
//    logic   [SLAVE_X_MASTER_NUM-1:0]                      hgrant;
//    logic                                                 hsel;
//  `ifdef  DYNAMIC_PRIORITY_ARBITER
//    logic [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_BIT-1:0] hprior;   
//  `endif
//    logic                                                 hclk,
//                                                          hreset_n;
////    modport rtl (
////      input hreq,
////      input hlast,
////      input hwait,
////      output hgrant,
////      output hsel,
////  `ifdef  DYNAMIC_PRIORITY_ARBITER
////      hprior;   
////  `endif
////      input hclk,
////            hreset_n
//    );
//
//  endinterface: arbiter_itf 
//
//  interface decode_itf (input clk)
//    logic [AHB_ADDR_WIDTH-1:0]      haddr;   
//    logic [MASTER_X_SLAVE_NUM-1:0]  hgrant;
//    logic                           hpreset_n;
//    logic                           hremap;
//    logic                           hsplit;
//    logic                           hdef_slv_sel;
//    logic [MASTER_X_SLAVE_NUM-1:0]  hreq;
//    logic                           herror;
//    logic                           hlast;
//    
//    modport rtl (
//      input   haddr,
//      input   hgrant,
//      input   hpreset_n,
//      input   hremap,
//      input   hsplit,
//      input   hdef_slv_sel,
//      output  hreq,
//      output  herror,
//      output  hlast
//    );
//  endinterface: decode_itf

endpackage: AHB_package
