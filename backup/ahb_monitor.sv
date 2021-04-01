//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_monitor.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_cells.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/config.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_interface.sv"

typedef class Mas_monitor;
//--------------------------------------------------------------------------------
 
class Mas_monitor_cbs;
  virtual task pre_rx( input Mas_monitor mmon,
                       input Slave       s);
  endtask: pre_rx

  virtual task post_rx( input Mas_monitor mmon,
                        input Slave      s);
  endtask: post_rx
endclass: Mas_monitor_cbs

//--------------------------------------------------------------------------------
 
class Mas_monitor;
  vmas_itf         mas;
  Mas_monitor_cbs cbsq[$];
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

//Hung mod 6_1_2021//--------------------------------------------------------------------------------
//Hung mod 6_1_2021
//Hung mod 6_1_2021task Mas_monitor::run();
//Hung mod 6_1_2021  Slave s;
//Hung mod 6_1_2021
//Hung mod 6_1_2021  //Hung db 2_1_2020
//Hung mod 6_1_2021  //s = new();
//Hung mod 6_1_2021  
//Hung mod 6_1_2021  forever begin
//Hung mod 6_1_2021    receive(s);
//Hung mod 6_1_2021    foreach(cbsq[i])
//Hung mod 6_1_2021      cbsq[i].post_rx(this, s);
//Hung mod 6_1_2021  end   
//Hung mod 6_1_2021  
//Hung mod 6_1_2021endtask: run
//Hung mod 6_1_2021
//Hung mod 6_1_2021//--------------------------------------------------------------------------------
//Hung mod 6_1_2021
//Hung mod 6_1_2021task  Mas_monitor::receive(output Slave s);
//Hung mod 6_1_2021  //Hung db 2_1_2020
//Hung mod 6_1_2021   s = new();
//Hung mod 6_1_2021
//Hung mod 6_1_2021   @(mas.master_cb.mas_out.hreadyout);
//Hung mod 6_1_2021   wait(mas.master_cb.mas_out.hreadyout);
//Hung mod 6_1_2021     //s.hreadyout <= 1'b1; 
//Hung mod 6_1_2021     //s.hresp <= mas.master_cb.mas_out.hresp;
//Hung mod 6_1_2021     //s.hrdata <= mas.master_cb.mas_out.hrdata; 
//Hung mod 6_1_2021     s.hreadyout = 1'b1; 
//Hung mod 6_1_2021     s.hresp = mas.master_cb.mas_out.hresp;
//Hung mod 6_1_2021     s.hrdata = mas.master_cb.mas_out.hrdata; 
//Hung mod 6_1_2021
//Hung mod 6_1_2021   s.display($sformatf("%t Master_Monitor (%0d) Receive", $time, portID)); 
//Hung mod 6_1_2021
//Hung mod 6_1_2021endtask: receive


//--------------------------------------------------------------------------------

task Mas_monitor::run();
  Slave s;

  //Hung db 2_1_2020
  //s = new();
  
  forever begin
    receive(s);
  end   
  
endtask: run

//--------------------------------------------------------------------------------

task  Mas_monitor::receive(output Slave s);
  //Hung db 2_1_2020
   s = new();

   @(mas.master_cb);
   //Hung db 8_1_2021 if(mas.master_cb.mas_out.hreadyout == 1'b1) begin
   wait(mas.master_cb.mas_out.hreadyout) begin 
   @(mas.master_cb);
   //Hung db 8_1_2021
     //s.hreadyout <= 1'b1; 
     //s.hresp <= mas.master_cb.mas_out.hresp;
     //s.hrdata <= mas.master_cb.mas_out.hrdata; 
     s.hreadyout = 1'b1; 
     s.hresp = mas.master_cb.mas_out.hresp;
     s.hrdata = mas.master_cb.mas_out.hrdata; 

     s.display($sformatf("%t Master_Monitor (%0d) Receive", $time, portID)); 
   
     foreach(cbsq[i])
       cbsq[i].post_rx(this, s);
   end
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
  Slv_monitor_cbs  cbsq[$];
  int              portID;

  extern function new( input vslv_itf slv,
                       input int      portID);
 
  extern task run();
  extern task receive(output Master m);

endclass: Slv_monitor

//--------------------------------------------------------------------------------

function Slv_monitor::new(
                    input vslv_itf slv,
                    input int      portID);
  this.slv = slv; 
  this.portID = portID;
endfunction: new

