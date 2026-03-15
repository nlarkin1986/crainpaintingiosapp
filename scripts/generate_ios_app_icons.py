#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
APP_ICON_DIR = ROOT / "CrainPaintVisualizer" / "Sources" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"
REVIEW_DIR = ROOT / "app-icon-review"
MASTER_SIZE = 1024

ICON_SPECS = [
    ("app-icon-20@2x.png", 40),
    ("app-icon-20@3x.png", 60),
    ("app-icon-29@2x.png", 58),
    ("app-icon-29@3x.png", 87),
    ("app-icon-40@2x.png", 80),
    ("app-icon-40@3x.png", 120),
    ("app-icon-60@2x.png", 120),
    ("app-icon-60@3x.png", 180),
    ("app-icon-20@1x-ipad.png", 20),
    ("app-icon-20@2x-ipad.png", 40),
    ("app-icon-29@1x-ipad.png", 29),
    ("app-icon-29@2x-ipad.png", 58),
    ("app-icon-40@1x-ipad.png", 40),
    ("app-icon-40@2x-ipad.png", 80),
    ("app-icon-76@1x.png", 76),
    ("app-icon-76@2x.png", 152),
    ("app-icon-83.5@2x.png", 167),
    ("app-icon-1024.png", 1024),
]

REVIEW_SPECS = [
    ("app-icon-29.png", 29),
    ("app-icon-60.png", 60),
    ("app-icon-120.png", 120),
    ("app-icon-180.png", 180),
]


def colorize(mask: Image.Image, rgb: tuple[int, int, int], opacity: int = 255) -> Image.Image:
    layer = Image.new("RGBA", mask.size, rgb + (0,))
    alpha = mask.point(lambda value: max(0, min(255, int(value * opacity / 255))))
    layer.putalpha(alpha)
    return layer


def gradient_fill(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size)
    pixels = image.load()
    for y in range(height):
        t = y / max(1, height - 1)
        red = int(top[0] * (1 - t) + bottom[0] * t)
        green = int(top[1] * (1 - t) + bottom[1] * t)
        blue = int(top[2] * (1 - t) + bottom[2] * t)
        for x in range(width):
            pixels[x, y] = (red, green, blue, 255)
    return image


