#!/usr/bin/perl
#======================================================================================
# File Name: 		dec_gen.pl
# Project Name:	AHB_Gen
# Email:         quanghungbk1999@gmail.com
# Version    Date      Author      Description
# v0.0       22/11/2020 Quang Hung  First Creation, this version does not support
#                                   hsplit & hretry
#======================================================================================

use 5.016;
use warnings;
use strict;

use Spreadsheet::Read qw(ReadData);
my $sample = '../Sample/AHB_decoder.sv';
my $AHB_config = '../Input/AHB_config.xlsx';
my $dest = '../Gen_Result/decoder/AHB_decoder_';
my $data = ReadData(${AHB_config});
#say "A1 " . $data->[2]{A1};
my $spe = "@";

print ("****************************************************************************\n");
print ("                              AHB_config\n");
print ("****************************************************************************\n");
print (" File Name: 	dec_gen.pl\n");
print (" Project Name:	AHB_Gen\n");
print (" Email:         quanghungbk1999${spe}gmail.com\n");
print (" Version    Date      Author      Description\n");
print (" v0.0       22/11/2020 Quang Hung  First Creation, this version does not support\n");
print ("                                   hsplit & hretry\n");
print ("****************************************************************************\n");
print ("                              AHB_config\n");
print ("****************************************************************************\n");

my $sheet_1_name = say $data->[1]{A1};
my $sheet_2_name = say $data->[2]{A1};
my @sheet_1_data = Spreadsheet::Read::rows($data->[1]);
my @sheet_2_data = Spreadsheet::Read::rows($data->[2]);
my $addr_width;
#my $master_name;




foreach my $i_1 (0 .. scalar @sheet_1_data)
{
  if($sheet_1_data[$i_1][0] eq 'ADDR_WIDTH') 
  {
    $addr_width =  $sheet_1_data[$i_1][1];
  }
  elsif(($sheet_1_data[$i_1][0] eq 'DECODER_IDENTIFY') && ($sheet_1_data[$i_1][1] ne 'sample'))
  {
    my $master_name = $sheet_1_data[$i_1][1];
    $i_1++;
    #my $fsm_type = $sheet_1_data[$i_1][1];
    #$i_1++;
    #my $glitch_free  = $sheet_1_data[$i_1][1];
    #$i_1++;
    my $in_ff  = $sheet_1_data[$i_1][1];
    #$i_1++;
    #my $out_ff  = $sheet_1_data[$i_1][1];
    #$i_1++;
    my $slave_num  = $sheet_1_data[$i_1][1];
    $i_1++;
    my @slave_name_a;
    my $slave_name;
   
    #db print ("db_1\n");
    for(my $k = 1; $k <= $slave_num + 1; $k++) 
    {
      push(@slave_name_a, $sheet_1_data[$i_1][$k]);
    } 
    open(SAMPLE, "<${sample}") or die "CAN'T open sample file"; 
    open(DEST, ">${dest}${master_name}.sv");
    #db print("${dest}${master_name}.sv\n");
    
    while (my $line = <SAMPLE>)
    {
      #db print ("db_2\n");
      $line =~ s/#NUM#/_$master_name/;
      $line =~ s///;
      print DEST "$line";
      #if($line =~ /#CONFIG_GEN#/)
      if($line eq '#CONFIG_GEN#')
      {
        #db print ("$fsm_type\n");
        #db print ("**********************");
        #if($fsm_type eq 'DEC')  
        #{
        #  print DEST "\t`define DECODE_STATE_FSM \n";    
        #}
        #else
        #{
        #  print DEST "\t`define NON_DECODE_STATE_FSM \n";    
        #}

        #if($glitch_free eq 'YES')
        #{
        #  print DEST "\t`define GLITCH_FREE\n";
        #}
        #Hung modify FF stage
        #if($in_ff eq 'YES')
        #{
        #  print DEST "\t`define IN_FF\n";
        #}
    
        #if($out_ff eq 'YES')
        #{
        #  print DEST "\t`define OUT_FF\n";
        #}
      }
      elsif($line =~ /#PARAGEN#/)
      {
        print DEST ("\tparameter AHB_ADDR_WIDTH = ${addr_width},\n");
        print DEST ("\tparameter MASTER_X_SLAVE_NUM = ${slave_num}\n");
      }
      elsif($line =~ /#ADDRMAPGEN#/)  
      {
        #db print ("db_3\n");
        print ("$slave_num");
        #for(my $g = 0; $g < $slave_num; $g++) 
        my $k = 0;
        for(my $g = $slave_num-1; $g >= 0 ;$g--) 
        {
          #db print ("@slave_name_a[$g]\n");
          my $cr_sl_name = @slave_name_a[$g];
          #db
          print ("..................................................................................\n");
          print ("$cr_sl_name\n");
          foreach my $slave (0 .. scalar @sheet_2_data)      
          {
            if($sheet_2_data[${slave}][0] eq $cr_sl_name)
            {
              print DEST ("\//db\t${cr_sl_name}\n");
              print DEST "\tassign low_addr[${k}] = ${addr_width}'h$sheet_2_data[${slave}][1];\n";
              print DEST "\tassign high_addr[${k}] = ${addr_width}'h$sheet_2_data[${slave}][2];\n";
            }
          }
          $k++;
        }
      }
    }
    close(SAMPLE);
    close(DEST);
  }
}


  print ("$addr_width\n");
