//////////////////////////////////////////////////////////////////////////////////
// File Name: 		ahb_driver.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date       Author      Description
// v0.0       02/10/2020 Quang Hung First Creation
//            12/01/2021 Quang Hung Add support for decode error
//////////////////////////////////////////////////////////////////////////////////

//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_cells.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/config.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_interface.sv"

//--------------------------------------------------------------------------------
typedef class  Mas_driver;

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

  virtual task dec_error(
    input Mas_driver drv,
    input Master      m);
  endtask: dec_error

endclass: Mas_driver_cbs  

//--------------------------------------------------------------------------------

class Mas_driver;
  mailbox mas_gen2drv;
  event   mas_drv2gen;
  vmas_itf mas;
  Mas_driver_cbs cbsq[$]; //queue of callback objects
  Config  cfg;
  int portID;

  extern function new(
    input mailbox  mas_gen2drv,
    input event    mas_drv2gen,
    input vmas_itf mas,
    input Config   cfg,
    input int      portID
  );

  extern task run();
  extern task send(input Master m);

endclass: Mas_driver

//--------------------------------------------------------------------------------

function Mas_driver::new(
    input mailbox  mas_gen2drv,
    input event    mas_drv2gen,
    input vmas_itf mas,
    input Config   cfg,
    input int      portID
  );
    this.mas_gen2drv = mas_gen2drv;
    this.mas_drv2gen = mas_drv2gen;
    this.cfg = cfg;
    this.mas = mas;
    this.portID = portID;
endfunction: new

//--------------------------------------------------------------------------------

task Mas_driver::run();
  //import ahb_package::*;
  import AHB_package::*;
  Master m;

    $display("%t: Driver debug ......", $time);
  //Initial 
  mas.master_cb.mas_in.haddr <= '0;
  mas.master_cb.mas_in.hwrite <= '0;
  mas.master_cb.mas_in.hsize <= WORD;
  mas.master_cb.mas_in.hburst <= SINGLE;
  mas.master_cb.mas_in.hprot <= '0;
  mas.master_cb.mas_in.htrans <= IDLE;
  mas.master_cb.mas_in.hmastlock <= '0;
  mas.master_cb.mas_in.hwdata <= '0;

  //dbx mas.master_cb.mas_in.haddr = '0;
  //dbx mas.master_cb.mas_in.hwrite = '0;
  //dbx mas.master_cb.mas_in.hsize = WORD;
  //dbx mas.master_cb.mas_in.hburst = SINGLE;
  //dbx mas.master_cb.mas_in.hprot = '0;
  //dbx mas.master_cb.mas_in.htrans = IDLE;
  //dbx mas.master_cb.mas_in.hmastlock = '0;
  //dbx mas.master_cb.mas_in.hwdata = '0;
  mas.master_cb.prio <= cfg.prior[portID];
  //Hung db 6_1_2021 $display("***************************************************");
  //Hung db 6_1_2021 $display("Initial value");
  //Hung db 6_1_2021 $display("haddr:%h", mas.master_cb.mas_in.haddr);
  //Hung db 6_1_2021 $display("hwrite:%h", mas.master_cb.mas_in.hwrite);
  //Hung db 6_1_2021 $display("hsize:%s", mas.master_cb.mas_in.hsize);
  //Hung db 6_1_2021 $display("hburst:%s", mas.master_cb.mas_in.hburst);
  //Hung db 6_1_2021 $display("hprot:%h", mas.master_cb.mas_in.hprot);
  //Hung db 6_1_2021 $display("htrans:%s", mas.master_cb.mas_in.htrans);
  //Hung db 6_1_2021 $display("hmastlock:%h", mas.master_cb.mas_in.hmastlock);
  //Hung db 6_1_2021 $display("hwdata:%h", mas.master_cb.mas_in.hwdata);
  //Hung db 6_1_2021 $display("prior:%h", mas.master_cb.prio);
  //Hung db 6_1_2021 $display("***************************************************");
  
  forever begin
    //Read from mailbox
    mas_gen2drv.peek(m);
    begin: mas_tx
      foreach(cbsq[i]) begin
        cbsq[i].pre_tx(this, m);
        //if(m.hmastlock) disable mas_tx;
      end
      
    //$display("%t: Driver debug ......", $time);
      m.display($sformatf("%t: %0d", $time, portID));
      send(m);
    //$display("%t: Driver debug ......", $time);
  
      //foreach (cbsq[i]) 
      //  cbsq[i].post_tx(this, m);
    end
    //$display("%t: Driver debug ......", $time);

    mas_gen2drv.get(m);
    -> mas_drv2gen;
    //$display("%t: Driver debug ......", $time);
  end

