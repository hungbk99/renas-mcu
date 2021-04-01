/*********************************************************************************
 * File Name: 		ahb_top.sv
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
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_env.sv"
//`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/ahb_test.sv"
////`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/dut.sv"

//--------------------------------------------------------------------------------

`define MasPort 4
`define SlvPort 7
`define HCYCLE 5

module top;
  
  parameter int MasNum = `MasPort;
  parameter int SlvNum = `SlvPort;

  logic hreset_n, hclk;

  initial begin
    hreset_n = 0;
    hclk = 0;
    #`HCYCLE hreset_n = 1;
    #`HCYCLE hclk = 1;
    #`HCYCLE hreset_n = 1; hclk = 0;
    forever 
      #`HCYCLE hclk = ~hclk; 
  end 

  //vmas_itf   mas[0:MasNum-1];  
  //vslv_itf   slv[0:SlvNum-1];  
  ahb_itf   mas[0:MasNum-1] (hclk);  
  ahb_itf   slv[0:SlvNum-1] (hclk);  

  //`include "D:/Project/AMBA_BUS/AHB_GEN_201/tb/crv/dut.sv"
  dut 
  #(
    .MasNum(MasNum),
    .SlvNum(SlvNum)
  )
  DUT
  (
    mas,
    slv,
    hreset_n,
    hclk
  );

  ahb_test
  #(
    .MASNUM(MasNum),
    .SLVNUM(SlvNum)
  )
  test
  (
    mas, slv, hreset_n, hclk
  );

  initial begin
    $dumpfile("waveforms.vcd");
    $dumpvars();
    $vcdpluson();
    //$dumpvars(0,top);
  end 

endmodule: top
