//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_monitor.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

typedef class Mas_monitor;
//--------------------------------------------------------------------------------
 
class Mas_monitor_cbs;
  virtual task pre_tx( input Ahb_monitor mmon,
                       input Slave       s);
  endtask: pre_tx

  virtual task post_tx( input Ahb_monitor mmon,
                        input Slave      s);
  endtask: post_tx
endclass: Mas_monitor_cbs

//--------------------------------------------------------------------------------
 
class Mas_monitor;
  vmas_itf         mas;
  Mas_monitor_cbs  cbsq[$];
  int              portID;

  extern function new( input vmas_itf mas,
                       input int      portID);  

  extern task run();
  extern task receive(output Slave s);

endclass: Mas_monitor

//--------------------------------------------------------------------------------

function Mas_monitor::new(
                       input vmas_itf mas, 
                       input int      portID); 
  this.mas = mas;
  this.portID = portID;
endfunction

//--------------------------------------------------------------------------------

task Mas_monitor::run();
  Slave s;

  forever begin
    receive(s);
    foreach(cbsq[i])
      cbsq[i].post_tx(this, s)
  end   
  
endtask: run

//--------------------------------------------------------------------------------

task  Mas_monitor::receive(output Slave s)
   s = new();

   @(mas.mas_in.hreadyout); 
     s.hresp <= mas.mas_in.hresp;
     s.hrdata <= mas.mas_in.hrdata; 

   s.display($sformatf("%t Master_Monitor %d", $time, portID)); 

endtask: receive

//--------------------------------------------------------------------------------

typedef class Slv_monitor;

class Slv_monitor_cbs;
  virtual task pre_rx( input Slv_monitor smon,
                       input Master       m);
  endtask: pre_rx

  virtual task post_rx( input Slv_monitor smon,
                        input Master       m);  
  endtask: post_rx

endclass: Slv_monitor_cbs

//--------------------------------------------------------------------------------

class Slv_monitor;
  vslv_itf         slv;
  Slv_monitor_cbs cbsq[$];
  int              portID;

  extern function new( input vslv_itf slv,
                       input int      portID);
 
  extern task run();
  exterm task receive(Master m);

endclass: Slv_monitor

//--------------------------------------------------------------------------------

function Slv_monitor::new(
                    input vslv_itf slv,
                    input int      portID);
  this.slv = slv; 
  this.portID = portID;
endfunction: new

//--------------------------------------------------------------------------------

task Slv_monitor::run();
  Master m;

  forever begin
    receive(m);
    foreach(cbsq[i])
      cbsq[i].post_rx(this, m);
  end
endtask: run

//--------------------------------------------------------------------------------

task Slv_monitor::receive(Master m);
  m = new();
  
  @(slv.slv_in.hsel); 
    m.initial_haddr <= slv.slv_in.haddr; 
    m.hwrite <= slv.slv_in.hwrite;
    m.hsize <= slv.slv_in.hsize;
    m.hburst <= slv.slv_in.hburst;
    m.hprot <= slv.slv_in.hprot;
    m.htrans <= slv.slv_in.htrans;
    m.hmastlock <= slv.slv_in.hmastlock;
    m.hwdata <= slv.slv_in.hwdata;

 m.display($sformatf("%t: Slave_Monitor %0d", $time, portID));

endtask: receive
