/*********************************************************************************
 * File Name: 		ahb_scoreboard.sv
 * Project Name:	AHB_Gen
 * Email:         quanghungbk1999@gmail.com
 * Version    Date       Author      Description
 * v0.0       02/10/2020 Quang Hung  First Creation
 *            12/01/2021 Quang Hung  Add support for decode error
 *********************************************************************************/

//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_cells.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/config.sv"

//--------------------------------------------------------------------------------

class Mas_expected_cells;
  Master mq[$];
  int iexpect, iactual;

endclass: Mas_expected_cells

//--------------------------------------------------------------------------------

class Mas_scoreboard;
  Config cfg;
  Mas_expected_cells expect_cells[];    
  //Master mq[$];
  int iexpect, iactual;                //Global counter
  
  extern function new(Config cfg);
  extern virtual function void wrap_up();
  extern function void save_expected(Master m);  
  extern function void check_actual(input Master m, input int portID);
  extern function void display(string prefix="");
  //Hung_mod_12_1_2021   
  extern function void clear_error(input Master m, input int portID);
  //Hung_mod_12_1_2021    
endclass: Mas_scoreboard

//--------------------------------------------------------------------------------

function Mas_scoreboard::new(Config cfg);
    //Hung mod 1_1_2020 
    this.cfg = cfg;
  expect_cells = new[cfg.masnum];
  foreach(expect_cells[i])
    expect_cells[i] = new();

endfunction: new
//function Mas_scoreboard::new();
//  expect_cells = new();
//
//endfunction: new


//--------------------------------------------------------------------------------

//Hung mod 8_1_2021 function void Mas_scoreboard::save_expected(Master m);
//Hung mod 8_1_2021   $display("============================================================================================================");
//Hung mod 8_1_2021   $display("%t: Master Scoreboard Saved", $time);
//Hung mod 8_1_2021   expect_cells[m.hwdata].mq.push_back(m);
//Hung mod 8_1_2021   expect_cells[m.hwdata].iexpect++;
//Hung mod 8_1_2021   iexpect++;
//Hung mod 8_1_2021   m.display($sformatf("%t: Mas scoreboard Saved:", $time)); 
//Hung mod 8_1_2021   foreach(expect_cells[m.hwdata].mq[i]) begin
//Hung mod 8_1_2021     expect_cells[m.hwdata].mq[i].display($sformatf("INFO: mq[%0d]", i));
//Hung mod 8_1_2021   end 
//Hung mod 8_1_2021   $display("============================================================================================================");
//Hung mod 8_1_2021 endfunction: save_expected

//Hung mod 8_1_2021
function void Mas_scoreboard::save_expected(Master m);
  Master deep_cp = m.copy();
  $display("============================================================================================================");
  $display("%t: Master Scoreboard Saved", $time);
  expect_cells[deep_cp.hwdata].mq.push_back(deep_cp);
  expect_cells[deep_cp.hwdata].iexpect++;
  iexpect++;
  deep_cp.display($sformatf("%t: Mas scoreboard Saved:", $time)); 
  foreach(expect_cells[deep_cp.hwdata].mq[i]) begin
    expect_cells[deep_cp.hwdata].mq[i].display($sformatf("INFO: mq[%0d]", i));
  end 
  $display("============================================================================================================");
endfunction: save_expected
//Hung mod 8_1_2021

//--------------------------------------------------------------------------------
// hwdata: the master identify --> monitor has to know which scoreboard must be 
// check
//--------------------------------------------------------------------------------

