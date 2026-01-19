#!/bin/bash

pc_folder=$(pwd)
python3 --version > python_version.txt
gen_config_file="${pc_folder}/configs/genconfig_melo_hx.conf"
output="${pc_folder}/logs"
CONFIG_PARAMS="--gen_config_file ${gen_config_file} --output ${output}"
EXE="python3 pdptwse.py"

cd ../../../../src/python/
if [ ! -x "$(command -v ${EXE})" ]; then
    error "${EXE}: not found or not executable (pwd: $(pwd))"
fi

if [ ! -d ".env" ]; then
    python3 -m venv .env
    source .env/bin/activate
    if [ -f requirements.txt ]; then
        pip install --upgrade pip
        pip install -r requirements.txt
    fi
else
    source .env/bin/activate
fi

insts_folder="${pc_folder}/../../../instances/orig_ams_fg"

logs_folder="${output}/std_outs_errs"
mkdir -p "${logs_folder}"


for group in ${insts_folder}/*_*_*; do
    n_req=${group: -15:3}
    if [[ ! "$n_req" =~ ^(06R|08R|10R|12R)$ ]]; then
        continue
    fi
    group_name_prefix=$(basename "${group:0: -4}")
    mkdir -p "${logs_folder}/${group_name_prefix}_03M"
    mkdir -p "${logs_folder}/${group_name_prefix}_04M"
    for type in ${group}/t2; do
        for inst in ${type}/lr*; do
            if [[ ! "$inst" =~ 0[1-5]$ ]]; then
                continue
            fi
            for com in {3..4}; do
                instname=$(basename "$inst")
                log_name="${logs_folder}/${group_name_prefix}_0${com}M/${instname}"
                EXE_PARAMS="--inst $inst ${CONFIG_PARAMS} --cutoff_machs ${com}"
                STDOUT="${log_name}.stdout"
                STDERR="${log_name}.stderr"
                echo "$EXE ${EXE_PARAMS} 1> ${STDOUT} 2> ${STDERR}"
                $EXE ${EXE_PARAMS} 1>"${STDOUT}" 2>"${STDERR}"
                if [ -f "$STDERR" ] && [ ! -s "$STDERR" ]; then
                    rm -f "$STDERR"
                fi
            done
        done
    done
done


