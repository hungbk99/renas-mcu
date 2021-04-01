//////////////////////////////////////////////////////////////////////////////////
// File Name: 		v_interface.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

import AHB_package::*;
interface ahb_itf (input bit hclk);

  logic [31:0] haddr;
  logic        hwrite;
  hsize_type   hsize;
  hburst_type  hburst;
  logic [3:0]  hprot;
  htrans_type  htrans;
  logic        hmastlock;
  logic        hready;
  logic [31:0] hwdata;
  logic        hresetn;
  
  logic        hreadyout;
  logic        hresp;    
  logic [31:0] hrdata;
  
  clocking master_cb @(posedge hclk);
    output  haddr, hwrite, hsize, hburst, hprot, htrans, hmastlock, hwdata;   
    input   hready, hresp, hreset_n, hrdata;
  endclocking: master

  clocking slave_cb @(posedge hclk);
    input   haddr, hwrite, hsize, hburst, hprot, htrans, hmastlock, hwdata, hreset_n;   
    input   hreadyout, hresp, hrdata;
  endclocking: master
  
  modport master_itf(clocking master_cb);
  modport slave_itf(clocking slave_cb);

endinterface: ahb_itf
