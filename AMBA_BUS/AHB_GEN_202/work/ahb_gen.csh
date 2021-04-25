#!/bin/csh
pwd

echo '****************************************************************************'
echo '                              AHB_GEN'
echo '****************************************************************************'
echo ' File Name: 	arb_gen.pl'
echo ' Project Name:	AHB_Gen'
echo ' Email:         quanghungbk1999@gmail.com'
echo ' Version    Date       Author      Description'
echo ' v0.0       29/11/2020 Quang Hung  First Creation, this version does not support'
echo '                                   decode error, hsplit & hretry'
echo '****************************************************************************'
echo '                              AHB_GEN'
echo '****************************************************************************'

./dec_gen.pl
./arb_gen.pl
./mux_gen.pl
./connect_gen.pl

echo '============================================================================'
echo '[Result]: ./run_list' 
./list_gen.csh
echo '============================================================================'
