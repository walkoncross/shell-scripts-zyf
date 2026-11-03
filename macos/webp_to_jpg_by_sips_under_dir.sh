#!/bin/bash
## author: zhaoyafei0210@gmail.com

# Convert all .webp files to .jpg format using sips command on macOS
# 
# Usage: 
#   ./webp_to_jpg.sh [input_dir] [output_dir]
#
# Arguments:
#   input_dir  - Directory containing .webp files (default: current directory)
#   output_dir - Directory to save converted .jpg files (default: current directory)
#
# Example:
#   ./webp_to_jpg.sh ./webp_images ./jpg_images

# Function to display usage
show_usage() {
    echo "Usage: $(basename $0) [input_dir] [output_dir]"
    echo "Convert .webp files to .jpg format using sips"
    echo ""
    echo "Arguments:"
    echo "  input_dir  - Directory containing .webp files (default: current directory)"
    echo "  output_dir - Directory to save converted .jpg files (default: current directory)"
    exit 1
}

# Parse input directory
if [[ $# -gt 0 ]]; then
    input_dir="$1"
else
    input_dir="."
fi

# Parse output directory
if [[ $# -gt 1 ]]; then
    output_dir="$2"
else
    output_dir="."
fi

# Validate input directory
if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory '$input_dir' does not exist."
    show_usage
fi

# Create output directory if it doesn't exist
if [[ ! -d "$output_dir" ]]; then
    echo "Creating output directory: $output_dir"
    mkdir -p "$output_dir"
fi

# Check if any .webp files exist
webp_files=("$input_dir"/*.webp)
if [[ ! -e "${webp_files[0]}" ]]; then
    echo "Error: No .webp files found in '$input_dir'"
    exit 1
fi

# Convert files
echo "Converting .webp files to .jpg..."
for file in "$input_dir"/*.webp; do
    filename=$(basename "$file")
    output_file="$output_dir/${filename%.webp}.jpg"
    echo "Converting: $filename"
    sips -s format jpeg "$file" --out "$output_file" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "  Success: Created $output_file"
    else
        echo "  Error: Failed to convert $filename"
    fi
done

echo "Conversion complete!"