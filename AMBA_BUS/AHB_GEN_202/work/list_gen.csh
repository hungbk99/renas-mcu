#!/bin/csh

set rtl_dir = "../Gen_Result"
set tb_dir = "../tb/crv"
rm  -rf run_list

foreach src_file(`find ${rtl_dir} -iname "*.sv"`)
    echo ${src_file} | tee -a run_list 
end

foreach src_file(`find ${tb_dir} -iname "*.sv"`)
    echo ${src_file} | tee -a run_list 
end
