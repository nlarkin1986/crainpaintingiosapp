#!/usr/bin/env python3
"""Generate Scandinavian-style Midwestern living room images for the Welcome screen."""

import os
from google import genai
from google.genai import types

client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

output_dir = "CrainPaintVisualizer/Sources/Resources/preview-images"
os.makedirs(output_dir, exist_ok=True)

prompt = """Create a stunning photorealistic interior photograph of a Scandinavian-style Midwestern living room.

The scene should feature:
- Freshly painted walls in a warm white / soft greige tone, with visible quality of the paint finish
- Clean minimalist Scandinavian furniture: a light oak coffee table, a cozy linen sofa in warm oatmeal
- Natural wood accents throughout (light oak flooring, wooden shelving)
- Cozy textiles: a chunky knit throw blanket, linen cushions in muted sage and cream
- Large windows letting in beautiful natural golden-hour light, sheer curtains
- A few green plants (fiddle leaf fig, trailing pothos) adding life
- Warm neutral color palette: cream, greige, soft sage, natural wood tones
- The room feels aspirational yet approachable and livable
- Midwest charm: slightly generous room proportions, comfortable and welcoming
- Shot with a 24mm wide-angle lens, natural lighting, editorial interior photography style
- The paint on the walls should look absolutely pristine and professionally applied, showcasing the transformative power of a fresh paint job

The mood should be calm, warm, and inviting - like a spread from Kinfolk or Cereal magazine. No people in the scene."""

print("Generating welcome screen hero image (9:16 portrait)...")
response = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents=[prompt],
    config=types.GenerateContentConfig(
        response_modalities=['TEXT', 'IMAGE'],
        image_config=types.ImageConfig(
            aspect_ratio="9:16",
        ),
    ),
)

for part in response.parts:
    if part.text:
        print(f"Model notes: {part.text}")
    elif part.inline_data:
        img = part.as_image()
        path = os.path.join(output_dir, "welcome-hero.jpg")
        img.save(path)
        print(f"Saved: {path}")

# Generate a second variation (landscape for potential iPad / detail use)
prompt_landscape = """Create a stunning photorealistic interior photograph detail shot of a Scandinavian-style Midwestern living room wall.

Focus on:
- A beautifully painted accent wall in a soft muted teal/sage tone, with perfect paint finish
- Partial view of minimalist wooden shelving with a ceramic vase and small plant
- Natural light streaming across the wall showing the paint's beautiful undertones
- Clean, editorial composition - tight crop showing paint quality and color
- Warm Scandinavian aesthetic with natural materials
- Shot with 50mm lens, soft natural window light, shallow depth of field
- Magazine-quality interior detail photography

No text, no people. The image should celebrate the beauty of a perfectly painted surface."""

print("\nGenerating welcome screen detail image (3:2 landscape)...")
response2 = client.models.generate_content(
    model="gemini-3-pro-image-preview",
    contents=[prompt_landscape],
    config=types.GenerateContentConfig(
        response_modalities=['TEXT', 'IMAGE'],
        image_config=types.ImageConfig(
            aspect_ratio="3:2",
        ),
    ),
)

for part in response2.parts:
    if part.text:
        print(f"Model notes: {part.text}")
    elif part.inline_data:
        img = part.as_image()
        path = os.path.join(output_dir, "welcome-detail.jpg")
        img.save(path)
        print(f"Saved: {path}")

print("\nDone! Images saved to:", output_dir)