def make_card(
    card_size: tuple[int, int],
    canvas_size: int,
    fill_top: tuple[int, int, int],
    fill_bottom: tuple[int, int, int],
    angle: int,
    *,
    knob: bool = False,
    knob_shift: tuple[int, int] = (-5, -2),
) -> tuple[Image.Image, Image.Image]:
    card_width, card_height = card_size
    center = (canvas_size // 2, canvas_size // 2)
    card_bottom_offset = 64
    card_radius = 34

    base = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    mask = Image.new("L", (canvas_size, canvas_size), 0)
    mask_draw = ImageDraw.Draw(mask)

    left = center[0] - card_width // 2
    top = center[1] - card_height + card_bottom_offset
    right = left + card_width
    bottom = top + card_height
    bounds = (left, top, right, bottom)
    mask_draw.rounded_rectangle(bounds, radius=card_radius, fill=255)

    fill = gradient_fill((canvas_size, canvas_size), fill_top, fill_bottom)
    base = Image.composite(fill, base, mask)

    gloss = Image.new("L", (canvas_size, canvas_size), 0)
    gloss_draw = ImageDraw.Draw(gloss)
    gloss_draw.rounded_rectangle(
        (left + 6, top + 10, right - 8, top + card_height * 0.56),
        radius=card_radius - 8,
        fill=64,
    )
    gloss = gloss.filter(ImageFilter.GaussianBlur(26))
    base.alpha_composite(colorize(gloss, (255, 255, 255), 70))

    edge = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    edge_draw = ImageDraw.Draw(edge)
    edge_draw.rounded_rectangle(bounds, radius=card_radius, outline=(255, 255, 255, 78), width=4)
    edge_draw.rounded_rectangle(
        (left + 4, top + 4, right - 4, bottom - 4),
        radius=card_radius - 4,
        outline=(86, 86, 86, 22),
        width=2,
    )
    base.alpha_composite(edge)

    if knob:
        knob_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        knob_x = center[0] + knob_shift[0]
        knob_y = center[1] + knob_shift[1]
        ImageDraw.Draw(knob_layer).ellipse(
            (knob_x - 24, knob_y - 24, knob_x + 24, knob_y + 24),
            fill=(184, 158, 112, 255),
            outline=(216, 198, 157, 255),
            width=4,
        )
        knob_shadow = colorize(knob_layer.split()[-1].filter(ImageFilter.GaussianBlur(12)), (59, 42, 21), 120)
        base.alpha_composite(knob_shadow)
        base.alpha_composite(knob_layer)

        shine = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        ImageDraw.Draw(shine).ellipse(
            (knob_x - 16, knob_y - 19, knob_x + 3, knob_y - 1),
            fill=(244, 226, 191, 108),
        )
        base.alpha_composite(shine)

    rotated = base.rotate(angle, resample=Image.Resampling.BICUBIC, center=center)
    alpha = rotated.split()[-1]
    shadow = Image.new("RGBA", rotated.size, (0, 0, 0, 0))
    shadow.putalpha(alpha.point(lambda value: int(value * 0.28)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    return shadow, rotated


def build_master_icon() -> Image.Image:
    background = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 255))
    pixels = background.load()
    for y in range(MASTER_SIZE):
        t = y / (MASTER_SIZE - 1)
        for x in range(MASTER_SIZE):
            center_x = (x - MASTER_SIZE / 2) / (MASTER_SIZE / 2)
            center_y = (y - MASTER_SIZE / 2) / (MASTER_SIZE / 2)
            radial = max(0.0, 1.0 - (center_x * center_x + center_y * center_y) * 0.62)
            red = int(11 + 14 * (1 - t) + 11 * radial)
            green = int(92 + 26 * (1 - t) + 12 * radial)
            blue = int(112 + 24 * (1 - t) + 12 * radial)
            pixels[x, y] = (red, green, blue, 255)

    card_width = 256
    card_height = 540
    pivot = (520, 760)
    canvas_size = 1800

    cards = [
        ((243, 239, 232), (229, 224, 216), 58, False),
        ((217, 198, 160), (200, 183, 145), 34, False),
        ((191, 184, 173), (176, 169, 158), 14, False),
        ((231, 206, 194), (218, 191, 178), -2, False),
        ((237, 183, 125), (225, 166, 110), -20, False),
        ((198, 217, 216), (176, 205, 205), -56, False),
        ((243, 110, 67), (232, 95, 56), -35, True),
    ]

    for top, bottom, angle, knob in cards:
        shadow, card = make_card((card_width, card_height), canvas_size, top, bottom, angle, knob=knob)
        background.alpha_composite(shadow, dest=(pivot[0] - canvas_size // 2 + 12, pivot[1] - canvas_size // 2 + 18))
        background.alpha_composite(card, dest=(pivot[0] - canvas_size // 2, pivot[1] - canvas_size // 2))

    ground_shadow = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(ground_shadow).ellipse((196, 694, 828, 872), fill=(0, 0, 0, 70))
    ground_shadow = ground_shadow.filter(ImageFilter.GaussianBlur(34))
    background.alpha_composite(ground_shadow)

    center_glow = Image.new("L", (MASTER_SIZE, MASTER_SIZE), 0)
    ImageDraw.Draw(center_glow).ellipse((180, 190, 860, 870), fill=46)
    center_glow = center_glow.filter(ImageFilter.GaussianBlur(84))
    background.alpha_composite(colorize(center_glow, (255, 255, 255), 30))

    return background


def export_icons(master: Image.Image, specs: list[tuple[str, int]], output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for filename, pixel_size in specs:
        icon = master.resize((pixel_size, pixel_size), Image.Resampling.LANCZOS).convert("RGB")
        icon.save(output_dir / filename)


def main() -> None:
    master = build_master_icon()
    export_icons(master, ICON_SPECS, APP_ICON_DIR)
    export_icons(master, REVIEW_SPECS, REVIEW_DIR)


if __name__ == "__main__":
    main()
