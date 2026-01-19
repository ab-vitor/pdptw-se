set=$1
cd ..

echo "group;instname;tw_shift;cap_incr"
for group in ../../instances/${set}/orig_ams/*04M; do
  group_name=$(basename $group)
  for i in $(seq 1 10); do
    idx=$(printf "%02d" "$i")
    julia --quiet compare_instances.jl ../../instances/${set}/orig_ams/${group_name}/t1/lr1${idx}/ ../../instances/${set}/orig_ams_fg/${group_name}/t1/lr1${idx}/
  done
  for i in $(seq 1 10); do
    idx=$(printf "%02d" "$i")
    julia --quiet compare_instances.jl ../../instances/${set}/orig_ams/${group_name}/t2/lr2${idx}/ ../../instances/${set}/orig_ams_fg/${group_name}/t2/lr2${idx}/
  done
done

for group in ../../instances/${set}/orig_ams/*06M; do
  group_name=$(basename $group)
  for i in $(seq 1 10); do
    julia --quiet compare_instances.jl ../../instances/${set}/orig_ams/${group_name}/t1/LR1_2_${i}/ ../../instances/${set}/orig_ams_fg/${group_name}/t1/LR1_2_${i}/
  done
  for i in $(seq 1 10); do
    julia --quiet compare_instances.jl ../../instances/${set}/orig_ams/${group_name}/t2/LR2_2_${i}/ ../../instances/${set}/orig_ams_fg/${group_name}/t2/LR2_2_${i}/
  done
done