#!/bin/bash

# Audio generation script for all video narrations
# Targets: 40 seconds, -14 LUFS, matching reference videos

API_KEY="sk_bb5b0b6e065c06a3502d4c04a31f6aa269c0c463125a1e26"
VOICE_ID="a8P2orUWbHAmeqUof99F"
SCRIPTS_DIR="/Users/pridhvi/Documents/Github/Scripts/maps/scripts"
AUDIO_DIR="/Users/pridhvi/Documents/Github/Scripts/maps/scripts/audio"

mkdir -p "$AUDIO_DIR"

generate_audio() {
    local script_file="$1"
    local base_name=$(basename "$script_file" .md)
    local output_file="$AUDIO_DIR/${base_name}_final.mp3"

    # Skip if already exists
    if [ -f "$output_file" ]; then
        echo "SKIP: $base_name (already exists)"
        return
    fi

    echo "PROCESSING: $base_name"

    # Extract narration (text between ## Narration and ---)
    narration=$(sed -n '/^## Narration/,/^---/p' "$script_file" | grep -v "^##" | grep -v "^---" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//')

    if [ -z "$narration" ]; then
        echo "ERROR: No narration found in $base_name"
        return
    fi

    # Add pauses for dramatic effect (after periods and key phrases)
    narration_with_pauses=$(echo "$narration" | sed 's/\. /... /g' | sed 's/? /?... /g')

    # Escape quotes for JSON
    narration_escaped=$(echo "$narration_with_pauses" | sed "s/'/\\\\'/g" | sed 's/"/\\"/g')

    # Generate raw audio
    echo "  Generating with ElevenLabs..."
    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
        -H "xi-api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"text\": \"$narration_escaped\",
            \"model_id\": \"eleven_multilingual_v2\",
            \"voice_settings\": {
                \"stability\": 0.4,
                \"similarity_boost\": 0.75,
                \"style\": 0.5,
                \"use_speaker_boost\": true
            }
        }" \
        --output "$AUDIO_DIR/${base_name}_raw.mp3"

    if [ ! -f "$AUDIO_DIR/${base_name}_raw.mp3" ]; then
        echo "ERROR: Failed to generate audio for $base_name"
        return
    fi

    # Get duration and calculate slowdown factor
    raw_duration=$(ffprobe -i "$AUDIO_DIR/${base_name}_raw.mp3" -show_entries format=duration -v quiet -of csv="p=0" 2>/dev/null)

    if [ -z "$raw_duration" ]; then
        echo "ERROR: Could not get duration for $base_name"
        return
    fi

    # Target 40 seconds, calculate tempo
    target_duration=40
    tempo=$(echo "scale=3; $raw_duration / $target_duration" | bc)

    # Clamp tempo between 0.5 and 1.0 (don't speed up, only slow down)
    if (( $(echo "$tempo > 1.0" | bc -l) )); then
        tempo="1.0"
    fi
    if (( $(echo "$tempo < 0.5" | bc -l) )); then
        tempo="0.5"
    fi

    echo "  Raw: ${raw_duration}s, Tempo: ${tempo}"

    # Slow down audio
    echo "  Slowing down..."
    ffmpeg -i "$AUDIO_DIR/${base_name}_raw.mp3" -filter:a "atempo=$tempo" -y "$AUDIO_DIR/${base_name}_slowed.mp3" 2>/dev/null

    # Normalize to -14 LUFS with limiter
    echo "  Normalizing..."
    ffmpeg -i "$AUDIO_DIR/${base_name}_slowed.mp3" \
        -af "loudnorm=I=-14:TP=-1:LRA=2,alimiter=limit=0.9:level=false" \
        -ar 44100 -b:a 128k -y "$output_file" 2>/dev/null

    # Clean up intermediate files
    rm -f "$AUDIO_DIR/${base_name}_raw.mp3" "$AUDIO_DIR/${base_name}_slowed.mp3"

    # Verify
    final_dur=$(ffprobe -i "$output_file" -show_entries format=duration -v quiet -of csv="p=0" 2>/dev/null)
    echo "  DONE: ${base_name}_final.mp3 (${final_dur}s)"
}

# Process all scripts
for script in "$SCRIPTS_DIR"/*.md; do
    # Skip non-script files
    base=$(basename "$script")
    if [[ "$base" == "README.md" ]] || [[ "$base" == *"_template"* ]]; then
        continue
    fi
    generate_audio "$script"
done

echo ""
echo "=== COMPLETE ==="
ls -la "$AUDIO_DIR"/*.mp3 2>/dev/null | wc -l
echo "audio files generated"
