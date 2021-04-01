//////////////////////////////////////////////////////////////////////////////////
// File Name: 		AHB_package.sv
// Project Name:	AHB_Gen
// Email:         quanghungbk1999@gmail.com
// Version    Date      Author      Description
// v0.0       14/11/2020 Quang Hung  First Creation
//////////////////////////////////////////////////////////////////////////////////

package ahb_package;
  typedef enum bit [1:0]
  {
    IDLE = 2'b00,
    BUSY = 2'b01,
    NONSEQ = 2'b10,
    SEQ = 2'b11
  } htrans_rtype;

  typedef enum bit [2:0]
  {
    BYTE,
    HALFWORD,
    WORD,
    DOUBLEWORD,
    FOURWORDLINE,
    EIGHTWORDLINE,
    SIXTEENWORDLINE,
    THIRTY2WORDLINE
  } hsize_rtype;

  typedef enum bit [2:0] 
  {
    SINGLE,
    INCR,
    WRAP4,
    INCR4,
    WRAP8,
    INCR8,
    WRAP16,
    INCR16
  } hburst_rtype;

  //typedef struct packed {
  //  bit [31:0]   haddr;
  //  bit          hwrite;
  //  hsize_type   hsize;
  //  hburst_type  hburst;
  //  bit [3:0]    hprot;
  //  htrans_type  htrans;
  //  bit          hmastlock;
  //  bit [31:0]   hwdata;
  //} mas_send_rtype;

  //typedef struct packed {
  //  bit          hreadyout;
  //  bit [31:0]   hrdata;
  //  bit          hresp;    
  //} slv_send_rtype;

endpackage: AHB_package
