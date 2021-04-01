//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_requestor.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////


//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------

class Master;

  bit [31:0] start_addr;
  bit [31:0] stop_addr;
  bit [31:0] haddr;

  rand bit [31:0] initial_haddr; 
  rand bit        hwrite;
  rand bit [2:0]  hsize;
  rand bit [2:0]  hburst;
  rand bit [3:0]  hprot;
  rand bit [1:0]  htrans;
  rand bit        hmastlock;
  rand bit [31:0] hwdata;

  //bit        hready;
  //bit        hresp;
  //bit [31:0] hrdata;
  
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
    haddr[1:0] == 2'b0;
    haddr inside {[start_addr:stop_addr]};
  }

  constraint c_hsize
  {
    hsize inside {[0:2]};
  }

  function new (input bit [31:0] start_addr, stop_addr; );
    this.start_addr = start_addr;
    this.stop_addr = stop_addr;
  endfunction: new

  function display(input string id);
    $write ("Config: start_addr = %0h, stop_addr = %0h", start_addr, stop_addr);
    $display();
    $write("MAS_ID: %s", id);
    $display();
    $write ("Rand: initial_addr = %0h, hwrite = %0b, hsize = %0h, hburst = %0h, hprot = %0h, " \
          "htrans = %0h, hmastlock = %b, hwdata = %0h", initial_haddr, hwrite, hsize, hburst,  \
            hprot, htrans, hmastlock, hwdata);
    $display();
  endfunction: display

endclass: Master

//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------

class Slave;
  
  //bit [31:0] haddr;

  //bit        hwrite;
  //bit [2:0]  hsize;
  //bit [2:0]  hburst;
  //bit [3:0]  hprot;
  //bit [1:0]  htrans;
  //bit        hmastlock;
  //bit [31:0] hwdata;

  rand bit        hreadyout;
  rand bit        hresp;
  rand bit [31:0] hrdata;

  constraint c_hreadyout;
  {
    hreadyout dist 
    {
      0 := 1,
      1 := 9
    };
  }

  constraint c_hresp;
  {
    hresp dist
    {
      0 := 9,
      1 := 1
    }
  }

endclass: Slave
