#!/bin/bash

# Check if FFmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "FFmpeg is not installed. Please install it first:"
    echo "sudo apt update && sudo apt install ffmpeg"
    exit 1
fi

# Function to display script usage
show_usage() {
    echo "Usage: ./compress_video.sh [option] input_file output_file"
    echo "Options:"
    echo "  -w, --web       Optimize for web (good balance of quality and size)"
    echo "  -f, --fast      Fast compression (lower quality, smaller size)"
    echo "  -h, --hq        High quality (better quality, larger size)"
    echo "  -m, --mobile    Optimize for mobile devices"
    echo "  -c, --custom    Custom compression (1080p, 2mbps)"
    exit 1
}

# Check if input arguments are provided
if [ "$#" -lt 3 ]; then
    show_usage
fi

# Parse arguments
OPTION=$1
INPUT=$2
OUTPUT=$3

# Get input video size
ORIGINAL_SIZE=$(du -h "$INPUT" | cut -f1)

# Function to show compression results
show_results() {
    NEW_SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "Compression completed!"
    echo "Original size: $ORIGINAL_SIZE"
    echo "New size: $NEW_SIZE"
}

case $OPTION in
    -w|--web)
        echo "Compressing video for web..."
        ffmpeg -i "$INPUT" \
            -c:v libx264 -crf 23 \
            -c:a aac -b:a 128k \
            -movflags +faststart \
            -vf "scale=-2:720" \
            "$OUTPUT"
        show_results
        ;;
        
    -f|--fast)
        echo "Fast compression with lower quality..."
        ffmpeg -i "$INPUT" \
            -c:v libx264 -crf 28 \
            -c:a aac -b:a 96k \
            -vf "scale=-2:480" \
            "$OUTPUT"
        show_results
        ;;
        
    -h|--hq)
        echo "High quality compression..."
        ffmpeg -i "$INPUT" \
            -c:v libx264 -crf 18 \
            -c:a aac -b:a 192k \
            -movflags +faststart \
            -vf "scale=-2:1080" \
            "$OUTPUT"
        show_results
        ;;
        
    -m|--mobile)
        echo "Compressing for mobile devices..."
        ffmpeg -i "$INPUT" \
            -c:v libx264 -crf 23 \
            -c:a aac -b:a 128k \
            -vf "scale=-2:480" \
            -movflags +faststart \
            -profile:v baseline -level 3.0 \
            "$OUTPUT"
        show_results
        ;;
        
    -c|--custom)
        echo "Custom compression (1080p, 2mbps)..."
        ffmpeg -i "$INPUT" \
            -c:v libx264 -b:v 2M \
            -c:a aac -b:a 128k \
            -vf "scale=-2:1080" \
            -movflags +faststart \
            "$OUTPUT"
        show_results
        ;;
        
    *)
        show_usage
        ;;
esac

# Show video information
echo -e "\nNew video information:"
ffmpeg -i "$OUTPUT" 2>&1 | grep -E 'Stream|Duration'