function void Mas_scoreboard::check_actual(input Master m, input int portID);
  $display("============================================================================================================");
  //Monitor already constructs the new object
  m.display($sformatf("%t:Master Scoreboard Check.......", $time));
  $display("Slave: %0d", portID); 

  if(expect_cells[m.hwdata].mq.size() == 0) begin
    $display("%t: ERROR: Cell not found because the scoreboard for Master %0d empty", $time, m.hwdata);
  end

  expect_cells[m.hwdata].iactual++;
  iactual++;
 
  foreach(expect_cells[m.hwdata].mq[i]) begin 
    $display("Queue:: before checking ..................................");
    expect_cells[m.hwdata].mq[i].display($sformatf("INFO: mq[%0d]", i));
  end

  foreach(expect_cells[m.hwdata].mq[i]) begin 
    //Hung mod 6_1_2021
    //expect_cells[m.hwdata].mq[i].display($sformatf("INFO: mq[%0d]", i));
    //m.display();
    if(expect_cells[m.hwdata].mq[i].compare(m)) begin
      $display("%t: PASS:: Master Cells Match............", $time);
      expect_cells[m.hwdata].mq.delete(i);  
      //expect_cells[m.hwdata].mq[i].display($sformatf("INFO: mq[%0d]", i));
    end
    else begin
      $display("%t: ERROR: Master Cells Miss............", $time);
      //Hung mod 1_1_2020 
      cfg.n_errors++;
    end
  end
 
  $display("Queue:: after checking .....................................");
  foreach(expect_cells[m.hwdata].mq[i]) begin 
    expect_cells[m.hwdata].mq[i].display($sformatf("INFO: mq[%0d]", i));
  end

  $display("============================================================================================================");
 
endfunction: check_actual

//--------------------------------------------------------------------------------

//Hung_mod_12_1_2021   
function void Mas_scoreboard::clear_error(input Master m, input int portID);
  foreach(expect_cells[m.hwdata].mq[i]) begin 
    $display("%t: PASS:: ERROR CLEAR............ at MASTER[%0d]", $time, portID);
    expect_cells[m.hwdata].mq.delete(i);  
  end
endfunction: clear_error
//Hung_mod_12_1_2021   

//--------------------------------------------------------------------------------

function void Mas_scoreboard::display(input string prefix="");
  $display("%t:[MASTER]: Total expected cells sent %d, Total actual cells received %d", $time, iexpect, iactual);
  foreach(expect_cells[i]) begin
    $display("Master: %d, expected: %d, actual: %d", i, expect_cells[i].iexpect, expect_cells[i].iactual);
    foreach (expect_cells[i].mq[j])
      expect_cells[i].mq[j].display($sformatf("%s Scoreboard: Master %d", prefix, i));
  end

endfunction: display

//--------------------------------------------------------------------------------

function void Mas_scoreboard::wrap_up();
  $display("[MASTER]: Total expected cells sent %0d, Total actual cells received %0d",  iexpect, iactual);
  foreach(expect_cells[i]) begin
    if(expect_cells[i].mq.size()) begin
      $display("[MASTER]:[ERROR]: cells remaining in Master[%0d] scoreboard at the end of the test", i);
      cfg.n_errors++;
    end
  end

endfunction: wrap_up

//--------------------------------------------------------------------------------
//================================================================================
//--------------------------------------------------------------------------------

class Slv_expected_cells;
  Slave sq[$];
  int iexpect, iactual;

endclass: Slv_expected_cells

//--------------------------------------------------------------------------------

class Slv_scoreboard;
  Config cfg;
  Slv_expected_cells expect_cells[];    
  //Master mq[$];
  int iexpect, iactual;                //Global counter
  
  extern function new(input Config cfg);
  extern virtual function void wrap_up();
  extern function void save_expected(Slave s);  
  extern function void check_actual(input Slave s, input int portID);
  extern function void display(string prefix="");

endclass: Slv_scoreboard

//--------------------------------------------------------------------------------

function Slv_scoreboard::new(input Config cfg);
    //Hung mod 1_1_2020 
    this.cfg = cfg;
  expect_cells = new[cfg.masnum];
  foreach(expect_cells[i])
    expect_cells[i] = new();

endfunction: new
//function Mas_scoreboard::new();
//  expect_cells = new();
//
//endfunction: new


//--------------------------------------------------------------------------------

