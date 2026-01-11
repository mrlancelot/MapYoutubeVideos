#!/bin/bash

# Trim audio files - remove trailing artifacts and add clean fade out

AUDIO_DIR="/Users/pridhvi/Documents/Github/Scripts/maps/scripts/audio"
TRIMMED_DIR="/Users/pridhvi/Documents/Github/Scripts/maps/scripts/audio/trimmed"

mkdir -p "$TRIMMED_DIR"

trim_audio() {
    local input="$1"
    local filename=$(basename "$input")
    local output="$TRIMMED_DIR/$filename"

    echo "Processing: $filename"

    # Get total duration
    total_dur=$(ffprobe -i "$input" -show_entries format=duration -v quiet -of csv="p=0")

    # Find last silence start (where speech ends)
    last_speech_end=$(ffmpeg -i "$input" -af "silencedetect=noise=-35dB:d=0.3" -f null - 2>&1 | \
        grep "silence_start" | tail -1 | awk -F'silence_start: ' '{print $2}')

    if [ -z "$last_speech_end" ]; then
        # No silence detected, use full duration minus 0.5s
        trim_point=$(echo "$total_dur - 0.5" | bc)
    else
        # Add 0.3s buffer after last speech
        trim_point=$(echo "$last_speech_end + 0.3" | bc)
    fi

    # Make sure we don't trim too much (minimum 30s)
    if (( $(echo "$trim_point < 30" | bc -l) )); then
        trim_point=$(echo "$total_dur - 0.5" | bc)
    fi

    echo "  Original: ${total_dur}s → Trimmed: ${trim_point}s"

    # Trim and add 0.3s fade out at the end
    ffmpeg -i "$input" -t "$trim_point" -af "afade=t=out:st=$(echo "$trim_point - 0.3" | bc):d=0.3" \
        -ar 44100 -b:a 128k -y "$output" 2>/dev/null

    # Get new duration
    new_dur=$(ffprobe -i "$output" -show_entries format=duration -v quiet -of csv="p=0")
    echo "  Done: ${new_dur}s"
}

echo "=== TRIMMING ALL AUDIO FILES ==="
echo ""

for file in "$AUDIO_DIR"/*_final.mp3; do
    if [ -f "$file" ]; then
        trim_audio "$file"
    fi
done

echo ""
echo "=== COMPLETE ==="
echo "Trimmed files in: $TRIMMED_DIR"
echo "Total files: $(ls -1 "$TRIMMED_DIR"/*.mp3 2>/dev/null | wc -l)"
