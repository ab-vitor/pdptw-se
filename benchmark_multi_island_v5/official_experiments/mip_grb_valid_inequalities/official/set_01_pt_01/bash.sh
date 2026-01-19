#!/bin/bash

# --- Setup and environment ---
pc_folder=$(pwd)
python3 --version > python_version.txt

gen_config_file="${pc_folder}/configs/genconfig_melo.conf"
output="${pc_folder}/logs"
CONFIG_PARAMS="--gen_config_file ${gen_config_file} --output ${output}"
EXE="python3 pdptwse.py"

cd ../../../../../src/python/ || { echo "Error: Cannot cd to src/python"; exit 1; }

if ! command -v python3 >/dev/null; then
    echo "Error: python3 not found (pwd: $(pwd))"
    exit 1
fi

# --- Virtual environment setup ---
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

# --- Paths and folders ---
insts_folder="${pc_folder}/../../../../instances/orig_ams_fg"
logs_folder="${output}/std_outs_errs"
mkdir -p "${logs_folder}"

# === Retry parameters ===
BASE_SLEEP=5           # seconds
MAX_SLEEP=$((30 * 60)) # 30 minutes in seconds

# --- Function to run one experiment ---
run_experiment() {
    local inst="$1"
    local group_name_prefix="$2"
    local com="$3"

    instname=$(basename "$inst")
    log_dir="${logs_folder}/${group_name_prefix}_0${com}M"
    mkdir -p "$log_dir"

    log_name="${log_dir}/${instname}"
    EXE_PARAMS="--inst $inst ${CONFIG_PARAMS} --cutoff_machs ${com}"
    STDOUT="${log_name}.stdout"
    STDERR="${log_name}.stderr"

    local attempt=1
    local sleep_time=${BASE_SLEEP}
    local killed_retry_done=false

    while true; do
        echo "[$(date '+%H:%M:%S')] Attempt ${attempt}: ${instname} (cutoff ${com})"
        echo "Running: $EXE ${EXE_PARAMS}"

        $EXE ${EXE_PARAMS} 1>"${STDOUT}" 2>"${STDERR}"
        exit_code=$?

        # === If process was killed ===
        if (( exit_code >= 128 )); then
            if [ "$killed_retry_done" = true ]; then
                echo "[$(date '+%H:%M:%S')] ERROR: ${instname} (cutoff ${com}) killed again (exit ${exit_code}). Stopping retries."
                break
            fi
            echo "[$(date '+%H:%M:%S')] WARNING: ${instname} (cutoff ${com}) was killed (exit ${exit_code}). Retrying once..."
            killed_retry_done=true
            ((attempt++))
            sleep "${BASE_SLEEP}"
            continue
        fi

        # === Success case: stderr empty or missing ===
        if [ ! -f "$STDERR" ] || [ ! -s "$STDERR" ]; then
            [ -f "$STDERR" ] && rm -f "$STDERR"
            echo "[$(date '+%H:%M:%S')] SUCCESS: ${instname} (cutoff ${com})"
            break
        fi

        # === Failure case: stderr non-empty ===
        echo "[$(date '+%H:%M:%S')] WARNING: stderr not empty for ${instname} (cutoff ${com})"
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

# --- Function to iterate over groups ---
process_group() {
    local group="$1"
    local type_subdir="$2"
    local valid_reqs="$3"

    n_req=${group: -15:3}
    if [[ ! "$n_req" =~ ^(${valid_reqs})$ ]]; then
        return
    fi

    group_name_prefix=$(basename "${group:0: -4}")
    mkdir -p "${logs_folder}/${group_name_prefix}_03M" "${logs_folder}/${group_name_prefix}_04M"

    for type in "${group}/${type_subdir}"; do
        for inst in "${type}"/lr*; do
            [[ "$inst" =~ 0[1-5]$ ]] || continue
            for com in {3..4}; do
                run_experiment "$inst" "$group_name_prefix" "$com"
            done
        done
    done
}

# --- Main loops ---
for group in ${insts_folder}/*_*_*; do
    process_group "$group" "t1" "06R|08R|10R|12R"
done

for group in ${insts_folder}/*_*_*; do
    process_group "$group" "t2" "06R"
done
