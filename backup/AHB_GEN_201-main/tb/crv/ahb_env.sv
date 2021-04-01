/*********************************************************************************
 * File Name: 		Environment.sv
 * Project Name:	AHB_Gen
 * Email:         quanghungbk1999@gmail.com
 * Version    Date      Author      Description
 * v0.0       2/10/2020 Quang Hung  First Creation
 *********************************************************************************/

//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_cells.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_interface.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/config.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_driver.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_monitor.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_scoreboard.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_generator.sv"
//================================================================================
// Call Scoreboard from Master Driver
//================================================================================
class Mscb_driver_cbs extends Mas_driver_cbs;
  Mas_scoreboard scb;

  function new(Mas_scoreboard scb);
    this.scb = scb;
  endfunction: new

  virtual task post_tx(
                input Mas_driver drv,
                input Master     m
                );
    scb.save_expected(m);
  endtask: post_tx

endclass: Mscb_driver_cbs

//================================================================================
// Call Scoreboard from Slave Driver
//================================================================================
class Sscb_driver_cbs extends Slv_driver_cbs;
  Slv_scoreboard scb;

  function new(Slv_scoreboard scb);
    this.scb = scb;
  endfunction: new

  virtual task post_tx(
                input Slv_driver drv,
                input Slave      s
                );
    scb.save_expected(s);
  endtask: post_tx

endclass: Sscb_driver_cbs

//================================================================================
// Call Scoreboard from Master Monitor
//================================================================================
class Mscb_monitor_cbs extends Mas_monitor_cbs;
  Slv_scoreboard scb;

  function new(Slv_scoreboard scb);
    this.scb = scb;
  endfunction: new

  virtual task post_rx(
                input Mas_monitor mmon,
                input Slave       s
                );
  // Check the reponse data and the Channel ID to ensure the correctness of transactions
    scb.check_actual(s, mmon.portID); 
  endtask: post_rx

endclass: Mscb_monitor_cbs

//================================================================================
// Call Scoreboard from Slave Monitor
//================================================================================
class Sscb_monitor_cbs extends Slv_monitor_cbs;
  Mas_scoreboard scb;

  function new(Mas_scoreboard scb);
    this.scb = scb;
  endfunction

  virtual task post_rx(
                input Slv_monitor smon,
                input Master      m);
    scb.check_actual(m, smon.portID);
  endtask: post_rx

endclass: Sscb_monitor_cbs

//cov//================================================================================
//cov// Call Coverage from Master Monitor
//cov//================================================================================
//covclass Cov_mmonitor_cbs extends Ahb_mmonitor_cbs
//cov  Ahb_mcoverage cov;
//cov
//cov  function new (Ahb_mcoverage cov);
//cov    this.cov = cov;
//cov  endfunction: new
//cov
//cov  vitual task post_rx(
//cov            input Ahb_mmonitor mmon,
//cov            input Mas_cell     m,
//cov            );
//cov  endtask: post_rx
//cov
//covendclass: Cov_mmonitor_cbs
//cov
//cov//================================================================================
//cov// Call Coverage from Slave Monitor
//cov//================================================================================
//covclass Cov_smonitor_cbs extends Ahb_smonitor_cbs
//cov  Ahb_scoverage cov;
//cov
//cov  function new (Ahb_scoverage cov);
//cov    this.cov = cov;
//cov  endfunction: new
//cov
//cov  vitual task post_rx(
//cov            input Ahb_mmonitor smon,
//cov            input Slv_cell     s,
//cov            );
//cov  endtask: post_rx
//cov
//covendclass: Cov_smonitor_cbs


////================================================================================
//// Hung mod 2_2_2020
////================================================================================
//class Mas_driver_prio extends Mas_driver;
//  
//  extern virtual function new(
//    input mailbox mas_gen2drv,
//    input event   mas_drv2gen,
//    input vmas_itf mas,
//    input int portID
//    input Config  cfg;
//  );
//
//endclass: Mas_driver_prio

//================================================================================
// Environment
//================================================================================

