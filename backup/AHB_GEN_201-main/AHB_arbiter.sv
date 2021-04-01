//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_arbiter.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date        Author      Description
// v0.0       2/10/2020   Quang Hung  First Creation
// v1.0       14/11/2020  Quang Hung  Interface modification
//////////////////////////////////////////////////////////////////////////////////

//================================================================================
//DEFI_GEN_$
//  `define ROUND_ROBIN_ARBITER
//  `define DYNAMIC_PRIORITY_ARBITER
  `define FIXED_PRIORITY_ARBITER
//================================================================================

module AHB_arbiter
#(
  `ifdef DYNAMIC_PRIORITY_ARBITER  
    parameter SLAVE_X_PRIOR_NUM = 4,
    parameter SLAVE_X_PRIOR_BIT = 2,
  `elsif ROUND_ROBIN_ARBITER
//    localparam SLAVE_X_PRIOR_NUM = SLAVE_X_MASTER_NUM,
//    localparam SLAVE_X_PRIOR_BIT = $clog2(SLAVE_X_MASTER_NUM), 
    parameter SLAVE_X_PRIOR_NUM = SLAVE_X_MASTER_NUM,
    parameter SLAVE_X_PRIOR_BIT = $clog2(SLAVE_X_MASTER_NUM), 
  `endif
  parameter SLAVE_X_MASTER_NUM = 4
)  
(
  input   [SLAVE_X_MASTER_NUM-1:0]                      hreq,
                                                        hlast,
  input                                                 hwait,
  output  logic [SLAVE_X_MASTER_NUM-1:0]                hgrant,
  output  logic                                         hsel,
`ifdef  DYNAMIC_PRIORITY_ARBITER
  input [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_BIT-1:0] hprior,   
`endif
  input                                                 hclk,
                                                        hreset_n
);
  
  logic [SLAVE_X_MASTER_NUM-1:0] raw_grant;
  logic [SLAVE_X_MASTER_NUM-1:0] grant;

`ifdef  FIXED_PRIORITY_ARBITER   
//  genvar i;
//  generate
//    for(i =0; i < SLAVE_X_MASTER_NUM-1; i ++)
//    begin: fixed_prior_arb_gen
//      assign mask_grant[i] = ~|hreq[SLAVE_X_MASTER_NUM-1:i] & mask_req[i];
//    end
//    assign  mask_grant[SLAVE_X_MASTER_NUM-1] = mask_req[SLAVE_X_MASTER_NUM]; 
//  endgenerate
//  
//  assign  mask_req = hreq & ~(~hlock & hgrant);


  Fixed_Prior_Mask 
  #(
    .REQ_NUM(SLAVE_X_MASTER_NUM)
  )
  FPA
  (
    .hlast(hlast),
    .collect_req(hreq),
    .hsel(hsel),  
    .raw_grant(raw_grant)
  );
  
`elsif  DYNAMIC_PRIORITY_ARBITER
  `define PRIOR_GEN
  
  Fixed_Prior_Mask  
  #(
    .REQ_NUM(SLAVE_X_MASTER_NUM)
  )
  FPM
  (
    .hlast(hlast),
    .collect_req(collect_req),
    .hsel(hsel),  
    .raw_grant(raw_grant)
  );
`elsif  ROUND_ROBIN_ARBITER
  `define PRIOR_GEN
  logic [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_BIT-1:0] prior_reg,
                                                        prior_cout,
                                                        hprior;
  logic [SLAVE_X_PRIOR_BIT-1:0] current_prior;
//  logic                         fal_hsel_detect,
//                                fal_hsel_buf; 
//
//  always_ff @(posedge hclk, negedge hreset_n)
//  begin
//    if(!hreset_n)
//      fal_hsel_buf <= 1'b0;
//    else 
//      fal_hsel_buf <= hsel;
//  end
//
//  assign fal_hsel_detect = fal_hsel_buf & ~hsel;
  logic update,
        current_hlast;

  always_ff @(posedge hclk, negedge hreset_n)
  begin
    for(int i = 0; i < SLAVE_X_MASTER_NUM; i++)
    begin
      if(!hreset_n)
        prior_reg[i] <= i;
      else if(update)                                      // Update the reg table at the last transfer of the current  
        prior_reg[i] <= prior_cout[i];                     // transaction if there are no wait request from slave
    end
  end
  
  assign update = hsel & ~hwait & current_hlast;

  // One-hot Mux
  always_comb begin
     current_prior = '0;
     current_hlast = 1'b0;
     prior_cout = prior_reg;
     for(int i = 0; i < SLAVE_X_MASTER_NUM; i++)
     begin
      if(grant == (1 << i))   
      begin
        current_prior = hprior[i];
        current_hlast = hlast[i];
        prior_cout[i] = '0;
      end
      else if (prior_reg[i] < current_prior)
        prior_cout[i] = prior_reg[i] + 1;
     end
  end

  assign hprior = prior_reg;
  
  BR_Req_Detect  
  #(
    .REQ_NUM(SLAVE_X_MASTER_NUM)
  )
  BRRD
  (
    .hlast(hlast),
    .collect_req(collect_req),
    .hsel(hsel),  
    .raw_grant(raw_grant)
  );
`endif

