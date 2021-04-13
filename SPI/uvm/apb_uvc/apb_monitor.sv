//////////////////////////////////////////////////////////////////////////////////
// File Name: 		apb_monitor.sv
// Project Name:	SPI - renas mcu
// Ho Chi Minh University of Technology
// Copyright (C) 2021 Le Quang Hung
// All Rights Reserved
// Email:         quanghungbk1999@gmail.com
// Version    Date       Author      Description
// v0.0       12/04/2021 Quang Hung First Creation
//////////////////////////////////////////////////////////////////////////////////

class apb_monitor extends uvm_monitor;
  //Virtual interface
  virtual apb_if.apb_cb vif;

  //Config Object Handler
  apb_config            cfg;

  //Status Property
  protected int unsigned num_transaction = 0;
  
  //Control Property
  bit check_enable = 1;
  bit coverage_enable = 1;

  //TLM ports:
  //---------- Send transaction to other components
  uvm_analysis_port #(apb_transaction) write_mon_port;
  
  //---------- Check reset port
  uvm_blocking_peek_imp #(apb_transaction) peek_mon_port;
  
  //Current APB transaction
  protected apb_transaction trans_collected;

  `uvm_component_utils_begin(apb_monitor)
    `uvm_object_field(cfg, UVM_DEFAULT)
    `uvm_int_field(num_transaction, UVM_DEFAULT)
    `uvm_int_field(check_enable, UVM_DEFAULT)
    `uvm_int_field(coverage_enable, UVM_DEFAULT)
  `uvm_component_utils_end

  //Coverage collector
  covergroup apb_cg;
    option.per_instance = 1;
    TRANS_ADDR: coverpoint trans_collected.paddr {
      bins SPICR     = {32'h00};
      bins SPIBR     = {32'h04};
      bins SPIINTER  = {32'h08};
      bins SPISR     = {32'h0C};
      bins SPIRINTR  = {32'h10};
      bins SPIINTR   = {32'h14};
      bins SPITXFIFO = {32'h18};
      bins SPIRXFIFO = {32'h1C};
    }

    TRANS_DIRECTION: coverpoint trans_collected.pwrite {
      bins READ = {APB_READ};
      bins WRITE = {APB_WRITE};
    }

    TRANS_DATA: coverpoint trans_collected.pdata {
      bins ZERO = {0};
      bins NON_ZERO = {[1:32'hFFFF_FFFE]};
      bins ALL_ONE = {[1:32'hFFFF_FFFE]};
    }
 
    TRANS_PSTROB: coverpoint trans_collected.pstrb {
      bins ZERO = {0};
      bins ALL_ONE = {15};
      bins NON_ZERO = {[1:14]};
    }

    ADDR_X_DIRECTION: cross TRANS_ADDR, TRANS_DIRECTION;  
  endgroup

  //Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  //Class methods
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task peek(output bit reset);
  extern virtual function perform_check();
  extern virtual function perform_coverage();
endclass: apb_monitor

