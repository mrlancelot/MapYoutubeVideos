# Font Download Instructions

## Primary Font: Bebas Neue
Bold condensed sans-serif - perfect for map captions

**Download:** https://fonts.google.com/specimen/Bebas+Neue

### How to Download:
1. Visit the Google Fonts link above
2. Click "Download family" button (top right)
3. Extract the ZIP file
4. Copy the .ttf files to this folder

---

## Alternative Fonts (Already on System):

### Impact
- Available on most systems
- Bold, condensed
- Classic meme font

### Arial Black
- Available on most systems
- Bold, clean

---

## For Remotion:
Add to your Remotion project:
```tsx
import { staticFile } from 'remotion';

// In your component
const fontFamily = 'Bebas Neue';

// Load in Root.tsx
<style>
  @font-face {
    font-family: 'Bebas Neue';
    src: url({staticFile('fonts/BebasNeue-Regular.ttf')});
  }
</style>
```
