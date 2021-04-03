//////////////////////////////////////////////////////////////////////////////////
// File Name: 		spi_regs.sv
// Project Name:	SPI - renas mcu
// Ho Chi Minh University of Technology
// Email:         quanghungbk1999@gmail.com
// Version    Date       Author      Description
// v0.0       01/04/2021 Quang Hung First Creation
//////////////////////////////////////////////////////////////////////////////////
//
//================================================================================
// SPI Control Register
//================================================================================
class spicr_reg extends uvm_reg;
    `uvm_reg_cb(spicr_reg, uvm_reg_cbs)
    `uvm_set_super_type(spicr_reg, uvm_reg)
    `uvm_object_utils(spicr_reg)
    rand uvm_reg_field spie;
    rand uvm_reg_field swr;
    rand uvm_reg_field dord; 
    rand uvm_reg_field mstr;
    rand uvm_reg_field cpol;
    rand uvm_reg_field cpha;
    rand uvm_reg_field mclksel;
    rand uvm_reg_field talk;
    rand uvm_reg_field spitxdl;
    rand uvm_reg_field ss;
    rand uvm_reg_field spitxrst;
    rand uvm_reg_field spirxrst;
    rand uvm_reg_field datalen;

    virtual function void build();
        //parent | size | lsb_pos | access | volatile | reset | has_reset | is_rand | individually_accessible
        //SPI enable
        spie = uvm_reg_field::type_id::create("spie");
        spie.configure(this, 1, 31, "RW", 0, 0, 1, 1, 1);
        //SPI software reset
        swr = uvm_reg_field::type_id::create("swr");
        swr.configure(this, 1, 30, "RW", 0, 0, 1, 1, 1);
        //SPI data order
        dord = uvm_reg_field::type_id::create("dord");
        dord.configure(this, 1, 29, "RW", 0, 0 , 1, 1, 1);
        //SPI master mode
        mstr = uvm_reg_field(this, 1, 28, "RW", 0, 0, 1, 1, 1);
        //SPI clock polarity
        cpol = uvm_reg_field::type_id::create("cpol");
        cpol.configure(this, 1, 27, "RW", 0 , 0 , 1, 1, 1);
        //SPI clock phase
        cpha = uvm_reg_field::type_id::create("cpha");
        cpha.configure(this, 1, 26, "RW", 0, 0, 1, 1, 1);
        //SPI naster clock select
        mclksel = uvm_reg_field::type_id::create("mclksel");
        mclksel.configure(this, 1, 25, "RW", 0 , 0, 1, 1, 1);
        //SPI transmit enable
        talk = uvm_reg_field::type_id::create("talk");
        talk.configure(this, 1, 24, "RW", 0, 0, 1, 1, 1);
        //SPI transfer delay
        spitxdl = uvm_reg_field::type_id::create("spitxdl");
        spitxdl.configure(this, 8, 16, "RW", 0, 0, 1, 1, 1);
        //SPI slave select
        ss = uvm_reg_field::type_id::create("ss");
        ss.configure(this, 2, 14, "RW", 0, 0, 1, 1, 1);
        //SPI transfer reset
        spitxrst = uvm_reg_field::type_id::create("spitxrst");
        spitxrst.configure(this, 1, 9, "RW", 0, 0, 1, 1, 1);
        //SPI receive reset
        spirxrst = uvm_reg_field::type_id::create("spirxrst");
        spirxrst.configure(this, 1, 8, "RW", 0, 0, 1, 1, 1);
        //SPI data length
        datalen = uvm_reg_field::type_id::create("datalen");
        datalen.configure(this, 5, 0, "RW", 0, 0, 1, 1, 1);
    endfunction:: build

    function new(string name = "unnamed-spicr_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
        w_spicr_cg.new;
        r_spicr_cg.new;
    endfunction: new

    covergroup w_spicr_cg;
        option.per_instance = 1;
        
        SPIE: coverpoint spie {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }
    
        SWR: coverpoint swr {
            bins    RESET = {1};
            bins    NON_RESET = {0};
        }

        DORD: coverpoint dord {
            bins    MSB_FIRST = {1};
            bins    LSB_FIRST = {0};
        }

        MSTR: coverpoint mstr {
            bins    MASTER = {1};
            bins    SLAVE = {0};
        }

        CPOL: coverpoint cpol {
            bins    POS_EDGE = {0};
            bins    NEG_EDGE = {1};
        }

        CPHA: coverpoint cpha {
            bins    FIST_EDGE = {0};
            bins    SECOND_EDEG = {1};
        }

        MCLKSEL: coverpoint mclksel {
            bins    APB_CLK = {0};
            bins    OTHER_CLK = {1};
        }

        TALK: coverpoint talk {
            bins    NORMAL_COM = {0};
            bins    RECEIVE_ONLY = {1};
        }

        SPITXDL: coverpoint spitxdl.value[7:0];

        SS: coverpoint ss.value[1:0];

        SPITXRST: coverpoint spitxrst {
            bins    TX_FF_RST = {0};
            bins    TX_FF_ENA = {1};
        }

        SPIRXRST: coverpoint spirxrst {
            bins    RX_FF_RST = {0};
            bins    RX_FF_ENA = {1};
        }

        DATALEN: coverpoint datalen.value[4:0];

        CLOCK_SCHEME: cross CPOL, CPHA;
    endgroup

    virtual function void sample(uvm_reg_data_t    data, byte_en,
                                 bit               is_read,
                                 uvm_reg_map       map);
        super.sample(data, byte_en, is_read, map);
        if(is_read) r_spicr_cg.sample();
        else w_spicr_cg.sample();
    endfunction: sample

endclass: spicr_reg

//================================================================================
// SPI Baud Rate Register
//================================================================================
class spibr_reg extends uvm_reg;
    `uvm_register_cb(spibr_reg, uvm_reg_cbs)
    `uvm_set_super_type(spibr, uvm_reg)
    `uvm_object_utils(spibr)

    rand uvm_reg_field spbr;

    virtual function void build();
        //parent | size | lsb_pos | access | volatile | reset | has_reset | is_rand | individually_accessible
        spbr = uvm_reg_field::type_id::create(this, 8, 0, "RW", 0, 0, 1, 1, 1);
        spbr.configure(this, 8, 0, "RW", 0, 0, 1, 1, 1);
    endfunction

    function new(string name = "unnamed-spibr_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
        w_spibr_cg.new;
        r_spibr_cg.new;
    endfunction: new

    covergroup w_spibr_cg;
        option.per_instance = 1;
        BAUDRATE: coverpoint spbr.value[7:0];
    endgroup
    
    covergroup r_spibr_cg;
        option.per_instance = 1;
        BAUDRATE: coverpoint spbr.value[7:0];
    endgroup
    
    virtual function void sample(uvm_reg_data_t    data, byte_en,
                                 bit               is_read,
                                 uvm_reg_map       map);
        super.sample(data, byte_en, is_read, map);
        if(is_read) r_spibr_cg.sample();
        else w_spibr_cg.sample();
    endfunction: sample
endclass: spibr_reg

//================================================================================
// SPI Interrupt Enable Register
//================================================================================
class spiinter_reg extends uvm_reg;
    `uvm_register_cb(spiinter_reg, uvm_reg_cbs)
    `uvm_set_super_type(spiinter_reg, uvm_reg)
    `uvm_object_utils(spiinter_reg)

    rand uvm_reg_field spitrcinte;

    rand uvm_reg_field spitxfinte;
    rand uvm_reg_field spitxointe;
    rand uvm_reg_field spitxeinte;
    rand uvm_reg_field spitxuinte;

    rand uvm_reg_field spirxfinte;
    rand uvm_reg_field spirxointe;
    rand uvm_reg_field spirxeinte;
    rand uvm_reg_field spirxuinte;

    virtual function void build();
        //parent | size | lsb_pos | access | volatile | reset | has_reset | is_rand | individually_accessible
        spitrcinte = uvm_reg_field::type_id::create("spitrcinte");    
        spitrcinte.configure(this, 1, 11, "RW", 0, 0, 1, 1, 1);    

        spitxfinte = uvm_reg_field::type_id::create("spitxfinte");    
        spitxfinte.configure(this, 1, 11, "RW", 0, 0, 1, 1, 1);    
        spitxointe = uvm_reg_field::type_id::create("spitxointe");    
        spitxointe.configure(this, 1, 10, "RW", 0, 0, 1, 1, 1);    
        spitxeinte = uvm_reg_field::type_id::create("spitxeinte");    
        spitxeinte.configure(this, 1, 9, "RW", 0, 0, 1, 1, 1);    
        spitxuinte = uvm_reg_field::type_id::create("spitxuinte");   
        spitxuinte.configure(this, 1, 8, "RW", 0, 0, 1, 1, 1);   
 
        spirxfinte = uvm_reg_field::type_id::create("spirxfinte");    
        spirxfinte.configure(this, 1, 11, "RW", 0, 0, 1, 1, 1);    
        spirxointe = uvm_reg_field::type_id::create("spirxointe");    
        spirxointe.configure(this, 1, 10, "RW", 0, 0, 1, 1, 1);    
        spirxeinte = uvm_reg_field::type_id::create("spirxeinte");    
        spirxeinte.configure(this, 1, 9, "RW", 0, 0, 1, 1, 1);    
        spirxuinte = uvm_reg_field::type_id::create("spirxuinte");   
        spirxuinte.configure(this, 1, 8, "RW", 0, 0, 1, 1, 1);   
    endfunction

    function new(string name = "unnamed-spiinter_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
        w_spiinter_cg.new;
        r_spiinter_cg.new;
    endfunction: new
 
    covergroup w_spiinter_cg;
        option.per_instance = 1;
        SPITXFINTE: coverpoint spitxfinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXOINTE: coverpoint spitxointe {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXEINTE: coverpoint spitxeinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXUINTE: coverpoint spitxuinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXFINTE: coverpoint spirxfinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXOINTE: coverpoint spirxointe {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXEINTE: coverpoint spirxeinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXUINTE: coverpoint spirxuinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }
    endgroup: w_spiinter_cg
    
    covergroup r_spiinter_cg;
        option.per_instance = 1;
        SPITXFINTE: coverpoint spitxfinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXOINTE: coverpoint spitxointe {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXEINTE: coverpoint spitxeinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXUINTE: coverpoint spitxuinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXFINTE: coverpoint spirxfinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXOINTE: coverpoint spirxointe {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXEINTE: coverpoint spirxeinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXUINTE: coverpoint spirxuinte {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }
    endgroup: r_spiinter_cg
    
    virtual function void sample(uvm_reg_data_t    data, byte_en,
                                 bit               is_read,
                                 uvm_reg_map       map);
        super.sample(data, byte_en, is_read, map);
        if(is_read) r_spiinter_cg.sample();
        else w_spiinter_cg.sample();
    endfunction: sample
endclass: spiinter_reg

//================================================================================
// SPI Status Register
//================================================================================
class spisr_reg extends uvm_reg;
    `uvm_register_cb(spisr_reg, uvm_reg_cbs)
    `uvm_set_super_type(spisr_reg, uvm_reg)
    `uvm_object_utils(spisr_reg)

    rand uvm_reg_field spitxst;
    rand uvm_reg_field spirxst;

    function new(string name = "unnamed-spisr_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
        w_spisr_cg.new;
        r_spisr_cg.new;
    endfunction: new

    virtual function void build();
        //parent | size | lsb_pos | access | volatile | reset | has_reset | is_rand | individually_accessible
        spitxst = uvm_reg_field::type_id::create("spitxst");
        spitxst.configure(this, 6, 8, "RO", 0, 0, 1, 1, 1);
        
        spirxst = uvm_reg_field::type_id::create("spirxst");
        spirxst.configure(this, 6, 0, "RO", 0, 0, 1, 1, 1);
    endfunction: build

endclass: spisr_reg

//================================================================================
// SPI Raw interrupt Register
//================================================================================
class spirintr_reg extends uvm_reg;
    `uvm_register_cb(spirintr_reg, uvm_reg_cbs)
    `uvm_set_super_type(spirintr_reg, uvm_reg)
    `uvm_object_utils(spirintr_reg)

    rand uvm_reg_field spitrcrint;

    rand uvm_reg_field spitxfrint;
    rand uvm_reg_field spitxorint;
    rand uvm_reg_field spitxerint;
    rand uvm_reg_field spitxurint;

    rand uvm_reg_field spirxfrint;
    rand uvm_reg_field spirxorint;
    rand uvm_reg_field spirxerint;
    rand uvm_reg_field spirxurint;

    virtual function void build();
        //parent | size | lsb_pos | access | volatile | reset | has_reset | is_rand | individually_accessible
        spitrcrint = uvm_reg_field::type_id::create("spitrcrint");    
        spitrcrint.configure(this, 1, 11, "RO", 0, 0, 1, 1, 1);    

        spitxfrint = uvm_reg_field::type_id::create("spitxfrint");    
        spitxfrint.configure(this, 1, 11, "RO", 0, 0, 1, 1, 1);    
        spitxorint = uvm_reg_field::type_id::create("spitxorint");    
        spitxorint.configure(this, 1, 10, "RO", 0, 0, 1, 1, 1);    
        spitxerint = uvm_reg_field::type_id::create("spitxerint");    
        spitxerint.configure(this, 1, 9, "RO", 0, 0, 1, 1, 1);    
        spitxurint = uvm_reg_field::type_id::create("spitxurint");   
        spitxurint.configure(this, 1, 8, "RO", 0, 0, 1, 1, 1);   
 
        spirxfrint = uvm_reg_field::type_id::create("spirxfrint");    
        spirxfrint.configure(this, 1, 11, "RO", 0, 0, 1, 1, 1);    
        spirxorint = uvm_reg_field::type_id::create("spirxorint");    
        spirxorint.configure(this, 1, 10, "RO", 0, 0, 1, 1, 1);    
        spirxerint = uvm_reg_field::type_id::create("spirxerint");    
        spirxerint.configure(this, 1, 9, "RO", 0, 0, 1, 1, 1);    
        spirxurint = uvm_reg_field::type_id::create("spirxurint");   
        spirxurint.configure(this, 1, 8, "RO", 0, 0, 1, 1, 1);   
    endfunction

    function new(string name = "unnamed-spirintr_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
        w_spirintr_cg.new;
        r_spirintr_cg.new;
    endfunction: new
 
    covergroup w_spirintr_cg;
        option.per_instance = 1;
        SPITXFRINT: coverpoint spitxfrint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXORINT: coverpoint spitxorint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXERINT: coverpoint spitxerint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXURINT: coverpoint spitxurint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXFRINT: coverpoint spirxfrint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXORINT: coverpoint spirxorint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXERINT: coverpoint spirxerint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXURINT: coverpoint spirxurint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }
    endgroup: w_spirintr_cg
    
    covergroup r_spirintr_cg;
        option.per_instance = 1;
        SPITXFRINT: coverpoint spitxfrint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXORINT: coverpoint spitxorint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXERINT: coverpoint spitxerint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXURINT: coverpoint spitxurint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXFRINT: coverpoint spirxfrint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXORINT: coverpoint spirxorint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXERINT: coverpoint spirxerint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXURINT: coverpoint spirxurint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }
    endgroup: r_spirintr_cg
    
    virtual function void sample(uvm_reg_data_t    data, byte_en,
                                 bit               is_read,
                                 uvm_reg_map       map);
        super.sample(data, byte_en, is_read, map);
        if(is_read) r_spirintr_cg.sample();
        else w_spirintr_cg.sample();
    endfunction: sample
endclass: spirintr_reg

//================================================================================
// SPI interrupt Register
//================================================================================
class spiintr_reg extends uvm_reg;
    `uvm_register_cb(spiintr_reg, uvm_reg_cbs)
    `uvm_set_super_type(spiintr_reg, uvm_reg)
    `uvm_object_utils(spiintr_reg)

    rand uvm_reg_field spitrcint;

    rand uvm_reg_field spitxfint;
    rand uvm_reg_field spitxoint;
    rand uvm_reg_field spitxeint;
    rand uvm_reg_field spitxuint;

    rand uvm_reg_field spirxfint;
    rand uvm_reg_field spirxoint;
    rand uvm_reg_field spirxeint;
    rand uvm_reg_field spirxuint;

    virtual function void build();
        //parent | size | lsb_pos | access | volatile | reset | has_reset | is_rand | individually_accessible
        spitrcint = uvm_reg_field::type_id::create("spitrcint");    
        spitrcint.configure(this, 1, 11, "RO", 0, 0, 1, 1, 1);    

        spitxfint = uvm_reg_field::type_id::create("spitxfint");    
        spitxfint.configure(this, 1, 11, "RO", 0, 0, 1, 1, 1);    
        spitxoint = uvm_reg_field::type_id::create("spitxoint");    
        spitxoint.configure(this, 1, 10, "RO", 0, 0, 1, 1, 1);    
        spitxeint = uvm_reg_field::type_id::create("spitxeint");    
        spitxeint.configure(this, 1, 9, "RO", 0, 0, 1, 1, 1);    
        spitxuint = uvm_reg_field::type_id::create("spitxuint");   
        spitxuint.configure(this, 1, 8, "RO", 0, 0, 1, 1, 1);   
 
        spirxfint = uvm_reg_field::type_id::create("spirxfint");    
        spirxfint.configure(this, 1, 11, "RO", 0, 0, 1, 1, 1);    
        spirxoint = uvm_reg_field::type_id::create("spirxoint");    
        spirxoint.configure(this, 1, 10, "RO", 0, 0, 1, 1, 1);    
        spirxeint = uvm_reg_field::type_id::create("spirxeint");    
        spirxeint.configure(this, 1, 9, "RO", 0, 0, 1, 1, 1);    
        spirxuint = uvm_reg_field::type_id::create("spirxuint");   
        spirxuint.configure(this, 1, 8, "RO", 0, 0, 1, 1, 1);   
    endfunction

    function new(string name = "unnamed-spiintr_reg");
        super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
        w_spiintr_cg.new;
        r_spiintr_cg.new;
    endfunction: new
 
    covergroup w_spiintr_cg;
        option.per_instance = 1;
        SPITXFINT: coverpoint spitxfint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXOINT: coverpoint spitxoint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXEINT: coverpoint spitxeint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXUINT: coverpoint spitxuint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXFINT: coverpoint spirxfint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXOINT: coverpoint spirxoint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXEINT: coverpoint spirxeint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXUINT: coverpoint spirxuint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }
    endgroup: w_spiintr_cg
    
    covergroup r_spiintr_cg;
        option.per_instance = 1;
        SPITXFINT: coverpoint spitxfint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXOINT: coverpoint spitxoint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXEINT: coverpoint spitxeint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPITXUINT: coverpoint spitxuint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXFINT: coverpoint spirxfint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXOINT: coverpoint spirxoint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXEINT: coverpoint spirxeint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }

        SPIRXUINT: coverpoint spirxuint {
            bins    ENABLE = {1};
            bins    DISABLE = {0};
        }
    endgroup: r_spiintr_cg
    
    virtual function void sample(uvm_reg_data_t    data, byte_en,
                                 bit               is_read,
                                 uvm_reg_map       map);
        super.sample(data, byte_en, is_read, map);
        if(is_read) r_spiintr_cg.sample();
        else w_spiintr_cg.sample();
    endfunction: sample