class Environment;
//Dynamic pointer array to manage master channels
  Mas_generator  mgen[];
  mailbox        mgen2drv[];   
  event          mdrv2gen[];
  Mas_driver     mdrv[];
  Mas_monitor    mmon[];
  Mas_scoreboard mscb;

//Dynamic pointer array to manage slave channels
  Slv_generator  sgen[];
  mailbox        sgen2drv[];
  event          sdrv2gen[];
  Slv_driver     sdrv[];
  Slv_monitor    smon[];
  Slv_scoreboard sscb;
  
  Config         cfg;
//cvr  Coverage   cov[];

  //virtual  ahb_itf.mas_itf   mas[];
  //virtual  ahb_itf.slv_itf   slv[];
  vmas_itf       mas[];
  vslv_itf       slv[];  
  
  int masnum, slvnum;

  extern function new(
                input vmas_itf mas[],
                input vslv_itf slv[],
                input int masnum, slvnum
                );

  extern virtual function void gen_cfg();
  extern virtual function void build();
  extern virtual function void wrap_up();
  extern virtual task run();

endclass: Environment

//================================================================================
// Construct the environment instance
//================================================================================

function Environment::new(
                input vmas_itf mas[],
                input vslv_itf slv[],
                input int masnum, slvnum
                );
  this.mas = new[mas.size()];
  this.slv = new[slv.size()];
  foreach (mas[i]) begin
    $display("db master virtual interface ......... %d", i);
    this.mas[i] = mas[i];
  end

  $display();

  foreach (slv[i]) begin
    $display("db slave virtual interface .......... %d", i);
    this.slv[i] = slv[i];
  end

  this.masnum = masnum;
  this.slvnum = slvnum;
 
  cfg = new(masnum, slvnum);

  if($test$plusargs("Random_seed"))
  begin
    int seed;
    $value$plusargs("Random_seed=%0d", seed);
    $display("Simulation run with random seed = %d", seed);
  end
  else
    $display("Simulation run with default random seed");

endfunction: new

//================================================================================
// Randomize the environment
//================================================================================

function void Environment::gen_cfg();
  assert(cfg.randomize());
  cfg.display();
endfunction: gen_cfg

//================================================================================
// Build the environment objects
// The objects are built for every channels
// Only mas_in_use channels can transfer data
//================================================================================

function void Environment::build();
  $display("%t: Build.............", $time);
  mgen = new[masnum];
  mdrv = new[masnum];
  mmon = new[masnum];
  mgen2drv = new[masnum];
  mdrv2gen = new[masnum];
  
  sgen = new[slvnum];
  sdrv = new[slvnum];
  smon = new[slvnum];
  sgen2drv = new[slvnum];
  sdrv2gen = new[slvnum];
 
  mscb = new(cfg); 
  sscb = new(cfg); 
  //mcov = new();
  //scov = new();

  //Connect DUT with Drivers, Drivers with Generators
  foreach(mgen[i]) begin
      $display("db master generator +++++++++++++ %d", i);
      $display("db master driver    +++++++++++++ %d", i);
    mgen2drv[i] = new();
    //mgen[i] = new(mgen2drv[i], mdrv2gen[i], cfg.mas_in_use[i], i); 
    mgen[i] = new(mgen2drv[i], mdrv2gen[i], cfg.n_cells_mas[i], i); 
    mdrv[i] = new(mgen2drv[i], mdrv2gen[i], mas[i], cfg, i);            
  end 

  $display("======================================================");

  foreach(sgen[i]) begin
      $display("db slave generator +++++++++++++ %d", i);
      $display("db slave driver    +++++++++++++ %d", i);
    sgen2drv[i] = new();
    sgen[i] = new(sgen2drv[i], sdrv2gen[i], i);
    sdrv[i] = new(sgen2drv[i], sdrv2gen[i], slv[i], i);
  end

  $display("======================================================");

  //Connect DUT with Monitors
  foreach(mmon[i]) begin
      $display("db master monitor+++++++++++++ %d", i);
    mmon[i] = new(mas[i], i);
  end

  $display("======================================================");
  
  foreach(smon[i]) begin
      $display("db slave monitor++++++++++++++ %d", i);
    smon[i] = new(slv[i], i);
  end

  $display("======================================================");
  
  //Connect scoreboard with callbacks	
  begin
    Mscb_driver_cbs  msdc = new(mscb); // Add Scoreboard to every Drivers
    foreach (mdrv[i]) begin
      mdrv[i].cbsq.push_back(msdc);
      $display("db master driver connect scoreboard+++++++++++++ %d", i);
    end
  end
  
  $display("======================================================");
  
  begin
    Mscb_monitor_cbs msmc = new(sscb); // Add Scoreboard to every Monitors
    foreach (mmon[i]) begin
      mmon[i].cbsq.push_back(msmc);
      $display("db master driver connect scoreboard+++++++++++++ %d", i);
    end
  end
 
  begin
    Sscb_driver_cbs  ssdc = new(sscb);
    foreach (sdrv[i]) 
      sdrv[i].cbsq.push_back(ssdc);
  end
  
  begin 
    Sscb_monitor_cbs ssmc = new(mscb);
    foreach (smon[i])
      smon[i].cbsq.push_back(ssmc);
  end

