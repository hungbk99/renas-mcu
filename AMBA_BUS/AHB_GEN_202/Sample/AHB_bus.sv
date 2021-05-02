//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_bus.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

  //`include "D:/Project/renas-mcu//AMBA_BUS/AHB_GEN_202/Gen_Result/AHB_package.sv"
  `include "D:/Project/renas-mcu//AMBA_BUS/AHB_GEN_202/Gen_Result/AHB_arbiter_package.sv"
  `include "D:/Project/renas-mcu//AMBA_BUS/AHB_GEN_202/Gen_Result/AHB_default_slave.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/arbiter/AHB_arbiter_slave_data.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/arbiter/AHB_arbiter_slave_inst.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/arbiter/AHB_arbiter_slave_peri.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/decoder/AHB_decoder_master_data.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/decoder/AHB_decoder_master_inst.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/decoder/AHB_decoder_master_peri.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/mux/AHB_mi_mux_slave_data.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/mux/AHB_mi_mux_slave_inst.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/mux/AHB_mi_mux_slave_peri.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/mux/AHB_si_mux_master_data.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/mux/AHB_si_mux_master_inst.sv"
  `include "D:/Project/renas-mcu/AMBA_BUS/AHB_GEN_202/Gen_Result/mux/AHB_si_mux_master_peri.sv"
//================================================================================
//#CONFIG_GEN#
//================================================================================

import AHB_package::*;
module AHB_bus
(
//#INTERFACEGEN#
//#SI#
//#MI#
);

  parameter SI_PAYLOAD = 78;
  parameter MI_PAYLOAD = 34;
//================================================================================
//#SIGGEN# 
//================================================================================
//#DECGEN# 
//================================================================================
//#ARBGEN#
//================================================================================
//#CROSSGEN#

endmodule: AHB_bus