`ifdef  PRIOR_GEN
  logic [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_NUM-1:0] gen_req;    
  logic [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_NUM-1:0]  mask_req;
  logic [SLAVE_X_MASTER_NUM-1:0]  collect_req;
//                                  raw_grant,
//                                  grant; 
 
  genvar i;
  generate
    for(i = 0; i < SLAVE_X_MASTER_NUM; i++)
    begin: PG_gen
      Prior_Gen 
      #(
        .PRIOR_BIT(SLAVE_X_PRIOR_BIT),
        .PRIOR_NUM(SLAVE_X_PRIOR_NUM)
      )
      PG
      (
        .hreq(hreq[i]),
        .hprior(hprior[i]),
        .hsel(hsel),
        .grant(grant[i]),
        .gen_req(gen_req[i])
      );
    end
  endgenerate

  Dynamic_Prior_Mask  
  #(
    .PRIOR_NUM(SLAVE_X_PRIOR_NUM),
    .REQ_NUM(SLAVE_X_MASTER_NUM)
  )
  DPM
  (
    .gen_req(gen_req),
    .mask_req(mask_req)
  );

  Req_Collect 
  #(
    .PRIOR_NUM(SLAVE_X_PRIOR_NUM),
    .REQ_NUM(SLAVE_X_MASTER_NUM)
  )
  RC
  (
    .mask_req(mask_req),
    .collect_req(collect_req)    
  );
  
`endif
  
//  always_ff @(posedge hclk, negedge hreset_n)
//  begin
//    if(!hreset_n)
//      hgrant <= '0;
//    else 
//      hgrant <= mask_grant;
//  end
//  assign hsel = |hgrant;

  always_ff @(posedge hclk, negedge hreset_n)
  begin
    if(!hreset_n)
      grant <= '0;
    else 
      grant <= raw_grant; 
  end

  assign hgrant = grant & ~hwait;  
  assign hsel = hwait & |grant; 

endmodule: AHB_arbiter

//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_arbiter.sv
// Project Name:	AHB_Gen
// Module Name:   Prior_Gen
//////////////////////////////////////////////////////////////////////////////////

module Prior_Gen
#(
  parameter PRIOR_BIT = 2,
  parameter PRIOR_NUM = 4
)
(
  input logic                   hreq,
  input logic [PRIOR_BIT-1:0]   hprior,
  input logic                   hsel,
                                grant,
  output logic [PRIOR_NUM-1:0]  gen_req
);

  logic [PRIOR_NUM-1:0]  raw_req;
  
  always_comb begin
    raw_req = '0;
    for(int i = 0; i < PRIOR_NUM; i++)
    begin
      if(hprior == i)
        raw_req[i] <= hreq;
    end
  end
  
  assign gen_req = (!hsel || (hsel && grant)) ? raw_req : '0;

endmodule: Prior_Gen

//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_arbiter.sv
// Project Name:	AHB_Gen
// Module Name:   Dynamic_Prior_Mask
//////////////////////////////////////////////////////////////////////////////////

module Dynamic_Prior_Mask
#(
  parameter PRIOR_NUM = 4,
  parameter REQ_NUM = 8
)
(
  input logic [REQ_NUM-1:0][PRIOR_NUM-1:0]   gen_req,
  output logic [REQ_NUM-1:0][PRIOR_NUM-1:0]  mask_req
);

  logic [PRIOR_NUM-1:0]               prior_mask,
                                      prior_detect;
  logic [PRIOR_NUM-1:0][REQ_NUM-1:0]  prior_classify;

  genvar a, b;
  generate
    for(a = 0; a < PRIOR_NUM; a++)
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
//    prior_mask[PRIOR_NUM-1] = prior_detect[PRIOR_NUM-1];
//    for(int i = 0; i < PRIOR_NUM-1; i++)
//    begin
//      prior_mask[i] = ~|prior_detect[PRIOR_NUM-1:i+1] & prior_detect[i];  
//    end
//  end 

  genvar c;
  generate
    for(c = 0; c < PRIOR_NUM-1; c++)
    begin: dynamic_prior_mask_gen
      assign prior_mask[c] = ~|prior_detect[PRIOR_NUM-1:c+1] & prior_detect[c];
    end
    assign prior_mask[PRIOR_NUM-1] = prior_detect[PRIOR_NUM-1];
  endgenerate

endmodule: Dynamic_Prior_Mask
  
//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_arbiter.sv
// Project Name:	AHB_Gen
// Module Name:   Req_Collect
//////////////////////////////////////////////////////////////////////////////////

module Req_Collect
#(
  parameter PRIOR_NUM = 4,
  parameter REQ_NUM = 8
)
(
  input logic [REQ_NUM-1:0][PRIOR_NUM-1:0]  mask_req,
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
// File Name: 		AHB_arbiter.sv
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
//    for(int i = 0; i < PRIOR_NUM-1; i++)
//    begin
//      raw_grant[i] = ~|collect_req[PRIOR_NUM-1:i+1] & collect_req[i] & ~(hlast[i] & hsel); 
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
// File Name: 		AHB_arbiter.sv
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
