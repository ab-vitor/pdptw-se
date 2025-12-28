#!/bin/bash

pc_folder=$(pwd)

EXE="python3 pdptwse.py"

cd ../../../../../src/python/
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


run_experiment() {
    local instpath="$1"
    local com="$2"
    local group_log="$3"
    local cid="$4"

    local instname
    instname=$(basename "$instpath")
    local log_name="${logs_folder}/${group_log}_${instname}"
    local EXE_PARAMS="--inst $instpath ${CONFIG_PARAMS} --cutoff_machs ${com}"
    local STDOUT="${log_name}_cid_${cid}.stdout"
    local STDERR="${log_name}_cid_${cid}.stderr"

    echo "$EXE ${EXE_PARAMS} 1> ${STDOUT} 2> ${STDERR}"
    $EXE ${EXE_PARAMS} 1>"${STDOUT}" 2>"${STDERR}"

    if [ -f "$STDERR" ] && [ ! -s "$STDERR" ]; then
        rm -f "$STDERR"
    fi
}

insts=()
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and lines starting with #
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    insts+=("$line")
done < "${pc_folder}/../../instances_selected.txt"

for cid in {1..12};do
    gen_config_file="${pc_folder}/configs/genconfig_melo_vi_${cid}.conf"
    output="${pc_folder}/logs"
    logs_folder="${output}/std_outs_errs/cid_${cid}"
    CONFIG_PARAMS="--gen_config_file ${gen_config_file} --output ${output}"
    
    insts_folder="${pc_folder}/../../../../instances/orig_ams_fg"

    mkdir -p "${logs_folder}"

    for inst in "${insts[@]}"; do
        set -- $inst
        instname="$1"
        base_group="$2"
        com="$3"

        type="${instname:2:1}"
        group_log="${base_group/04M/0${com}M}"
        instpath="${insts_folder}/${base_group}/t${type}/${instname}"

        run_experiment "$instpath" "$com" "$group_log" "$cid"
    done
done


