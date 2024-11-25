#!/bin/bash

# Configuration
INPUT_DIR="./input"
OUTPUT_DIR="./output"
TEMP_DIR="./temp"

# Create necessary directories
mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

# Default quality settings (CRF - lower number means better quality, 18-28 is good range)
LAPTOP_CRF=23
TABLET_CRF=24
MOBILE_CRF=25

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

# Function to compress video with object-cover-like scaling and progress bar
compress_video() {
    local input="$1"
    local output="$2"
    local target_width="$3"
    local target_height="$4"
    local crf="$5"
    local duration=$(get_duration "$input")
    local dimensions=$(get_dimensions "$input")
    local input_width=$(echo $dimensions | cut -d: -f1)
    local input_height=$(echo $dimensions | cut -d: -f2)
    
    # Calculate scaling parameters for object-cover-like behavior
    local scale_w="$target_width"
    local scale_h="$target_height"
    local input_aspect=$(bc -l <<< "$input_width/$input_height")
    local target_aspect=$(bc -l <<< "$target_width/$target_height")
    
    if (( $(bc -l <<< "$input_aspect > $target_aspect") )); then
        scale_w="-1"
        scale_h="$target_height"
    else
        scale_w="$target_width"
        scale_h="-1"
    fi

    ffmpeg -i "$input" \
        -c:v libx264 -preset slow \
        -crf "$crf" \
        -profile:v high -level:v 4.0 \
        -movflags +faststart \
        -vf "scale=$scale_w:$scale_h,crop=$target_width:$target_height" \
        -c:a aac -b:a 128k \
        -y "$output" \
        2>&1 | while read -r line; do
            if [[ "$line" =~ time=([0-9]+):([0-9]+):([0-9]+\.[0-9]+) ]]; then
                current_seconds=$(bc <<< "${BASH_REMATCH[1]}*3600 + ${BASH_REMATCH[2]}*60 + ${BASH_REMATCH[3]}")
                progress=$(bc <<< "scale=2; $current_seconds/$duration * 100")
                printf "\rProgress: %5.1f%%" "$progress"
            fi
        done
    echo -e "\nCompleted: $output"
}

# Function to generate WebP thumbnail with object-cover
generate_webp_thumbnail() {
    local input="$1"
    local output="$2"
    local target_width="$3"
    local target_height="$4"
    
    ffmpeg -i "$input" -ss 00:00:01 -vframes 1 \
        -vf "scale=max($target_width\,a*$target_height):max($target_height\,a*$target_width),crop=$target_width:$target_height" \
        -c:v libwebp -quality 80 \
        "$output" -y
}

# Main process function
process_video() {
    local input="$1"
    local filename=$(basename "$input")
    local name="${filename%.*}"

    echo "Processing: $filename"
    
    # Laptop version (1080p)
    echo "Creating laptop version..."
    compress_video "$input" \
        "$OUTPUT_DIR/${name}_laptop.mp4" \
        1920 1080 $LAPTOP_CRF

    # Tablet version (720p)
    echo "Creating tablet version..."
    compress_video "$input" \
        "$OUTPUT_DIR/${name}_tablet.mp4" \
        1280 720 $TABLET_CRF

    # Mobile version (480p)
    echo "Creating mobile version..."
    compress_video "$input" \
        "$OUTPUT_DIR/${name}_mobile.mp4" \
        854 480 $MOBILE_CRF

    # Generate WebP thumbnails for different sizes
    echo "Generating WebP thumbnails..."
    generate_webp_thumbnail "$input" "$OUTPUT_DIR/${name}_thumb_laptop.webp" 1920 1080
    generate_webp_thumbnail "$input" "$OUTPUT_DIR/${name}_thumb_tablet.webp" 1280 720
    generate_webp_thumbnail "$input" "$OUTPUT_DIR/${name}_thumb_mobile.webp" 854 480

    # Print file sizes
    echo -e "\nFile sizes:"
    echo "Original: $(du -h "$input" | cut -f1)"
    echo "Laptop: $(du -h "$OUTPUT_DIR/${name}_laptop.mp4" | cut -f1)"
    echo "Tablet: $(du -h "$OUTPUT_DIR/${name}_tablet.mp4" | cut -f1)"
    echo "Mobile: $(du -h "$OUTPUT_DIR/${name}_mobile.mp4" | cut -f1)"
}

# Check for ffmpeg installation
if ! command -v ffmpeg &> /dev/null; then
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
