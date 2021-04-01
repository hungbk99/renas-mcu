class Slave;
  
  bit [31:0] haddr;

  bit        hwrite;
  bit [2:0]  hsize;
  bit [2:0]  hburst;
  bit [3:0]  hprot;
  bit [1:0]  htrans;
  bit        hmastlock;
  bit [31:0] hwdata;

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
