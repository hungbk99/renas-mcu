//////////////////////////////////////////////////////////////////////////////////
// File Name: 		apb_transaction.sv
// Project Name:	SPI - renas mcu
// Ho Chi Minh University of Technology
// Copyright (C) 2021 Le Quang Hung
// All Rights Reserved
// Email:         quanghungbk1999@gmail.com
// Version    Date       Author      Description
// v0.0       10/04/2021 Quang Hung First Creation
//////////////////////////////////////////////////////////////////////////////////

interface apb_if(input pclk, input preset_n);
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;
  parameter SLAVE_NUM = 8;

  //APB signals
  logic [ADDR_WIDTH-1:0]  paddr;
  logic [DATA_WIDTH-1:0]  pwdata,
                          prdata;
  
  logic                   pwrite,
                          penable,
                          pslverr,
                          pready;
  
  logic [3:0]             pstrb;
  logic [2:0]             pprot;
  logic [SLAVE_NUM-1:0]   psel;

  //Control fields
  bit                     check_enable = 1;
  bit                     coverage_enable = 1;

  clocking  apb_cb @(posedge pclk);
    output  paddr;
    output  pwdata;
    output  pwrite;
    output  penable;
    output  psel;
    output  pprot;
    output  pstrb;

    input   pslverr;
    input   pready;
    input   prdata;
  endclocking: apb_cb

  //Assertion checks
  `include "D:/Project/renas-mcu/SPI/UVM/apb_uvc/apb_assertion.sv"
endinterface: apb_if
