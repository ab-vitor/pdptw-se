#!/bin/bash

pc_folder=$(pwd)
gen_config_file="${pc_folder}/configs/genconfig_melo.conf"
output="${pc_folder}/logs"
CONFIG_PARAMS="--gen_config_file ${gen_config_file} --output ${output} --elevator"
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

run_experiment() {
    local inst="$1"
    local com="$2"
    local group_log="$3"

    local instname
    instname=$(basename "$inst")
    local log_name="${logs_folder}/${group_log}/${instname}"
    local EXE_PARAMS="--inst $inst ${CONFIG_PARAMS} --cutoff_machs ${com}"

    echo "$EXE ${EXE_PARAMS}"
    $EXE ${EXE_PARAMS}
}

jobs=(
    "2 lr203 10R_10V_04F_04M 4"
    "2 lr204 10R_10V_04F_04M 3"
    "2 lr204 10R_10V_04F_04M 4"
    "2 lr204 12R_12V_02F_04M 4"
    "2 lr202 12R_12V_04F_04M 3"
)

for job in "${jobs[@]}"; do
    set -- $job
    type="$1"
    instname="$2"
    base_group="$3"
    com="$4"

    group_log="${base_group/04M/0${com}M}"
    inst="${insts_folder}/${base_group}/t${type}/${instname}"

    run_experiment "$inst" "$com" "$group_log"
done
