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
  int reg_array [string];  
  reg_array[SPICR]    = 32'h00;
  reg_array[SPIBR]    = 32'h04;
  reg_array[SPIINTER] = 32'h08;
  reg_array[SPISR]    = 32'h0C;
  reg_array[SPIRINTR] = 32'h10;
  reg_array[SPIINTR]  = 32'h14;
  reg_array[SPIINTR]  = 32'h14;
  reg_array[SPITXFF]  = 32'h18;
  reg_array[SPIRXFF]  = 32'h1C;

  `uvm_object_utils_begin(spi_config)
    `uvm_field_array_int(reg_array, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "spi_config");
    super.new(name);
  endfunction: new
  
endclass: spi_config
