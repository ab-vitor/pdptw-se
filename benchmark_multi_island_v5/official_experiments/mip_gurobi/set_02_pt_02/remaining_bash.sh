#!/bin/bash

pc_folder=$(pwd)
python3 --version > python_version.txt
gen_config_file="${pc_folder}/configs/genconfig_melo.conf"
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

run_experiment() {
    local inst="$1"
    local com="$2"
    local group_log="$3"

    local instname
    instname=$(basename "$inst")
    local log_name="${logs_folder}/${group_log}/${instname}"
    local EXE_PARAMS="--inst $inst ${CONFIG_PARAMS} --cutoff_machs ${com}"
    local STDOUT="${log_name}_rb.stdout"
    local STDERR="${log_name}_rb.stderr"

    echo "$EXE ${EXE_PARAMS} 1> ${STDOUT} 2> ${STDERR}"
    $EXE ${EXE_PARAMS} 1>"${STDOUT}" 2>"${STDERR}"

    if [ -f "$STDERR" ] && [ ! -s "$STDERR" ]; then
        rm -f "$STDERR"
    fi
}

jobs=(
    "lr203 10R_10V_04I_04M 4"
    "lr204 10R_10V_04I_04M 3"
    "lr204 10R_10V_04I_04M 4"
    "lr204 12R_12V_02I_04M 3"
    "lr202 12R_12V_04I_04M 3"
    "lr203 12R_12V_04I_04M 3"
    "lr203 12R_12V_04I_04M 4"
)


for job in "${jobs[@]}"; do
    set -- $job
    instname="$1"
    base_group="$2"
    com="$3"

    group_log="${base_group/04M/0${com}M}"
    inst="${insts_folder}/${base_group}/t2/${instname}"

    run_experiment "$inst" "$com" "$group_log"
done

