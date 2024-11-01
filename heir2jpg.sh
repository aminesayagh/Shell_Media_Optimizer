#!/bin/bash

# Check if libheif-examples is installed
check_dependencies() {
    if ! command -v heif-convert &>/dev/null; then
        echo "heif-convert is not installed. Installing libheif-examples..."
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y libheif-examples
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y libheif-examples
        elif command -v pacman &>/dev/null; then
            sudo pacman -S libheif
        else
            echo "Please install libheif-examples manually for your distribution"
            exit 1
        fi
    fi
}

# Convert single file
convert_single_file() {
    local input_file="$1"
    local output_file="${input_file%.*}.jpg"

    if [ -f "$input_file" ]; then
        echo "Converting: $input_file -> $output_file"
        heif-convert "$input_file" "$output_file"
        if [ $? -eq 0 ]; then
            echo "Successfully converted $input_file"
        else
            echo "Failed to convert $input_file"
        fi
    else
        echo "File not found: $input_file"
    fi
}

# Convert directory
convert_directory() {
    local input_dir="$1"
    local count=0
    local failed=0

    if [ ! -d "$input_dir" ]; then
        echo "Directory not found: $input_dir"
        exit 1
    fi

    echo "Converting all HEIC files in $input_dir..."

    for file in "$input_dir"/*.{HEIC,heic}; do
        if [ -f "$file" ]; then
            convert_single_file "$file"
            if [ $? -eq 0 ]; then
                ((count++))
            else
                ((failed++))
            fi
        fi
    done

    echo "Conversion complete!"
    echo "Successfully converted: $count files"
    if [ $failed -gt 0 ]; then
        echo "Failed conversions: $failed files"
    fi
}

# Main script
main() {
    check_dependencies

    if [ $# -eq 0 ]; then
        echo "Usage: $0 [file.HEIC or directory]"
        exit 1
    fi

    if [ -d "$1" ]; then
        convert_directory "$1"
    elif [ -f "$1" ]; then
        convert_single_file "$1"
    else
        echo "Input not found: $1"
        exit 1
    fi
}

main "$@"
