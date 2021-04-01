#!/usr/bin/perl
#======================================================================================
# File Name: 		mux_gen.pl
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
my $sample = '../Sample/AHB_mux.sv';
my $AHB_config = '../Input/AHB_config.xlsx';
my $dest_si = '../Gen_Result/mux/AHB_si_mux_';
my $dest_mi = '../Gen_Result/mux/AHB_mi_mux_';
my $data = ReadData(${AHB_config});
#say "A1 " . $data->[2]{A1};
my $spe = "@";

print ("****************************************************************************\n");
print ("                              AHB_config\n");
print ("****************************************************************************\n");
print (" File Name: 	mux_gen.pl\n");
print (" Project Name:	AHB_Gen\n");
print (" Email:         quanghungbk1999${spe}gmail.com\n");
print (" Version    Date      Author      Description\n");
print (" v0.0       22/11/2020 Quang Hung  First Creation, this version does not support\n");
print ("                                   hsplit & hretry\n");
print ("****************************************************************************\n");
print ("                              AHB_config\n");
print ("****************************************************************************\n");

my $sheet_1_name = say $data->[1]{A1};
my $sheet_3_name = say $data->[2]{A1};
my @sheet_1_data = Spreadsheet::Read::rows($data->[1]);
my @sheet_3_data = Spreadsheet::Read::rows($data->[3]);
my $addr_width;


foreach my $i (0 .. scalar @sheet_1_data)
{
  if(($sheet_1_data[$i][0] eq 'DECODER_IDENTIFY') && ($sheet_1_data[$i][1] ne 'sample'))
  {
    my $master_name = $sheet_1_data[$i][1];
    #$i++;
    #$i++;
    $i++;
    my $slave_num = $sheet_1_data[$i][1];
    $i++;

    open(SAMPLE, "<${sample}") or die "CAN'T open sample file"; 
    open(DEST, ">${dest_si}${master_name}.sv");
    #db print("${dest}${master_name}.sv\n");
    
    while (my $line = <SAMPLE>)
    {
      #db print ("db_2\n");
      $line =~ s/#NUM#/_$master_name/;
      $line =~ s/#CHNUM#/$slave_num/;
      $line =~ s///;
      print DEST "$line";
      if($line =~ /#CONFIG_GEN#/)
      {
        #print DEST "\t`define CHNUM ${slave_num}\n";
        print DEST "\t`define MAS_$master_name\n";
      }
    }
    close(SAMPLE);
    close(DEST);
  }
}

foreach my $j (0 .. scalar @sheet_3_data)
{
  if(($sheet_3_data[$j][0] eq 'ARBITER_IDENTIFY') && ($sheet_3_data[$j][1] ne 'sample'))
  {
    my $slave_name = $sheet_3_data[$j][1];
    $j++;
    my $master_num = $sheet_3_data[$j][1];
    
    open(SAMPLE, "<${sample}") or die "CAN'T open sample file"; 
    open(DEST, ">${dest_mi}${slave_name}.sv");

    while (my $line = <SAMPLE>)
    {
      #db print ("db_2\n");
      $line =~ s/#NUM#/_$slave_name/;
      $line =~ s/#CHNUM#/$master_num/;
      $line =~ s///;
      print DEST "$line";
      if($line =~ /#CONFIG_GEN#/)
      {
        #print DEST "\t`define CHNUM ${master_num}\n";
        print DEST "\t`define SLV_$slave_name\n";
      }
    }
    close(SAMPLE);
    close(DEST);
  }
}
