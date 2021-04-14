//////////////////////////////////////////////////////////////////////////////////
// File Name: 		config.sv
// Project Name:	SPI - renas mcu
// Ho Chi Minh University of Technology
// Copyright (C) 2021 Le Quang Hung
// All Rights Reserved
// Email:         quanghungbk1999@gmail.com
// Version    Date       Author      Description
// v0.0       10/04/2021 Quang Hung First Creation
//////////////////////////////////////////////////////////////////////////////////

class spi_config extends uvm_object;
  int spicr    = 32'h00
  int spibr    = 32'h04
  int spiinter = 32'h08
  int spisr    = 32'h0C
  int spirintr = 32'h10
  int spiintr  = 32'h14

endclass: spi_config
