//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_driver.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////


//--------------------------------------------------------------------------------
typedef class Mas_driver;

class Mas_driver_cbs;
  virtual task pre_tx(
    input Mas_driver drv,
    input Master m
  );
  endtask

  virtual task post_tx(
    input Mas_driver drv,
    input Master m
  );
  endtask

endclass: Mas_driver_cbs  

class Mas_driver;
  mailbox mas_gen2drv;
  event   mas_drv2gen;
  mas_itf mas;
  Mas_driver_cbs cbsq[$]; //queue of callback objects
  int portID;

  extern function new(
    input mailbox mas_gen2drv,
    input event   mas_drv2gen,
    input mas_itf mas,
    input int portID
  );

  extern task run();
  extern task send(input Master m);

endclass: Mas_driver

function Mas_driver::new(
    input mailbox mas_gen2drv,
    input event   mas_drv2gen,
    input mas_itf mas,
    input int portID
  );
    this.mas_gen2drv = mas_gen2drv;
    this.mas_drv2gen = mas_drv2gen;
    this.mas = mas;
    this.portID = portID;
endfunction: new

task Mas_driver::run();
  Master m;

  //Initial 
  mas.master_cb.haddr <= '0;
  mas.master_cb.hwrite <= '0;
  mas.master_cb.hsize <= '0;
  mas.master_cb.hburst <= '0;
  mas.master_cb.hprot <= '0;
  mas.master_cb.htrans <= '0;
  mas.master_cb.hmastlock <= '0;
  mas.master_cb.hwdata <= '0;

  forever begin
    //Read from mailbox
    mas_gen2drv.peek(m);
    begin: mas_tx
      foreach(cbsq[i]) begin
        cbsq[i].pre_tx(this, m);
        if(m.hmastlock) disable mas_tx;
      end
      
      m.display($sformatf("%t: %0d"), $time, portID);
      send(m);
  
      foreach (cbsq[i]) begin
        cbsq[i].post_tx(this, m);
    end

    mas_gen2drv.get(m);
    -> mas_drv2gen;
  end

endtask: run

//--------------------------------------------------------------------------------
typedef class Slv_driver;

class Slv_driver_cbs;
  virtual task pre_tx(
    input Slv_driver drv,
    input Slave      s 
  );
  endtask

  virtual task post_tx(
    input Slv_driver drv,
    input Slave      s
  );
  endtask

endclass: Slv_driver_cbs

class Slv_driver;
  mailbox         slv_gen2drv;
  event           slv_drv2gen;  
  slave_itf       slv;
  Slv_driver_cbs  cbsq;
  int             portID;

  extern function new (
    input mailbox   slv_gen2drv,
    input event     slv_drv2gen,
    input slave_itf slv,
    input int       portID
  );

  extern task run;
  extern task send(input Slave s);
endclass: Slv_driver


