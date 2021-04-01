class Config;
  bit [31:0] start_addr;
  bit [31:0] stop_addr;

  rand bit [31:0] haddr; 
  rand bit        hwrite;
  rand bit [2:0]  hsize;
  rand bit [2:0]  hburst;
  rand bit [3:0]  hprot;
  rand bit [1:0]  htrans;
  rand bit        hmastlock;
  rand bit [31:0] hwdata;

  rand bit        hreadyout;
  rand bit [31:0] hrdata;

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

  function display();
    $write ("Config: start_addr = %0h, stop_addr = %0h", start_addr, stop_addr);
    $display();
  endfunction: display

endclass: Config
