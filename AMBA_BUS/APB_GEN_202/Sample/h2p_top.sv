//////////////////////////////////////////////////////////////////////////////////
// File Name: 		x2p_top.sv
// Function:		  AHB to APB interconnect
// Project Name:	renas mcu
// Copyright (C) 	Le Quang Hung 
// Ho Chi Minh University of Technology
// Email: 			quanghungbk1999@gmail.com  
// Ver    Date        Author    Description
// v0.0   04.04.2021  hungbk99  First creation
// v0.1   05.16.2021  hungbk99  Remove support for GPIO
//        05.20.2021  hungbk99  Debug: trans_done
//////////////////////////////////////////////////////////////////////////////////

import apb_package::*;
import AHB_package::*;
module x2p_top
(
  //AHB interface
  input                              hsel_slave_peri,  
  input   AHB_package::mas_send_type slave_peri_out,
  output  AHB_package::slv_send_type slave_peri_in,
  //APB interface
  output  apb_package::master_s_type apb_spi_out,
  output  logic                      spi_psel,   
  input   apb_package::slave_s_type  apb_spi_in,
  //Hung_mod output  apb_package::master_s_type apb_gpio_out,
  //Hung_mod //Hung_mod output  logic                      gpio_hsel,  
  //Hung_mod input   apb_package::slave_s_type  apb_gpio_in;
  input                              ahb_clk,
  input                              apb_clk,
                                     rst_n
);
//--------------------------------------------------------------------------------
// Internal signals
//--------------------------------------------------------------------------------
  //Hung_mod localparam  GPIO_LOW  =     0x0000;
  //Hung_mod localparam  GPIO_HIGH =     0x0020;
  localparam  PERI_BASE =     32'h0001_0000;
  localparam  SPI_LOW   =     32'h0100 + PERI_BASE;
  localparam  SPI_HIGH  =     32'h011C + PERI_BASE;

  //Hung_mod logic                       gpio_sel,
  logic                       spi_sel,
                              ahb_hsel,
                              //apb_hsel,
                              apb_sample_ack,
                              sample_ena,
                              trans_done,
                              trans_end,
                              trans_end_dl,
                              terminate,
                              resp_support;
                              
  //AHB_package::mas_send_type  ahb_master_sample;
  AHB_package::mas_send_type  apb_master_sample;
  apb_package::master_s_type  apb_trans_out;
  apb_package::slave_s_type   apb_trans_in;

  enum logic [1:0] {
    IDLE = 2'b00,
    SETUP = 2'b01,
    ACCESS = 2'b10
  } current_state, next_state;