//Hung mod 6_1_2021//--------------------------------------------------------------------------------
//Hung mod 6_1_2021
//Hung mod 6_1_2021task Slv_monitor::run();
//Hung mod 6_1_2021  Master m;
//Hung mod 6_1_2021  //Hung db 2_1_2020
//Hung mod 6_1_2021  //m = new(32'h0, 32'hFFFF_FFFF);
//Hung mod 6_1_2021
//Hung mod 6_1_2021  forever begin
//Hung mod 6_1_2021    receive(m);
//Hung mod 6_1_2021    foreach(cbsq[i])
//Hung mod 6_1_2021      cbsq[i].post_rx(this, m);
//Hung mod 6_1_2021  end
//Hung mod 6_1_2021endtask: run
//Hung mod 6_1_2021
//Hung mod 6_1_2021//--------------------------------------------------------------------------------
//Hung mod 6_1_2021
//Hung mod 6_1_2021task Slv_monitor::receive(output Master m);
//Hung mod 6_1_2021  //Hung db 2_1_2020
//Hung mod 6_1_2021  m = new(32'h0, 32'hFFFF_FFFF);
//Hung mod 6_1_2021  
//Hung mod 6_1_2021  @(slv.slave_cb); 
//Hung mod 6_1_2021  wait(slv.slave_cb.hsel); 
//Hung mod 6_1_2021   //Hung 5_1_2020 m.initial_haddr <= slv.slave_cb.slv_out.haddr; 
//Hung mod 6_1_2021   //Hung 5_1_2020 m.hwrite <= slv.slave_cb.slv_out.hwrite;
//Hung mod 6_1_2021   //Hung 5_1_2020 m.hsize <= slv.slave_cb.slv_out.hsize;
//Hung mod 6_1_2021   //Hung 5_1_2020 m.hburst <= slv.slave_cb.slv_out.hburst;
//Hung mod 6_1_2021   //Hung 5_1_2020 m.hprot <= slv.slave_cb.slv_out.hprot;
//Hung mod 6_1_2021   //Hung 5_1_2020 m.htrans <= slv.slave_cb.slv_out.htrans;
//Hung mod 6_1_2021   //Hung 5_1_2020 m.hmastlock <= slv.slave_cb.slv_out.hmastlock;
//Hung mod 6_1_2021   //Hung 5_1_2020 m.hwdata <= slv.slave_cb.slv_out.hwdata;
//Hung mod 6_1_2021
//Hung mod 6_1_2021   m.initial_haddr = slv.slave_cb.slv_out.haddr; 
//Hung mod 6_1_2021   m.hwrite = slv.slave_cb.slv_out.hwrite;
//Hung mod 6_1_2021   m.hsize = slv.slave_cb.slv_out.hsize;
//Hung mod 6_1_2021   m.hburst = slv.slave_cb.slv_out.hburst;
//Hung mod 6_1_2021   m.hprot = slv.slave_cb.slv_out.hprot;
//Hung mod 6_1_2021   m.htrans = slv.slave_cb.slv_out.htrans;
//Hung mod 6_1_2021   m.hmastlock = slv.slave_cb.slv_out.hmastlock;
//Hung mod 6_1_2021   m.hwdata = slv.slave_cb.slv_out.hwdata;
//Hung mod 6_1_2021   m.display($sformatf("%t: Slave_Monitor (%0d) Receive", $time, portID));
//Hung mod 6_1_2021
//Hung mod 6_1_2021endtask: receive

//--------------------------------------------------------------------------------

task Slv_monitor::run();
  Master m;
  //Hung db 2_1_2020
  //m = new(32'h0, 32'hFFFF_FFFF);

  forever begin
    receive(m);
    //foreach(cbsq[i])
    //  cbsq[i].post_rx(this, m);
  end
endtask: run

//--------------------------------------------------------------------------------

task Slv_monitor::receive(output Master m);
  //Hung db 2_1_2020
  
  //@(slv.slave_cb); 
  //Hung db 8_1_2021 if(slv.slave_cb.hsel === 1'b1) begin
  wait(slv.slave_cb.hsel) begin
  //Hung db 8_1_2021 if(slv.slave_cb.hsel === 1'b1) begin
    @(slv.slave_cb); 
    m = new(32'h0, 32'hFFFF_FF);
    m.initial_haddr = slv.slave_cb.slv_out.haddr; 
    m.hwrite = slv.slave_cb.slv_out.hwrite;
    m.hsize = slv.slave_cb.slv_out.hsize;
    m.hburst = slv.slave_cb.slv_out.hburst;
    m.hprot = slv.slave_cb.slv_out.hprot;
    m.htrans = slv.slave_cb.slv_out.htrans;
    m.hmastlock = slv.slave_cb.slv_out.hmastlock;
    m.hwdata = slv.slave_cb.slv_out.hwdata;
    m.display($sformatf("%t: Slave_Monitor (%0d) Receive", $time, portID));
 
    foreach(cbsq[i])
      cbsq[i].post_rx(this, m);
  end  
endtask: receive
