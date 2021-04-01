#!/usr/bin/perl
#======================================================================================
# File Name: 		arb_gen.pl
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
my $sample = '../Sample/AHB_arbiter.sv';
my $AHB_config = '../Input/AHB_config.xlsx';
my $dest = '../Gen_Result/arbiter/AHB_arbiter_';
my $data = ReadData(${AHB_config});
#say "A1 " . $data->[2]{A1};
my $spe = "@";

print ("****************************************************************************\n");
print ("                              AHB_config\n");
print ("****************************************************************************\n");
print (" File Name: 	arb_gen.pl\n");
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

my @sheet_3_data = Spreadsheet::Read::rows($data->[3]);

my $prior_level;

foreach my $i (0 .. scalar @sheet_3_data)
{
  if($sheet_3_data[$i][0] eq 'PRIOR_LEVEL')
  {
    $prior_level = $sheet_3_data[$i][1];
  }
  elsif(($sheet_3_data[$i][0] eq 'ARBITER_IDENTIFY') && ($sheet_3_data[$i][1] ne 'sample'))
  {
    my $slave_name = $sheet_3_data[$i][1];
    $i++;
    my $master_num = $sheet_3_data[$i][1];
    $i++;

    open(SAMPLE, "<${sample}") or die "CAN'T open sample file";
    open(DEST, ">${dest}${slave_name}.sv\n");
    
    while (my $line = <SAMPLE>)
    {
      #db print ("db_2\n");
      $line =~ s/#NUM#/_$slave_name/;
      $line =~ s///;
      print DEST "$line";
      if($line =~ /#CONFIG_GEN#/)
      {
        print ("$slave_name\n");
        if($sheet_3_data[$i][1] eq 'YES')
        {
          print ("$sheet_3_data[$i][0]\n");
          print DEST ("\t`define FIXED_PRIORITY_ARBITER_$slave_name\n");
        }
        elsif($sheet_3_data[$i+1][1] eq 'YES')
        {
          print ("$sheet_3_data[$i+1][0]\n");
          print DEST ("\t`define DYNAMIC_PRIORITY_ARBITER_$slave_name\n");
        }
        elsif($sheet_3_data[$i+2][1] eq 'YES')
        {
          print ("$sheet_3_data[$i+2][0]\n");
          print DEST ("\t`define ROUND_ROBIN_ARBITER_$slave_name\n");
        }
        else
        {
          print DEST ("\t`define ONE_PATH_$slave_name\n");
        }
        $i++;
        $i++;
      }
      elsif($line =~ /#PARAGEN#/)
      {
        if($sheet_3_data[$i-1][1] eq 'YES')
        {
          print DEST ("\tparameter SLAVE_X_PRIOR_LEVEL = ${prior_level},\n");
          #Hung db 4_2_2020 print DEST ("\tparameter SLAVE_X_PRIOR_BIT = \$clog2(SLAVE_X_PRIOR_LEVEL),\n");
          print DEST ("\tparameter SLAVE_X_PRIOR_BIT = SLAVE_X_PRIOR_LEVEL,\n");
        }

        if($sheet_3_data[$i][1] eq 'YES')
        {
          print DEST ("\tparameter SLAVE_X_PRIOR_LEVEL = ${master_num},\n");
          print DEST ("\tparameter SLAVE_X_PRIOR_BIT = \$clog2(SLAVE_X_PRIOR_LEVEL),\n");
        }
        
        print DEST ("\tparameter SLAVE_X_MASTER_NUM = ${master_num}\n");
      }
    }
    close(SAMPLE);
    close(DEST);
  }
}