endclass: spiintr_reg

//================================================================================
// SPI Register Block
//================================================================================

class spi_reg_block extends uvm_reg_block;
    `uvm_object_utils(spi_reg_block)

    rand spicr_reg     spicr;
    rand spibr_reg     spibr;
    rand spiinter_reg  spiinter;
    rand spisr_reg     spisr;
    rand spirintr_reg  spirintr;
    rand spiintr_reg   spiintr;

    function new(string name = "spi_reg_block");
        super.new(name);
    endfunction

    virtual function build();
        //Create all registers 
        spicr    = spicr_reg::type_id::create("spicr",,get_full_name());
        spibr    = spibr_reg::type_id::create("spibr",, get_full_name());
        spiinter = spiinter_reg::type_id::create("spiinter",, get_full_name());
        spisr    = spisr_reg::type_id::create("spisr",, get_full_name());
        spirintr = spirintr_reg::type_id::create("spirintr",, get_full_name());
        spiintr  = spiinter_reg::type_id::create("spiintr",, get_full_name());

        //Set parent || hdl path
        spicr.configure(this, null, ""); 
        spibr.configure(this, null, ""); 
        spiinter.configure(this, null, "");
        spisr.configure(this, null, ""); 
        spirintr.configure(this, null, "");
        spiintr.configure(this, null, ""); 
        
        //Build all registers
        spicr.build(); 
        spibr.build(); 
        spiinter.build();
        spisr.build(); 
        spirintr.build();
        spiintr.build(); 
        
        //Address Mapping
        default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN);
        default_map.add_reg(spicr, `UVM_REG_ADDR_WIDTH'h0, "RW");
        default_map.add_reg(spibr, `UVM_REG_ADDR_WIDTH'h4, "RW");
        default_map.add_reg(spiinter, `UVM_REG_ADDR_WIDTH'h8, "RW");
        default_map.add_reg(spisr, `UVM_REG_ADDR_WIDTH'hC, "RO");
        default_map.add_reg(spirintr, `UVM_REG_ADDR_WIDTH'h10, "RO");
        default_map.add_reg(spiintr, `UVM_REG_ADDR_WIDTH'h14, "RO"); 
    endfunction: build
endclass: spi_reg_block

//================================================================================
// Address Map
//================================================================================

class spi_reg_addr_map extends uvm_reg_block;
    `uvm_object_utils(spi_reg_addr_map)
        
    rand spi_reg_block spi_regs;     

    function new(string name = "spi_reg_addr_map");
        super.new(name);
    endfunction: new

    virtual function void build();
        default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN);
        spi_regs = spi_reg_block::type_id::create("spi_regs",, get_full_name());
        spi_regs.configure(this, "spi_top.reg_model");
        spi_regs.build();
        spi_regs.lock_model();
        default_map.add_submap(spi_regs.default_map, `UVM_REG_ADDR_WIDTH'h0);
        //set_hdl_path_root("");
        default_map.set_check_on_read(); 
    endfunction
endclass: spi_reg_addr_map
