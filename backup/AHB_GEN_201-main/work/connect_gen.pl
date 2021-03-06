#!/usr/bin/perl
#======================================================================================
# File Name: 		connect_gen.pl
# Project Name:	AHB_Gen
# Email:         quanghungbk1999@gmail.com
# Version    Date      Author      Description
# v0.0       29/11/2020 Quang Hung  First Creation, this version does not support
#                                   hsplit & hretry
#======================================================================================

use 5.016;
use warnings;
use strict;

use Spreadsheet::Read qw(ReadData);
my $sample = '../Sample/AHB_bus.sv';
my $AHB_config = '../Input/AHB_config.xlsx';
my $dest = '../Gen_Result/AHB_bus.sv';
my $data = ReadData(${AHB_config});
#say "A1 " . $data->[2]{A1};
my $spe = "@";

print ("****************************************************************************\n");
print ("                              AHB_config\n");
print ("****************************************************************************\n");
print (" File Name: 	connect_gen.pl\n");
print (" Project Name:	AHB_Gen\n");
print (" Email:         quanghungbk1999${spe}gmail.com\n");
print (" Version    Date      Author      Description\n");
print (" v0.0       29/11/2020 Quang Hung  First Creation, this version does not support\n");
print ("                                   hsplit & hretry\n");
print ("****************************************************************************\n");
print ("                              AHB_config\n");
print ("****************************************************************************\n");

my $sheet_1_name = say $data->[1]{A1};
my $sheet_2_name = say $data->[2]{A1};
my $sheet_3_name = say $data->[3]{A1};
my $sheet_4_name = say $data->[4]{A1};
my @sheet_1_data = Spreadsheet::Read::rows($data->[1]);
my @sheet_2_data = Spreadsheet::Read::rows($data->[2]);
my @sheet_3_data = Spreadsheet::Read::rows($data->[3]);
my @sheet_4_data = Spreadsheet::Read::rows($data->[4]);

open(SAMPLE, "<${sample}") or die "CAN'T open sample file"; 
open(DEST, ">${dest}");

my $prior_level = $sheet_3_data[1][1];

