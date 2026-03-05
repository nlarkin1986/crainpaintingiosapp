const BRAND_LABEL: Record<string, string> = {
  benjamin_moore: "Benjamin Moore",
  sherwin_williams: "Sherwin-Williams",
};

const SURFACE_PROMPT_MAP: Record<string, string> = {
  "Exterior / Siding": `Repaint ONLY the exterior siding, clapboards, or stucco on the house body to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the trim, windows, doors, shutters, roof, gutters, porch columns, foundation, sky, or landscaping. Apply a smooth, professional exterior paint finish that respects the existing texture of the siding. Preserve the original lighting, shadows, and depth on the house.`,

  "Walls": `Repaint ONLY the wall surfaces to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the trim, baseboards, crown molding, ceiling, doors, windows, floors, or any fixtures. Apply a smooth, even finish. Preserve the original lighting and shadows.`,

  "Cabinets": `Repaint ONLY the cabinet doors, drawer fronts, and cabinet face frames to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the walls, countertops, backsplash, cabinet hardware, appliances, or any other surfaces. Apply a smooth, professional cabinet finish. Preserve the original lighting and shadows on the cabinets.`,

  "Front Door": `Repaint ONLY the front door panels and door slab to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the door frame, casing, sidelights, transom, walls, porch floor, or any other surfaces. Apply a smooth, professional paint finish. Preserve the original lighting, door hardware, and shadows.`,

  "Trim": `Repaint ONLY the trim — including baseboards, crown molding, window casings, door casings, and any other decorative moldings — to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the walls, ceiling, floors, doors, or any other surfaces. Apply a smooth, clean finish. Preserve the original lighting and shadows.`,

  "Ceiling": `Repaint ONLY the ceiling to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the walls, trim, crown molding, light fixtures, fans, or any other surfaces. Apply a smooth, flat finish. Preserve the original lighting and any existing shadows or texture.`,

  "Shutters": `Repaint ONLY the window shutters to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the house siding, windows, window frames, trim, doors, or any other surfaces. Apply a smooth, professional finish. Preserve the original lighting and shadows.`,
};

function fillTemplate(
  template: string,
  tokens: Record<string, string>
): string {
  // Single-pass replacement — prevents cross-token injection if a color name
  // happens to contain a token like {colorHex}.
  return template.replace(
    /\{(brandLabel|colorName|colorNumber|colorHex)\}/g,
    (_, key) => tokens[key] ?? ""
  );
}

export function buildPaintPrompt(params: {
  surface: string;
  colorName: string;
  colorNumber: string;
  colorHex: string;
  brand?: "benjamin_moore" | "sherwin_williams" | string;
  customInstruction?: string;
}): string {
  // Normalize hex — strip any accidental leading # so prompt reads "hex #C4B5A0" not "hex ##C4B5A0"
  const colorHex = params.colorHex.replace(/^#/, "");

  const brandLabel =
    BRAND_LABEL[params.brand ?? "benjamin_moore"] ?? "Benjamin Moore";
  const colorDescription = `${brandLabel} ${params.colorName} (${params.colorNumber}, hex #${colorHex})`;

  // Custom instruction overrides surface lookup
  if (params.customInstruction) {
    return `Repaint ONLY the ${params.customInstruction} to ${colorDescription}. Apply a smooth, professional paint finish. Keep all other elements completely unchanged. Preserve the original lighting, shadows, and textures.`;
  }

  // Guard against surface="custom" with no customInstruction
  // (UI prevents this via disabled button, but be defensive)
  if (params.surface === "custom") {
    return `Repaint ONLY the selected surface to ${colorDescription}. Apply a smooth, professional paint finish. Keep all other elements completely unchanged. Preserve the original lighting, shadows, and textures.`;
  }

  const tokens = {
    brandLabel,
    colorName: params.colorName,
    colorNumber: params.colorNumber,
    colorHex,
  };

  const template = SURFACE_PROMPT_MAP[params.surface];
  if (template) {
    return fillTemplate(template, tokens);
  }

  // Fallback for any unknown surface key
  return `Repaint ONLY the ${params.surface} to ${colorDescription}. Apply a smooth, professional paint finish. Keep all other elements completely unchanged. Preserve the original lighting, shadows, and textures.`;
}
