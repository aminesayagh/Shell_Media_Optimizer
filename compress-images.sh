#!/bin/bash

# Default settings
QUALITY=82
MAX_WIDTH=1920
OUTPUT_DIR="compressed"
PATTERN="french-dandy-cover-*.jpg"

# Check if ImageMagick is installed
check_dependencies() {
    if ! command -v convert &> /dev/null; then
        echo "ImageMagick is not installed. Installing..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y imagemagick
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y imagemagick
        elif command -v pacman &> /dev/null; then
            sudo pacman -S imagemagick
        else
            echo "Please install ImageMagick manually for your distribution"
            exit 1
        fi
    fi
}

# Print size in human-readable format
human_size() {
    local bytes=$1
    if ((bytes < 1024)); then
        echo "${bytes}B"
    elif ((bytes < 1048576)); then
        echo "$(( (bytes + 512) / 1024 ))KB"
    else
        echo "$(( (bytes + 524288) / 1048576 ))MB"
    fi
}

# Calculate compression percentage
calc_compression() {
    local original=$1
    local compressed=$2
    local saving=$(( 100 - (compressed * 100 / original) ))
    echo $saving
}

# Compress single image
compress_image() {
    local input_file="$1"
    local output_file="$OUTPUT_DIR/$1"
    local original_size=$(stat -f%z "$input_file" 2>/dev/null || stat -c%s "$input_file")
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"
    
    echo "Processing: $input_file"
    
    # Compress the image
    convert "$input_file" \
        -strip \
        -resize "${MAX_WIDTH}x${MAX_WIDTH}>" \
        -auto-orient \
        -quality "$QUALITY" \
        -sampling-factor 4:2:0 \
        -interlace Plane \
        -colorspace sRGB \
        "$output_file"
    
    if [ $? -eq 0 ]; then
        local compressed_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file")
        local saving=$(calc_compression $original_size $compressed_size)
        echo "  Original size: $(human_size $original_size)"
        echo "  Compressed size: $(human_size $compressed_size)"
        echo "  Space saved: $saving%"
        echo "  Saved to: $output_file"
        return 0
    else
        echo "  Failed to compress $input_file"
        return 1
    fi
}

# Print usage information
print_usage() {
    echo "Usage: $0 [-q quality] [-w max_width] [-p pattern] [-o output_dir]"
    echo "  -q: JPEG quality (1-100, default: $QUALITY)"
    echo "  -w: Maximum width in pixels (default: $MAX_WIDTH)"
    echo "  -p: File pattern (default: $PATTERN)"
    echo "  -o: Output directory (default: $OUTPUT_DIR)"
    echo "  -h: Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -q 85 -w 1600 -p \"french-dandy-cover-*.jpg\" -o compressed"
}

# Main script
main() {
    local total_original_size=0
    local total_compressed_size=0
    local processed=0
    local failed=0
    
    # Parse command line options
    while getopts "q:w:p:o:h" opt; do
        case $opt in
            q) QUALITY="$OPTARG"
               if ! [[ "$QUALITY" =~ ^[0-9]+$ ]] || [ "$QUALITY" -lt 1 ] || [ "$QUALITY" -gt 100 ]; then
                   echo "Error: Quality must be between 1 and 100"
                   exit 1
               fi
               ;;
            w) MAX_WIDTH="$OPTARG"
               if ! [[ "$MAX_WIDTH" =~ ^[0-9]+$ ]] || [ "$MAX_WIDTH" -lt 1 ]; then
                   echo "Error: Width must be a positive number"
                   exit 1
               fi
               ;;
            p) PATTERN="$OPTARG"
               ;;
            o) OUTPUT_DIR="$OPTARG"
               ;;
            h) print_usage
               exit 0
               ;;
            \?) print_usage
                exit 1
                ;;
        esac
    done
    
    check_dependencies
    
    echo "Starting compression with:"
    echo "  Quality: $QUALITY"
    echo "  Max width: $MAX_WIDTH"
    echo "  Pattern: $PATTERN"
    echo "  Output directory: $OUTPUT_DIR"
    echo ""
    
    # Process all matching files
    for file in $PATTERN; do
        if [ -f "$file" ]; then
            local original_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
            total_original_size=$((total_original_size + original_size))
            
            compress_image "$file"
            
            if [ $? -eq 0 ]; then
                local compressed_size=$(stat -f%z "$OUTPUT_DIR/$file" 2>/dev/null || stat -c%s "$OUTPUT_DIR/$file")
                total_compressed_size=$((total_compressed_size + compressed_size))
                ((processed++))
            else
                ((failed++))
            fi
        fi
    done
    
    # Print summary
    echo ""
    echo "Compression complete!"
    echo "Files processed: $processed"
    if [ $failed -gt 0 ]; then
        echo "Files failed: $failed"
    fi
    echo "Total original size: $(human_size $total_original_size)"
    echo "Total compressed size: $(human_size $total_compressed_size)"
    echo "Total space saved: $(calc_compression $total_original_size $total_compressed_size)%"
}

main "$@"