//--------------------------------------------------------------------------------
// X2P Core
//--------------------------------------------------------------------------------
//Sample

  always_ff @(posedge ahb_clk, negedge rst_n) 
  begin
    if(!rst_n) begin
      //ahb_master_sample <= '0;
      ahb_hsel <= 1'b0;
      sample_ena <= 1'b1;
    end
    else begin
      //ahb_master_sample <= slave_peri_out;
      if(ahb_hsel == 1'b1) 
        ahb_hsel <= !apb_sample_ack;
      else if (sample_ena)
        ahb_hsel <= hsel_slave_peri;
      
      //Hung_mod_05.20.2021 if(apb_sample_ack)
      if(apb_sample_ack && !trans_done)
        sample_ena <= 1'b0;
      else if(trans_done)
        sample_ena <= 1'b1;
    end
  end

  //Hung_db_05.20.2021
  assign trans_done = trans_end_dl; //trans_end; //trans_end_dl ???
  //Hung_db_05.20.2021
  always_ff @(posedge apb_clk, negedge rst_n)
  begin
    if(!rst_n) begin
      apb_master_sample <= '0;
      apb_sample_ack <= 1'b0;
    end
    else if(ahb_hsel == 1'b1) begin
      apb_sample_ack <= 1'b1; 
      apb_master_sample <= slave_peri_out;
    end 
    else if(trans_end) begin
      apb_master_sample <= '0;
      apb_sample_ack <= 1'b0;
    end
  end
// Decoder
  always_comb begin
    //Hung_mod gpio_sel = 1'b0;
    spi_sel = 1'b0;
    //raw_ena = 1'b0;
    if((apb_master_sample.htrans != IDLE) && !trans_end) begin
      //raw_ena = 1'b1;
      //Hung_mod if((apb_master_sample.haddr >= GPIO_LOW) && (apb_master_sample.haddr <= GPIO_HIGH))
      //Hung_mod   gpio_sel = 1'b1;
      //Hung_mod else 
      if ((apb_master_sample.haddr >= SPI_LOW) && (apb_master_sample.haddr <= SPI_HIGH))
        spi_sel = 1'b1;
    end
  end

  always_ff @(posedge apb_clk, negedge rst_n)
  begin
    if(!rst_n)
      current_state <= IDLE;
    else
      current_state <= next_state;
  end
 
  always_comb begin
    //Hung_mod gpio_hsel = 1'b0;
    spi_psel = 1'b0;
    apb_trans_out.penable = 1'b0;
    unique case(current_state)
      IDLE: begin
        //Hung_mod if(gpio_sel || spi_sel)
        if(spi_sel)
          next_state = SETUP;
        else
          next_state = current_state;
      end
      SETUP: begin
        //Hung_mod gpio_hsel = gpio_sel;
        spi_psel = spi_sel;
        next_state = ACCESS;
      end
      ACCESS: begin
        //Hung_mod gpio_hsel = gpio_sel;
        spi_psel = spi_sel;
        apb_trans_out.penable = 1'b1;
        if(apb_spi_in.pready)
          next_state = IDLE;
        else 
          next_state = current_state;
      end
      default: next_state = current_state;
    endcase
  end

  always_ff @(posedge apb_clk, negedge rst_n)
  begin
    if(!rst_n)
      trans_end_dl <= 1'b0;
    else
      trans_end_dl <= trans_end;
  end

  always_ff @(posedge apb_clk, negedge rst_n)
  begin
    if(!rst_n) begin
      trans_end <= 1'b0;
      apb_trans_in <= '0;
    end
    //else if(apb_trans_in.pready && apb_trans_out.penable)
    else if(apb_spi_in.pready && apb_trans_out.penable)
    begin
      trans_end <= 1'b1;
      //Hung_mod if(gpio_sel)
      //Hung_mod   apb_trans_in = apb_gpio_in;
      //Hung_mod else 
      //if(spi_sel)
        apb_trans_in = apb_spi_in;
    end
    else begin 
      trans_end <= 1'b0;
    end
  end

  always_comb begin
    apb_trans_out.paddr = apb_master_sample.haddr;
    apb_trans_out.pwrite = apb_master_sample.hwrite;
    apb_trans_out.pwdata = apb_master_sample.hwdata;
    apb_trans_out.pprot[2] = apb_master_sample.hprot[0];
    apb_trans_out.pprot[1] = 1'b1;
    apb_trans_out.pprot[0] = apb_master_sample.hprot[1];
    apb_trans_out.pstrb = 4'hF;
  end

  assign apb_spi_out = apb_trans_out;
  //Hung_mod assign apb_gpio_out = apb_trans_out;

// AHB response
  always_ff @(posedge ahb_clk, negedge rst_n)
  begin
    if(!rst_n) begin
      slave_peri_in <= '0;
      terminate <= 1'b0;
      resp_support <= 1'b0;
    end
    else if(trans_end && !terminate) begin
      slave_peri_in.hresp <= apb_trans_in.pslverr;
      slave_peri_in.hrdata <= apb_trans_in.prdata;
      if(!apb_trans_in.pslverr) begin
        slave_peri_in.hreadyout <= 1'b1;
        terminate <= 1'b1;
      end else if(resp_support) begin
        slave_peri_in.hreadyout <= 1'b1;
        terminate <= 1'b1;
      end else
        resp_support <= 1'b1;
    end
    else if(trans_end_dl)
      terminate <= 1'b0;
    else
      slave_peri_in <= '0;
  end

endmodule: x2p_top

