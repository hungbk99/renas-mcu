//////////////////////////////////////////////////////////////////////////////////
// File Name: 		x2p_top.sv
// Function:		  AHB to APB interconnect
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.0   04.04.2021  hungbk99  First creation
//////////////////////////////////////////////////////////////////////////////////

import apb_package::*;
import AHB_package::*;
module x2p_top
(
  //AHB interface
  input                              hsel_slave_peri,  
  input   AHB_package::mas_send_type master_peri_out,
  output  AHB_package::slv_send_type master_peri_in,
  //APB interface
  output  apb_package::master_s_type apb_spi_out,
  output  logic                      spi_hsel,   
  input   apb_package::slave_s_type  apb_spi_in;
  output  apb_package::master_s_type apb_gpio_out,
  output  logic                      gpio_hsel,  
  input   apb_package::slave_s_type  apb_gpio_in;
  input                              ahb_clk
  input                              apb_clk,
                                     rst_n
);
//--------------------------------------------------------------------------------
// Internal signals
//--------------------------------------------------------------------------------
  localparam  GPIO_LOW  =     0x0000;
  localparam  GPIO_HIGH =     0x0020;
  localparam  SPI_LOW   =     0x0100;
  localparam  SPI_HIGH  =     0x011C;

  logic                       gpio_sel,
                              spi_sel,
                              ahb_hsel,
                              apb_hsel,
                              apb_samp_ack,
                              sample_ena,
                              trans_done,
                              trans_end,
                              trans_end_dl,
                              terminate,
                              resp_support;
                              
  AHB_package::mas_send_type  ahb_master_sample;
  AHB_package::mas_send_type  apb_master_sample;
  apb_package::master_s_type  apb_trans_out;
  apb_package::slave_s_type   apb_trans_in;

  enum logic [1:0] {
    IDLE = 2'b00;
    SETUP = 2'b01;
    ACCESS = 2'b10;
  } current_state, next_state;

//--------------------------------------------------------------------------------
// X2P Core
//--------------------------------------------------------------------------------
//Sample
  always_ff @(posedge ahb_clk, posedge rst_n) 
  begin
    if(!rst_n) begin
      ahb_master_sample <= '0;
      ahb_hsel <= 1'b0;
      sample_ena <= 1'b1;
    end
    else begin
      ahb_master_sample <= master_peri_out;
      if(ahb_hsel == 1'b1) 
        ahb_hsel <= !apb_samp_ack;
      else if (sample_ena)
        ahb_hsel <= hsel_slave_peri;
      
      if(apb_sample_ack)
        sample_ena <= 1'b0;
      else if(trans_done)
        sample_ena <= 1'b1;
    end
  end

  always_ff @(posedge apb_clk, posedge rst_n)
  begin
    if(!rst_n) begin
      apb_master_sample <= '0;
      apb_samp_ack <= 1'b0;
    end
    else if(ahb_hsel == 1'b1) begin
      apb_sample_ack <= 1'b1; 
      apb_master_sample <= ahb_master_sample;
    end 
    else if(trans_end)
      apb_master_sample <= '0;
  end
// Decoder
  always_comb begin
    gpio_sel = 1'b0;
    spi_sel = 1'b0;
    raw_ena = 1'b0;
    if((apb_master_sample.htrans != IDLE) && !trans_end) begin
      raw_ena = 1'b1;
      if((apb_master_sample.haddr >= GPIO_LOW) && (apb_master_sample.haddr <= GPIO_HIGH))
        gpio_sel = 1'b1;
      else if ((apb_master_sample.haddr >= SPI_LOW) && (apb_master_sample.haddr <= SPI_HIGH))
        spi_sel = 1'b1;
    end
  end

  always_ff @(posedge pclk, negedge rst_n)
  begin
    if(rst_n)
      current_state <= IDLE;
    else
      current_state <= next_state;
  end
 
  always_comb begin
    gpio_hsel = 1'b0;
    spi_hsel = 1'b0;
    apb_trans_out.penable = 1'b0;
    unique case(current_state)
      IDLE: begin
        if(gpio_sel || spi_sel)
          next_state = SETUP;
        else
          next_state = current_state;
      end
      SETUP: begin
        gpio_hsel = gpio_sel;
        spi_hsel = spi_sel;
        next_state = ACCESS;
      end
      ACCESS: begin
        gpio_hsel = gpio_sel;
        spi_hsel = spi_sel;
        apb_trans_out.penable = 1'b1;
        if(apb_trans_in.pready)
          next_state = IDLE;
        else 
          next_state = current_state;
      end
      default: next_state = current_state;
  end

  always_ff @(posedge pclk, negedge rst_n)
  begin
    if(!rst_n)
      trans_end_dl <= 1'b0;
    else
      trans_end_dl <= trans_end;
  end

  always_ff @(posedge pclk, negedge rst_n)
  begin
    if(rst_n) begin
      trans_end <= 1'b0;
      apb_trans_in <= '0;
    end
    else if(apb_trans_in.pready && apb_trans_out.penable)
    begin
      trans_end <= 1'b1;
      if(gpio_sel)
        apb_trans_in = apb_gpio_in;
      else if(spi_sel)
        apb_trans_in = apb_spi_in;
    end
    else begin 
      trans_end <= 1'b0;
    end
  end

  always_comb begin
    apb_trans_out.paddr = apb_master_sample.haddr;
    apb_trans_out.pwrite = apb_master_sample.hwrite;
    apb_trans_out.pprot[2] = apb_master_sample.hprot[0]
    apb_trans_out.pprot[1] = 1'b1;
    apb_trans_out.pprot[0] = apb_master_sample.hprot[1];
    apb_trans_out.pstrb = 4'hF;
  end

  assign apb_spi_out = apb_trans_out;
  assign apb_gpio_out = apb_trans_out;

// AHB response
  always_ff @(posedge ahb_clk, negedge rst_n)
  begin
    if(!rst_n) begin
      master_peri_in <= '0;
      terminate <= 1'b0;
      resp_support <= 1'b0;
    end
    else if(trans_end && !terminate) begin
      master_peri_in.hresp <= apb_trans_out.pslverr;
      master_peri_in.hrdata <= apb_trans_out.prdata;
      if(!apb_trans_out.pslverr) begin
        master_peri_in.hreadyout <= 1'b1;
        terminate <= 1'b1;
      end else if(resp_support) begin
        master_peri_in.hreadyout <= 1'b1;
        terminate <= 1'b1;
      end else
        resp_support <= 1'b1;
    end
    else if(trans_end_dl)
      terminate <= 1'b0;
    else
      master_peri_in <= '0;
  end

endmodule: x2p_top

