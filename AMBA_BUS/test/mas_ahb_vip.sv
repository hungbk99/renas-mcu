//////////////////////////////////////////////////////////////////////////////////
// File Name: 		mas_ahb_vip_#NUM#.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       2/10/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////


import AHB_package::*;
module mas_ahb_vip#NUM#
#(
  parameter ADDR = #STARTADDR#,
  parameter DATA = #STARTDATA#
)
(
  master_itf interfaces(hclk)
);

  initial begin
    interfaces.haddr = ADDR;
    interfaces.hwrite = '0;
    interfaces.hsize = WORD;
    interfaces.hburst = SINGLE;
    interfaces.hprot = '0;
    interfaces.htrans = IDLE;
    interfaces.hmastlock = '0;
    interfaces.hwdata = '0;
  end

  forever begin
    @interfaces.master_cb;
    if(interfaces.hready)
     haddr = haddr + 1; 
  end


endmodule: mas_ahb_vip#NUM#
