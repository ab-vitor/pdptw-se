set=$1
group=$2
is_big=$3
# echo Group: $group
cd ..

if [ "$is_big" = false ]; then
  for i in $(seq 1 5); do
    julia --quiet is_tw_cap_changed.jl ../../${set}/instances/orig_ams/${group}/t1/lr10${i}/ ../../${set}/instances/orig_ams_fg/${group}/t1/lr10${i}/
  done
  for i in $(seq 1 5); do
    julia --quiet is_tw_cap_changed.jl ../../${set}/instances/orig_ams/${group}/t2/lr20${i}/ ../../${set}/instances/orig_ams_fg/${group}/t2/lr20${i}/
  done
fi

if [ "$is_big" = true ]; then
  for i in $(seq 1 5); do
    julia --quiet is_tw_cap_changed.jl ../../${set}/instances/orig_ams/${group}/t1/LR1_2_${i}/ ../../${set}/instances/orig_ams_fg/${group}/t1/LR1_2_${i}/
  done
  for i in $(seq 1 5); do
    julia --quiet is_tw_cap_changed.jl ../../${set}/instances/orig_ams/${group}/t2/LR2_2_${i}/ ../../${set}/instances/orig_ams_fg/${group}/t2/LR2_2_${i}/
  done
fi