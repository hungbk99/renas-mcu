/*********************************************************************************
 * File Name: 		ahb_config.sv
 * Project Name:	AHB_Gen
 * Email:         quanghungbk1999@gmail.com
 * Version    Date      Author      Description
 * v0.0       2/10/2020 Quang Hung  First Creation
 *********************************************************************************/

class Ahb_config;
  int n_errors;
  bit [7:0] masnum, slvnum;
  rand bit [31:0] n_cells;  //Number of cells to transmit
  rand bit mas_in_use[];    //Master enable     
  rand bit n_cells_mas[];   //Number of cells to transmit each master

  constraint c_n_cells
  {
    n_cells inside {[1:4]};
  }
 
  constraint c_nummasslv
  {
    masnum inside {[1:$]};
    slvnum inside {[1:$]};
  }  

  constraint c_in_use
  {
    mas_in_use > 0;
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

  //bit [31:0] start_addr;
  //bit [31:0] stop_addr;

  //rand bit [31:0] haddr; 
  //rand bit        hwrite;
  //rand bit [2:0]  hsize;
  //rand bit [2:0]  hburst;
  //rand bit [3:0]  hprot;
  //rand bit [1:0]  htrans;
  //rand bit        hmastlock;
  //rand bit [31:0] hwdata;

  //rand bit        hreadyout;
  //rand bit [31:0] hrdata;

  //constraint c_haddr
  //{
  //  haddr[1:0] == 2'b0;
  //  haddr inside {[start_addr:stop_addr]};
  //}

  //constraint c_hsize
  //{
  //  hsize inside {[0:2]};
  //}

  //function new (input bit [31:0] start_addr, stop_addr; );
  //  this.start_addr = start_addr;
  //  this.stop_addr = stop_addr;
  //endfunction: new

  //function display();
  //  $write ("Ahb_config: start_addr = %0h, stop_addr = %0h", start_addr, stop_addr);
  //  $display();
  //endfunction: display

endclass: Ahb_config

function Ahb_config::new(input bit [7:0] masnum, slvnum);
  this.masnum = masnum;
  mas_in_use = new[masnum];
  this.slvnum = svlnum;
  n_cells_mas = new[masnum];
endfunction: new

function void Ahb_config::display(input string prefix="");
  $display("%sConfig: %0d masters, %0d slaves, %0d cells", prefix, masnum, slvnum, n_cells);
  foreach (mas_in_use[i])
  begin
    if(mas_in_use[i])
      $write("mas_in_use = %0d, cells = %0d", mas_in_use[i], n_cells_mas[i] || );
  end  
  $display(); 
endfunction: display
                  
