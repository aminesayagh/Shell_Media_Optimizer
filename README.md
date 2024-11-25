# Video & Image Processing Scripts

A collection of high-performance shell scripts for video compression, image optimization, and format conversion, designed for web content optimization.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Scripts Overview](#scripts-overview)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Required dependencies:
- `ffmpeg` for video processing
- `ImageMagick` for image processing
- `libwebp-tools` for WebP conversion
- `bc` for mathematical calculations

Install dependencies on Ubuntu/Debian:
```bash
sudo apt update
sudo apt install ffmpeg imagemagick webp bc
```

## Scripts Overview

### 1. Video Compression Script (`compress_video.sh`)
Compresses and optimizes videos for web delivery with responsive sizes.

Features:
- Multiple output sizes (mobile, tablet, desktop)
- Object-cover-like scaling
- WebP thumbnail generation
- Progress tracking
- Quality preservation
- Automatic aspect ratio handling

### 2. Video Cropping Script (`crop_video.sh`)
Crops and resizes videos while maintaining aspect ratios.

Features:
- Smart cropping with center focus
- Custom dimensions support
- Progress tracking
- WebP thumbnail generation
- Multiple output formats

### 3. Image Compression Script (`compress_image.sh`)
Optimizes JPEG images for web use.

Features:
- Maintains image quality
- Strips metadata
- Resizes to maximum dimensions
- Progressive loading support
- Batch processing capability

### 4. WebP Conversion Script (`convert_webp.sh`)
Converts images to WebP format with optimization.

Features:
- Quality control
- Batch processing
- Size comparison
- Progress tracking
- Original file preservation

## Installation

1. Clone or download the scripts
2. Make them executable:
```bash
chmod +x compress_video.sh crop_video.sh compress_image.sh convert_webp.sh
```

## Usage

### Video Compression
```bash
./compress_video.sh input_video.mp4
# or process all videos in input directory
./compress_video.sh
```

### Video Cropping
```bash
./crop_video.sh input_video.mp4
```

### Image Compression
```bash
./compress_image.sh -q 82 -w 1920 -p "*.jpg" -o compressed
```

### WebP Conversion
```bash
./convert_webp.sh -q 82 -p "*.jpg" -o webp
```

## Configuration

### Video Compression Settings
```bash
# Default CRF values (lower = better quality)
LAPTOP_CRF=23
TABLET_CRF=24
MOBILE_CRF=25

# Default dimensions
LAPTOP: 1920x1080
TABLET: 1280x720
MOBILE: 854x480
```

### Image Compression Settings
```bash
QUALITY=82        # JPEG quality
MAX_WIDTH=1920    # Maximum width
```

### WebP Conversion Settings
```bash
QUALITY=82        # WebP quality
```

## Examples

### Compress a Video for Web
```bash
./compress_video.sh video.mp4
```
Output:
- video_laptop.mp4 (1920x1080)
- video_tablet.mp4 (1280x720)
- video_mobile.mp4 (854x480)
- video_thumb_[size].webp

### Crop Video to Specific Dimensions
```bash
./crop_video.sh video.mp4
```
Output:
- video_mobile.mp4 (500x700)
- video_tablet.mp4 (800x700)
- video_thumb.webp

### Compress Images
```bash
./compress_image.sh -q 85 -w 1600 -p "images/*.jpg"
```

### Convert to WebP
```bash
./convert_webp.sh -p "french-dandy-*.jpg" -q 85
```

## Troubleshooting

### Common Issues

1. Permission Denied
```bash
chmod +x script_name.sh
```

2. FFmpeg Not Found
```bash
sudo apt install ffmpeg
```

3. Low Quality Output
- Adjust CRF values (lower number = higher quality)
- Modify quality settings for images

4. Processing Fails
- Check input file exists
- Verify sufficient disk space
- Check FFmpeg/ImageMagick installation

### Tips
- Use `-h` flag for help with any script
- Monitor output directory for space
- Check generated file sizes and quality
- Use appropriate quality settings for your needs

## License
These scripts are provided under the MIT License.

## Contributing
Feel free to submit issues, fork the repository, and create pull requests.
