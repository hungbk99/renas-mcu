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

typedef bit { APB_READ, APB_WRITE } apb_direction_enum;

class apb_transaction extends uvm_sequence_item;
  rand bit [31:0]         paddr;
  rand bit [31:0]         pwdata;
  rand bit [2:0]          pprot;
  rand bit [3:0]          pstrb;
  
  rand bit                pready;
  rand bit [31:0]         prdata;
  rand apb_direction_enum pwrite;
  rand bit                pslverr;
  
  string                  slave;
  string                  master;

  //Control Fields
  rand int unsigned       transmit_delay;
  rand int unsigned       pready_delay;    
 
  //Constraints
  constraint c_word_aligned  { paddr[1:0] == 2'b00; }
  constraint c_pstrb { pstrb dist {15:= 9, [0:14]:/1}; }
  constraint c_pready { pready dist {1:= 9, 0:=1}; }
  constraint c_pready_delay { pready_delay dist {0:=8, 1:=1, 2:=1}; }

  //UVM utilities & automation macros for data items
  `uvm_object_utils_begin(apb_transaction)
    `uvm_field_int(paddr, UVM_DEFAULT)
    `uvm_field_int(pwdata, UVM_DEFAULT)
    `uvm_field_int(pprot, UVM_DEFAULT)
    `uvm_field_int(pstrb, UVM_DEFAULT)
    
    `uvm_field_int(pslverr, UVM_DEFAULT)
    `uvm_field_int(prdata, UVM_DEFAULT)
    `uvm_field_int(pready, UVM_DEFAULT)
    `uvm_field_enum(apb_direction_enum, pwrite, UVM_DEFAULT)
   
    `uvm_field_int(transmit_delay, UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOPACK)
    `uvm_field_int(pready_delay, UVM_DEFAULT | UVM_NOCOMPARE | UVM_NOPACK)
    `uvm_field_string(slave, UVM_DEFAULT | UVM_NOCOMPARE);
    `uvm_field_string(master, UVM_DEFAULT | UVM_NOCOMPARE);
  `uvm_object_utils_end

  //Constructor
  function new(string name = "apb_transaction");
    super.new(name);
  endfunction: new

endclass: apb_transaction
