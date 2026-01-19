#!/bin/bash

# Function to process a single .stdout file
process_file() {
    input_file="$1"
    output_file="$2"
    
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$output_file")"
    
    # Process the file and save to output
    sed -n '/STATISTICS/,$p' "$input_file" | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' > "$output_file"
}

# Check if source directory is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <source_std_outs_errs_dir>"
    exit 1
fi

src_dir="$1"
dst_dir="./std_outs_chars"

# Find all .stdout files and process them
find "$src_dir" -type f -name "*.stdout" | while read -r file; do
    # Get relative path from src_dir
    rel_path="${file#$src_dir/}"
    # Create output path
    output_file="$dst_dir/$rel_path"
    echo "Processing: $file"
    echo "Output to: $output_file"
    process_file "$file" "$output_file"
done 
