//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_arbiter_package.sv
// Project Name:	AHB_Gen
// Module Name:   Prior_Gen
//////////////////////////////////////////////////////////////////////////////////


import AHB_package::*;
//package AHB_arbiter_package;
  //////////////////////////////////////////////////////////////////////////////////
  // File Name: 		AHB_arbiter_package.sv
  // Project Name:	AHB_Gen
  // Module Name:   Prior_Gen
  //////////////////////////////////////////////////////////////////////////////////
  
  module Prior_Gen
  #(
    parameter PRIOR_BIT = 2,
    parameter PRIOR_LEVEL = 4
  )
  (
    input logic                   hreq,
    input logic [PRIOR_BIT-1:0]   hprior,
    input logic                   hsel,
                                  grant,
    output logic [PRIOR_LEVEL-1:0]  gen_req
  );
  
    logic [PRIOR_LEVEL-1:0]  raw_req;
    
    always_comb begin
      raw_req = '0;
      for(int i = 0; i < PRIOR_LEVEL; i++)
      begin
        if(hprior == i)
          raw_req[i] <= hreq;
      end
    end
    
    assign gen_req = (!hsel || (hsel && grant)) ? raw_req : '0;
  
  endmodule: Prior_Gen
  
  //////////////////////////////////////////////////////////////////////////////////
  // File Name: 		AHB_arbiter_package.sv
  // Project Name:	AHB_Gen
  // Module Name:   Dynamic_Prior_Mask
  //////////////////////////////////////////////////////////////////////////////////
  
  module Dynamic_Prior_Mask
  #(
    parameter PRIOR_LEVEL = 4,
    parameter REQ_NUM = 8
  )
  (
    input logic [REQ_NUM-1:0][PRIOR_LEVEL-1:0]   gen_req,
    output logic [REQ_NUM-1:0][PRIOR_LEVEL-1:0]  mask_req
  );
  
    logic [PRIOR_LEVEL-1:0]               prior_mask,
                                        prior_detect;
    logic [PRIOR_LEVEL-1:0][REQ_NUM-1:0]  prior_classify;
  
    genvar a, b;
    generate
      for(a = 0; a < PRIOR_LEVEL; a++)
      begin: prior_class_gen_a
        for(b = 0; b < REQ_NUM; b++)
        begin: prior_class_gen_b
          assign prior_classify[a][b] = gen_req[b][a];
          assign mask_req[b][a] = gen_req[b][a] & prior_mask[a];
        end
        assign prior_detect[a] = |prior_classify[a]; 
      end
    endgenerate
  
  //  always_comb begin
  //    prior_mask[PRIOR_LEVEL-1] = prior_detect[PRIOR_LEVEL-1];
  //    for(int i = 0; i < PRIOR_LEVEL-1; i++)
  //    begin
  //      prior_mask[i] = ~|prior_detect[PRIOR_LEVEL-1:i+1] & prior_detect[i];  
  //    end
  //  end 
  
    genvar c;
    generate
      for(c = 0; c < PRIOR_LEVEL-1; c++)
      begin: dynamic_prior_mask_gen
        assign prior_mask[c] = ~|prior_detect[PRIOR_LEVEL-1:c+1] & prior_detect[c];
      end
      assign prior_mask[PRIOR_LEVEL-1] = prior_detect[PRIOR_LEVEL-1];
    endgenerate
  
  endmodule: Dynamic_Prior_Mask
    
  //////////////////////////////////////////////////////////////////////////////////
  // File Name: 		AHB_arbiter_package.sv
  // Project Name:	AHB_Gen
  // Module Name:   Req_Collect
  //////////////////////////////////////////////////////////////////////////////////
  
  module Req_Collect
  #(
    parameter PRIOR_LEVEL = 4,
    parameter REQ_NUM = 8
  )
  (
    input logic [REQ_NUM-1:0][PRIOR_LEVEL-1:0]  mask_req,
    output logic [REQ_NUM-1:0]                collect_req    
  );
  
    genvar a;
    generate
      for(a = 0; a < REQ_NUM; a++)
      begin: collect_req_gen
          assign  collect_req[a] = |mask_req[a];
      end
    endgenerate
    
  endmodule: Req_Collect
  
  //////////////////////////////////////////////////////////////////////////////////
  // File Name: 		AHB_arbiter_package.sv
  // Project Name:	AHB_Gen
  // Module Name:   Fixed_Prior_Mask
  //////////////////////////////////////////////////////////////////////////////////
  
  module Fixed_Prior_Mask
  #(
    parameter REQ_NUM = 8
  )
  (
    input logic [REQ_NUM-1:0]   hlast,
                                collect_req,
    input logic                 hsel,  
    output logic [REQ_NUM-1:0]  raw_grant
  );
  
  //  always_comb begin
  //    raw_grant[REQ_NUM-1] = collect_req[REQ_NUM-1] & ~(hlast[REQ_NUM-1] & hsel);
  //    for(int i = 0; i < PRIOR_LEVEL-1; i++)
  //    begin
  //      raw_grant[i] = ~|collect_req[PRIOR_LEVEL-1:i+1] & collect_req[i] & ~(hlast[i] & hsel); 
  //    end
  //  end 
  
    genvar i;
    generate 
      for(i = 0; i < REQ_NUM-1; i++)
      begin: fixed_prior_mask_gen
        assign raw_grant[i] = ~|collect_req[REQ_NUM-1:i+1] & collect_req[i] & ~(hlast[i] & hsel); 
      end
      assign raw_grant[REQ_NUM-1] = collect_req[REQ_NUM-1] & ~(hlast[REQ_NUM-1] & hsel);
    endgenerate
  
  endmodule: Fixed_Prior_Mask
  
  //////////////////////////////////////////////////////////////////////////////////
  // File Name: 		AHB_arbiter_package.sv
  // Project Name:	AHB_Gen
  // Module Name:   BR_Req_Detect
  //////////////////////////////////////////////////////////////////////////////////
  
  module BR_Req_Detect
  #(
    parameter REQ_NUM = 8
  )
  (
    input logic [REQ_NUM-1:0]   hlast,
                                collect_req,
    input logic                 hsel,  
    output logic [REQ_NUM-1:0]  raw_grant
  );
  
    always_comb begin
      for(int i = 0; i < REQ_NUM; i++)
      begin
        raw_grant[i] = collect_req[i] & ~(hlast[i] & hsel); 
      end
    end 
  
  endmodule: BR_Req_Detect