endtask: run

//--------------------------------------------------------------------------------
// hwdata is portID: this help to do the check_actual in monitor
//--------------------------------------------------------------------------------

task Mas_driver::send(input Master m);
  //import ahb_package::*;
  import AHB_package::*;
  //Master package;
  Master fix;
  int num;
  bit [31:0] wrap_addr, limit_addr;
  $display("Master sendinggg.....");
  $display("Package fixing.......");
  mas.master_cb.mas_in.haddr <= m.initial_haddr;
  //dbx mas.master_cb.mas_in.haddr = m.initial_haddr;

  //mas.master_cb.mas_out.hwdata <= m.hwdata;
  mas.master_cb.mas_in.hwdata <= portID;
  //dbx mas.master_cb.mas_in.hwdata = portID;
  case(m.hburst)
    SINGLE, INCR: num = 1;
    WRAP4, INCR4:
    begin 
      num = 4;
      wrap_addr = m.initial_haddr & ('1 << (m.hsize + 2));
      limit_addr = wrap_addr + 2**(m.hsize)*3; 
    end
    WRAP8, INCR8: 
    begin
      num = 8;
      wrap_addr = m.initial_haddr & ('1 << (m.hsize + 3)); 
      limit_addr = wrap_addr + 2**(m.hsize)*7; 
    end
    WRAP16, INCR16:
    begin
      num = 16;
      wrap_addr = m.initial_haddr & ('1 << (m.hsize + 4)); 
      limit_addr = wrap_addr + 2**(m.hsize)*15; 
    end
  endcase

  $display("wrap addr: %h | limit addr: %h", wrap_addr, limit_addr);

  //fix = new();
  fix = m;
  fix.hwdata = portID;
  mas.master_cb.mas_in.haddr <= fix.initial_haddr;
  mas.master_cb.mas_in.hwrite <= fix.hwrite;
  mas.master_cb.mas_in.hsize <= fix.hsize;
  mas.master_cb.mas_in.hburst <= fix.hburst;
  mas.master_cb.mas_in.hprot <= fix.hprot;
  //mas.master_cb.mas_in.htrans <= fix.htrans;
  mas.master_cb.mas_in.hmastlock <= fix.hmastlock;
  mas.master_cb.mas_in.hwdata <= fix.hwdata;
  
  //dbx mas.master_cb.mas_in.haddr = fix.initial_haddr;
  //dbx mas.master_cb.mas_in.hwrite = fix.hwrite;
  //dbx mas.master_cb.mas_in.hsize = fix.hsize;
  //dbx mas.master_cb.mas_in.hburst = fix.hburst;
  //dbx mas.master_cb.mas_in.hprot = fix.hprot;
  //dbx //mas.master_cb.mas_in.htrans <= fix.htrans;
  //dbx mas.master_cb.mas_in.hmastlock = fix.hmastlock;
  //dbx mas.master_cb.mas_in.hwdata = fix.hwdata;
   
//Hung mod 6_1_2021  //Hung mod 6_1_2021   
//Hung mod 6_1_2021  @(mas.master_cb);
//Hung mod 6_1_2021  
//Hung mod 6_1_2021  for(int i = 0; i < num; i++)  
//Hung mod 6_1_2021  begin
//Hung mod 6_1_2021    //$display("============================================================================================================");
//Hung mod 6_1_2021    //$display("Transfer.... [%0d]", i);
//Hung mod 6_1_2021    if(i == 0) begin
//Hung mod 6_1_2021      mas.master_cb.mas_in.htrans <= NONSEQ; 
//Hung mod 6_1_2021      //dbx mas.master_cb.mas_in.htrans = NONSEQ; 
//Hung mod 6_1_2021      fix.htrans = NONSEQ;
//Hung mod 6_1_2021      //dbx mas.master_cb.mas_in.haddr = fix.initial_haddr;
//Hung mod 6_1_2021      mas.master_cb.mas_in.haddr <= fix.initial_haddr;
//Hung mod 6_1_2021      $display("DBBBBB.... [%0d]", i);
//Hung mod 6_1_2021    end
//Hung mod 6_1_2021    else begin
//Hung mod 6_1_2021      //@(mas.master_cb.mas_out.hreadyout);
//Hung mod 6_1_2021        mas.master_cb.mas_in.htrans <= SEQ; 
//Hung mod 6_1_2021        //dbx mas.master_cb.mas_in.htrans = SEQ; 
//Hung mod 6_1_2021        fix.htrans = SEQ;
//Hung mod 6_1_2021      //Hung mod 31_12_2020
//Hung mod 6_1_2021      //Hung mod 6_1_2021 if(((m.hburst == WRAP4) || (m.hburst == WRAP8) || (m.hburst == WRAP16)) && (mas.master_cb.mas_in.haddr == limit_addr))
//Hung mod 6_1_2021      //Sampling of clocking block output is not allowed
//Hung mod 6_1_2021      if(((m.hburst == WRAP4) || (m.hburst == WRAP8) || (m.hburst == WRAP16)) && (fix.initial_haddr == limit_addr))
//Hung mod 6_1_2021      begin
//Hung mod 6_1_2021        //dbx mas.master_cb.mas_in.haddr = wrap_addr;
//Hung mod 6_1_2021        mas.master_cb.mas_in.haddr <= wrap_addr;
//Hung mod 6_1_2021        fix.initial_haddr = wrap_addr;
//Hung mod 6_1_2021      end
//Hung mod 6_1_2021      else begin
//Hung mod 6_1_2021        //Hung mod 6_1_2021 mas.master_cb.mas_in.haddr <= mas.master_cb.mas_in.haddr + 2**(m.hsize);
//Hung mod 6_1_2021        mas.master_cb.mas_in.haddr <= fix.initial_haddr + 2**(m.hsize);
//Hung mod 6_1_2021        //dbx mas.master_cb.mas_in.haddr = mas.master_cb.mas_in.haddr + 2**(m.hsize);
//Hung mod 6_1_2021        //Hung mod 6_1_2021 fix.initial_haddr = mas.master_cb.mas_in.haddr + 2**(m.hsize);
//Hung mod 6_1_2021        fix.initial_haddr = fix.initial_haddr + 2**(m.hsize);
//Hung mod 6_1_2021      end    
//Hung mod 6_1_2021      $display("DBBBBB.... [%0d]", i);
//Hung mod 6_1_2021    end 
//Hung mod 6_1_2021  
//Hung mod 6_1_2021
//Hung mod 6_1_2021    //if(((m.hburst == WRAP4) || (m.hburst == WRAP8) || (m.hburst == WRAP16)) && (mas.master_cb.mas_in.haddr == limit_addr))
//Hung mod 6_1_2021    //begin
//Hung mod 6_1_2021    //  mas.master_cb.mas_in.haddr <= wrap_addr;
//Hung mod 6_1_2021    //  fix.initial_haddr = wrap_addr;
//Hung mod 6_1_2021    //end
//Hung mod 6_1_2021    //else begin
//Hung mod 6_1_2021    //  mas.master_cb.mas_in.haddr <= mas.master_cb.mas_in.haddr + 2**(m.hsize);
//Hung mod 6_1_2021    //  fix.initial_haddr = mas.master_cb.mas_in.haddr + 2**(m.hsize);
//Hung mod 6_1_2021    //end    
//Hung mod 6_1_2021    //mas.master_cb.mas_out.hwdata <= mas.master_cb.mas_out.hwdata + 1;
//Hung mod 6_1_2021    
//Hung mod 6_1_2021    //fix.initial_haddr = mas.master_cb.mas_in.haddr;
//Hung mod 6_1_2021
//Hung mod 6_1_2021    //Hung mod 6_1_2021 //put data in Mas_scoreboard
//Hung mod 6_1_2021    //Hung mod 6_1_2021 foreach (cbsq[i]) begin
//Hung mod 6_1_2021    //Hung mod 6_1_2021   cbsq[i].post_tx(this, fix);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("%t: Driver (Master) Callback ...... cbsq_size=%0d, i=%0d", $time, cbsq.size(), i);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 end
//Hung mod 6_1_2021    //$display("%t: Driver debug ......", $time);
//Hung mod 6_1_2021      
//Hung mod 6_1_2021    @(mas.master_cb);
//Hung mod 6_1_2021    wait(mas.master_cb.mas_out.hreadyout);
//Hung mod 6_1_2021    $display("============================================================================================================");
//Hung mod 6_1_2021    $display("Transfer.... [%0d]", i);
//Hung mod 6_1_2021    $display("***************************************************");
//Hung mod 6_1_2021    //$display("%0d transfer.... [%0d]", i);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("Send value");
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("haddr:%h", mas.master_cb.mas_in.haddr);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("hwrite:%h", mas.master_cb.mas_in.hwrite);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("hsize:%s", mas.master_cb.mas_in.hsize);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("hburst:%s", mas.master_cb.mas_in.hburst);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("hprot:%h", mas.master_cb.mas_in.hprot);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("htrans:%s", mas.master_cb.mas_in.htrans);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("hmastlock:%h", mas.master_cb.mas_in.hmastlock);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("hwdata:%h", mas.master_cb.mas_in.hwdata);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("prior:%h", mas.master_cb.prio);
//Hung mod 6_1_2021    $display("Send value");
//Hung mod 6_1_2021    $display("haddr:%h", m.initial_haddr);
//Hung mod 6_1_2021    $display("hwrite:%h", m.hwrite);
//Hung mod 6_1_2021    $display("hsize:%s", m.hsize);
//Hung mod 6_1_2021    $display("hburst:%s", m.hburst);
//Hung mod 6_1_2021    $display("hprot:%h", m.hprot);
//Hung mod 6_1_2021    $display("htrans:%s", m.htrans);
//Hung mod 6_1_2021    $display("hmastlock:%h", m.hmastlock);
//Hung mod 6_1_2021    $display("hwdata:%h", m.hwdata);
//Hung mod 6_1_2021    $display("prior:%h", cfg.prior[portID]);
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("***************************************************");
//Hung mod 6_1_2021    //Hung mod 6_1_2021 $display("%t: Doneeeee ......", $time);
//Hung mod 6_1_2021    //put data in Mas_scoreboard
//Hung mod 6_1_2021    foreach (cbsq[i]) begin
//Hung mod 6_1_2021      cbsq[i].post_tx(this, fix);
//Hung mod 6_1_2021    $display("%t: Driver (Master) Callback ...... cbsq_size=%0d, i=%0d", $time, cbsq.size(), i);
//Hung mod 6_1_2021    end
//Hung mod 6_1_2021  end
//Hung mod 6_1_2021 
//Hung mod 6_1_2021    //$display("%t: Driver debug ......", $time);
//Hung mod 6_1_2021endtask: send

  //Hung mod 6_1_2021   
  
  for(int i = 0; i < num;) 
  begin
    @(mas.master_cb);
    //Hung_mod_12_1_2021
    if(mas.master_cb.mas_out.hresp) begin
      foreach (cbsq[i]) 
        cbsq[i].dec_error(this, fix);
      mas.master_cb.mas_in.htrans <= IDLE;
    $display("============================================================================================================");
    $display("Transfer.... [%0d]", i);
      $display("****************************************************"); 
      $display("%t:[INFO]:[ERROR RESPONSE][D]: received in Master[%0d]", $time, portID); 
      $display("****************************************************"); 
      break; 
    end 
    else
    //Hung_mod_12_1_2021
    if(i == 0) begin
      mas.master_cb.mas_in.htrans <= NONSEQ; 
      //dbx mas.master_cb.mas_in.htrans = NONSEQ; 
      fix.htrans = NONSEQ;
      //dbx mas.master_cb.mas_in.haddr = fix.initial_haddr;
      mas.master_cb.mas_in.haddr <= fix.initial_haddr;
      //$display("DBBBBB.... [%0d]", i);
      
      //Hung_db_12_1_2021
      if(num == 1) begin
        $display("============================================================================================================");
          //put data in Mas_scoreboard
          ////Hung mod 8_1_2021
          //@(mas.master_cb);
          foreach (cbsq[i]) begin
            cbsq[i].post_tx(this, fix);
          $display("%t: Driver (Master) Callback ...... cbsq_size=%0d, i=%0d", $time, cbsq.size(), i);
          end
        $display("============================================================================================================");
        $display("Transfer.... [%0d]", i);
        $display("***************************************************");
        $display("Send value");
        $display("haddr:%h", m.initial_haddr);
        $display("hwrite:%h", m.hwrite);
        $display("hsize:%s", m.hsize);
        $display("hburst:%s", m.hburst);
        $display("hprot:%h", m.hprot);
        $display("htrans:%s", m.htrans);
        $display("hmastlock:%h", m.hmastlock);
        $display("hwdata:%h", m.hwdata);
        $display("prior:%h", cfg.prior[portID]);
        $display("============================================================================================================");
        @(mas.master_cb);
        //Hung_db_15_1_2021 wait(mas.master_cb.mas_out.hreadyout);
        wait(mas.master_cb.mas_out.hreadyout || mas.master_cb.mas_out.hresp);
        mas.master_cb.mas_in.htrans <= IDLE;
        if(mas.master_cb.mas_out.hresp) begin
          foreach (cbsq[i]) 
            cbsq[i].dec_error(this, fix);
        end
        break;
      end
      //Hung_db_12_1_2021

    $display("============================================================================================================");
      //put data in Mas_scoreboard
      foreach (cbsq[i]) begin
        cbsq[i].post_tx(this, fix);
      $display("%t: Driver (Master) Callback ...... cbsq_size=%0d, i=%0d", $time, cbsq.size(), i);
      end
    $display("============================================================================================================");
    $display("Transfer.... [%0d]", i);
    $display("***************************************************");
    $display("Send value");
    $display("haddr:%h", m.initial_haddr);
    $display("hwrite:%h", m.hwrite);
    $display("hsize:%s", m.hsize);
    $display("hburst:%s", m.hburst);
    $display("hprot:%h", m.hprot);
    $display("htrans:%s", m.htrans);
    $display("hmastlock:%h", m.hmastlock);
    $display("hwdata:%h", m.hwdata);
    $display("prior:%h", cfg.prior[portID]);
    $display("============================================================================================================");
      i++;  
    end
    else if(mas.master_cb.mas_out.hreadyout)
    begin
      //@(mas.master_cb.mas_out.hreadyout);
        mas.master_cb.mas_in.htrans <= SEQ; 
        //dbx mas.master_cb.mas_in.htrans = SEQ; 
        fix.htrans = SEQ;
      //Hung mod 31_12_2020
      //Hung mod 6_1_2021 if(((m.hburst == WRAP4) || (m.hburst == WRAP8) || (m.hburst == WRAP16)) && (mas.master_cb.mas_in.haddr == limit_addr))
      //Sampling of clocking block output is not allowed
      if(((m.hburst == WRAP4) || (m.hburst == WRAP8) || (m.hburst == WRAP16)) && (fix.initial_haddr == limit_addr))
      begin
        //dbx mas.master_cb.mas_in.haddr = wrap_addr;
        mas.master_cb.mas_in.haddr <= wrap_addr;
        fix.initial_haddr = wrap_addr;
      end
      else begin
        //Hung mod 6_1_2021 mas.master_cb.mas_in.haddr <= mas.master_cb.mas_in.haddr + 2**(m.hsize);
        mas.master_cb.mas_in.haddr <= fix.initial_haddr + 2**(m.hsize);
        //dbx mas.master_cb.mas_in.haddr = mas.master_cb.mas_in.haddr + 2**(m.hsize);
        //Hung mod 6_1_2021 fix.initial_haddr = mas.master_cb.mas_in.haddr + 2**(m.hsize);
        fix.initial_haddr = fix.initial_haddr + 2**(m.hsize);
      end    

    $display("============================================================================================================");
      //put data in Mas_scoreboard
      ////Hung mod 8_1_2021
      //@(mas.master_cb);
      foreach (cbsq[i]) begin
        cbsq[i].post_tx(this, fix);
      $display("%t: Driver (Master) Callback ...... cbsq_size=%0d, i=%0d", $time, cbsq.size(), i);
      end
    $display("============================================================================================================");
    $display("Transfer.... [%0d]", i);
    $display("***************************************************");
    $display("Send value");
    $display("haddr:%h", m.initial_haddr);
    $display("hwrite:%h", m.hwrite);
    $display("hsize:%s", m.hsize);
    $display("hburst:%s", m.hburst);
    $display("hprot:%h", m.hprot);
    $display("htrans:%s", m.htrans);
    $display("hmastlock:%h", m.hmastlock);
    $display("hwdata:%h", m.hwdata);
    $display("prior:%h", cfg.prior[portID]);
    $display("============================================================================================================");
      i++;  
      $display("DBBBBB.... [%0d]", i);
    end 
  
    //Hung mod 6_1_2021 $display("***************************************************");
    //Hung mod 6_1_2021 $display("%t: Doneeeee ......", $time);
  end

  //Hung mod 8_1_2021
  /*
  force output of each masters after transfering data into IDLE state 
  if not, old value will remain on the output of each masters
  as a result, hsel will be grant all the time
  */
  //Initial 
  @(mas.master_cb);
  mas.master_cb.mas_in.haddr <= '0;
  mas.master_cb.mas_in.hwrite <= '0;
  mas.master_cb.mas_in.hsize <= WORD;
  mas.master_cb.mas_in.hburst <= SINGLE;
  mas.master_cb.mas_in.hprot <= '0;
  mas.master_cb.mas_in.htrans <= IDLE;
  mas.master_cb.mas_in.hmastlock <= '0;
  mas.master_cb.mas_in.hwdata <= '0;
  $display("%t: Driver (Master) Clear ......", $time);
  //Hung mod 8_1_2021
endtask: send

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

//--------------------------------------------------------------------------------

class Slv_driver;
  mailbox         slv_gen2drv;
  event           slv_drv2gen;  
  vslv_itf        slv;
  Slv_driver_cbs  cbsq[$];
  int             portID;
  //Hung_mod_11_1_2021
  int             num, cnt;
  //Hung_mod_11_1_2021

  extern function new (
    input mailbox   slv_gen2drv,
    input event     slv_drv2gen,
    input vslv_itf  slv,
    input int       portID
  );

  extern task run;
  extern task send(input Slave s);
endclass: Slv_driver

//--------------------------------------------------------------------------------

function Slv_driver::new(
                input mailbox    slv_gen2drv,
                input event      slv_drv2gen,
                input vslv_itf   slv,
                input int        portID
                );
  this.slv_gen2drv = slv_gen2drv;
  this.slv_drv2gen = slv_drv2gen;
  this.slv         = slv;
  this.portID      = portID;
endfunction: new

//--------------------------------------------------------------------------------
task Slv_driver::run();
  Slave s;
  
  $display("***************************************");
   // $display("%t: Driver debug ......", $time);
  //Initial 
  //Hung mod 6_1_2021 slv.slave_cb.slv_in.hreadyout = 0;
  //Hung mod 6_1_2021 slv.slave_cb.slv_in.hresp = 0;
  //Hung mod 6_1_2021 slv.slave_cb.slv_in.hrdata = '0;
  slv.slave_cb.slv_in.hreadyout <= 0;
  slv.slave_cb.slv_in.hresp <= 0;
  slv.slave_cb.slv_in.hrdata <= '0;

   // $display("%t: Driver debug ......", $time);
  forever begin
    //Read from mailbox
    //$display("%t: Driver debug ......", $time);
    slv_gen2drv.peek(s);
    begin: slv_tx
      //foreach(cbsq[i]) begin
      //  cbsq[i].pre_tx(this, s);
      //end
      
     // $display("%t: Driver debug ......", $time);

      s.display($sformatf("%t: %0d", $time, portID));

      send(s);

      //foreach(cbsq[i]) begin
      //  cbsq[i].post_tx(this, s);
      //end

      slv_gen2drv.get(s); 
      ->slv_drv2gen;
    end
  end  

endtask: run

//--------------------------------------------------------------------------------
// hrdata is portID: this help to do the check_actual in monitor
//--------------------------------------------------------------------------------

task Slv_driver::send(input Slave s);
  import ahb_package::*;
  //Slave package;
  int num;
  Slave fix;
  //fix = new();
  $display("Slave sendinggg......");
  $display("Package fixing.......");
  fix = s;

  
  //Hung mod 6_1_2021 slv.slave_cb.slv_in.hrdata = portID;
  slv.slave_cb.slv_in.hrdata <= portID;
  fix.hrdata = portID;
  fix.hreadyout = 1;
  //Hung db 8_1_2021 fix.hresp = 1;
  fix.hresp = 0;  
  //Hung db 8_1_2021 fix.hresp = 1;
 
  @(slv.slave_cb);
  wait(slv.slave_cb.hsel);  // This is ok --> wait consume no delay
  slv.slave_cb.slv_in.hreadyout <= 1;
  slv.slave_cb.slv_in.hresp <= 0;
  
  //Hung_mod_11_1_2021
  case(slv.slave_cb.slv_out.hburst)
    SINGLE, INCR: num = 1;
    WRAP4, INCR4: num = 4;
    WRAP8, INCR8: num = 8;
    WRAP16, INCR16: num = 16;
  endcase

  //$display("DBDBDBDBDDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDB");
  //$display("num=%d", num);    
  //$display("DBDBDBDBDDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDBDB");
    
  //slv.slave_cb.slv_out.hrdata = slv.slave_cb.slv_out.hrdata + 1;
  //Put data in Slv_scoreboard
  
  if(cnt<num) begin 
    $display("============================================================================================================");
    $display("Response....");
    foreach(cbsq[i])
      cbsq[i].post_tx(this, fix);
    $display("%t: Driver (Slave) Callback ...... cbsq_size=%0d", $time, cbsq.size());
    $display("============================================================================================================");
    cnt++;
  end else 
  begin
    cnt = 0;
    //Hung_mod_12_1_2021
    @(slv.slave_cb);
    slv.slave_cb.slv_in.hreadyout <= 0;
    //Hung_mod_12_1_2021
  end
  //Hung_mod_11_1_2021

endtask: send 


















