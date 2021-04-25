#!/bin/csh
#######################################################
# Author:         Quang Hung
# Date:           24/11/2020
# Description:    SV simulate
#######################################################

set now = 105747 #`date '+%H%M%S'`
echo $now
#Display
    echo 'Syntax: run_vcs ' 

#set top = "../02_tb/top.sv"
#set top = `grep "\<module\>" ${top} | awk '{print $2}' | sed -e 's/(*);//' -e 's/(//' -e 's/;//'`  

set top = "top"
echo $top
set log_file = "${top}.log"
set run_list = `cat ./run_list`

bs -os REDHATE5_0 -m HOSTGR_L -M 1900 -tool vhdlan \
   -source /common/appl/Env/Synopsys/vcs-mx_vL-2016.06-SP2 \
   -J ipmmu_OSID/tlb_osid_16osid \
   vcs +evalorder +error+100 \
   +vcs+lic+wait +vcs+flush+dump \
   +v2k -R -I -Mmakeprogram=gmake \
   +define+VCS \
   +memcbk \
   +dumpvars \
   -debug_all \
   -debug_access+all \
   -sverilog \
   -full64 \
   +nowarn+INVPRG \
   -l ${log_file}    \
   -cm tgl+line+cond+branch+fsm -cm_hier ../tb/crv/ahb_coverage.sv -cm_name cov_report \
   #urg -dir ./sim/top/simv.vdb -report report \
   ${run_list} +ntb_random_seed=${now} 

if(-e ./sim/${top}) then
    rm -rf ./sim/${top} 
    rm -rf ./log/${top}  
    rm -rf ./result/${top}  
endif
    mkdir ./sim/${top}
    mkdir ./log/${top}
    mkdir ./result/${top} 
    
#	sed -n '/Coverage Metrics Release L-2016.06-SP2_Full64 Copyright (c) 1991-2016 by Synopsys Inc/,$p' ./${log_file} | tee ./result/${top}/result
#   sed -n '/Compiler version L-2016.06-SP2_Full64; Runtime version L-2016.06-SP2_Full64/,$p' ./${log_file} | tee ./result/${top}/result
    echo "Result Gennnnn"
#nok    sed -n '/Compiler version L-2016.06-SP2_Full64; Runtime version L-2016.06-SP2_Full64/,$'  < ./${log_file} >>! ./result/${top}/result
#ok    sed -n '/Compiler version L-2016.06-SP2_Full64; Runtime version L-2016.06-SP2_Full64/,$p' ./${log_file} | tee ./result/${top}/result
    sed -n '/Compiler version L-2016.06-SP2_Full64; Runtime version L-2016.06-SP2_Full64/,$p' ./${log_file} >>! ./result/${top}/result
 
    mv ./simv*  ./sim/${top}/
    mv ./${log_file} ./log/${top}/
  
    rm -rf ./csrc
    rm -rf ./*.log
    rm -rf ./*.key
 
    echo "===========================================" 
    echo " sim:     ./sim/${top}/"
    echo " log:     ./log/${top}/${log_file}"
    echo " result:  ./result/${top}/result"
    echo "===========================================" 