//Hung mod 8_1_2021 function void Slv_scoreboard::save_expected(Slave s);
//Hung mod 8_1_2021   $display("============================================================================================================");
//Hung mod 8_1_2021   $display("%t: Slave Scoreboard Saved", $time);
//Hung mod 8_1_2021   expect_cells[s.hrdata].sq.push_back(s);
//Hung mod 8_1_2021   expect_cells[s.hrdata].iexpect++;
//Hung mod 8_1_2021   iexpect++;
//Hung mod 8_1_2021   s.display($sformatf("%t: Slv scoreboard Saved:", $time)); 
//Hung mod 8_1_2021   $display("============================================================================================================");
//Hung mod 8_1_2021 endfunction: save_expected

function void Slv_scoreboard::save_expected(Slave s);
  Slave deep_cp;
  deep_cp = s.copy();
  $display("============================================================================================================");
  $display("%t: Slave Scoreboard Saved", $time);
  expect_cells[deep_cp.hrdata].sq.push_back(deep_cp);
  expect_cells[deep_cp.hrdata].iexpect++;
  iexpect++;
  deep_cp.display($sformatf("%t: Slv scoreboard Saved:", $time)); 
  $display("============================================================================================================");
endfunction: save_expected

//--------------------------------------------------------------------------------
// hwdata: the master identify --> monitor has to know which scoreboard must be 
// check
//--------------------------------------------------------------------------------

function void Slv_scoreboard::check_actual(input Slave s, input int portID);
  $display("============================================================================================================");
  s.display($sformatf("%t: Slave Scoreboard Check.......", $time));
  $display("Master: %0d", portID); 
  if(expect_cells[s.hrdata].sq.size() == 0) begin
    $display("%t: ERROR: Cell not found because the scoreboard for Slave %0d empty", $time, s.hrdata);
  end

  //Hung db 2_1_2020 expect_cells[s.hrdata].iactual++;
  expect_cells[s.hrdata].iactual++;
  iactual++; 
 
  $display("before checking ......");
  foreach(expect_cells[s.hrdata].sq[i]) begin 
    expect_cells[s.hrdata].sq[i].display($sformatf("INFO: mq[%0d]", i));
    s.display();
  end

  foreach(expect_cells[s.hrdata].sq[i]) begin 
    //Hung mod 6_1_2021
    //expect_cells[s.hrdata].sq[i].display($sformatf("INFO: mq[%0d]", i));
    //s.display();
    if(expect_cells[s.hrdata].sq[i].compare(s)) begin
      $display("%t: PASS:: Slave Cells Match............", $time);
      expect_cells[s.hrdata].sq.delete(i); 
	  //Hung mod 8_1_2021
      break; 
      //Hung mod 8_1_2021 
    end
    else begin
      $display("%t: ERROR: Slave Cells Miss............", $time);
      cfg.n_errors++;
    end
  end
  
  $display("after checking ......");
  foreach(expect_cells[s.hrdata].sq[i]) begin 
    expect_cells[s.hrdata].sq[i].display($sformatf("INFO: mq[%0d]", i));
    s.display();
  end
  $display("============================================================================================================");
 
endfunction: check_actual

//--------------------------------------------------------------------------------

function void Slv_scoreboard::display(input string prefix="");
  $display("%t:[SLAVE]: Total expected cells sent %0d, Total actual cells received %0d", $time, iexpect, iactual);
  foreach(expect_cells[i]) begin
    $display("Slave: %0d, expected: %0d, actual: %0d", i, expect_cells[i].iexpect, expect_cells[i].iactual);
    foreach (expect_cells[i].sq[j])
      expect_cells[i].sq[j].display($sformatf("%s Scoreboard: Slave %0d", prefix, i));
  end

endfunction: display

//--------------------------------------------------------------------------------

function void Slv_scoreboard::wrap_up();
  $display("[SLAVE]: Total expected cells sent %0d, Total actual cells received %0d", iexpect, iactual);
  foreach(expect_cells[i]) begin
    if(expect_cells[i].sq.size()) begin
      $display("[SLAVE]:[ERROR]: cells remaining in Slave[%0d] scoreboard at the end of the test", i);
      cfg.n_errors++;
    end
  end

endfunction: wrap_up

