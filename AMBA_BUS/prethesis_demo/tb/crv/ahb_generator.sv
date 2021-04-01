//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_generator.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date       Author      Description
// v0.0       02/10/2020 Quang Hung First Creation
//            12/01/2021 Quang Hung Add support for decode error
//////////////////////////////////////////////////////////////////////////////////

//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_cells.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/config.sv"

//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------

class Mas_generator;
  Master  blueprint;
  mailbox mas_gen2drv;
  event   mas_drv2gen;
  int     ncells; //numbers of gen
  int     portID; 

  bit [31:0] startq[$] = {32'h0,
                          32'h400,
                          32'h1000,
                          32'h2000,
                          32'h2404,
                          32'h4000,
                          32'h5000},

             stopq[$] = {32'h3FF,
                         32'hCF0,
                         32'h100F,
                         32'h2403,
                         32'h24FF,
                         32'h4FFF,
                         32'h5FFF};

  function new(
    input mailbox mas_gen2drv,
    input event mas_drv2gen,
    input int ncells,
    input int portID
  );
    this.mas_gen2drv = mas_gen2drv;
    this.mas_drv2gen = mas_drv2gen;
    this.ncells = ncells;
    this.portID = portID;
    blueprint = new(startq[portID], stopq[portID]);
  endfunction

  task run();
    Master m;
      $display("Master Generator on ..... portID[%0d]", portID);
      $display("###########################################################################################");
      $display("[MASTER CELLS]::%0d", ncells);
      $display("###########################################################################################");
    repeat (ncells) begin
      assert(blueprint.randomize());
      $cast(m, blueprint.copy()); // m is not a handle of blueprint
      mas_gen2drv.put(m); // wait until driver receive the data
      //$display("Master cells on ..... portID[%0d]", portID);
      $display("###########################################################################################");
      m.display($sformatf("%t:[MASTER SEED]:", $time));
      $display("###########################################################################################");
      @mas_drv2gen;
      $display("###########################################################################################");
      $display("Master Driver receive ... portID[%0d]", portID);
      $display("###########################################################################################");
    end
  endtask

endclass: Mas_generator

//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------

class Slv_generator;
  Slave   blueprint;
  mailbox slv_gen2drv;
  event   slv_drv2gen;
  //int     ncells;
  int     portID;

  function new(
    input mailbox slv_gen2drv,
    input event   slv_drv2gen,
    //input int     ncells,
    input int     portID
  );
    this.slv_gen2drv = slv_gen2drv;
    this.slv_drv2gen = slv_drv2gen;
    //this.ncells = ncells;
    this.portID = portID;
    blueprint = new();
  endfunction

  task run();
    //Hung mod 8_1_2021
    forever begin
      Slave s;
      $display("Slave Generator on ..... portID[%0d]", portID);
      //repeat (ncells) begin
      assert(blueprint.randomize());
      $cast(s, blueprint.copy());
      slv_gen2drv.put(s);
      $display("Slave cells on ..... portID[%0d]", portID);
      @slv_drv2gen;
      $display("Slave Driver receive ... portID[%0d]", portID);
    //end
    end
    //Hung mod 8_1_2021
  endtask

endclass: Slv_generator
