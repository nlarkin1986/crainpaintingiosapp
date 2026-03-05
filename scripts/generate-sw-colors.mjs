import { writeFileSync } from 'fs';

const res = await fetch('https://raw.githubusercontent.com/glamp/sherwin-williams/main/data/colors.json');
const raw = await res.json();

function hexToHSL(hex) {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  let h, s, l = (max + min) / 2;
  if (max === min) { h = s = 0; }
  else {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
      case g: h = ((b - r) / d + 2) / 6; break;
      case b: h = ((r - g) / d + 4) / 6; break;
    }
  }
  return { h: h * 360, s: s * 100, l: l * 100 };
}

function deriveFamily(hex) {
  const { h, s, l } = hexToHSL(hex);
  if (l > 88) return 'White';
  if (s < 12 && l > 40) return 'Gray';
  if (s < 12) return 'Black';
  if (h >= 20 && h < 50 && s < 35) return 'Beige';
  if (h >= 20 && h < 50 && s < 60) return 'Brown';
  if ((h >= 340 || h < 20) && s > 30) return 'Red';
  if (h >= 300 && h < 340 && s > 20) return 'Pink';
  if (h >= 20 && h < 40 && s > 50) return 'Orange';
  if (h >= 40 && h < 70 && s > 30) return 'Yellow';
  if (h >= 70 && h < 165 && s > 15) return 'Green';
  if (h >= 165 && h < 260 && s > 15) return 'Blue';
  if (h >= 260 && h < 300 && s > 20) return 'Purple';
  return 'Neutral';
}

const colors = raw.map((c, i) => ({
  number: `SW${String(i + 1).padStart(4, '0')}`,
  name: c.name,
  family: deriveFamily(c.hex),
  hex: c.hex.replace('#', ''),
}));

writeFileSync('src/data/sw-colors.json', JSON.stringify(colors, null, 2));
console.log(`Wrote ${colors.length} SW colors`);
