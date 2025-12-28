#!/bin/bash
set -euo pipefail

# === Setup paths ===
pc_folder=$(pwd)
julia --version > julia_version.txt
output="${pc_folder}/logs"
gen_config_file="${pc_folder}/configs/genconfig_mslp.conf"
CONFIG_PARAMS_BASE="--genconfigfile ${gen_config_file} --output ${output}"
EXE="julia pdptwse.jl"

cd ../../../../../src/julia/ || { echo "Failed to cd into Julia source folder"; exit 1; }

if ! command -v julia >/dev/null; then
    echo "Error: Julia not found or not executable (pwd: $(pwd))"
    exit 1
fi

logs_folder="${output}/std_outs_errs"
mkdir -p "${logs_folder}"

bash_file=$(basename "$0")
bash_id="${bash_file%.*}"
insts_folder="${pc_folder}/../../../../instances/orig_ams_fg"

# === Retry parameters ===
BASE_SLEEP=5           # seconds
MAX_SLEEP=$((30 * 60)) # 30 minutes in seconds

# === Helper to run one experiment ===
run_experiment() {
    local instpath=$1
    local com=$2
    local seed=$3
    local group_name_prefix=$4

    local instname
    instname=$(basename "$instpath")
    local group_log="${group_name_prefix}_0${com}M"
    log_folder_cp="${logs_folder}/${group_log}/t${instname:2:1}/seed_${seed}"
    mkdir -p "${log_folder_cp}"
    local log_name="${log_folder_cp}/${group_log}_${instname}_seed_${seed}"

    local CONFIG_PARAMS="${CONFIG_PARAMS_BASE} --suff_csv _${bash_id} --suff_outputs _seed_${seed}"
    local EXE_PARAMS="--inst ${instpath} ${CONFIG_PARAMS} --cutoffmachs ${com} --seed ${seed}"

    local STDOUT="${log_name}.stdout"
    local STDERR="${log_name}.stderr"

    local attempt=1
    local sleep_time=${BASE_SLEEP}

    while true; do
        echo "[$(date '+%H:%M:%S')] Attempt ${attempt}: ${instname} (cutoff ${com}, seed ${seed})"
        echo "Running: $EXE ${EXE_PARAMS}"

        $EXE ${EXE_PARAMS} 1>"${STDOUT}" 2>"${STDERR}"

        # === Success case: stderr empty or missing ===
        if [ ! -f "$STDERR" ] || [ ! -s "$STDERR" ]; then
            [ -f "$STDERR" ] && rm -f "$STDERR"
            echo "[$(date '+%H:%M:%S')] SUCCESS: ${instname} (cutoff ${com}, seed ${seed})"
            break
        fi

        # === Failure case: stderr non-empty ===
        echo "[$(date '+%H:%M:%S')] WARNING: stderr not empty for ${instname} (cutoff ${com}, seed ${seed})"
        echo "Sleeping ${sleep_time}s before retry..."
        sleep "${sleep_time}"
        ((attempt++))

        # Every 3 attempts, increase sleep time (capped at MAX_SLEEP)
        if (( attempt % 3 == 0 )); then
            if (( sleep_time < MAX_SLEEP )); then
                sleep_time=$(( sleep_time * 2 ))
                (( sleep_time > MAX_SLEEP )) && sleep_time=${MAX_SLEEP}
                echo "[$(date '+%H:%M:%S')] Increasing sleep time to ${sleep_time}s"
            else
                echo "[$(date '+%H:%M:%S')] Sleep time capped at ${sleep_time}s (max reached)"
            fi
        fi
    done
}

# === Main loop ===
seed_id="${bash_id: -1:1}"
offset="5"
seed=$(((seed_id+offset) * 17 + 7))

for group in ${insts_folder}/*_*_*_*; do
    n_req=${group: -15:3}
    group_name_prefix=$(basename "${group:0:-4}")

    # === Small instances (3M–4M) ===
    if [[ "$n_req" =~ ^(06R|08R|10R|12R)$ ]]; then
        for com in {3..4}; do
            mkdir -p "${logs_folder}/${group_name_prefix}_0${com}M"
        done
        for type in "${group}"/t*; do
            for inst in "${type}"/lr*; do
                [[ "$inst" =~ 0[1-5]$ ]] || continue
                for com in {3..4}; do
                    run_experiment "$inst" "$com" "$seed" "$group_name_prefix"
                done
            done
        done
    fi

    # === Large instances (5M–6M) ===
    if [[ "$n_req" =~ ^(40R|60R)$ ]]; then
        for com in {5..6}; do
            mkdir -p "${logs_folder}/${group_name_prefix}_0${com}M"
        done
        for type in "${group}"/t*; do
            for inst in "${type}"/LR*; do
                [[ "$inst" =~ _[1-5]$ ]] || continue
                for com in {5..6}; do
                    run_experiment "$inst" "$com" "$seed" "$group_name_prefix"
                done
            done
        done
    fi
done
