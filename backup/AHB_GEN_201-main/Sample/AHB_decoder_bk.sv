////////////////////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_decoder#NUM#.sv
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

module AHB_decoder#NUM# 
#(
//#PARAGEN#
)
(
  input [AHB_ADDR_WIDTH-1:0]      haddr,   
  input htrans_type               htrans,
//  input                           hremap,
//  input [MASTER_X_SLAVE_NUM-1:0]  hsplit,
  output                          default_slv_sel,
  output [MASTER_X_SLAVE_NUM-1:0] hreq,
  input                           hreset_n,   
  input                           hclk
);

//================================================================================
//Internal Signals 
  logic [MASTER_X_SLAVE_NUM-1:0]  slave_detect,
                                  hreq_buf;
  logic                           dec_error;
  
  logic [MASTER_X_SLAVE_NUM-1:0][AHB_ADDR_WIDTH-1:0] low_addr,
                                                     high_addr;

//================================================================================
//ADDRESS MAP
//#ADDRMAPGEN#
//================================================================================

//  `ifdef IN_FF       
//      always_ff @(posedge hclk, negedge hreset_n)
//      begin
//        if(!hreset_n)
//        begin
//          haddr_buf <= '0; 
//          htrans_buf <= '0; 
//          hremap_buf <= '0;
//          hsplit_buf <= '0,
//        end
//        else 
//        begin
//          haddr_buf <= haddr; 
//          hhtrans_buf <= htrans; 
//          hhremap_buf <= remap;
//          hhsplit_buf <= split,
//        end
//      end
//  `else
      assign haddr_buf = haddr; 
      assign htrans_buf = htrans; 
      //assign hremap_buf = hremap;
      //assign hsplit_buf = hsplit;
//  `endif  
            
  genvar i;
  generate
    for(i = 0; i < MASTER_X_SLAVE_NUM; i++)
    begin: req_gen
      always_comb begin
        slave_detect[i] = 1'b0;
        if((haddr_buf[AHB_ADDR_WIDTH-1:10] > low_addr[i])&&(haddr_buf[AHB_ADDR_WIDTH-1:10] < high_addr[i]))
          slave_detect[i] = 1'b1;  
      end
    end
  endgenerate
  
  assign  dec_error = (htrans_buf != IDLE) ? ~|slave_detect : 1'b0;  //Access undefine region

  assign  hreq_buf = (htrans_buf != IDLE) ?  slave_detect : '0;

//  `ifdef OUT_FF
//    always_ff @(posedge hclk, negedge hreset_n)
//    begin
//      default_slv_sel <= 1'b0;
//      hreq <= '0;
//    end
//    else 
//    begin
//      default_slv_sel <= dec_error;
//      hreq <= hreq_buf;  
//    end
//  `else
    assign default_slv_sel = dec_error;
    assign hreq = hreq_buf;
//  `endif    

endmodule: AHB_decoder#NUM#


//module AHB_decoder#NUM# 

