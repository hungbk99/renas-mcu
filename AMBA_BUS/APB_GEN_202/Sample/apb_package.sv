//////////////////////////////////////////////////////////////////////////////////
// File Name: 		apb_package.sv
// Function:		  interface signals for x2p
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.0   04.04.2021  hungbk99  First creation
//////////////////////////////////////////////////////////////////////////////////

package apb_package;
import 	RVS192_package::*;
  //parameter DATA_LENGTH = 32;
  //parameter ADDR_LENGTH = 32;
  typedef struct packed {
    logic [DATA_LENGTH-1:0] paddr;
    logic [2:0]             pprot;
    //Hung_mod logic                   psel;
    logic                   penable;
    logic                   pwrite;
    logic [DATA_LENGTH-1:0] pwdata;
    logic [3:0]             pstrb;
  } master_s_type;

  typedef struct packed {
    logic                   pready;
    logic [DATA_LENGTH-1:0] prdata;
    logic                   pslverr;
  } slave_s_type;
endpackage: apb_package
