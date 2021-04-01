//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_cells.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////


//--------------------------------------------------------------------------------
//import ahb_package::*;
import AHB_package::*;
virtual class Basetrans;
  static int count = 0;        // Number of instances created
  int id;                  // Unique transaction id  

  function new();
    id = count++;
    $display("%t: id debug ......... %0d", $time, count);
  endfunction
//pure: no implementaion needed in base class
//      must be overridden in derived class
//compare  pure virtual function bit compare(input Basetrans to);
  pure virtual function Basetrans copy(input Basetrans to=null);
  pure virtual function void display(input string prefix="");

endclass: Basetrans

class Master extends Basetrans;

  bit [31:0] start_addr;
  bit [31:0] stop_addr;

  rand bit [31:0]   initial_haddr; 
  rand bit          hwrite;
  rand hsize_type   hsize;
  rand hburst_type  hburst;
  rand bit [3:0]    hprot;
  rand htrans_type  htrans;
  rand bit          hmastlock;
  rand bit [31:0]   hwdata;
  
  constraint c_hmastlock
  {
    hmastlock dist
    {
      0 := 9,
      1 := 1
    };
  }
  
  constraint c_haddr
  {
    initial_haddr[1:0] == 2'b0;
    initial_haddr inside {[start_addr:stop_addr]};
  }

  constraint c_hsize
  {
    hsize inside {[0:2]};
  }

  extern function new(input bit [31:0] start_addr, stop_addr); 
  extern function void display(input string prefix=""); 
  extern function compare(input Master to);
  extern virtual function void copy_data(input Master copy);
  //Hung mod 8_1_2021 extern virtual function Basetrans copy (input Basetrans to=null);   
  extern virtual function Master copy (input Basetrans to=null);   

endclass: Master

//--------------------------------------------------------------------------------

function Master::new (input bit [31:0] start_addr, stop_addr );
  this.start_addr = start_addr;
  this.stop_addr = stop_addr;
endfunction: new

//--------------------------------------------------------------------------------

function void Master::display(input string prefix="");
  $write ("Config: start_addr = %0h, stop_addr = %0h", start_addr, stop_addr);
  $display();
  $display("INFO: %s", prefix);
  $write("CELL_ID: %d", id);
  $display();
  $write ("Rand: initial_addr = %0h, hwrite = %0b, hsize = %0s, hburst = %0s, hprot = %0h, htrans = %0s, hmastlock = %b, hwdata = %0h", initial_haddr, hwrite, hsize, hburst,hprot, htrans, hmastlock, hwdata);
  $display();
endfunction: display 

//--------------------------------------------------------------------------------

function Master::compare(input Master to);
  if(this.hwrite    != to.hwrite)    return 0;
  if(this.hsize     != to.hsize)     return 0;
  if(this.hburst    != to.hburst)    return 0;
  if(this.hprot     != to.hprot)     return 0;
  if(this.htrans    != to.htrans)    return 0;
  if(this.hmastlock != to.hmastlock) return 0;
  if(this.hwdata    != to.hwdata)    return 0;
  return 1;
endfunction: compare

//--------------------------------------------------------------------------------

function void Master::copy_data(input Master copy);
  copy.start_addr =  this.start_addr;
  copy.stop_addr = this.stop_addr;
  copy.initial_haddr = this.initial_haddr; 
  copy.hwrite = this.hwrite;
  copy.hsize = this.hsize;
  copy.hburst = this.hburst;
  copy.hprot = this.hprot;
  copy.htrans = this.htrans;
  copy.hmastlock = this.hmastlock;
  copy.hwdata = this.hwdata;
endfunction: copy_data

//--------------------------------------------------------------------------------

//Hung mod 8_1_2021 function Basetrans Master::copy(input Basetrans to=null);
function Master Master::copy(input Basetrans to=null);
  Master dst;
  if(to == null) dst = new(this.start_addr, this.stop_addr);
  else           $cast(dst, to);
  copy_data(dst);
  return dst;
endfunction

//--------------------------------------------------------------------------------

class Slave;

  bit             hreadyout;
  rand bit        hresp;
  rand bit [31:0] hrdata;

  //constraint c_hreadyout;
  //{
  //  hreadyout dist 
  //  {
  //    0 := 1,
  //    1 := 9
  //  };
  //}

  constraint c_hresp
  {
    hresp dist
    {
      0 := 9,
      1 := 1
    };
  }

  extern function compare(input Slave to);
  extern function void display(input string prefix="");
  extern function void copy_data(input Slave copy);  
  extern function Slave copy(input Slave to=null);

endclass: Slave

//--------------------------------------------------------------------------------

function Slave::compare(input Slave to);
  if(this.hresp  != to.hresp) return 0;
  if(this.hrdata != to.hrdata) return 0; 
  return 1;
endfunction: compare


//--------------------------------------------------------------------------------

function void Slave::copy_data(input Slave copy);
  //copy.hreadyout = this.hreadyout;
  copy.hresp = this.hresp;
  copy.hrdata = this.hrdata;
endfunction: copy_data

//--------------------------------------------------------------------------------

function Slave Slave::copy(input Slave to=null);
  Slave dst;
  if(to == null) dst = new();
  else           $cast(dst, to);
  copy_data(dst);
  return dst;
endfunction: copy

//--------------------------------------------------------------------------------

function void Slave::display(
              //input int id, 
              input string prefix="");
  //$write("Config: hreadyout = %b, hresp = %b, hrdata = %h", hreadyout, hresp, hrdata);  
  $write("Config: hrdata = %h, hresp = %b", hrdata, hresp);  
  $display();
  //$write("SLV_ID: %d", id);
  $display("INFO: %s", prefix);
endfunction: display



