//cov  // connect coverage wth callbacks
//cov  begin
//cov    Cov_mmonitor_cbs mc = new(mcov);    
//cov    foreach (mnon[i]) mmon[i].cbsq.push_back(mc);
//cov  end
//cov  
//cov  begin  
//cov    Cov_smonitor_cbs sc = new(scov);
//cov    foreach (smon[i]) smon[i].sbsq.push_back(sc);
//cov  end

endfunction: build

//================================================================================
// Start the transactors (generators, drivers, monitors) in the environment
// Channels that are not in use don't get started
//================================================================================

task Environment::run();
  int running;
  running = masnum;  

  $display("%t: Runnnn.............", $time);
  // Start in_use Master channels
  // Hung mod 31_12_2020
  fork 
    //Hung db 4_1_2021
    fork 
      foreach(mgen[i]) begin
        //int j=i;
        //  $display("db +++++++++++++ %d", j);
        fork
          int j=i;
          $display("########################################################################");
          $display("db +++++++++++++ %d", j);
          $display("db mgen + mdrv+++++++++++++ %d", j);

          //Hung mod +++ 30_12_2020
          if(cfg.mas_in_use[j])
          begin 
            $display("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            $display("Generate...");
            $display("master in used: %d", j);
            $display("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            mgen[j].run();
          end   
          
          if(cfg.mas_in_use[j])
          begin 
            $display("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            $display("Drive...");
            $display("master in used: %d", j);
            $display("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            //$display("master in used: %d", j);
            mdrv[j].run();
          end   
        join_none
        //join_any
        //join
        running--;    
      end   
 
      // Start all Slave channels 
      foreach(smon[i]) begin
        int j=i;
          $display("db smon+++++++++++++ %d", j);
        fork
          smon[j].run();
        join_none
      end

      foreach(sgen[i]) begin
        int j=i;
          $display("db sgen + sdrv+++++++++++++ %d", j);
        fork
          sgen[j].run();
          sdrv[j].run();
        join_none
      end

      foreach(mmon[i]) begin
        int j=i;
          $display("db mmon+++++++++++++ %d", j);
        fork
          mmon[j].run();
        join_none
      end
    //Hung mod 8_1_2021 join_any
    join
    //Hung mod 8_1_2021 join_any

    fork: timeout
      wait(running == 0)
        disable timeout;

      begin
        repeat(1000000) @(mas[0].master_cb);
          $display("%t: ERRORRR: Timeout while waiting for master transactors", $time);
          cfg.n_errors++;
      end  
    join_any
    
    begin: run_time
        repeat(1000000) @(mas[0].master_cb);
    end
  join
endtask: run

function void Environment::wrap_up();
  $display("****************************************************************************");
  mscb.wrap_up;
  sscb.wrap_up;  
  $display("Run time:: %t", $time);  
  $display("END OF SIMULATION:: %0d Total error%s",  
    cfg.n_errors, cfg.n_errors==1 ? "" : "s");
  $display("****************************************************************************");
endfunction: wrap_up

