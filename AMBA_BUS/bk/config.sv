/*********************************************************************************
 * File Name: 		config.sv
 * Project Name:	AHB_Gen
 * Email:         quanghungbk1999@gmail.com
 * Version    Date      Author      Description
 * v0.0       2/10/2020 Quang Hung  First Creation
 *********************************************************************************/

class Config;
  int n_errors;
  bit [7:0]                masnum,                //Master num 
                           slvnum;                //Slave num
  rand bit                 mas_in_use[];    //Master enable --- which master can send data?    
  rand bit [1:0]           n_cells_mas[];   //Number of cells to transmit-each master
  rand bit [`PRIORBIT-1:0] prio[];

 
  constraint c_numitf
  {
    masnum inside {[1:$]};
    slvnum inside {[1:$]};
  }  

  constraint c_cell_per_mas
  {
    foreach (n_cells_mas[i])
    {
      solve mas_in_use[i] before n_cells_mas[i];
      if(mas_in_use[i])
        n_cells_mas[i] inside {[1:n_cells]};
      else
        n_cells_mas[i] == 0;
    }
  }

  extern function new(input bit [7:0] masnum, slvnum);
  extern virtual function void display(input string prefix="");

endclass: Config

function Config::new(input bit [7:0] masnum, slvnum);
  this.masnum = masnum;
  this.prior = new[masnum];
  mas_in_use = new[masnum];
  this.slvnum = svlnum;
  n_cells_mas = new[masnum];
endfunction: new

function void Config::display(input string prefix="");
  $display("%s:Config: %0d masters, %0d slaves", prefix, masnum, slvnum);
  foreach (mas_in_use[i])
  begin
    if(mas_in_use[i])
      $write("mas_in_use = %0d, cells = %0d, prio = %d", mas_in_use[i], n_cells_mas[i], prio[i]);
  end  
  $display(); 
endfunction: display
                  
