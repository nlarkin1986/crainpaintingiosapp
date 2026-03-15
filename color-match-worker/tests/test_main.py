import unittest
from pathlib import Path
import sys

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from main import (
    AnalyzeRequest,
    CaptureContext,
    FocusRect,
    analyze_color,
    apply_color_correction,
)


def solid_image(color_bgr, size=32):
    image = np.zeros((size, size, 3), dtype=np.uint8)
    image[:, :] = np.array(color_bgr, dtype=np.uint8)
    return image


class ColorMatchWorkerTests(unittest.TestCase):
    def test_apply_color_correction_returns_metadata_rich_result(self):
        image = solid_image((120, 160, 190))
        context = CaptureContext(
            flashUsed=False,
            exposureBias=0.2,
            whiteBalanceMode="continuous_auto",
            whiteBalanceTemperature=5200,
            whiteBalanceTint=6,
            whiteBalanceRedGain=2.0,
            whiteBalanceGreenGain=1.0,
            whiteBalanceBlueGain=1.7,
            iso=80,
            exposureDurationSeconds=0.01,
            deviceModel="iPhone17,1",
            capturedAt="2026-03-13T12:00:00Z",
            latitude=43.0389,
            longitude=-87.9065,
            source="ios_camera",
        )

        corrected = apply_color_correction(image, context)

        self.assertEqual(corrected.awb_model, "metadata_guided")
        self.assertRegex(corrected.pre_correction_hex, r"^[0-9A-F]{6}$")
        self.assertRegex(corrected.post_correction_hex, r"^[0-9A-F]{6}$")
        self.assertEqual(corrected.corrected_image.shape, image.shape)

    def test_analyze_color_returns_expanded_diagnostics(self):
        image = solid_image((120, 160, 190))
        _, encoded = cv2.imencode(".jpg", image)
        request = AnalyzeRequest(
            imageBase64=__import__("base64").b64encode(encoded.tobytes()).decode("ascii"),
            imageMimeType="image/jpeg",
            focusRect=FocusRect(x=0, y=0, width=1, height=1),
            captureContext=CaptureContext(source="ios_camera"),
        )

        response = analyze_color(request)

        self.assertTrue(hasattr(response, "awbModel"))
        self.assertTrue(hasattr(response.diagnostics, "preCorrectionHex"))
        self.assertTrue(hasattr(response.diagnostics, "postCorrectionHex"))


if __name__ == "__main__":
    unittest.main()
