//////////////////////////////////////////////////////////////////////////////////
// File Name: 		apb_driver.sv
// Project Name:	SPI - renas mcu
// Ho Chi Minh University of Technology
// Copyright (C) 2021 Le Quang Hung
// All Rights Reserved
// Email:         quanghungbk1999@gmail.com
// Version    Date       Author      Description
// v0.0       10/04/2021 Quang Hung First Creation
//////////////////////////////////////////////////////////////////////////////////

class apb_driver extends uvm_driver #(apb_transaction);
  //Virtual interface
  virtual apb_if.apb_cb vif;

  //Config Object Handler
  apb_config            cfg;

  `uvm_component_utils_begin(apb_driver)
    `uvm_field_object(cfg, UVM_DEFAULT)
  `uvm_component_utils_end
 
  //Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  //Class methods
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task pre_reset_phase(uvm_phase phase);
  extern virtual task reset_phase(uvm_phase phase);
  extern virtual protected task reset();
  extern virtual protected task drive_transfer(apb_transaction trans);
  extern virtual protected task drive_address_phase(apb_transaction trans);
  extern virtual protected task drive_data_phase(apb_transaction trans);
endclass: apb_driver;

//--------------------------------------------------------------------------------

function void apb_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg))
      `uvm_error("[NOCONFIG]", {"apb_config has not been set for:", get_full_name()})
endfunction: build_phase

//--------------------------------------------------------------------------------

function void apb_driver::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_error("[NOVIF]", {"interface must be set for: ", get_full_name(), ".vif"})
endfunction: connect_phase

//--------------------------------------------------------------------------------

function void apb_driver::pre_reset_phase(uvm_phase phase);
  phase.raise_objection(this);
  vif.preset_n <= 1'b1;
  #1;
  phase.drop_objection(this);
endfunction: pre_reset_phase

//--------------------------------------------------------------------------------

function void apb_driver::reset_phase(uvm_phase phase);
  phase.raise_objection(this);
  vif.preset_n <= 1'b0;
  #13
  vif.preset_n <= 1'b1;
  phase.drop_objection(this);
endfunction: reset_phase

//--------------------------------------------------------------------------------

task apb_driver::run_phase(uvm_phase phase);
  reset();
  @(posedge vif.preset_n)
  `uvm_info("[APB DRyyIVER]","[reset releasing...]", UVM_MEDIUM)
  forever begin
    fork 
      begin
        @(negedge vif.preset_n)
        `uvm_info("[APB Driver]", "[reset dropping ...]", UVM_MEDIUM)
        reset();
      end  

      begin
        forever begin
          @(posedge vif.pclk iff vif.preset_n)
          seq_item_port.get_next_item(req);
          //$cast(rsp, req.clone());
          //rsp.set_id_info(req); //copy the sequence id
          drive_transfer(req);
          seq_item_port.item_done();
        end
      end
    join_any

    disable fork;
  end
endtask: run_phase

//--------------------------------------------------------------------------------

task apb_driver::reset();
  wait(!vif.preset_n);
  `uvm_info("[APB Driver]", "[reset ...]", UVM_MEDIUM)
  vif.paddr   <= '0;
  vif.pwdata  <= '0;
  vif.pwrite  <= '0;
  vif.penable <= '0;
  vif.psel    <= '0;
  vif.pprot   <= '0;
  vif.pstrb   <= '0;
endtask: reset

//--------------------------------------------------------------------------------

task apb_driver::drive_transfer(apb_transaction trans);
  `uvm_info("[APB Driver]", "[New transaction ...]", UVM_MEDIUM)
  if(trans.transmit_delay > 0) begin
    repeat(trans.transmit_delay) @(posedge vif.pclk);
  end
  `uvm_info("[APB Driver]", "[Transfering ...]", UVM_MEDIUM)
  drive_address_phase(trans);
  drive_data_phase(trans);
  `uvm_info("[APB Driver]", "[Transaction finished ...]", UVM_MEDIUM)
endtask: drive_transfer

//--------------------------------------------------------------------------------

task apb_driver::drive_address_phase(apb_transaction trans);
  vif.paddr   <= trans.paddr;
  vif.pwrite  <= trans.pwrite;
  vif.penable <= 1'b0;
  vif.psel    <= 1'b1;
  vif.pprot   <= trans.pprot;
  if(trans.pwrite == APB_READ)
    vif.pstrb   <= '0;
  else begin
    vif.pstrb   <= trans.pstrb;
    vif.pwdata  <= trans.pwdata;
  end
  @(posedge vif.pclk)
endtask: drive_address_phase

//--------------------------------------------------------------------------------

task apb_driver::drive_data_phase(apb_transaction trans);
  vif.penable <= 1'b1;
  @(posedge vif.pclk iff vif.pready);
  if(vif.pwrite == APB_READ) 
    trans.prdata <= vif.prdata;
  vif.penable <= 1'b0;
  vif.psel <= 1'b0;
endtask: drive_data_phase

