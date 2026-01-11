set=$1

echo "group;instname;tw_shift;cap_incr"
for group in ../../../${set}/instances/orig_ams/06R*; do
    group_name=$(basename $group)
    ./is_tw_cap_changed_all_instances.sh $set $group_name false
done
for group in ../../../${set}/instances/orig_ams/08R*; do
    group_name=$(basename $group)
    ./is_tw_cap_changed_all_instances.sh $set $group_name false
done
for group in ../../../${set}/instances/orig_ams/10R*; do
    group_name=$(basename $group)
    ./is_tw_cap_changed_all_instances.sh $set $group_name false
done
for group in ../../../${set}/instances/orig_ams/12R*; do
    group_name=$(basename $group)
    ./is_tw_cap_changed_all_instances.sh $set $group_name false
done
for group in ../../../${set}/instances/orig_ams/40R*; do
    group_name=$(basename $group)
    ./is_tw_cap_changed_all_instances.sh $set $group_name true
done
for group in ../../../${set}/instances/orig_ams/60R*; do
    group_name=$(basename $group)
    ./is_tw_cap_changed_all_instances.sh $set $group_name true
done