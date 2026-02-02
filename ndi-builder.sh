#!/usr/bin/env bash
set -e
# Prompt user to put there ndi installer sh in the external/ndi folder
# cd to the folder
# run the installer and send a y to the prompt
# copy out the needed files to external/ndi
# clean up temp files
TEMP_DIR="/tmp/ndi-installer-temp"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR
mkdir -p "external/ndi"

echo "[ndi] Please place the NDI Linux installer .sh file in the external/ndi folder."
read -p "[ndi] Press Enter to continue once the file is in place..."
NDI_INSTALLER=$(ls external/ndi/Install_*.sh | head -n 1)
if [ -z "$NDI_INSTALLER" ]; then
    echo "[ndi] No NDI installer .sh file found in external/ndi. Exiting."
    exit 1
fi
cp "$NDI_INSTALLER" "$TEMP_DIR/ndi-installer.sh"
chmod +x "$TEMP_DIR/ndi-installer.sh"
home="$PWD"
cd "$TEMP_DIR"
export PAGER=cat
# Run installer and wait until a specific output marker appears
MARKER="NDI Advanced SDK for Linux/licenses/openssl.txt"
LOGFILE="$TEMP_DIR/installer.log"

# Start installer; feed 'y' to prompts; capture output to a log
( TERM=dumb yes | "$TEMP_DIR/ndi-installer.sh" ) >"$LOGFILE" 2>&1 &
INSTALLER_PID=$!
echo "[ndi] Installer started (pid $INSTALLER_PID). Waiting for marker: $MARKER"

# Poll the log until the marker appears or the installer exits
while true; do
    if grep -q "$MARKER" "$LOGFILE" 2>/dev/null; then
        echo "[ndi] Marker found in installer output. Proceeding."
        break
    fi
    if ! kill -0 "$INSTALLER_PID" 2>/dev/null; then
        echo "[ndi] Installer exited before marker appeared. Continuing."
        break
    fi
    sleep 1
done

# Ensure installer has fully exited (ignore non-zero if any)
wait "$INSTALLER_PID" || true
cd "$home"


listof_files=(
    "$TEMP_DIR/NDI Advanced SDK for Linux/lib/x86_64-linux-gnu/libndi.so"
    "$TEMP_DIR/NDI Advanced SDK for Linux/lib/x86_64-linux-gnu/libndi.so.6"
    "$TEMP_DIR/NDI Advanced SDK for Linux/lib/x86_64-linux-gnu/libndi.so.6.0.0"
)

MAX_WAIT=200
for file in "${listof_files[@]}"; do
    COUNT=0
    while [ ! -f "$file" ]; do
        sleep 1
        COUNT=$((COUNT + 1))
        if [ "$COUNT" -ge "$MAX_WAIT" ]; then
            echo "File $file not found after $MAX_WAIT seconds, exiting."
            exit 1
        fi
    done
    cp "$file" "$PWD/external/ndi/$(basename "$file")"
    echo "[ndi] Copied $(basename "$file") to external"
done

rm -rf $TEMP_DIR