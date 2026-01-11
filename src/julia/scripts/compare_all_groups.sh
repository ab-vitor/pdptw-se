set=$1

echo "group;instname;tw_shift;cap_incr;mean_z;std_z;var_z;chi_squared_z;reqs_split"
for group in ../../../${set}/instances/orig_ams/60R_*06M; do
    group_name=$(basename $group)
    ./compare_all_instances.sh $set $group_name
done