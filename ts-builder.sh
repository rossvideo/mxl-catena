
#!/usr/bin/env bash

set -euo pipefail

echo "[ts] Please place any mp4 files to be processed in the project root."
read -p "[ts] Press Enter to continue once the file(s) is in place..."

# Ensure output directory exists
mkdir -p external/ts

# Verify Docker availability
if ! command -v docker >/dev/null 2>&1; then
    echo "[ts] Docker is required to run ffmpeg in a container."
    echo "[ts] Please install Docker and ensure the daemon is running."
    exit 1
fi

# Allow override of ffmpeg image via FFMPEG_IMAGE env var
FFMPEG_IMAGE=${FFMPEG_IMAGE:-jrottenberg/ffmpeg:5.1-alpine}

for file in *.mp4; do
    if [ -f "$file" ]; then
        output="${file%.mp4}.ts"
        echo "[ts] Converting $file to $output using Docker ($FFMPEG_IMAGE)..."
        echo "[ts] docker run --rm -v \"$PWD\":/workspace -w /workspace $FFMPEG_IMAGE -y -fflags +genpts -re -i \"$file\" -an external/ts/\"$output\""
        docker run --rm \
            -v "$PWD":/workspace \
            -w /workspace \
            "$FFMPEG_IMAGE" \
            -y -fflags +genpts -re -i "$file" -an "external/ts/$output"
        echo "[ts] Finished converting $file to $output."
    else
        echo "[ts] No mp4 files found in the project root."
    fi
done

listof_ts_urls=(
    "https://tsduck.io/streams/uk-freeview/586000000.ts"
    "https://ftp.itec.aau.at/datasets/Nature-1k/Preview/0131_comp.MP4"
    "https://www.elecard.com/storage/video/TSU_1920x1080.mp4"
    "https://ftp.itec.aau.at/datasets/Nature-1k/Preview/0224_comp.MP4"
    "https://ftp.itec.aau.at/datasets/Nature-1k/Preview/0552_comp.MP4"


)

for url in "${listof_ts_urls[@]}"; do
    filename=$(basename "$url")
    # check if file already exists and is the same size
    if [ -f "external/ts/$filename" ]; then
        existing_size=$(stat -c%s "external/ts/$filename")
        remote_size=$(curl -sI "$url" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')
        if [ "$existing_size" -eq "$remote_size" ]; then
            echo "[ts] $filename already exists and is the same size. Skipping download."
            continue
        else
            echo "[ts] $filename exists but size differs. Re-downloading."
        fi
    fi
    echo "[ts] Downloading $filename from $url..."
    # if the file is a .MP4, convert it to .ts after download
    curl -L -o "external/ts/$filename" "$url"
    if [[ "$filename" == *.MP4 || "$filename" == *.mp4 ]]; then
        if [[ "$filename" == *.mp4 ]]; then
            ts_filename="${filename%.mp4}.ts"
        else
            ts_filename="${filename%.MP4}.ts"
        fi
        echo "[ts] Converting $filename to $ts_filename using Docker ($FFMPEG_IMAGE)..."
        docker run --rm \
            -v "$PWD":/workspace \
            -w /workspace \
            "$FFMPEG_IMAGE" \
            -y -fflags +genpts -re -i "external/ts/$filename" -an "external/ts/$ts_filename"
        echo "[ts] Finished converting $filename to $ts_filename."
        rm "external/ts/$filename"
    fi
    echo "[ts] Finished downloading $filename."
done