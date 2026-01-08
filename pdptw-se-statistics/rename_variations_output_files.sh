find . -type f -name "*_I5*" -exec bash -c '
    for file do
        mv "$file" "${file//_I5/_multi_island}"
    done
' bash {} +

find . -type f -name "*_F3*" -exec bash -c '
    for file do
        mv "$file" "${file//_F3/_multi_floor}"
    done
' bash {} +

find . -type f -name "*I5_*" -exec bash -c '
    for file do
        mv "$file" "${file//I5_/multi_island_}"
    done
' bash {} +

find . -type f -name "*F3_*" -exec bash -c '
    for file do
        mv "$file" "${file//F3_/multi_floor_}"
    done
' bash {} +