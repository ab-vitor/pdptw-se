#!/usr/bin/env bash
set -euo pipefail

# Generates a combined CSV from all parsed .stdout files under ./std_outs_chars
# Output: ./sol_chars_table.csv (created next to this script)

src_dir="${1:-./std_outs_chars}"
out_csv="./sol_chars_table.csv"
delim=";"
# Enable debug printing by setting DEBUG=1 in the environment when running the script
DEBUG="${DEBUG:-0}"

LC_NUMERIC=C
# CSV header: group,name, then the requested columns
header=(
  group
  name
  feasible
  seed
  n_vehicles_used
  n_machines_used
  max_max_load_all_vehicles
  min_max_load_all_vehicles
  mean_max_load_all_vehicles
  min_completion_time
  max_completion_time
  mean_completion_time
  avrg_machines_travel_time_with_vehicle
  avrg_machines_travel_time_only_with_vehicle
  avrg_machines_travel_time_no_vehicle
  avrg_vehicles_waiting_time_for_a_machine_travel
  avrg_vehicles_waiting_time_for_a_service
)

# Write header
( IFS="$delim"; echo "${header[*]}" ) > "$out_csv"

# Find and process each .stdout file
if [ ! -d "$src_dir" ]; then
  echo "Source directory '$src_dir' not found" >&2
  exit 1
fi

find "$src_dir" -type f -name "*.stdout" | sort | while IFS= read -r file; do
  # derive group = first path component under src_dir, name = basename
  rel_path="${file#$src_dir/}"
  group="$(echo "$rel_path" | awk -F/ '{print $1}')"
  seed="$(echo "$rel_path" | awk -F/ '{print $3}')"
  seed="${seed#seed_}"
  name="$(basename "$file" .stdout)"
  name="$(echo "$rel_path" | grep -o 'M_.*_seed' | sed 's/M_//;s/_seed//')"
  echo $group $seed $name

  # initialize values
  feasible=0
  n_vehicles_used=""
  n_machines_used=""
  min_completion_time=""
  max_completion_time=""
  mean_completion_time=""
  avrg_with=""
  avrg_only=""
  avrg_no=""
  avrg_wait_machine=""
  avrg_wait_service=""
  max_load_array=""

  # Read file and extract lines of interest
  # We assume the files are simplified (start at STATISTICS) but be tolerant
  while IFS= read -r line; do
    # Check for "Everything is awesome!" anywhere in the file
    if [[ "$line" == *"Everything is awesome!"* ]]; then
      feasible=1
    fi
    
    # trim
    tline="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    case "$tline" in
      "Vehicles used"*|"Machines used"*|"Min completion time"*|"Max completion time"*|"Mean completion time"*|"Avrg travel time (with vehicle)"*|"Avrg travel time (only with vehicle)"*|"Avrg travel time (no vehicle)"*|"Avrg waiting time (machine travel)"*|"Avrg waiting time (service)"*|"Max load per vehicle"*)
        key="$(echo "$tline" | cut -d':' -f1)"
        val="$(echo "$tline" | cut -d':' -f2- | sed 's/^[[:space:]]*//')"
        case "$key" in
          "Vehicles used"*) n_vehicles_used="$val" ;;
          "Machines used"*) n_machines_used="$val" ;;
          "Min completion time"*) min_completion_time="$val" ;;
          "Max completion time"*) max_completion_time="$val" ;;
          "Mean completion time"*) mean_completion_time="$val" ;;
          "Avrg travel time (with vehicle)"*) avrg_with="$val" ;;
          "Avrg travel time (only with vehicle)"*) avrg_only="$val" ;;
          "Avrg travel time (no vehicle)"*) avrg_no="$val" ;;
          "Avrg waiting time (machine travel)"*) avrg_wait_machine="$val" ;;
          "Avrg waiting time (service)"*) avrg_wait_service="$val" ;;
          "Max load per vehicle"*)
            # remove brackets and commas -> space separated numbers
            tmp="$(echo "$val" | sed 's/\[//g; s/\]//g; s/,/ /g; s/^[[:space:]]*//; s/[[:space:]]*$//')"
            max_load_array="$tmp"
            ;;
        esac
        ;;
      *) ;; # ignore
    esac
  done < "$file"

  # compute stats from max_load_array
  if [ -n "$max_load_array" ]; then
    if [ "$DEBUG" -eq 1 ]; then
      echo "DEBUG: max_load_array=[$max_load_array]" >&2
    fi

    # safer awk: initialize max/min on first numeric token encountered
    # pass DEBUG into awk so it can print token-level debug info to stderr when enabled
    read max_m min_m mean_m <<<$(awk -v DEBUG="$DEBUG" '
      BEGIN{sum=0; n=0}
      {
        for(i=1;i<=NF;i++){
          if($i!=""){
            num = $i + 0;
            if(n==0 && num>0.0){ max=num; min=num }
            else { if(num>max) max=num; if(num<min && num > 0.0) min=num }
            sum+=num
            if(num>0.0){n++}
          }
        }
      }
      END{
        if(n>0){ printf "%f %f %f", max, min, sum/n } else { printf "NA NA NA" }
      }' <<<"$max_load_array")

    if [ "$DEBUG" -eq 1 ]; then
      echo "DEBUG: awk result: max="$max_m" min="$min_m" mean="$mean_m"" >&2
    fi
  else
    max_m="NA"; min_m="NA"; mean_m="NA"
  fi
  # prepare CSV-safe values (remove commas inside values if any)
  clean() { echo "$1" | sed 's/,/./g' ; }
  out_line=(
    "$group"
    "$name"
    "$feasible"
    "$seed"
    "$(clean "$n_vehicles_used")"
    "$(clean "$n_machines_used")"
    "$(clean "$max_m")"
    "$(clean "$min_m")"
    "$(clean "$mean_m")"
    "$(clean "$min_completion_time")"
    "$(clean "$max_completion_time")"
    "$(clean "$mean_completion_time")"
    "$(clean "$avrg_with")"
    "$(clean "$avrg_only")"
    "$(clean "$avrg_no")"
    "$(clean "$avrg_wait_machine")"
    "$(clean "$avrg_wait_service")"
  )

  ( IFS="$delim"; echo "${out_line[*]}" ) >> "$out_csv"
  echo "Wrote row for: $file"
done

echo "Done. Combined CSV: $out_csv"
exit 0