//endpackage: AHB_arbiter_package
  
//  //////////////////////////////////////////////////////////////////////////////////
//  // File Name: 		AHB_arbiter_package.sv
//  // Project Name:	AHB_Gen
//  // Module Name:   monitor
//  //////////////////////////////////////////////////////////////////////////////////
// 
//  module monitor
//  #(
//    parameter UNDL_LIMIT = 4
//  )
//  (
//    input             hwait,
//    input             hsel,
//    input hburst_type hburst,
//    input hsize_type  hsize,
//    input [9:0]       haddr_last,
//    input             hclk,
//    input             hreset_n,
//    output            hlast
//  );
//   
//    enum logic {
//      IDLE,
//      MONITOR
//    } current_state, next_state;
//   
//    logic [3:0] count;
//    logic       count_clr,
//                count_en,
//                //bdr_reach,
//                hlast;
//
//    always_comb begin
//      count_en = 1'b0;
//      count_clr = 1'b0;
//      unique case(current_state)
//      IDLE: 
//      begin
//        count_clr = 1'b1;
//        if(hsel == 1'b1)
//          next_state = MONITOR;
//        else
//          next_state = current_state;
//      end
//      MONITOR: 
//      begin 
//        count_en = 1'b1;
//        if(hlast == 1'b1)
//          next_state = IDLE;
//        else
//          next_state = current_state;
//      end
//      endcase
//    end
//
//    always_ff @(posedge hclk, negedge hreset_n)
//    begin
//      if(!hreset_n)
//        count <= '0;
//      else if (count_clr)
//        count <= '0;
//      else if (count_en && !hwait)
//        count <= count + 1;
//      else 
//        count <= count;
//      end
//    end
//
////    // 1KB boundary detect
////    always_comb begin
////      bdr_reach = 1'b0;
////      unique case(hsize)
////      BYTE:             bdr_reach = (haddr[9:0] == 10'h3FF);
////      HALFWORD:         bdr_reach = (haddr[9:0] == 10'h3FE);
////      WORD:             bdr_reach = (haddr[9:0] == 10'h3FC);
////      DOUBLEWORD:       bdr_reach = (haddr[9:0] == 10'h3F8);
////      FOURWORDLINE:     bdr_reach = (haddr[9:0] == 10'h3F0);
////      EIGHTWORDLINE:    bdr_reach = (haddr[9:0] == 10'h3E0);
////      SIXTEENWORDLINE:  bdr_reach = (haddr[9:0] == 10'h3C0); 
////      THIRTY2WORDLINE:  bdr_reach = (haddr[9:0] == 10'h380);
////      endcase
////    end
// 
//    // End of burst 
//    always_comb begin
//      burst_limit = 1'b0;
//      unique case (hburst)
//        SINGLE: burst_limit = '0; 
//        INCR:   burst_limit = UNDL_LIMIT;
//        WRAP4:  burst_limit = 3;
//        INCR4:  burst_limit = 3;
//        WRAP8:  burst_limit = 7;
//        INCR8:  burst_limit = 7;
//        WRAP16: burst_limit = 15;
//        INCR16: burst_limit = 15;
//      endcase
//    end
//
////    assign hlast = ((burst_limit == count) || (bdr_reach)) ? 1'b1 : 1'b0;
//    assign hlast = (burst_limit == count) ? 1'b1 : 1'b0;
//
//  endmodule: monitor
  
  