while (my $line = <SAMPLE>)
{
  #db print ("db_2\n");
  $line =~ s/
//;
  print DEST "$line\n";
  if($line =~ /#SI#/)
  {
    foreach my $i_1 (0 .. scalar @sheet_1_data)
    {
      if(($sheet_1_data[$i_1][0] eq 'DECODER_IDENTIFY') && ($sheet_1_data[$i_1][1] ne 'sample'))
      {
        my $master_name = $sheet_1_data[$i_1][1];
        #print DEST ("\toutput mas_send_type  ${master_name}_out,\n");
        #print DEST ("\tinput  [\$clog2(${prior_level})-1:0]  hprior_${master_name},\n");
        #print DEST ("\tinput  slv_send_type  ${master_name}_in,\n");
        print DEST ("\tinput  mas_send_type  ${master_name}_in,\n");
        #print DEST ("\tinput  [\$clog2(${prior_level})-1:0]  hprior_${master_name},\n");
        print DEST ("\tinput  [${prior_level}-1:0]  hprior_${master_name},\n");
        #print DEST ("\tinput  [${prior_level}-1:0]  hprior_${master_name},\n");
        print DEST ("\toutput  slv_send_type  ${master_name}_out,\n");
      }
    }
  }
  elsif($line =~ /#MI#/)
  {
    foreach my $i_1 (0 .. scalar @sheet_3_data)
    {
      if(($sheet_3_data[$i_1][0] eq 'ARBITER_IDENTIFY') && ($sheet_3_data[$i_1][1] ne 'sample'))
      {
        my $slave_name = $sheet_3_data[$i_1][1];
        #print DEST ("\toutput slv_send_type  ${slave_name}_out,\n");
        #print DEST ("\toutput hsel_${slave_name},\n");
        #print DEST ("\tinput  mas_send_type  ${slave_name}_in,\n");
        print DEST ("\tinput  slv_send_type  ${slave_name}_in,\n");
        print DEST ("\toutput hsel_${slave_name},\n");
        print DEST ("\toutput mas_send_type  ${slave_name}_out,\n");
      }
    }
    print DEST ("\tinput\t\t\t\t\t hclk,\n");
    print DEST ("\tinput\t\t\t\t\t hreset_n\n");
  }
  elsif($line =~ /#SIGGEN#/) 
  {
    foreach my $i_1 (0 .. scalar @sheet_1_data)
    {
      if(($sheet_1_data[$i_1][0] eq 'DECODER_IDENTIFY') && ($sheet_1_data[$i_1][1] ne 'sample'))
      {
        my $master_name = $sheet_1_data[$i_1][1];
        $i_1++;
        #$i_1++;
        #$i_1++;
        my $slave_num = $sheet_1_data[$i_1][1];
        print DEST ("\tlogic [${slave_num}-1:0][MI_PAYLOAD-1:0] payload_${master_name}_in;\n");
        #print DEST ("\tlogic [MI_PAYLOAD-1:0] payload_${master_name}_out;\n");
        print DEST ("\tslv_send_type payload_${master_name}_out;\n");
        print DEST ("\tlogic default_slv_sel_${master_name};\n");
        print DEST ("\tlogic [${slave_num}-1:0] hreq_${master_name};\n");
      }
    }

    print DEST ("\n");

    foreach my $i_1 (0 .. scalar @sheet_3_data)
    {
      if(($sheet_3_data[$i_1][0] eq 'ARBITER_IDENTIFY') && ($sheet_3_data[$i_1][1] ne 'sample'))
      {
        my $slave_name = $sheet_3_data[$i_1][1];
        $i_1++;
        #$i_1++;
        #$i_1++;
        my $master_num = $sheet_3_data[$i_1][1];
        print DEST ("\tlogic [${master_num}-1:0] hreq_${slave_name};\n");
        print DEST ("\tlogic [${master_num}-1:0][SI_PAYLOAD-1:0] payload_${slave_name}_in;\n");
        #print DEST ("\tlogic [SI_PAYLOAD-1:0] payload_${slave_name}_out;\n");
        print DEST ("\tmas_send_type payload_${slave_name}_out;\n");
        print DEST ("\tlogic [${master_num}-1:0] hgrant_${slave_name};\n");
        #Hung mod 28_12
        #Hung mod 4_2_2020 print DEST ("\tlogic [${master_num}-1:0][\$clog2($prior_level)-1:0] hprior_${slave_name};\n");
        print DEST ("\tlogic [${master_num}-1:0][$prior_level-1:0] hprior_${slave_name};\n");
          # Hung add 12/12
          #my $master_num = $sheet_3_data[$i_1][1]; 
        foreach my $k (0 .. scalar @sheet_4_data)
        {
          if($slave_name eq $sheet_4_data[$k][0])
          {
            #print DEST ("\n");
            #db print ("db..........................\n");
            my @row = Spreadsheet::Read::row($data->[4], $k+1);
            for my $h (1 .. $#row) {
              if($row[$h] ne 'N')
              {
                print DEST ("\tlogic hgrant_${slave_name}_${sheet_4_data[2][$h]};\n");
              }
            }
          }
        }
          # Hung add 12/12
      }
    }
  }
  elsif($line =~ /#DECGEN#/)
  {
    foreach my $i_1 (0 .. scalar @sheet_1_data)
    {
      if(($sheet_1_data[$i_1][0] eq 'DECODER_IDENTIFY') && ($sheet_1_data[$i_1][1] ne 'sample'))
      {
        my $master_name = $sheet_1_data[$i_1][1];
        print DEST ("\tAHB_decoder_${master_name} DEC_${master_name}");
        print DEST ("\t(\n"); 
        print DEST ("\t\t.haddr(${master_name}_in.haddr),\n");
        print DEST ("\t\t.htrans(${master_name}_in.htrans),\n");
        #print DEST ("\t\t.htrans(htrans_${master_name}),\n");
        #print DEST ("\t\t.hremap(hremap_${master_name}),\n");
        #print DEST ("\t\t.hsplit(hsplit_${master_name}),\n");
        print DEST ("\t\t.default_slv_sel(default_slv_sel_${master_name}),\n");
        print DEST ("\t\t.hreq(hreq_${master_name}),\n");
        print DEST ("\t\t.*\n");
        print DEST ("\t);\n\n\n");  
        print DEST ("\tAHB_mux_${master_name} MUX_${master_name}\n");  
        print DEST ("\t(\n");  
        print DEST ("\t\t.payload_in(payload_${master_name}_in),\n");  
        print DEST ("\t\t.payload_out(payload_${master_name}_out),\n");  
        print DEST ("\t\t.sel(hreq_${master_name})\n");  
        print DEST ("\t);\n\n");  
      }
    }
  }
  elsif($line =~ /#ARBGEN#/)
  {
    foreach my $i_1 (0 .. scalar @sheet_3_data)
    {
      if(($sheet_3_data[$i_1][0] eq 'ARBITER_IDENTIFY') && ($sheet_3_data[$i_1][1] ne 'sample'))
      {
        my $slave_name = $sheet_3_data[$i_1][1];
        $i_1++;
        $i_1++;
        $i_1++;
        #$i_1++;
        my $prior = $sheet_3_data[$i_1][1];
        print DEST ("\tAHB_arbiter_${slave_name } ARB_${slave_name}\n");
        print DEST ("\t(\n"); 
        print DEST ("\t\t.hreq(hreq_${slave_name}),\n"); 
        print DEST ("\t\t.hburst(payload_${slave_name}_out.hburst),\n"); 
        print DEST ("\t\t.hwait(~${slave_name}_in.hreadyout),\n"); 
        print DEST ("\t\t.hgrant(hgrant_${slave_name}),\n"); 
        print DEST ("\t\t.hsel(hsel_${slave_name}),\n");
        if($prior eq 'YES')
        {
          print DEST ("\t\t.hprior(hprior_${slave_name}),\n"); 
        }
        print DEST ("\t\t.*\n");
        print DEST ("\t);\n\n\n");  
        print DEST ("\tAHB_mux_${slave_name} MUX_${slave_name}\n");  
        print DEST ("\t(\n");  
        print DEST ("\t\t.payload_in(payload_${slave_name}_in),\n");  
        print DEST ("\t\t.payload_out(payload_${slave_name}_out),\n");  
        #Hung db 4_2_2021 
        print DEST ("\t\t.sel(hgrant_${slave_name})\n");  
        #print DEST ("\t\t.sel(hsel_${slave_name})\n");  
        #print DEST ("\t\t.sel(hreq_${slave_name})\n");  
        print DEST ("\t);\n\n");  
      }
    }
  }
  elsif($line eq '//#CROSSGEN#')
  {
    #db print ("Reach...................\n");
    foreach my $i_1 (0 .. scalar @sheet_3_data)
    {
      if(($sheet_3_data[$i_1][0] eq 'ARBITER_IDENTIFY') && ($sheet_3_data[$i_1][1] ne 'sample'))
      {
        my $slave_name = $sheet_3_data[$i_1][1];
        print DEST ("\tassign ${slave_name}_out = payload_${slave_name}_out;\n");
        $i_1++;
        my $master_num = $sheet_3_data[$i_1][1]; 
        foreach my $k (0 .. scalar @sheet_4_data)
        {
          if($slave_name eq $sheet_4_data[$k][0])
          {
            print DEST ("\n");
            #db print ("db..........................\n");
            my @row = Spreadsheet::Read::row($data->[4], $k+1);
            print DEST ("\tassign hreq_${slave_name} = {");
            for my $h (1 .. $#row) {
              if($row[$h] ne 'N')
              {
                $master_num--;
                if($master_num != 0)
                {
                  print DEST (" hreq_${sheet_4_data[2][$h]}[$row[$h]],");
                }
                else
                {
                  print DEST (" hreq_${sheet_4_data[2][$h]}[$row[$h]]");
                }
              }
            }
            print DEST ("};\n");
          }

          # Hung add 12/12
          my $master_num = $sheet_3_data[$i_1][1]; 
          if($slave_name eq $sheet_4_data[$k][0])
          {
            #print DEST ("\n");
            #db print ("db..........................\n");
            my @row = Spreadsheet::Read::row($data->[4], $k+1);
            print DEST ("\tassign {");
            for my $h (1 .. $#row) {
              if($row[$h] ne 'N')
              {
                $master_num--;
                if($master_num != 0)
                {
                  print DEST (" hgrant_${slave_name}_${sheet_4_data[2][$h]},");
                }
                else
                {
                  print DEST (" hgrant_${slave_name}_${sheet_4_data[2][$h]}} = hgrant_${slave_name};\n");
                }
              }
            }
          }
          # Hung add 12/12

          my $master_num = $sheet_3_data[$i_1][1]; 
          if($slave_name eq $sheet_4_data[$k][0])
          {
            #print DEST ("\n");
            #db print ("db..........................\n");
            my @row = Spreadsheet::Read::row($data->[4], $k+1);
            print DEST ("\tassign hprior_${slave_name} = {");
            for my $h (1 .. $#row) {
              if($row[$h] ne 'N')
              {
                $master_num--;
                if($master_num != 0)
                {
                  print DEST (" hprior_${sheet_4_data[2][$h]},");
                }
                else
                {
                  print DEST (" hprior_${sheet_4_data[2][$h]}");
                }
              }
            }
            print DEST ("};\n");
          }

          my $master_num = $sheet_3_data[$i_1][1]; 
          if($slave_name eq $sheet_4_data[$k][0])
          {
            #db print ("db..........................\n");
            my @row = Spreadsheet::Read::row($data->[4], $k+1);
            for my $h (1 .. $#row) {
              if($row[$h] ne 'N')
              {
                $master_num--;
                print DEST ("\tassign payload_${slave_name}_in[${master_num}] = ${sheet_4_data[2][$h]}_in;\n");
              }
            }
          }
        }
      }
    }
    
    print DEST ("\n");

    foreach my $i_1 (0 .. scalar @sheet_3_data)
    {
      if(($sheet_1_data[$i_1][0] eq 'DECODER_IDENTIFY') && ($sheet_1_data[$i_1][1] ne 'sample'))
      {
        my $master_name = $sheet_1_data[$i_1][1];
        print DEST ("\tassign ${master_name}_out = payload_${master_name}_out;\n");
        $i_1++;
        my $slave_num = $sheet_1_data[$i_1][1];
        print ("$slave_num\n");
        my @row = Spreadsheet::Read::row($data->[4], 3);
        for my $h (1 .. $#row) 
        {
          #my $slave_num = $sheet_1_data[$i_1][1]; 
          if($row[$h] eq $master_name)
          {
            #db print ("db\n");
            #db print ("$master_name\n");
            print DEST ("\n");
            my $count = 0;
            foreach my $k (3 .. scalar @sheet_4_data)
            #foreach my $k (($h + 1) .. scalar @sheet_4_data)
            {
              if(($sheet_4_data[$k][$h] ne 'N') && ($count < $slave_num))
              {
                $count++;
                #db print ("db\n");
                #db print ("$count vs $slave_num\n");
                print DEST ("\tassign payload_${master_name}_in[$sheet_4_data[$k][$h]] =".
                " {$sheet_4_data[$k][0]_in.hreadyout & hgrant_${sheet_4_data[$k][0]}_${master_name}, $sheet_4_data[$k][0]_in.hrdata, $sheet_4_data[$k][0]_in.hresp};\n");
              }                          
            }                            
          }                              
        }                                
      }                                  
    }                                    
  }                                      
}                                        
                                         


close(SAMPLE);
close(DEST);

