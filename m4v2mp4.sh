#!/bin/bash

# Check if FFmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "FFmpeg is not installed. Please install it first:"
    echo "sudo apt update && sudo apt install ffmpeg"
    exit 1
fi

# Function to display script usage
show_usage() {
    echo "Usage: ./m4v_to_mp4.sh [option] input_file/directory"
    echo "Options:"
    echo "  -s, --single    Convert a single file"
    echo "  -b, --batch     Convert all M4V files in a directory"
    echo "  -q, --quality   High quality conversion (slower)"
    echo "  -f, --fast      Fast conversion (lower quality)"
    echo "Examples:"
    echo "  ./m4v_to_mp4.sh -s video.m4v"
    echo "  ./m4v_to_mp4.sh -b /path/to/directory"
    exit 1
}

# Function to convert single file
convert_file() {
    local input=$1
    local quality=$2
    local filename=$(basename "$input" .m4v)
    local output="${filename}.mp4"
    
    echo "Converting: $input to $output"
    
    if [ "$quality" = "high" ]; then
        # High quality conversion
        ffmpeg -i "$input" \
            -c:v libx264 -preset slow -crf 18 \
            -c:a aac -b:a 192k \
            -movflags +faststart \
            "$output"
    else
        # Standard/fast conversion
        ffmpeg -i "$input" \
            -c:v libx264 -preset medium -crf 23 \
            -c:a aac -b:a 128k \
            "$output"
    fi
    
    if [ $? -eq 0 ]; then
        echo "Successfully converted: $output"
        # Show file size comparison
        original_size=$(du -h "$input" | cut -f1)
        new_size=$(du -h "$output" | cut -f1)
        echo "Original size: $original_size"
        echo "New size: $new_size"
    else
        echo "Error converting: $input"
    fi
}

# Check if input arguments are provided
if [ "$#" -lt 2 ]; then
    show_usage
fi

# Parse arguments
OPTION=$1
INPUT=$2
QUALITY="standard"

# Set quality if specified
if [ "$3" = "-q" ] || [ "$3" = "--quality" ]; then
    QUALITY="high"
fi

case $OPTION in
    -s|--single)
        if [ ! -f "$INPUT" ]; then
            echo "Error: Input file not found: $INPUT"
            exit 1
        fi
        convert_file "$INPUT" "$QUALITY"
        ;;
        
    -b|--batch)
        if [ ! -d "$INPUT" ]; then
            echo "Error: Input directory not found: $INPUT"
            exit 1
        fi
        
        echo "Converting all M4V files in directory: $INPUT"
        
        # Find all M4V files in the directory (case insensitive)
        find "$INPUT" -type f -iname "*.m4v" | while read -r file; do
            convert_file "$file" "$QUALITY"
        done
        
        echo "Batch conversion completed!"
        ;;
        
    *)
        show_usage
        ;;
esac
