//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_requestor.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////


//--------------------------------------------------------------------------------
import ahb_package::*;
virtual class Basereq;
  static int count;
  int id;

  function new();
    id = count++;
  endfunction

endclass: basereq

class Master extends Basereq;

  bit [31:0] start_addr;
  bit [31:0] stop_addr;

  rand bit [31:0]   initial_haddr; 
  rand bit          hwrite;
  rand hsize_rtype  hsize;
  rand hburst_rtype hburst;
  rand bit [3:0]    hprot;
  bit htrans_rtype  htrans;
  rand bit          hmastlock;
  rand bit [31:0]   hwdata;
  
  constraint c_hmastlock;
  {
    hmastlock dist
    {
      0 := 9,
      1 := 1
    }
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

  function new (input bit [31:0] start_addr, stop_addr; );
    this.start_addr = start_addr;
    this.stop_addr = stop_addr;
  endfunction: new

  function display(input string data);
    $write ("Config: start_addr = %0h, stop_addr = %0h", start_addr, stop_addr);
    $display("INFO: %s", data);
    $write("MAS_ID: %d", id);
    $display();
    $write ("Rand: initial_addr = %0h, hwrite = %0b, hsize = %0h, hburst = %0h, hprot = %0h, " \
          "htrans = %0h, hmastlock = %b, hwdata = %0h", initial_haddr, hwrite, hsize, hburst,  \
            hprot, htrans, hmastlock, hwdata);
    $display();
  endfunction: display 

  extern virtual function void Master copy_data(input Master copy);
  extern virtual function Master copy (input Master to);   

endclass: Master

//--------------------------------------------------------------------------------

function void Master Master::copy_data(input Master copy);
  copy.start_addr =  this.start_addr;
  copy.stop_addr = this.stop_addr;
  copy.initial_haddr = this.initial_haddr; 
  copy.hwrite = this.hwrite;
  copy.hsize = this.hsize;
  copy.hburst = this.hburst;
  copy.hprot = this.prot;
  copy.htrans = this.htrans;
  copy.hmastlock = this.hmastlock;
  copy.hwdata = this.hwdata;
endfunction: copy

function Master::copy(input Master to);
  Master dst;
  if(to == null) dst = new();
  else           $cast(dst, to);
  copy_data(dst);
  return dst;
endfunction

//--------------------------------------------------------------------------------

class Slave;

  //rand bit        hreadyout;
  //rand bit        hresp;
  rand bit [31:0] hrdata;

  //constraint c_hreadyout;
  //{
  //  hreadyout dist 
  //  {
  //    0 := 1,
  //    1 := 9
  //  };
  //}

  //constraint c_hresp;
  //{
  //  hresp dist
  //  {
  //    0 := 9,
  //    1 := 1
  //  }
  //}

  function display(
                //input int id, 
                input string data);
    //$write("Config: hreadyout = %b, hresp = %b, hrdata = %h", hreadyout, hresp, hrdata);  
    $write("Config: hrdata = %h", hrdata);  
    //$write("SLV_ID: %d", id);
    $display("INFO: %s", data);
  endfunction: display

  extern function void Slave copy_data(input Slave copy);  
  extern function Slave copy(input Slave to);

endclass: Slave

//--------------------------------------------------------------------------------

function void Slave::copy_data(input Slave copy)
  //copy.hreadyout = this.hreadyout;
  //copy.hresp = this.hresp;
  copy.hrdata = this.hrdata;
endfunction: copy_data

//--------------------------------------------------------------------------------

function Slave::copy(input Slave to)
  Slave dst;
  if(to == null) dst = new();
  else           $cast(dst, to);
  copy_data(dst);
  return(dst);
endfunction: copy




















