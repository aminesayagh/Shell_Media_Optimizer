#!/bin/bash

# Configuration
INPUT_DIR="./input"
OUTPUT_DIR="./output"
TEMP_DIR="./temp"

# Create necessary directories
mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

# Default quality settings
CRF=23 # Constant Rate Factor (18-28 is good range)

# Function to validate input file
validate_input() {
    if [ ! -f "$1" ]; then
        echo "Error: Input file '$1' not found!"
        exit 1
    fi
}

# Function to get video duration
get_duration() {
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1"
}

# Function to get video dimensions
get_dimensions() {
    local width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$1")
    local height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$1")
    echo "$width:$height"
}

# Function to crop and resize video with progress bar
crop_and_resize() {
    local input="$1"
    local output="$2"
    local target_width="$3"
    local target_height="$4"
    local duration
    duration=$(get_duration "$input")

    # Get input dimensions
    local dimensions
    dimensions=$(get_dimensions "$input")
    local input_width
    input_width=$(echo "$dimensions" | cut -d: -f1)
    local input_height
    input_height=$(echo "$dimensions" | cut -d: -f2)

    # Calculate crop dimensions to maintain aspect ratio
    local crop_width="$input_width"
    local crop_height="$input_height"
    local target_aspect
    target_aspect=$(bc -l <<<"$target_width/$target_height")
    local current_aspect
    current_aspect=$(bc -l <<<"$input_width/$input_height")

    if (($(bc -l <<<"$current_aspect > $target_aspect"))); then
        # Current video is wider than target - crop width
        crop_width=$(bc -l <<<"$input_height*$target_aspect")
        crop_width=${crop_width%.*}
        local x_offset
        x_offset=$(bc -l <<<"($input_width-$crop_width)/2")
        x_offset=${x_offset%.*}
        crop_filter="crop=$crop_width:$input_height:$x_offset:0"
    else
        # Current video is taller than target - crop height
        crop_height=$(bc -l <<<"$input_width/$target_aspect")
        crop_height=${crop_height%.*}
        local y_offset
        y_offset=$(bc -l <<<"($input_height-$crop_height)/2")
        y_offset=${y_offset%.*}
        crop_filter="crop=$input_width:$crop_height:0:$y_offset"
    fi

    echo "Input dimensions: ${input_width}x${input_height}"
    echo "Target dimensions: ${target_width}x${target_height}"
    echo "Crop dimensions: ${crop_width}x${crop_height}"

    ffmpeg -i "$input" \
        -vf "${crop_filter},scale=$target_width:$target_height" \
        -c:v libx264 -preset slow \
        -crf $CRF \
        -profile:v high -level:v 4.0 \
        -movflags +faststart \
        -c:a aac -b:a 128k \
        -y "$output" \
        2>&1 | while read -r line; do
        if [[ "$line" =~ time=([0-9]+):([0-9]+):([0-9]+\.[0-9]+) ]]; then
            current_seconds=$(bc <<<"${BASH_REMATCH[1]}*3600 + ${BASH_REMATCH[2]}*60 + ${BASH_REMATCH[3]}")
            progress=$(bc <<<"scale=2; $current_seconds/$duration * 100")
            printf "\rProgress: %5.1f%%" "$progress"
        fi
    done
    echo -e "\nCompleted: $output"
}

# Main process function
process_video() {
    local input="$1"
    local filename
    filename=$(basename "$input")
    local name="${filename%.*}"

    echo "Processing: $filename"

    # Mobile version (500x700)
    echo "Creating mobile version..."
    crop_and_resize "$input" \
        "$OUTPUT_DIR/${name}_mobile.mp4" \
        500 700

    # Tablet version (800x700)
    echo "Creating tablet version..."
    crop_and_resize "$input" \
        "$OUTPUT_DIR/${name}_tablet.mp4" \
        800 700

    # Generate WebP thumbnail
    echo "Generating WebP thumbnails..."
    ffmpeg -i "$input" -vf "${crop_filter},scale=500:700" \
        -ss 00:00:01 -vframes 1 \
        -c:v libwebp -quality 80 \
        "$OUTPUT_DIR/${name}_thumb.webp" -y

    # Print file sizes
    echo -e "\nFile sizes:"
    echo "Original: $(du -h "$input" | cut -f1)"
    echo "Mobile: $(du -h "$OUTPUT_DIR/${name}_mobile.mp4" | cut -f1)"
    echo "Tablet: $(du -h "$OUTPUT_DIR/${name}_tablet.mp4" | cut -f1)"
}

# Check for ffmpeg installation
if ! command -v ffmpeg &>/dev/null; then
    echo "Error: ffmpeg is not installed. Please install it first."
    exit 1
fi

# Process all videos in input directory or single file
if [ $# -eq 0 ]; then
    # Process all videos in input directory
    for video in "$INPUT_DIR"/*.{mp4,mov,mkv}; do
        if [ -f "$video" ]; then
            process_video "$video"
        fi
    done
else
    # Process single file
    validate_input "$1"
    process_video "$1"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "Processing complete!"
