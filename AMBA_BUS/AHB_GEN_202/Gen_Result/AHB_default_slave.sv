//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_bus.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////
module default_slave
(
  input          default_slv_sel,
  output logic   hreadyout,
                 hresp, 
                 error_sel,
  input          hclk,
                 hreset_n 
);

  enum logic {
    IDLE,
    ERROR
  } current_state, next_state;

  always_comb begin
    error_sel = 1'b0;
    hreadyout = 1'b0;
    hresp     = 1'b0;
    case(current_state)
      IDLE: begin
        error_sel = 1'b1;
        if(default_slv_sel)
          next_state = ERROR;
        else
          next_state = current_state;
      end
      ERROR: begin
        error_sel = 1'b1;
        hresp = 1'b1;
        if(!default_slv_sel)
        begin
          next_state = IDLE;
          hreadyout = 1'b1;  
        end
        else
          next_state = current_state;
      end
    endcase
  end


  always_ff @(posedge hclk, negedge hreset_n)
  begin
    if(!hreset_n)
      current_state <= IDLE;
    else
      current_state <= next_state;
  end

endmodule: default_slave
