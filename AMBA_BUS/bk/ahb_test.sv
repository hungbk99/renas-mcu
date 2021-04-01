/*********************************************************************************
 * File Name: 		ahb_test.sv
 * Project Name:	AHB_Gen
 * Email:         quanghungbk1999@gmail.com
 * Version    Date      Author      Description
 * v0.0       2/10/2020 Quang Hung  First Creation
 *********************************************************************************/

//--------------------------------------------------------------------------------

program automatic ahb_test
#(
  parameter MASNUM = 4,
  parameter SLVNUM = 8
)
(
  vmas_itf    mas[0:MasNum-1],
  vslv_itf    slv[0:SlvNum-1],
  input       hreset_n,
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

