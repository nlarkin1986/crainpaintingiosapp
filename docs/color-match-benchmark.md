# Color Match Benchmark

Create a manifest JSON file with labeled samples, then run:

```bash
COLOR_MATCH_BENCHMARK_BASE_URL=http://localhost:3000 npm run color-match:benchmark -- path/to/manifest.json
```

Manifest shape:

```json
{
  "samples": [
    {
      "id": "bm-chip-daylight-01",
      "imagePath": "../fixtures/bm-chip-daylight-01.jpg",
      "imageMimeType": "image/jpeg",
      "focusRect": { "x": 0.22, "y": 0.18, "width": 0.46, "height": 0.46 },
      "captureContext": {
        "source": "ios_camera",
        "whiteBalanceTemperature": 5200,
        "whiteBalanceTint": 6,
        "whiteBalanceRedGain": 2.1,
        "whiteBalanceGreenGain": 1.0,
        "whiteBalanceBlueGain": 1.8
      },
      "expected": {
        "brand": "benjamin_moore",
        "number": "HC-114"
      }
    }
  ]
}
```

The benchmark report prints:

- Top-1 accuracy
- Top-3 accuracy
- Median `deltaETop1`
- Per-sample `matchMethod` and diagnostics
