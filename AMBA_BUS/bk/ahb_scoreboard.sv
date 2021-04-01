/*********************************************************************************
 * File Name: 		ahb_scoreboard.sv
 * Project Name:	AHB_Gen
 * Email:         quanghungbk1999@gmail.com
 * Version    Date      Author      Description
 * v0.0       2/10/2020 Quang Hung  First Creation
 *********************************************************************************/

//--------------------------------------------------------------------------------

class Expected_scells;
  Slave sq[$];
  int iexpect, iactual;

endclass: Expected_scells

//--------------------------------------------------------------------------------

class Mas_scoreboard;
  Config cfg;
  Expected_scells expect_cells[];    
  Slave sq[$];
  int iexpect, iactual;
  
  extern function new(Config cfg);
  extern virtual function void wrap_up();
  extern function void save_expected(Slave s);  
  extern function void check_actual(input Slave s, input int portID);
  extern function void display(string prefix="");

endclass: Mas_scoreboard

//--------------------------------------------------------------------------------

function Mas_scoreboard::new(Config cfg);
  this.cfg = cfg;
  expect_cells = new[cfg.masnum];
  foreach(expect_cells[i])
    expect_cells[i] = new();

endfunction: new

//--------------------------------------------------------------------------------

function Mas_scoreboard::save_expected(Slave s);
  $display("%t: Master_Scb Saved", $time);

endfunction: Mas_scoreboard
