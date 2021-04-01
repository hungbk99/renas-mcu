//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_interface.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

import AHB_package::*;

interface ahb_itf;

  bit [31:0]   haddr;
  bit          hwrite;
  hsize_type   hsize;
  hburst_type  hburst;
  bit [3:0]    hprot;
  htrans_type  htrans;
  bit          hmastlock;
  bit          hready;
  bit [31:0]   hwdata;
  bit          hresetn;
  bit          hclk;

  bit          hreadyout;
  bit          hresp;    
  bit [31:0]   hrdata;
  
  clocking master_cb @(posedge hclk);
    output  haddr, hwrite, hsize, hburst, hprot, htrans, hmastlock, hwdata;   
    input   hready, hresp, hreset_n, hrdata;
  endclocking: master

  clocking slave_cb @(posedge hclk);
    input   haddr, hwrite, hsize, hburst, hprot, htrans, hmastlock, hwdata, hreset_n;   
    output   hreadyout, hresp, hrdata;
  endclocking: master
  
  modport master_itf(clocking master_cb);
  modport slave_itf(clocking slave_cb);

endinterface: ahb_itf

