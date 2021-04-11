//////////////////////////////////////////////////////////////////////////////////
// File Name: 		apb_assertion.sv
// Project Name:	SPI - renas mcu
// Ho Chi Minh University of Technology
// Copyright (C) 2021 Le Quang Hung
// All Rights Reserved
// Email:         quanghungbk1999@gmail.com
// Version    Date       Author      Description
// v0.0       10/04/2021 Quang Hung First Creation
//////////////////////////////////////////////////////////////////////////////////

always @(posedge pclk) begin
    if(preset_n) begin
    //Property: PADDR must not be X or Z when PSEL is asserted
    paddr_unknown: assert 
                    (!((apb_cb.psel == 0) || !$isunknown(apb_cb.paddr) || (check_enable == 0)))
                      $error("PADDR went to X or Z when PSEL is asserted");
    
    //Property: PWRITE must not be X or Z when PSEL is asserted
    pwrite_unknown: assert 

                    (!((apb_cb.psel == 0) || !$isunknown(apb_cb.pwrite) || (check_enable == 0)))
                      $error("PWRITE went to X or Z when PSEL is asserted");
    
    //Property: PWDATA must not be X or Z during a write transaction
    pwdata_unknown: assert 

                    (!((apb_cb.psel == 0) || (apb_cb.pwrite == 0) || !$isunknown(apb_cb.pwdata) || (check_enable == 0)))
                      $error("PWDATA went to X or Z during a write transaction");
    
    //Property: PRDATA must not be X or Z during a read transaction
    prdata_unknown: assert 

                    (!((apb_cb.psel == 0) || (apb_cb.pready == 0) || (apb_cb.pwrite == 1) || !$isunknown(apb_cb.prdata) || (check_enable == 0)))
                      $error("PRDATA went to X or Z during a read transaction");
    
    //Property: PENABLE must not be X or Z
    penable_unknown: assert 

                     (($isunknown(apb_cb.penable)) && (check_enable == 1))
                       $error("PENABLE went to X or Z");
    
    //Property: PSEL must not be X or Z
    psel_unknown: assert 

                    ($isunknown(apb_cb.psel) && (check_enable == 1))
                      $error("PSEL went to X or Z");
    
    //Property: PSLVERR must not be X or Z
    pslverr_unknow: assert 

                    (!((apb_cb.psel == 0) || (apb_cb.pready == 0) || !$isunknown(apb_cb.pslverr)))
                      $error("PSLVERR went to X or Z");
  end
end 
