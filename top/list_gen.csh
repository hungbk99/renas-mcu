#!/bin/csh

set ahb_dir = "../AMBA_BUS/AHB_GEN_202/Gen_Result"
set cpu_dir = "../RISC-V/renas_cpu/src/rtl"
rm  -rf run_list

foreach src_file(`find ${ahb_dir} -iname "*.sv"`)
    echo ${src_file} | tee -a run_list 
end

foreach src_file(`find ${cpu_dir} -iname "*.sv"`)
    echo ${src_file} | tee -a run_list 
end
