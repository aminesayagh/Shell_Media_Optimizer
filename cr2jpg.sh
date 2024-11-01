#!/bin/bash

# Check if required dependencies are installed
check_dependencies() {
    local missing_deps=()

    if ! command -v dcraw &>/dev/null; then
        missing_deps+=("dcraw")
    fi

    if ! command -v convert &>/dev/null; then
        missing_deps+=("imagemagick")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Installing missing dependencies: ${missing_deps[*]}"
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y "${missing_deps[@]}"
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y "${missing_deps[@]}"
        elif command -v pacman &>/dev/null; then
            sudo pacman -S "${missing_deps[@]}"
        else
            echo "Please install ${missing_deps[*]} manually for your distribution"
            exit 1
        fi
    fi
}

# Convert single file with quality settings
convert_single_file() {
    local input_file="$1"
    local temp_ppm="${input_file%.*}_temp.ppm"
    local output_file="${input_file%.*}.jpg"
    local quality=${2:-90} # Default JPEG quality is 90

    if [ -f "$input_file" ]; then
        echo "Converting: $input_file -> $output_file"

        # Extract and process the RAW file with dcraw
        # -c: Output to stdout
        # -w: Use camera white balance
        # -b 2.0: Apply brightness boost
        # -q 3: Use high-quality interpolation
        # -h: Half-size output (faster processing, still good quality)
        dcraw -c -w -b 2.0 -q 3 "$input_file" >"$temp_ppm"

        if [ $? -eq 0 ]; then
            # Convert to JPG with ImageMagick
            # -quality: Set JPEG quality
            # -sharpen: Apply subtle sharpening
            # -auto-level: Optimize contrast
            convert "$temp_ppm" \
                -quality "$quality" \
                -sharpen 0x1.0 \
                -auto-level \
                "$output_file"

            if [ $? -eq 0 ]; then
                echo "Successfully converted $input_file"
                rm "$temp_ppm" # Clean up temporary file
            else
                echo "Failed to process with ImageMagick: $input_file"
                rm "$temp_ppm"
                return 1
            fi
        else
            echo "Failed to process with dcraw: $input_file"
            return 1
        fi
    else
        echo "File not found: $input_file"
        return 1
    fi
}

# Convert directory
convert_directory() {
    local input_dir="$1"
    local quality=${2:-90}
    local count=0
    local failed=0

    if [ ! -d "$input_dir" ]; then
        echo "Directory not found: $input_dir"
        exit 1
    fi

    echo "Converting all CR2 files in $input_dir..."

    for file in "$input_dir"/*.{CR2,cr2}; do
        if [ -f "$file" ]; then
            convert_single_file "$file" "$quality"
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

# Print usage information
print_usage() {
    echo "Usage: $0 [-q quality] input"
    echo "  input: CR2 file or directory containing CR2 files"
    echo "  -q: JPEG quality (1-100, default: 90)"
    echo ""
    echo "Examples:"
    echo "  $0 image.CR2"
    echo "  $0 -q 95 image.CR2"
    echo "  $0 directory_path"
}

# Main script
main() {
    local quality=90

    # Parse command line options
    while getopts "q:h" opt; do
        case $opt in
        q)
            quality="$OPTARG"
            if ! [[ "$quality" =~ ^[0-9]+$ ]] || [ "$quality" -lt 1 ] || [ "$quality" -gt 100 ]; then
                echo "Error: Quality must be between 1 and 100"
                exit 1
            fi
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

    shift $((OPTIND - 1))

    check_dependencies

    if [ $# -eq 0 ]; then
        print_usage
        exit 1
    fi

    if [ -d "$1" ]; then
        convert_directory "$1" "$quality"
    elif [ -f "$1" ]; then
        convert_single_file "$1" "$quality"
    else
        echo "Input not found: $1"
        exit 1
    fi
}

main "$@"
