# Map Animation Assets

## Folder Structure
```
assets/
├── memes/
│   ├── blue-emoji/     # MANUAL DOWNLOAD REQUIRED - see instructions
│   ├── doge/           # ✅ Downloaded (swole-doge, cheems)
│   ├── reactions/      # ✅ Downloaded (pikachu, wojak, drake, etc.)
│   └── misc/           # Additional memes as needed
├── flags/
│   ├── historical/     # ✅ Downloaded (20 flags)
│   └── modern/         # Add as needed
├── maps/
│   ├── base/           # Base map tiles/vectors
│   └── overlays/       # Territory overlays, boundaries
├── music/              # See MUSIC_RECOMMENDATIONS.md
├── photos/
│   └── historical/     # Historical photos for videos
└── fonts/              # See FONT_INSTRUCTIONS.md
```

## Downloaded Assets

### Flags (19 files)
- british-empire.svg
- qing-dynasty.svg
- austria-hungary.svg
- german-empire.svg
- russian-empire.svg
- french-republic.svg
- serbia.svg
- ottoman-empire.svg
- belgium.svg
- portugal.svg
- italy.svg
- spain.svg
- ussr.svg
- usa.svg
- japan-imperial.svg
- afghanistan.svg (Taliban)
- british-raj.svg
- macedon.svg

### Memes - Doge (2 files)
- swole-doge.png
- cheems.png

### Memes - Reactions (7 files)
- shocked-pikachu.png
- this-is-fine.png
- thinking-emoji.png
- gigachad.jpg
- wojak.png
- pointing-spiderman.jpg
- drake.jpg

### Memes - Misc (4 files)
- evil-kermit.jpg
- mr-burns-hands.jpg ("excellent")
- hold-my-beer.jpg
- understandable-have-nice-day.jpg

## Manual Downloads Required

### Blue Emojis
Visit https://bluemoji.io/ and download:
- angry, crying, flushed, smug, scheming, lipbite, shocked, sad

### Music Tracks
Visit https://pixabay.com/music/ - see music/MUSIC_RECOMMENDATIONS.md

### Fonts
Visit https://fonts.google.com/specimen/Bebas+Neue - see fonts/FONT_INSTRUCTIONS.md

### Additional Memes to Find
- nuh-uh.png (finger wag meme) - search "nuh uh meme"
- domino-effect.png - search "domino effect meme template"

## Usage in Remotion
```tsx
import { Img, staticFile } from 'remotion';

// Use flag
<Img src={staticFile('assets/flags/historical/british-empire.svg')} />

// Use meme
<Img src={staticFile('assets/memes/doge/swole-doge.png')} />
```
