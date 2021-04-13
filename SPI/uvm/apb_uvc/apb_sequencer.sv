//////////////////////////////////////////////////////////////////////////////////
// File Name: 		apb_sequencer.sv
// Project Name:	SPI - renas mcu
// Ho Chi Minh University of Technology
// Copyright (C) 2021 Le Quang Hung
// All Rights Reserved
// Email:         quanghungbk1999@gmail.com
// Version    Date       Author      Description
// v0.0       12/04/2021 Quang Hung First Creation
//////////////////////////////////////////////////////////////////////////////////

class apb_sequencer extends uvm_sequencer #(apb_transaction);
  //Virtual interface
  virtual apb_if.apb_cb vif;

  //Config Object Handler
  apb_config            cfg;

  `uvm_component_utils_begin(apb_driver)
    `uvm_object_field(cfg, UVM_DEFAULT)
  `uvm_component_utils_end
 
  //Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
//--------------------------------------------------------------------------------

  virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg))
        `uvm_error("[NOCONFIG]", {"apb_config has not been set for:", get_full_name()})
  endfunction: build_phase
  
  //--------------------------------------------------------------------------------
  
  virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
        `uvm_error("[NOVIF]", {"interface must be set for: ", get_full_name(), ".vif"})
  endfunction: connect_phase
endclass: apb_sequencer
