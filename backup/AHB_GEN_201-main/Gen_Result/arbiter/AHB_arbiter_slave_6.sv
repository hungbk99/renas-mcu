//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_arbiter_slave_6.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

//================================================================================
//#CONFIG_GEN#
	`define ONE_PATH_slave_6
//================================================================================

import AHB_package::*;
//import AHB_arbiter_package::*;
module AHB_arbiter_slave_6 
#(
//#PARAGEN#
	parameter SLAVE_X_MASTER_NUM = 1
)  
(
  input   [SLAVE_X_MASTER_NUM-1:0]                      hreq,
  input   hburst_type                                   hburst,
  input                                                 hwait,
  output  logic [SLAVE_X_MASTER_NUM-1:0]                hgrant,
  output  logic                                         hsel,
`ifdef  DYNAMIC_PRIORITY_ARBITER_slave_6
  input [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_BIT-1:0] hprior,   
`endif
  input                                                 hclk,
                                                        hreset_n
);
  
//================================================================================
// Internal signals
  logic [SLAVE_X_MASTER_NUM-1:0] raw_grant;
  logic [SLAVE_X_MASTER_NUM-1:0] grant;
  logic [SLAVE_X_MASTER_NUM-1:0] hlast;
    
  logic                          monitor_last,
                                 count_clr,
                                 count_ena;
  logic [3:0]                    count,
                                 count_limit; 
  hburst_type                    burst;  
 
  enum logic {
    IDLE,
    MONITOR
  } monitor_state, monitor_next_state;    
 
`ifdef  DYNAMIC_PRIORITY_ARBITER_slave_6
  `define PRIOR_GEN
  logic [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_LEVEL-1:0] gen_req;    
  logic [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_LEVEL-1:0] mask_req;
  logic [SLAVE_X_MASTER_NUM-1:0]                          collect_req;
`elsif  ROUND_ROBIN_ARBITER_slave_6
  `define PRIOR_GEN_slave_6
  logic [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_LEVEL-1:0] gen_req;    
  logic [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_LEVEL-1:0] mask_req;
  logic [SLAVE_X_MASTER_NUM-1:0]                          collect_req;
  logic [SLAVE_X_MASTER_NUM-1:0][SLAVE_X_PRIOR_BIT-1:0]   prior_reg,
                                                          prior_cout,
                                                          hprior;
  logic [SLAVE_X_PRIOR_BIT-1:0]                           current_prior;
  logic                                                   update,
                                                          current_hlast;
`endif
//================================================================================
// AHB Scheme
//================================================================================
`ifdef  FIXED_PRIORITY_ARBITER_slave_6  

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
  
`elsif  DYNAMIC_PRIORITY_ARBITER_slave_6
  
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
`elsif  ROUND_ROBIN_ARBITER_slave_6

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

`ifdef  PRIOR_GEN_slave_6
 
  genvar i;
  generate
    for(i = 0; i < SLAVE_X_MASTER_NUM; i++)
    begin: PG_gen
      Prior_Gen 
      #(
        .PRIOR_BIT(SLAVE_X_PRIOR_BIT),
        .PRIOR_LEVEL(SLAVE_X_PRIOR_LEVEL)
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
    .PRIOR_LEVEL(SLAVE_X_PRIOR_LEVEL),
    .REQ_NUM(SLAVE_X_MASTER_NUM)
  )
  DPM
  (
    .gen_req(gen_req),
    .mask_req(mask_req)
  );

  Req_Collect 
  #(
    .PRIOR_LEVEL(SLAVE_X_PRIOR_LEVEL),
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

`ifdef ONE_PATH_slave_6
  assign raw_grant = hreq;  
`endif  
  always_ff @(posedge hclk, negedge hreset_n)
  begin
    if(!hreset_n)
      grant <= '0;
    else 
      grant <= raw_grant; 
  end

  assign hgrant = grant & ~hwait;  
  //Hung mod 4_1_2020 assign hsel = hwait & |grant; 
  //Hung mod 5-1_2020 assign hsel = |grant; 
  assign hsel = (|grant) ? 1'b1 : 1'b0; 

//================================================================================
// Monitor
//================================================================================

  always_comb begin
    count_limit = '0;
    unique case(burst)
        WRAP4, INCR4: count_limit = 3'h3;
        WRAP8, INCR8: count_limit = 3'h7;
        WRAP16, INCR16: count_limit = 3'hF;
    endcase
  end    

  always_ff @(posedge hclk, negedge hreset_n)
  begin
    if(!hreset_n)
    begin
        count <= '0;    
        //Hung db 4_2_2020 burst <= SINGLE;  //db
    end
    else
    begin
        //Hung db 4_2_2020 burst <= hburst;
        if(count_clr)
            count <= '0;
        else if (count_ena && !hwait)
            count <= count + 1;
        else
            count <= count;
    end    
  end
  
  //Hung db 4_2_2020 
  assign burst = hburst;
  assign monitor_last = (count == count_limit) ? 1'b1 : 1'b0;    
  
  always_comb begin
    count_ena = 1'b0;
    count_clr = 1'b0;
    monitor_next_state = IDLE;
    unique case (monitor_state)
      IDLE: begin
        //burst = hburst;
        count_clr = 1'b1;
        if(hsel)
          monitor_next_state = MONITOR;
        else
          monitor_next_state = monitor_state;
      end
      MONITOR: begin
        count_ena = 1'b1;
        if(monitor_last)
          monitor_next_state = IDLE;
        else
          monitor_next_state = monitor_state;
      end  
    endcase
  end
  
  always_ff @(posedge hclk, negedge hreset_n)
  begin
    if(!hreset_n)
      monitor_state <= IDLE;
    else
      monitor_state <= monitor_next_state;
  end  

  //Hung mod 4_2_2020 assign hlast = grant & monitor_last;  
  assign hlast = (monitor_state == MONITOR) ? (grant & monitor_last) : 1'b0;  
          
endmodule: AHB_arbiter_slave_6

