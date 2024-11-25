#!/bin/bash

# Default settings
OUTPUT_DIR="converted"
PATTERN="*.mov"
PRESET="medium" # FFmpeg preset (ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow)
CRF="23"        # Constant Rate Factor (0-51, lower means better quality, 23 is default)
AUDIO_BITRATE="192k"

# Check if FFmpeg is installed
check_dependencies() {
    if ! command -v ffmpeg &>/dev/null; then
        echo "FFmpeg is not installed. Installing..."
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y ffmpeg
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y ffmpeg
        elif command -v pacman &>/dev/null; then
            sudo pacman -S ffmpeg
        else
            echo "Please install FFmpeg manually for your distribution"
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
        echo "$(((bytes + 512) / 1024))KB"
    elif ((bytes < 1073741824)); then
        echo "$(((bytes + 524288) / 1048576))MB"
    else
        echo "$(((bytes + 536870912) / 1073741824))GB"
    fi
}

# Calculate compression percentage
calc_compression() {
    local original=$1
    local compressed=$2
    local saving=$((100 - (compressed * 100 / original)))
    echo $saving
}

# Get video duration in seconds
get_duration() {
    local duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1")
    echo ${duration%.*}
}

# Format time in HH:MM:SS
format_time() {
    local seconds=$1
    printf "%02d:%02d:%02d" $((seconds / 3600)) $((seconds % 3600 / 60)) $((seconds % 60))
}

# Convert single video
convert_video() {
    local input_file="$1"
    local output_file="$OUTPUT_DIR/${input_file%.*}.mp4"
    local original_size=$(stat -f%z "$input_file" 2>/dev/null || stat -c%s "$input_file")
    local duration=$(get_duration "$input_file")

    echo "Converting: $input_file"
    echo "Duration: $(format_time $duration)"

    # Convert using FFmpeg with progress
    ffmpeg -i "$input_file" \
        -c:v libx264 -preset "$PRESET" -crf "$CRF" \
        -c:a aac -b:a "$AUDIO_BITRATE" \
        -movflags +faststart \
        -y "$output_file" \
        -progress pipe:1 2>/dev/null | while read -r line; do
        if [[ $line == out_time_ms=* ]]; then
            current_ms=${line#*=}
            current_seconds=$((current_ms / 1000000))
            progress=$((current_seconds * 100 / duration))
            printf "\rProgress: %3d%% " $progress
        fi
    done

    if [ $? -eq 0 ]; then
        local compressed_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file")
        local saving=$(calc_compression $original_size $compressed_size)
        echo -e "\n  Original size: $(human_size $original_size)"
        echo "  Converted size: $(human_size $compressed_size)"
        echo "  Space saved: $saving%"
        echo "  Saved to: $output_file"
        return 0
    else
        echo -e "\n  Failed to convert $input_file"
        return 1
    fi
}

# Print usage information
print_usage() {
    echo "Usage: $0 [-p preset] [-q quality] [-a audio_bitrate] [-f pattern] [-o output_dir]"
    echo "  -p: FFmpeg preset (ultrafast to veryslow, default: $PRESET)"
    echo "  -q: Quality (0-51, lower is better, default: $CRF)"
    echo "  -a: Audio bitrate (default: $AUDIO_BITRATE)"
    echo "  -f: File pattern (default: $PATTERN)"
    echo "  -o: Output directory (default: $OUTPUT_DIR)"
    echo "  -h: Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                # Convert all MOV files in current directory"
    echo "  $0 -p fast -q 20                 # Convert with fast preset and higher quality"
    echo "  $0 -f \"video*.mov\"               # Convert specific files"
    echo "  $0 -o mp4_videos                 # Output to custom directory"
}

# Main script
main() {
    local total_original_size=0
    local total_compressed_size=0
    local processed=0
    local failed=0
    local start_time=$(date +%s)

    # Parse command line options
    while getopts "p:q:a:f:o:h" opt; do
        case $opt in
        p)
            PRESET="$OPTARG"
            if [[ ! "$PRESET" =~ ^(ultrafast|superfast|veryfast|faster|fast|medium|slow|slower|veryslow)$ ]]; then
                echo "Error: Invalid preset"
                exit 1
            fi
            ;;
        q)
            CRF="$OPTARG"
            if ! [[ "$CRF" =~ ^[0-9]+$ ]] || [ "$CRF" -lt 0 ] || [ "$CRF" -gt 51 ]; then
                echo "Error: Quality (CRF) must be between 0 and 51"
                exit 1
            fi
            ;;
        a)
            AUDIO_BITRATE="$OPTARG"
            ;;
        f)
            PATTERN="$OPTARG"
            ;;
        o)
            OUTPUT_DIR="$OPTARG"
            ;;
        h)
            print_usage
            exit 0
            ;;
        \?)
            print_usage
            exit 1
            ;;
        esac
    done

    check_dependencies

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    echo "Starting conversion with:"
    echo "  Preset: $PRESET"
    echo "  Quality (CRF): $CRF"
    echo "  Audio bitrate: $AUDIO_BITRATE"
    echo "  Pattern: $PATTERN"
    echo "  Output directory: $OUTPUT_DIR"
    echo ""

    # Process all matching files
    for file in $PATTERN; do
        if [ -f "$file" ]; then
            local original_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
            total_original_size=$((total_original_size + original_size))

            convert_video "$file"

            if [ $? -eq 0 ]; then
                local output_file="$OUTPUT_DIR/${file%.*}.mp4"
                local compressed_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file")
                total_compressed_size=$((total_compressed_size + compressed_size))
                ((processed++))
            else
                ((failed++))
            fi
        fi
    done

    # Print summary
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo ""
    echo "Conversion complete!"
    echo "Time taken: $(format_time $duration)"
    echo "Files processed: $processed"
    if [ $failed -gt 0 ]; then
        echo "Files failed: $failed"
    fi
    echo "Total original size: $(human_size $total_original_size)"
    echo "Total converted size: $(human_size $total_compressed_size)"
    echo "Total space saved: $(calc_compression $total_original_size $total_compressed_size)%"
}

main "$@"
