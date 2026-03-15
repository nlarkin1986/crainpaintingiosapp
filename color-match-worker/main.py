import base64
import binascii
import os
from dataclasses import dataclass
from typing import Literal

import cv2
import numpy as np
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field, model_validator


app = FastAPI(title="Crain Color Match Worker", version="0.2.0")


class FocusRect(BaseModel):
    x: float = Field(ge=0, le=1)
    y: float = Field(ge=0, le=1)
    width: float = Field(gt=0, le=1)
    height: float = Field(gt=0, le=1)

    @model_validator(mode="after")
    def validate_bounds(self) -> "FocusRect":
        if (self.x + self.width) > 1 or (self.y + self.height) > 1:
            raise ValueError("focusRect must stay within the image bounds.")
        return self


class CaptureContext(BaseModel):
    flashUsed: bool | None = None
    exposureBias: float | None = None
    whiteBalanceMode: str | None = None
    whiteBalanceTemperature: float | None = None
    whiteBalanceTint: float | None = None
    whiteBalanceRedGain: float | None = None
    whiteBalanceGreenGain: float | None = None
    whiteBalanceBlueGain: float | None = None
    iso: float | None = None
    exposureDurationSeconds: float | None = None
    deviceModel: str | None = None
    capturedAt: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    source: str | None = None


class AnalyzeRequest(BaseModel):
    imageBase64: str
    imageMimeType: str
    focusRect: FocusRect
    captureContext: CaptureContext | None = None


class Diagnostics(BaseModel):
    coveragePct: float
    glarePct: float
    variance: float
    preCorrectionHex: str | None = None
    postCorrectionHex: str | None = None


class AnalyzeResponse(BaseModel):
    sampleHex: str
    quality: Literal["good", "mixed", "poor"]
    warnings: list[str]
    diagnostics: Diagnostics
    awbModel: str
    cropBase64: str
    cropMimeType: Literal["image/png"]
    correctedCropBase64: str
    correctedCropMimeType: Literal["image/png"]


@dataclass
class ColorCorrectionResult:
    corrected_image: np.ndarray
    awb_model: str
    pre_correction_hex: str
    post_correction_hex: str


def get_required_bearer_token() -> str | None:
    token = os.environ.get("COLOR_MATCH_WORKER_TOKEN", "").strip()
    return token or None


def get_awb_model_preference() -> str:
    return os.environ.get("COLOR_MATCH_AWB_MODEL", "metadata_guided").strip() or "metadata_guided"


def require_authorization(authorization: str | None) -> None:
    required_token = get_required_bearer_token()
    if not required_token:
        return

    expected_header = f"Bearer {required_token}"
    if authorization != expected_header:
        raise HTTPException(status_code=401, detail="Unauthorized.")


