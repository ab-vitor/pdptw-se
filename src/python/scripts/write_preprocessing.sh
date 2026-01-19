#! /bin/bash
cd ../

for group_path in ../../benchmark_multi_island_v5/instances/orig_ams_fg/*R_*/; do
  if [[ $group_path == *"50R"* ]]; then
    echo "Skipping group $group_path"
    continue
  fi
  group_04M=$(basename ${group_path})
  mkdir -p ../../benchmark_multi_island_v5/pc01/outputs/${group_04M}/
  str_03M="03M"
  group_03M=$(echo "${group_04M}" | sed "s/04M/${str_03M}/")
  echo $group_03M
  mkdir -p ../../benchmark_multi_island_v5/pc01/outputs/${group_03M}/
  for i in $(seq 1 5); do
    python3 pdptwse.py --inst ../../benchmark_multi_island_v5/instances/orig_ams_fg/${group_04M}/t1/lr10${i}/ --cutoff_machs 3 --gen_config_file configs/preprocessing/preprocessing.conf
  done
  for i in $(seq 1 5); do
    python3 pdptwse.py --inst ../../benchmark_multi_island_v5/instances/orig_ams_fg/${group_04M}/t1/lr10${i}/ --gen_config_file configs/preprocessing/preprocessing.conf
  done

  for i in $(seq 1 5); do
    python3 pdptwse.py --inst ../../benchmark_multi_island_v5/instances/orig_ams_fg/${group_04M}/t2/lr20${i}/ --cutoff_machs 3 --gen_config_file configs/preprocessing/preprocessing.conf
  done
  for i in $(seq 1 5); do
    python3 pdptwse.py --inst ../../benchmark_multi_island_v5/instances/orig_ams_fg/${group_04M}/t2/lr20${i}/ --gen_config_file configs/preprocessing/preprocessing.conf
  done
done

for group_path in ../../benchmark_multi_floor_v3/instances/orig_ams_fg/*R_*/; do
  if [[ $group_path == *"50R"* ]]; then
    echo "Skipping group $group_path"
    continue
  fi
  group_04M=$(basename ${group_path})
  mkdir -p ../../benchmark_multi_floor_v3/pc01/outputs/${group_04M}/
  str_03M="03M"
  group_03M=$(echo "${group_04M}" | sed "s/04M/${str_03M}/")
  echo $group_03M
  mkdir -p ../../benchmark_multi_floor_v3/pc01/outputs/${group_03M}/
  for i in $(seq 1 5); do
    python3 pdptwse.py --inst ../../benchmark_multi_floor_v3/instances/orig_ams_fg/${group_04M}/t1/lr10${i}/ --cutoff_machs 3 --gen_config_file configs/preprocessing/preprocessing.conf
  done
  for i in $(seq 1 5); do
    python3 pdptwse.py --inst ../../benchmark_multi_floor_v3/instances/orig_ams_fg/${group_04M}/t1/lr10${i}/ --gen_config_file configs/preprocessing/preprocessing.conf
  done

  for i in $(seq 1 5); do
    python3 pdptwse.py --inst ../../benchmark_multi_floor_v3/instances/orig_ams_fg/${group_04M}/t2/lr20${i}/ --cutoff_machs 3 --gen_config_file configs/preprocessing/preprocessing.conf
  done
  for i in $(seq 1 5); do
    python3 pdptwse.py --inst ../../benchmark_multi_floor_v3/instances/orig_ams_fg/${group_04M}/t2/lr20${i}/ --gen_config_file configs/preprocessing/preprocessing.conf
  done
done