//#(
////#db PARAGEN#
//)
//(
//  input [AHB_ADDR_WIDTH-1:0]      haddr,   
//  input [MASTER_X_SLAVE_NUM-1:0]  hgrant,
//  input htrans_type               htrans,
//  input hsize_type                hsize,
//  input [MASTER_X_SLAVE_NUM-1:0]  hlast_slv, // Reverse signals: Not use => assign to 0         
//  input                           hremap,
//  input [MASTER_X_SLAVE_NUM-1:0]  hsplit,
//  output                          default_slv_sel,
//  output [MASTER_X_SLAVE_NUM-1:0] hreq,
////  output                          herror,
////  let default slave take care of error signals
//  input                           hreset_n,   
//  input                           hclk
//);
//
//
//
////================================================================================
////Internal Signals 
//  logic [MASTER_X_SLAVE_NUM-1:0]  slave_detect,
//                                  hdec,
//                                  hreq_buf;
//  logic                           dec_error,
//                                  dec_last,
//                                  dec_break,
//                                  hlast_detect,
//                                  hslv_wait_detect, 
//                                  default_slv_sel_buf;
//
//  `ifdef DECODE_STATE_FSM  
//    enum logic [1:0]
//    {
//      DFSM_IDLE,
//      DFSM_DECODE,
//      DFSM_SLVSEL,
//      DFSM_ERROR
//    } dfsm_current_state, dfsm_next_state;
//  `elsif NON_DECODE_STATE_FSM
//    enum logic [1:0]
//    {
//     NDFSM_IDLE,
//     NDFSM_SLVSEL,
//     NDFSM_ERROR
//    } ndfsm_current_state, ndfsm_next_state;
//  `endif
//  
//  logic [MASTER_X_SLAVE_NUM-1:0][AHB_ADDR_WIDTH-1:0] low_addr,
//                                                     high_addr;
////================================================================================
////ADDRESS MAP
////#db ADDRMAPGEN#
////================================================================================
////  genvar i;
////  generate
////    for(i = 0; i < MASTER_X_SLAVE_NUM; i++)
////    begin: req_gen
////      always_comb begin
////        slave_detect[i] = 1'b0;
////        if((haddr[AHB_ADDR_WIDTH-1:10] > `AHB_SLAVE_$ADDRGEN$_LOW_ADDR)&&(haddr[AHB_ADDR_WIDTH-1:10] < `AHB_SLAVE_$ADDRGEN$_HIGH_ADDR))
////          slave_detect[i] = 1'b1;  
////      end
////    end
////  endgenerate
//
//  genvar i;
//  generate
//    for(i = 0; i < MASTER_X_SLAVE_NUM; i++)
//    begin: req_gen
//      always_comb begin
//        slave_detect[i] = 1'b0;
//        if((haddr[AHB_ADDR_WIDTH-1:10] > low_addr[i])&&(haddr[AHB_ADDR_WIDTH-1:10] < high_addr[i]))
//          slave_detect[i] = 1'b1;  
//      end
//    end
//  endgenerate
//
//  assign  dec_error = ~|slave_detect;  //Access undefine region
//  assign  hslv_wait_detect = |(~hgrant & hreq); 
//  `ifdef DECODE_STATE_FSM 
//  //  Use for fast systems where the decoder might not have enough time to decode the address and assert the sel signals
//  //  Seperate the dec and sel timing path
//  //  Moore
//
//    assign hlast_detect = |hlast_slv; //|(hreq & hlast_slv);
//
//    always_ff @(posedge hclk, negedge hreset_n)
//    begin
//      if(!hreset_n)
//        hdec <= '0;
//      else 
//        hdec <= slave_detect;
//    end
//
//    // 1KB boundary detect
//    always_comb begin
//      dec_last = 1'b0;
//      unique case(hsize)
//      BYTE:             dec_last = (haddr[9:0] == 10'h3FF);
//      HALFWORD:         dec_last = (haddr[9:0] == 10'h3FE);
//      WORD:             dec_last = (haddr[9:0] == 10'h3FC);
//      DOUBLEWORD:       dec_last = (haddr[9:0] == 10'h3F8);
//      FOURWORDLINE:     dec_last = (haddr[9:0] == 10'h3F0);
//      EIGHTWORDLINE:    dec_last = (haddr[9:0] == 10'h3E0);
//      SIXTEENWORDLINE:  dec_last = (haddr[9:0] == 10'h3C0); 
//      THIRTY2WORDLINE:  dec_last = (haddr[9:0] == 10'h380);
//      endcase
//    end
//
//    assign dec_break = ((htrans == NONSEQ) & !hslv_wait_detect) || ((htrans == SEQ) & (dec_last | hlast_detect)); 
//    
//    always_comb begin
//      hreq_buf = '0;
//      default_slv_sel_buf = 1'b0;
//      dfsm_next_state = dfsm_current_state;
//      unique case(dfsm_current_state)    
//        DFSM_IDLE: 
//        begin
//          if(htrans == NONSEQ)
//            dfsm_next_state = DFSM_DECODE;
//          else 
//            dfsm_next_state = dfsm_current_state;
//        end
//        DFSM_DECODE:
//        begin
//          if(!dec_error)
//            dfsm_next_state = DFSM_SLVSEL;
//          else 
//            dfsm_next_state = DFSM_ERROR;
//        end
//        DFSM_SLVSEL:
//        begin
//          hreq_buf = hdec;
//          if(dec_break)
//            dfsm_next_state = DFSM_DECODE;
//          else if((htrans == IDLE) && !hslv_wait_detect) 
//            dfsm_next_state = DFSM_IDLE;
//          else
//            dfsm_next_state = dfsm_current_state;
//        end
//        DFSM_ERROR:
//        begin
//          default_slv_sel_buf = 1'b1;
//          if((htrans == NONSEQ) || ((htrans == SEQ) && dec_last))
//            dfsm_next_state = DFSM_DECODE;
//          else if(htrans == IDLE)
//            dfsm_next_state = DFSM_IDLE;
//          else 
//            dfsm_next_state = dfsm_current_state;
//        end
//        // default: dfsm_next_state = dfsm_current_state;
//      endcase
//    end
//
//    always_ff @(posedge hclk, negedge hreset_n)
//    begin
//      if(!hreset_n)
//        dfsm_current_state <= DFSM_IDLE;
//      else
//        dfsm_current_state <= dfsm_next_state;
//    end
//
//  `elsif NON_DECODE_STATE_FSM
//  //  This decoder does not insert any decode cycle.  
//  //  It decodes the address, and asserts the sel signal in the one timing path 
//
//    assign hdec = slave_detect;
//    
//    always_comb begin
//      ndfsm_next_state = ndfsm_current_state;  
//      hreq_buf = '0;
//      default_slv_sel_buf = 1'b0;
//      unique case(ndfsm_current_state)
//      NDFSM_IDLE:
//      begin
//        if((htrans == NONSEQ) || (htrans == SEQ))
//        begin
//          if(!dec_error)
//          begin
//            ndfsm_next_state = NDFSM_SLVSEL;
//            hreq_buf = hdec;
//          end
//          else begin
//            ndfsm_next_state = NDFSM_ERROR;
//            default_slv_sel_buf = 1'b1;
//          end
//        end
//        else 
//           ndfsm_next_state = ndfsm_current_state;
//      end
//      NDFSM_SLVSEL:
//      begin
//        if((htrans == IDLE) && !hslv_wait_detect)
//          ndfsm_next_state = NDFSM_IDLE;
//        else if((htrans != IDLE) && !hslv_wait_detect && dec_error)
//        begin
//          ndfsm_next_state = NDFSM_ERROR;
//          default_slv_sel_buf = 1'b1;
//        end
//        else begin 
//           ndfsm_next_state = ndfsm_current_state;
//           hreq_buf = hdec;
//        end
//      end
//      NDFSM_ERROR:
//      begin
//        if(htrans == IDLE)
//          ndfsm_next_state = NDFSM_IDLE;
//        else begin
//          ndfsm_next_state = ndfsm_current_state;
//          default_slv_sel_buf = 1'b1;
//        end
//      end
//     // default: ndfsm_next_state = ndfsm_current_state;
//      endcase
//    end
//
//    always_ff @(posedge hclk, negedge hreset_n)
//    begin
//      if(!hreset_n)
//        ndfsm_current_state <= NDFSM_IDLE;
//      else 
//        ndfsm_current_state <= ndfsm_next_state;
//    end
//
//  `endif
//  
// // assign hreq = hreq_en ? slave_detect : '0
// // assign default_slv_sel = defaut_ena; 
//
//  `ifdef GLITCH_FREE
//  `define OUT_FF
//  `endif
//
//  `ifdef OUT_FF
//    always_ff @(posedge hclk, negedge hreset_n)
//    begin
//      if(!hreset_n)
//      begin
//        hreq <= '0;
//        default_slv_sel <= 1'b0;
//      end
//      else begin
//        hreq <= hreq_buf;
//        default_slv_sel <= default_slv_sel_buf;
//      end
//    end
//  `else
//    assign hreq = hreq_buf;
//    assign default_slv_sel = default_slv_sel_buf;
//  `endif
//
//endmodule: AHB_decoder#NUM#
