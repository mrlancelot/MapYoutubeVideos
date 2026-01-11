#!/usr/bin/env python3
"""Audio generation for map scripts using ElevenLabs API"""

import os
import re
import json
import subprocess
import requests
import time

API_KEY = "sk_bb5b0b6e065c06a3502d4c04a31f6aa269c0c463125a1e26"
VOICE_ID = "a8P2orUWbHAmeqUof99F"
SCRIPTS_DIR = "/Users/pridhvi/Documents/Github/Scripts/maps/scripts"
AUDIO_DIR = "/Users/pridhvi/Documents/Github/Scripts/maps/scripts/audio"

os.makedirs(AUDIO_DIR, exist_ok=True)

def extract_narration(script_path):
    """Extract narration text from markdown script."""
    with open(script_path, 'r') as f:
        content = f.read()

    # Find text between ## Narration and ---
    match = re.search(r'## Narration\n\n(.+?)\n\n---', content, re.DOTALL)
    if match:
        return match.group(1).strip()
    return None

def add_pauses(text):
    """Add dramatic pauses to narration."""
    text = text.replace('. ', '... ')
    text = text.replace('? ', '?... ')
    return text

def generate_audio(script_path):
    """Generate and process audio for a script."""
    base_name = os.path.splitext(os.path.basename(script_path))[0]
    final_path = os.path.join(AUDIO_DIR, f"{base_name}_final.mp3")
    raw_path = os.path.join(AUDIO_DIR, f"{base_name}_raw.mp3")
    slowed_path = os.path.join(AUDIO_DIR, f"{base_name}_slowed.mp3")

    # Skip if already exists
    if os.path.exists(final_path):
        print(f"SKIP: {base_name} (already exists)")
        return True

    print(f"PROCESSING: {base_name}")

    # Extract narration
    narration = extract_narration(script_path)
    if not narration:
        print(f"  ERROR: No narration found")
        return False

    # Add pauses
    narration_with_pauses = add_pauses(narration)

    # Generate audio via ElevenLabs API
    print("  Generating with ElevenLabs...")

    payload = {
        "text": narration_with_pauses,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.4,
            "similarity_boost": 0.75,
            "style": 0.5,
            "use_speaker_boost": True
        }
    }

    headers = {
        "xi-api-key": API_KEY,
        "Content-Type": "application/json"
    }

    response = requests.post(
        f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}",
        headers=headers,
        json=payload
    )

    if response.status_code != 200:
        print(f"  ERROR: API returned {response.status_code}: {response.text[:100]}")
        return False

    with open(raw_path, 'wb') as f:
        f.write(response.content)

    # Get raw duration
    result = subprocess.run(
        ['ffprobe', '-i', raw_path, '-show_entries', 'format=duration',
         '-v', 'quiet', '-of', 'csv=p=0'],
        capture_output=True, text=True
    )

    if not result.stdout.strip():
        print(f"  ERROR: Could not get duration")
        os.remove(raw_path)
        return False

    raw_duration = float(result.stdout.strip())
    print(f"  Raw duration: {raw_duration:.1f}s")

    # Calculate tempo (target 40s)
    target_duration = 40
    tempo = raw_duration / target_duration
    tempo = max(0.5, min(1.0, tempo))  # Clamp between 0.5 and 1.0

    print(f"  Tempo: {tempo:.3f}")

    # Process: slow down + normalize + limit
    print("  Processing audio...")
    subprocess.run([
        'ffmpeg', '-i', raw_path,
        '-af', f'atempo={tempo},loudnorm=I=-14:TP=-1:LRA=2,alimiter=limit=0.9:level=false',
        '-ar', '44100', '-b:a', '128k', '-y', final_path
    ], capture_output=True)

    # Verify final duration
    result = subprocess.run(
        ['ffprobe', '-i', final_path, '-show_entries', 'format=duration',
         '-v', 'quiet', '-of', 'csv=p=0'],
        capture_output=True, text=True
    )

    final_duration = float(result.stdout.strip()) if result.stdout.strip() else 0
    print(f"  DONE: {base_name}_final.mp3 ({final_duration:.1f}s)")

    # Clean up
    os.remove(raw_path)

    return True

def main():
    # Get all script files
    scripts = []
    for f in os.listdir(SCRIPTS_DIR):
        if f.endswith('.md') and f != 'README.md' and '_template' not in f:
            scripts.append(os.path.join(SCRIPTS_DIR, f))

    scripts.sort()

    success = 0
    failed = 0

    for script in scripts:
        try:
            if generate_audio(script):
                success += 1
            else:
                failed += 1
            # Small delay to avoid rate limiting
            time.sleep(0.5)
        except Exception as e:
            print(f"  ERROR: {e}")
            failed += 1

    print(f"\n=== COMPLETE ===")
    print(f"Success: {success}, Failed: {failed}")

    # Count final files
    final_files = [f for f in os.listdir(AUDIO_DIR) if f.endswith('_final.mp3')]
    print(f"Total audio files: {len(final_files)}")

if __name__ == "__main__":
    main()
