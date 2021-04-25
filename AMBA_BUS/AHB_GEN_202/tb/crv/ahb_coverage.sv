/*********************************************************************************
 * File Name: 		AHB_coverage.sv
 * Project Name:	AHB_Gen
 * Email:         quanghungbk1999@gmail.com
 * Version    Date       Author      Description
 * v0.0       02/10/2020 Quang Hung  First Creation
 *            12/01/2021 Quang Hung  Add support for decode error
 *            12/01/2021 Quang Hung  Config maximum cells per masters
 *            16/01/2021 Quang Hung  Add coverage support
 *********************************************************************************/

import ahb_package::*;
class Coverage;
  bit [1:0] mas_htrans_cov;
  bit [2:0] mas_hsize_cov;
  bit [2:0] mas_hburst_cov;
  
  bit [1:0] slv_htrans_cov;
  bit [2:0] slv_hsize_cov;
  bit [2:0] slv_hburst_cov;
  
  bit [7:0]   masnum, 
              slvnum;
  bit [7:0]   mas_cov, 
              slv_cov;
  
  covergroup Mas_Cov;
    coverpoint mas_htrans_cov
    {
      bins IDLE = {0};
      bins BUSY = {1};
      bins NONSEQ = {2};
      bins SEQ = {3};
    }

    coverpoint mas_hsize_cov
    {
      bins BYTE = {0};
      bins HALFWORD = {1};
      bins WORD = {2};
      ignore_bins unsupported = {[3:$]};     
    }

    coverpoint mas_hburst_cov
    {
      bins SINGLE = {0};
      bins INCR   = {1};
      bins WRAP4  = {2};
      bins INCR4  = {3};
      bins WRAP8  = {4};
      bins INCR8  = {5};
      bins WRAP16 = {6};
      bins INCR16 = {7};
    }

    coverpoint mas_cov
    {
      bins mas_cov[] = {[0:masnum-1]};
    }

    cross mas_cov, mas_htrans_cov;
    cross mas_cov, mas_hsize_cov;
    cross mas_cov, mas_hburst_cov;

  endgroup: Mas_Cov

  covergroup Slv_Cov;
    coverpoint slv_htrans_cov
    {
      bins IDLE = {0};
      bins BUSY = {1};
      bins NONSEQ = {2};
      bins SEQ = {3};
    }

    coverpoint slv_hsize_cov
    {
      bins BYTE = {0};
      bins HALFWORD = {1};
      bins WORD = {2};
      ignore_bins unsupported = {[3:$]};    
    }

    coverpoint slv_hburst_cov
    {
      bins SINGLE = {0};
      bins INCR   = {1};
      bins WRAP4  = {2};
      bins INCR4  = {3};
      bins WRAP8  = {4};
      bins INCR8  = {5};
      bins WRAP16 = {6};
      bins INCR16 = {7};
    }

    coverpoint slv_cov
    {
      bins slv_cov[] = {[0:slvnum-1]};
    }

    cross slv_cov, slv_htrans_cov;
    cross slv_cov, slv_hsize_cov;
    cross slv_cov, slv_hburst_cov;

  endgroup: Slv_Cov

  function new(input [7:0] masnum, input [7:0] slvnum);
    this.masnum = masnum;   
    this.slvnum = slvnum; 
    Mas_Cov = new;
    Slv_Cov = new;
    //Hung_db_18_1_2021 this.masnum = masnum;
    //Hung_db_18_1_2021 this.slvnum = slvnum;
  endfunction: new

  function void mas_sample(
    input bit [1:0] mas_htrans,
    input bit [2:0] mas_hsize,
    input bit [2:0] mas_hburst,
    input bit [7:0] master
  );
    this.mas_htrans_cov = mas_htrans;
    this.mas_hsize_cov = mas_hsize;
    this.mas_hburst_cov = mas_hburst;
    this.mas_cov = master;
    Mas_Cov.sample();
  endfunction: mas_sample

  function void slv_sample(
    input bit [1:0] slv_htrans,
    input bit [2:0] slv_hsize,
    input bit [2:0] slv_hburst,
    input bit [7:0] slave
  );
    this.slv_htrans_cov = slv_htrans;
    this.slv_hsize_cov = slv_hsize;
    this.slv_hburst_cov = slv_hburst;
    this.slv_cov = slave;
    Slv_Cov.sample();
  endfunction: slv_sample

endclass: Coverage

