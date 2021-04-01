//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_generator.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////


//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------

class Mas_generator;
  Master  blueprint;
  mailbox mas_gen2drv;
  event   mas_drv2gen;
  int     ncells; //numbers of gen
  int     portID; 

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
    blueprint = new();
  endfunction

  task run();
    Master m;
    repeat (ncells) begin
      assert(blueprint.randomize());
      $cast(m, blueprint.copy()); // m is not a handle of blueprint
      mas_gen2drv.put(m); // wait until driver receive the data
      @mas_drv2gen
    end
  endtask

endclass: mas_generator

//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------

class Slv_generator;
  Slave   blueprint;
  mailbox slv__gen2drv;
  event   slv_drv2gen;
  int     ncells;
  int     portID;

  function new(
    input mailbox slv_gen2drv,
    input event   slv_drv2gen,
    input int     ncells,
    input int     portID
  );
    this.slv_gen2drv = slv_gen2drv;
    this.slv_drv2gen = slv_drv2gen;
    this.ncells = ncells;
    this.portID = portID;
    blueprint = new();
  endfunction

  task run();
    Slave s;
    repeat (ncells) begin
      assert(blueprint.randomize());
      $cast(s, blueprint.copy());
      slv_gen2drv.put(s);
      @slv_drv2gen
    end
  endtask

endclass: Slv_generator
