module dut
#(
  parameter MasNum = 4,
  parameter SlvNum = 8
)
(
  ahb_itf.master_dut   mas[0:MasNum-1],
  ahb_itf.slave_dut    slv[0:SlvNum-1],
  input                hreset_n,
  input                hclk
);
  
  `include"D:/Project/AMBA_BUS/AHB_GEN_201/Gen_Result/AHB_bus.sv"
  AHB_bus bus
  (
    .master_1_in(mas[0].mas_in),
    .hprior_master_1(mas[0].prio),
    .master_1_out(mas[0].mas_out),
    .master_2_in(mas[1].mas_in),
    .hprior_master_2(mas[1].prio),
    .master_2_out(mas[1].mas_out),
    .master_3_in(mas[2].mas_in),
    .hprior_master_3(mas[2].prio),
    .master_3_out(mas[2].mas_out),
    .kemee_in(mas[3].mas_in),
    .hprior_kemee(mas[3].prio),
    .kemee_out(mas[3].mas_out),
//#MI
    .slave_1_in(slv[0].slv_in),
    .hsel_slave_1(slv[0].hsel),
    .slave_1_out(slv[0].slv_out),
    .slave_2_in(slv[1].slv_in),
    .hsel_slave_2(slv[1].hsel),
    .slave_2_out(slv[1].slv_out),
    .slave_3_in(slv[2].slv_in),
    .hsel_slave_3(slv[2].hsel),
    .slave_3_out(slv[2].slv_out),
    .slave_4_in(slv[3].slv_in),
    .hsel_slave_4(slv[3].hsel),
    .slave_4_out(slv[3].slv_out),
    .slave_5_in(slv[4].slv_in),
    .hsel_slave_5(slv[4].hsel),
    .slave_5_out(slv[4].slv_out),
    .slave_6_in(slv[5].slv_in),
    .hsel_slave_6(slv[5].hsel),
    .slave_6_out(slv[5].slv_out),
    .slave_7_in(slv[6].slv_in),
    .hsel_slave_7(slv[6].hsel),
    .slave_7_out(slv[6].slv_out),
    .hclk(hclk),
    .hreset_n(hreset_n)
    //.*
  );

endmodule: dut
