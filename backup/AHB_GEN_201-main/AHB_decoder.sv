/////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_decoder.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       14/11/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

//================================================================================
//DEFI_GEN_$
//================================================================================
import AHB_package::*;
module AHB_decoder 
#(
//PARA_GEN_$
)
(
  input [AHB_ADDR_WIDTH-1:0]      haddr,   
  input [MASTER_X_SLAVE_NUM-1:0]  hgrant,
  input htrans_type               htrans, 
  input                           hreset_n,
  input                           hremap,
  input                           hsplit,
  output                          default_slv_sel,
  output [MASTER_X_SLAVE_NUM-1:0] hreq,
  output                          herror,
  
  input                           hlast,
  input                           hclk
);

//================================================================================
//Internal Interfaces
  logic [MASTER_X_SLAVE_NUM-1:0] slave_detect;

//================================================================================
//ADDR_MAP_GEN_$  
//================================================================================
  
//================================================================================
//Internal Signals 
  logic [MASTER_X_SLAVE_NUM-1:0]  slave_detect;
  logic                           dec_error;
  `ifdef DECODE_CYCLE_FSM  
    enum logic [1:0]
    {
      DFSM_IDLE,
      DFSM_DECODE,
      DFSM_SLVSEL,
      DFSM_ERROR
    } dfsm_current_state, dfsm_next_state;
  `elsif NON_DECODE_CYCLE_FSM
    enum logic [1:0]
    {
     NDFSM_IDLE,
     NDFSM_SLVSEL,
     NDFSM_ERROR
    } ndfsm_current_state, ndfsm_next_state;
  `endif
//================================================================================
  genvar i;
  generate
    for(i = 0; i < MASTER_X_SLAVE_NUM; i++)
    begin: req_gen
      always_comb begin
        slave_detect[i] = 1'b0;
        if((haddr[AHB_ADDR_WIDTH-1:10] > AHB_SLAVE_$_$_LOW_ADDR)&&(haddr[AHB_ADDR_WIDTH-1:10] < AHB_SLAVE_$_$_HIGH_ADDR))
          slave_detect[i] = 1'b1;  
      end
    end
  endgenerate

  assign  dec_error = ~|slave_detect;  //Access undefine region
  
  `ifdef DECODE_CYCLE_FSM  
    assign dec_last = ; // 1KB boundary detect
    assign req_break = hwrap_detect || hslv_error_detect || seq
    
    always_comb begin
      unique case(dfsm_current_state)    
        DFSM_IDLE: 
        begin
          if(htrans == NONSEQ)
            dfsm_next_state = DFSM_DECODE;
          else 
            dfsm_next_state = dfsm_current_state;
        end
        DFSM_DECODE:
        begin
          if(!dec_error)
            dfsm_next_state = DFSM_SLVSEL;
          else 
            dfsm_next_state = DFSM_ERROR;
        end
        DFSM_SLVSEL:
        begin
          if(((htrans == NONSEQ)&&!dec_break) || ((htrans == SEQ) && (dec_last)))
          if(!req_break)
        end
        DFSM_ERROR:
        begin

        end
        default: 
      endcase
    end



  `elsif NON_DECODE_CYCLE_FSM
  // This decoder does not insert any decode cycle, it decodes the address every cycle.  
    always_comb begin
      unique case(ndfsm_current_state)
      NDFSM_IDLE:
      begin
        if((htrans == NONSEQ) || (htrans == SEQ))
        begin
          if(!dec_error)
            ndfsm_next_state = NDFSM_SLVSEL;
          else
            ndfsm_next_state = NDFSM_ERROR;
        end
        else 
           ndfsm_next_state = ndfsm_current_state;
      end
      NDFSM_SLVSEL:
      begin
        if((htrans == IDLE) && !hslv_wait_detect)
          ndfsm_next_state = NDFSM_IDLE;
        else if((htrans != IDLE) && !hslv_wait_detect && dec_error)
          ndfsm_next_state = NDFSM_ERROR;
        else 
           ndfsm_next_state = ndfsm_current_state;
      end
      NDFSM_ERROR:
      begin
        if(htrans == IDLE)
          ndfsm_next_state = NDFSM_IDLE;
        else
          ndfsm_next_state = ndfsm_current_state;
      end
      default: ndfsm_next_state = ndfsm_current_state;
    end

    always_ff @(posedge hclk, negedge hreset_n)
    begin
      if(!hreset_n)
        ndfsm_current_state <= NDFSM_IDLE;
      else 
        ndfsm_current_state <= ndfsm_next_state;
    end

    always_comb begin
      hreq_ena = 1'b0;   
      defaut_ena = 1'b0;
      unique case(ndfsm_current_state)
      DFSM_IDLE:
      begin
        
      end
      DFSM_DECODE:
      begin

      end
      DFSM_SLVSEL:
      begin

      end
      DFSM_ERROR:
      begin

      end
      endcase
    end
  `endif
  
  assign hreq = hreq_en ? slave_detect : '0
  assign default_slv_sel = defaut_ena; 

endmodule: AHB_decoder
