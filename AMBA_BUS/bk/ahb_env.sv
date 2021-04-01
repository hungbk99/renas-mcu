/*********************************************************************************
 * File Name: 		ahb_env.sv
 * Project Name:	AHB_Gen
 * Email:         quanghungbk1999@gmail.com
 * Version    Date      Author      Description
 * v0.0       2/10/2020 Quang Hung  First Creation
 *********************************************************************************/

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
    scb.save_expected(s);
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
    scb.save_expected(m);
  endtask: post_tx

endclass: Sscb_driver_cbs

//================================================================================
// Call Scoreboard from Master Monitor
//================================================================================
class Mscb_monitor_cbs extends Mas_monitor_cbs;
  Slv_scoreboard scb;

  function new(Slv_scoreboard scb);
    this.scb = scb;
  endfunction

  virtual task post_rx(
                input Mas_monitor mon,
                input Slave       s
                );
  // Check the reponse data and the Channel ID to ensure the correctness of transactions
    scb.check_actual(s, mon.portID); 
  endtask: post_rx

endclass: Mscb_monitor_cbs

//================================================================================
// Call Scoreboard from Slave Monitor
//================================================================================
class Sscb_monitor_cbs extends Slv_monitor_cbs;
  Slv_scoreboard scb;

  function new(Ahb_mscoreboard scb);
    this.scb = scb;
  endfunction

  virtual task post_rx(
                input Ahb_mmonitor mon,
                input Mas_cell     m
                );
    scb.check_actual(m, mon.portID);
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
  Mas_scoreboard mscb[];

//Dynamic pointer array to manage slave channels
  Slv_genertor   sgen[];
  mailbox        sgen2drv[];
  event          sdrv2gen[];
  Slv_driver     sdrv[];
  Slv_monitor    smon[];
  Slv_scoreboard sscb[];
  
  Config         cfg[];
//cvr  Coverage   cov[];

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

endclass: Ahb_env

//================================================================================
e/ Construct the environment instance
//================================================================================

function Environment::new(
                input vmas_itf mas[],
                input vslv_itf slv[],
                input int masnum, slvnum
                );
  this.mas = new[mas.size()];
  foreach (mas[i])
    this.mas[i] = mas[i];
  foreach (slv[i])
    this.slv[i] = slv[i];
  this.masnum = masnum;
  this.slvnum = slvnum;
 
  cfg = new(masnum, slvnum);

  if($test$plusargs("Random_seed"))
    int seed;
    $value$plusargs("Random_seed=%0d", seed);
    $display("Simulation run with random seed = %d", seed);
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
  mcov = new();
  scov = new();

  //Connect DUT with Drivers, Drivers with Generators
  foreach(mgen[i]) begin
    mgen2drv[i] = new();
    mgen[i] = new(mgen2drv[i], mdrv2gen[i], cfg.mas_in_use[i], i); 
    mdrv[i] = new(mgen2drv[i], mdrv2gen[i], mas[i], i);            
  end 

  foreach(sgen[i]) begin
    sgen2drv[i] = new();
    sgen[i] = new(sgen2drv[i], mdrv2gen[i], i);
    sdrv[i] = new(mgen2drv[i], mdrv2gen[i], slv[i], i);
  end

  //Connect DUT with Monitors
  foreach(mmon[i])
    mmon[i] = new(mas[i], i);

  foreach(smon[i])
    smon[i] = new(slv[i], i);
   
  //Connect scoreboard with callbacks	
  begin
    Mscb_driver_cbs  msdc = new(mscb); // Add Scoreboard to every Drivers
    foreach (mdrv[i]) 
      mdrv[i].cbsq.push_back(msdc);
   
    Mscb_monitor_cbs msmc = new(mscb); // Add Scoreboard to every Monitors
    foreach (mmon[i])
      mmon[i].cbsq.push_back(msmc);
  end
 
  begin
    Sscb_driver_cbs  ssdc = new(sscb);
    foreach (sdrv[i]) 
      sdrv[i].cbsq.push_back(ssdc);
    
    Sscb_monitor_cbs ssmc = new(sscb);
    foreach (mmon[i])
      mmon[i].cbsq.push_back(ssmc);
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

  // Start in_use Master channels
  foreach(mgen[i]) begin
    int j=i;
    fork
      if(cfg.mas_in_use[j])
      begin 
        mgen[j].run();
        mdrv[j].run();
      end   
    join_none
    running--;    
  end   
 
  // Start all Slave channels 
  foreach(smon[i]) begin
    int j=i;
    fork
      smon[j].run();
    join_none
  end

  foreach(sgen[i]) begin
    int j=i;
    fork
      sgen[j].run();
      sdrv[j].run();
    join_none
  end

  foreach(mmon[i]) begin
    int j=i;
    fork
      mmon[j].run();
    join_none
  end

  fork: timeout
    wait(running == 0);

    begin
      repeat(1000000) @(mas[0]);
        $display("%t: ERRORRR: Timeout while waiting for master transactors", $time);
        cfg.n_errors++;
    end  
  join_any
  disable timeout

endtask: run

function void Environment::wrap_up();
  $display("%t: End of simulation, %d error%s",  
    $time, cfg.n_errors, cfg.n_errors==1 ? "" : "s");
    
  mscb.wrap_up;
  sscb.wrap_up;  

endfunction: wrap_up