def decode_image(image_base64: str) -> np.ndarray:
    try:
        raw_bytes = base64.b64decode(image_base64, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise HTTPException(status_code=400, detail="imageBase64 must be valid base64 data.") from exc

    buffer = np.frombuffer(raw_bytes, dtype=np.uint8)
    image = cv2.imdecode(buffer, cv2.IMREAD_COLOR)
    if image is None or image.size == 0:
        raise HTTPException(status_code=400, detail="Could not decode image.")
    return image


def crop_from_focus_rect(image: np.ndarray, focus_rect: FocusRect) -> np.ndarray:
    height, width = image.shape[:2]
    left = max(0, min(width - 1, int(round(focus_rect.x * width))))
    top = max(0, min(height - 1, int(round(focus_rect.y * height))))
    crop_width = max(1, int(round(focus_rect.width * width)))
    crop_height = max(1, int(round(focus_rect.height * height)))
    right = min(width, left + crop_width)
    bottom = min(height, top + crop_height)

    if right <= left or bottom <= top:
        raise HTTPException(status_code=400, detail="focusRect produced an empty crop.")

    crop = image[top:bottom, left:right].copy()
    if crop.size == 0:
        raise HTTPException(status_code=400, detail="focusRect produced an empty crop.")
    return crop


def gray_world_balance(image: np.ndarray) -> np.ndarray:
    float_image = image.astype(np.float32)
    channel_means = float_image.reshape(-1, 3).mean(axis=0)
    safe_means = np.where(channel_means < 1e-3, 1.0, channel_means)
    target_mean = float(np.mean(safe_means))
    scales = target_mean / safe_means
    balanced = float_image * scales
    return np.clip(balanced, 0, 255).astype(np.uint8)


def shades_of_gray_balance(image: np.ndarray, power: int = 6) -> np.ndarray:
    float_image = image.astype(np.float32) / 255.0
    powered = np.power(np.clip(float_image, 1e-6, 1.0), power)
    illuminant = np.power(np.mean(powered.reshape(-1, 3), axis=0), 1.0 / power)
    safe = np.where(illuminant < 1e-3, 1.0, illuminant)
    target = float(np.mean(safe))
    scales = target / safe
    balanced = float_image * scales
    return np.clip(balanced * 255.0, 0, 255).astype(np.uint8)


def blend_images(primary: np.ndarray, secondary: np.ndarray, weight: float) -> np.ndarray:
    alpha = float(np.clip(weight, 0.0, 1.0))
    return cv2.addWeighted(primary, 1.0 - alpha, secondary, alpha, 0.0)


def apply_capture_gain_hint(image: np.ndarray, context: CaptureContext) -> np.ndarray:
    gains = np.array([
        context.whiteBalanceBlueGain or 1.0,
        context.whiteBalanceGreenGain or 1.0,
        context.whiteBalanceRedGain or 1.0,
    ], dtype=np.float32)
    gains = np.where(gains < 1e-3, 1.0, gains)
    gains /= float(np.mean(gains))
    inverse = np.reciprocal(gains)
    inverse /= float(np.mean(inverse))

    hinted = image.astype(np.float32) * inverse.reshape(1, 1, 3)
    return np.clip(hinted, 0, 255).astype(np.uint8)


def apply_temperature_tint_hint(image: np.ndarray, context: CaptureContext) -> np.ndarray:
    temperature = float(context.whiteBalanceTemperature or 5000.0)
    tint = float(context.whiteBalanceTint or 0.0)

    cool_warm = np.clip((temperature - 5000.0) / 2500.0, -1.0, 1.0)
    tint_shift = np.clip(tint / 40.0, -1.0, 1.0)
    scales = np.array([
        1.0 - (0.07 * cool_warm),
        1.0 - (0.03 * tint_shift),
        1.0 + (0.07 * cool_warm),
    ], dtype=np.float32)

    adjusted = image.astype(np.float32) * scales.reshape(1, 1, 3)
    return np.clip(adjusted, 0, 255).astype(np.uint8)


def apply_exposure_hint(image: np.ndarray, context: CaptureContext) -> np.ndarray:
    exposure_bias = float(context.exposureBias or 0.0)
    if abs(exposure_bias) < 0.35:
        return image

    gamma = 1.0 + np.clip(exposure_bias * 0.18, -0.28, 0.28)
    normalized = np.clip(image.astype(np.float32) / 255.0, 0.0, 1.0)
    adjusted = np.power(normalized, 1.0 / gamma)
    return np.clip(adjusted * 255.0, 0, 255).astype(np.uint8)


def median_hex_from_bgr_pixels(pixels: np.ndarray) -> str:
    if pixels.size == 0:
        raise HTTPException(status_code=500, detail="No usable pixels remained after masking.")

    median_bgr = np.median(pixels.astype(np.float32), axis=0)
    blue, green, red = [int(np.clip(round(channel), 0, 255)) for channel in median_bgr]
    return f"{red:02X}{green:02X}{blue:02X}"


def median_hex_from_image(image: np.ndarray) -> str:
    return median_hex_from_bgr_pixels(image.reshape(-1, 3))


def apply_color_correction(image: np.ndarray, capture_context: CaptureContext | None) -> ColorCorrectionResult:
    pre_correction_hex = median_hex_from_image(image)
    preferred_model = get_awb_model_preference()

    if preferred_model == "gray_world":
        corrected = gray_world_balance(image)
        return ColorCorrectionResult(
            corrected_image=corrected,
            awb_model="gray_world",
            pre_correction_hex=pre_correction_hex,
            post_correction_hex=median_hex_from_image(corrected),
        )

    corrected = blend_images(
        gray_world_balance(image),
        shades_of_gray_balance(image),
        0.42,
    )

    awb_model = "hybrid_scene_awb"
    if capture_context and any(
        value is not None
        for value in [
            capture_context.whiteBalanceTemperature,
            capture_context.whiteBalanceTint,
            capture_context.whiteBalanceRedGain,
            capture_context.whiteBalanceGreenGain,
            capture_context.whiteBalanceBlueGain,
            capture_context.exposureBias,
        ]
    ):
        metadata_guided = corrected
        if capture_context.whiteBalanceRedGain or capture_context.whiteBalanceGreenGain or capture_context.whiteBalanceBlueGain:
            metadata_guided = blend_images(
                metadata_guided,
                apply_capture_gain_hint(image, capture_context),
                0.45,
            )

        if capture_context.whiteBalanceTemperature is not None or capture_context.whiteBalanceTint is not None:
            metadata_guided = blend_images(
                metadata_guided,
                apply_temperature_tint_hint(metadata_guided, capture_context),
                0.35,
            )

        metadata_guided = apply_exposure_hint(metadata_guided, capture_context)
        corrected = metadata_guided
        awb_model = "metadata_guided"

    return ColorCorrectionResult(
        corrected_image=corrected,
        awb_model=awb_model,
        pre_correction_hex=pre_correction_hex,
        post_correction_hex=median_hex_from_image(corrected),
    )


def run_grabcut(image: np.ndarray) -> np.ndarray:
    height, width = image.shape[:2]
    mask = np.full((height, width), cv2.GC_PR_BGD, dtype=np.uint8)

    inset_x = max(2, int(round(width * 0.08)))
    inset_y = max(2, int(round(height * 0.08)))
    rect_width = max(1, width - (2 * inset_x))
    rect_height = max(1, height - (2 * inset_y))
    rect = (
        min(inset_x, width - 1),
        min(inset_y, height - 1),
        rect_width,
        rect_height,
    )

    background_model = np.zeros((1, 65), dtype=np.float64)
    foreground_model = np.zeros((1, 65), dtype=np.float64)

    try:
        cv2.grabCut(image, mask, rect, background_model, foreground_model, 3, cv2.GC_INIT_WITH_RECT)
        refined = np.where(
            (mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD),
            255,
            0,
        ).astype(np.uint8)
    except cv2.error:
        refined = np.full((height, width), 255, dtype=np.uint8)

    kernel = np.ones((3, 3), np.uint8)
    refined = cv2.morphologyEx(refined, cv2.MORPH_OPEN, kernel, iterations=1)
    refined = cv2.morphologyEx(refined, cv2.MORPH_CLOSE, kernel, iterations=1)
    return refined


def masked_pixels(image: np.ndarray, mask: np.ndarray) -> np.ndarray:
    pixels = image[mask > 0]
    if pixels.size == 0:
        return image.reshape(-1, 3)
    return pixels


def compute_variance(image: np.ndarray, mask: np.ndarray) -> float:
    pixels = masked_pixels(image, mask)
    if pixels.size == 0:
        return 0.0
    lab_pixels = cv2.cvtColor(pixels.reshape(-1, 1, 3), cv2.COLOR_BGR2LAB).reshape(-1, 3).astype(np.float32)
    median = np.median(lab_pixels, axis=0)
    deltas = np.linalg.norm(lab_pixels - median, axis=1)
    return float(np.std(deltas))


def compute_glare_pct(image: np.ndarray) -> float:
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    glare_pixels = np.count_nonzero(gray >= 245)
    total_pixels = max(1, gray.size)
    return (glare_pixels / total_pixels) * 100.0


def select_sample_pixels(image: np.ndarray, mask: np.ndarray) -> np.ndarray:
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    value_channel = hsv[:, :, 2]
    usable = (mask > 0) & (value_channel > 20) & (value_channel < 245)
    pixels = image[usable]
    if pixels.size == 0:
        return masked_pixels(image, mask)
    return pixels


def encode_png_base64(image: np.ndarray) -> str:
    ok, encoded = cv2.imencode(".png", image)
    if not ok:
        raise HTTPException(status_code=500, detail="Could not encode crop PNG.")
    return base64.b64encode(encoded.tobytes()).decode("ascii")


def classify_quality(coverage_pct: float, glare_pct: float, variance: float, warnings: list[str]) -> Literal["good", "mixed", "poor"]:
    if coverage_pct < 18 or glare_pct > 28 or variance > 18:
        return "poor"
    if coverage_pct < 35 or glare_pct > 12 or variance > 10 or warnings:
        return "mixed"
    return "good"


def build_warnings(
    coverage_pct: float,
    glare_pct: float,
    variance: float,
    capture_context: CaptureContext | None,
) -> list[str]:
    warnings: list[str] = []

    if coverage_pct < 35:
        warnings.append("The selected region contains limited uniform paint area.")
    if glare_pct > 12:
        warnings.append("Strong highlights or glare may reduce match accuracy.")
    if variance > 10:
        warnings.append("The sampled area shows visible color variation or texture.")
    if capture_context and capture_context.flashUsed:
        warnings.append("Flash was enabled, which can shift perceived color.")
    if capture_context and capture_context.whiteBalanceTemperature and abs(capture_context.whiteBalanceTemperature - 5000) > 1700:
        warnings.append("The capture light looked strongly warm or cool, so color correction was applied aggressively.")

    return warnings


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/match/analyze", response_model=AnalyzeResponse)
def analyze_color(
    request: AnalyzeRequest,
    authorization: str | None = Header(default=None),
) -> AnalyzeResponse:
    require_authorization(authorization)
    image = decode_image(request.imageBase64)
    cropped_original = crop_from_focus_rect(image, request.focusRect)
    correction = apply_color_correction(cropped_original, request.captureContext)
    corrected_crop = correction.corrected_image
    grabcut_mask = run_grabcut(corrected_crop)

    coverage_pct = float((np.count_nonzero(grabcut_mask) / max(1, grabcut_mask.size)) * 100.0)
    glare_pct = compute_glare_pct(cropped_original)
    variance = compute_variance(corrected_crop, grabcut_mask)
    warnings = build_warnings(coverage_pct, glare_pct, variance, request.captureContext)
    quality = classify_quality(coverage_pct, glare_pct, variance, warnings)

    sample_pixels = select_sample_pixels(corrected_crop, grabcut_mask)
    original_sample_pixels = select_sample_pixels(cropped_original, grabcut_mask)
    sample_hex = median_hex_from_bgr_pixels(sample_pixels)
    pre_correction_hex = median_hex_from_bgr_pixels(original_sample_pixels)

    return AnalyzeResponse(
        sampleHex=sample_hex,
        quality=quality,
        warnings=warnings,
        diagnostics=Diagnostics(
            coveragePct=round(coverage_pct, 2),
            glarePct=round(glare_pct, 2),
            variance=round(variance, 2),
            preCorrectionHex=pre_correction_hex,
            postCorrectionHex=sample_hex,
        ),
        awbModel=correction.awb_model,
        cropBase64=encode_png_base64(cropped_original),
        cropMimeType="image/png",
        correctedCropBase64=encode_png_base64(corrected_crop),
        correctedCropMimeType="image/png",
    )
