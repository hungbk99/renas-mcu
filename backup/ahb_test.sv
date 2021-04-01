/*********************************************************************************
 * File Name: 		ahb_test.sv
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

//--------------------------------------------------------------------------------

program automatic ahb_test
#(
  parameter MASNUM = 4,
  parameter SLVNUM = 8
)
(
  //input vmas_itf    mas[0:MASNUM-1],
  //input vslv_itf    slv[0:SLVNUM-1],
  ahb_itf.mas_itf   mas[0:MASNUM-1],
  ahb_itf.slv_itf   slv[0:SLVNUM-1],
  input                   hreset_n,
                          hclk
);

  initial begin
    $display("********************************************************************");
    $display("    Simulation was run with:............");
    $display("    MasPort := %0d", MASNUM);
    $display("    SlvPort := %0d", SLVNUM);
    $display("********************************************************************");
  end
  
  Environment env;

  initial begin
    env = new(mas, slv, MASNUM, SLVNUM);
    env.gen_cfg();
    env.build();
    env.run();
    env.wrap_up();
  end

endprogram: ahb_test

