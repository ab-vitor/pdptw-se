set=$1
cd ..

for group_path in ../../${set}/instances/orig_ams_fg/*; do
  group=$(basename $group_path)
  for i in $(seq 1 5); do
    julia --quiet analyse_instance.jl ../../${set}/instances/orig_ams_fg/${group}/t1/lr10${i}/
  done
  for i in $(seq 1 5); do
    julia --quiet analyse_instance.jl ../../${set}/instances/orig_ams_fg/${group}/t2/lr20${i}/
  done
done
