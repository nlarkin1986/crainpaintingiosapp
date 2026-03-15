# Color Match Worker

Containerized FastAPI worker for color-sample preprocessing. It accepts a base64 image plus a normalized focus rectangle, crops the sample area, applies a pluggable white-balance correction stage, runs OpenCV GrabCut to isolate the dominant painted region, and returns a median sample color with quality diagnostics plus original and corrected PNG crops for OCR and reranking.

## Files

- `main.py`: FastAPI service with `GET /health` and `POST /match/analyze`
- `requirements.txt`: Python dependencies
- `Dockerfile`: container build for Cloud Run or any OCI host

## Local Run

```bash
cd color-match-worker
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8080
```

Health check:

```bash
curl http://localhost:8080/health
```

Optional worker auth:

- Set `COLOR_MATCH_WORKER_TOKEN` on the worker and the Next.js app to require `Authorization: Bearer <token>` on `POST /match/analyze`.
- Leave it unset to allow internal-only traffic without a bearer token.

Optional AWB tuning:

- Set `COLOR_MATCH_AWB_MODEL=gray_world` to force the legacy gray-world correction.
- Leave it unset to use the new metadata-guided hybrid correction path.

## Request Shape

`POST /match/analyze`

```json
{
  "imageBase64": "<base64 image bytes>",
  "imageMimeType": "image/jpeg",
  "focusRect": {
    "x": 0.28,
    "y": 0.24,
    "width": 0.32,
    "height": 0.32
  },
  "captureContext": {
    "flashUsed": false,
    "exposureBias": 0,
    "whiteBalanceMode": "auto",
    "source": "ios_camera"
  }
}
```

## Response Shape

```json
{
  "sampleHex": "A4AE9F",
  "quality": "good",
  "warnings": [],
  "diagnostics": {
    "coveragePct": 84.12,
    "glarePct": 1.03,
    "variance": 4.82,
    "preCorrectionHex": "B3BAA5",
    "postCorrectionHex": "A4AE9F"
  },
  "awbModel": "metadata_guided",
  "cropBase64": "<base64 PNG crop>",
  "cropMimeType": "image/png",
  "correctedCropBase64": "<base64 PNG crop>",
  "correctedCropMimeType": "image/png"
}
```

## Container Build

```bash
cd color-match-worker
docker build -t color-match-worker .
docker run --rm -p 8080:8080 color-match-worker
```

For Cloud Run, build the image and deploy with port `8080`. The service is stateless and does not require any local file storage.
