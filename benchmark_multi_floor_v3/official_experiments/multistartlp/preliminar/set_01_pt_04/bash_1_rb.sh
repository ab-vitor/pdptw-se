#!/bin/bash

pc_folder=$(pwd)
julia --version > julia_version.txt
output="${pc_folder}/logs"
EXE="julia pdptwse.jl"

cd ../../../../../src/julia/
if [ ! -x "$(command -v ${EXE})" ]; then
    error "${EXE}: not found or not executable (pwd: $(pwd))"
fi

insts_folder="${pc_folder}/../../../../instances/orig_ams_fg"
logs_folder_base="${output}/std_outs_errs"
mkdir -p "${logs_folder_base}"
bash_file=$(basename "$0")
bash_id="${bash_file%.*}"

run_experiment() {
    local instpath="$1"
    local com="$2"
    local group_log="$3"
    local seed="$4"
    local CONFIG_PARAMS="$5"

    local instname
    instname=$(basename "$instpath")
    local log_name="${logs_folder}/${group_log}_${instname}_seed_${seed}_alpha_${alpha_name}"
    local EXE_PARAMS="--inst $instpath ${CONFIG_PARAMS} --cutoffmachs ${com} --seed ${seed}"
    local STDOUT="${log_name}.stdout"
    local STDERR="${log_name}.stderr"

    echo "$EXE ${EXE_PARAMS} 1> ${STDOUT} 2> ${STDERR}"
    $EXE ${EXE_PARAMS} 1>"${STDOUT}" 2>"${STDERR}"

    if [ -f "$STDERR" ] && [ ! -s "$STDERR" ]; then
        rm -f "$STDERR"
    fi
}

insts=()
while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    insts+=("$line")
done < "${pc_folder}/../instances_selected.txt"

for seed_id in {11..20}; do
    seed=$(($seed_id*7 + 17))
    for inst in "${insts[@]}"; do
        set -- $inst
        instname="$1"
        base_group="$2"
        com="$3"

        if [[ "$com" == "4" || "$com" == "6" ]]; then
            continue
        fi

        for alpha in 0.05; do
            alpha_name="${alpha/0./}p"
            gen_config_file="${pc_folder}/configs/genconfig_mslp.conf"
            output="${pc_folder}/logs"
            logs_folder="${output}/std_outs_errs/alpha_${alpha_name}/seed_${seed}"
            CONFIG_PARAMS="--genconfigfile ${gen_config_file} --output ${output} --elevator --alpha ${alpha} --suff_csv _${bash_id} --suff_outputs _seed_${seed}_alpha_${alpha_name}"

            insts_folder="${pc_folder}/../../../../instances/orig_ams_fg"

            mkdir -p "${logs_folder}"

            type="${instname:2:1}"
            group_log="${base_group/06M/0${com}M}"
            group_log="${group_log/04M/0${com}M}"
            instpath="${insts_folder}/${base_group}/t${type}/${instname}"

            log_name="${logs_folder}/${group_log}_${instname}_seed_${seed}_alpha_${alpha_name}"
            STDERR="${log_name}.stderr"

            # Run only if .stderr exists and is non-empty
            if [ -s "$STDERR" ]; then
                run_experiment "$instpath" "$com" "$group_log" "$seed" "$CONFIG_PARAMS"
            fi
        done
    done
done
