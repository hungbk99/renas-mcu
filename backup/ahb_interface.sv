//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_interface.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

`define PRIORBIT 2
interface ahb_itf(input hclk);
  import AHB_package::*;
    
  mas_send_type            mas_in, slv_out;
  slv_send_type            mas_out, slv_in;  
  logic                    hsel;
  logic [`PRIORBIT-1:0]    prio;

  modport master_dut(  
    output mas_out, 
    input  mas_in, prio); 

  modport slave_dut(  
    input  slv_in,  
    output hsel,
    output slv_out);  
  
  clocking master_cb @(posedge hclk);
    input  mas_out;  
    output mas_in;
    output prio; 
  endclocking: master_cb

  clocking slave_cb @(posedge hclk);
    output slv_in;  
    input  hsel; 
    input  slv_out;  
  endclocking: slave_cb
  
  //clocking master_cb @(posedge hclk);
  //  output mas_out;  
  //  input  mas_in, prio; 
  //endclocking: master_cb

  //clocking slave_cb @(posedge hclk);
  //  input  slv_in;  
  //  output hsel; 
  //  output slv_out;  
  //endclocking: slave_cb
  
  modport mas_itf(clocking master_cb);
  modport slv_itf(clocking slave_cb);

endinterface: ahb_itf

typedef virtual ahb_itf vahb_itf;
typedef virtual ahb_itf.mas_itf vmas_itf;
typedef virtual ahb_itf.slv_itf vslv_itf;
