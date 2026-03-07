import { getBrandLabel } from "@/lib/brands";

const SURFACE_PROMPT_MAP: Record<string, string> = {
  "Exterior / Siding": `Repaint ONLY the exterior siding, clapboards, or stucco on the house body to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the trim, windows, doors, shutters, roof, gutters, porch columns, foundation, sky, or landscaping. Apply a smooth, professional exterior paint finish that respects the existing texture of the siding. Preserve the original lighting, shadows, and depth on the house.`,

  "Walls": `Repaint ONLY the wall surfaces to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the trim, baseboards, crown molding, ceiling, doors, windows, floors, or any fixtures. Apply a smooth, even finish. Preserve the original lighting and shadows.`,

  "Cabinets": `Repaint ONLY the cabinet doors, drawer fronts, and cabinet face frames to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the walls, countertops, backsplash, cabinet hardware, appliances, or any other surfaces. Apply a smooth, professional cabinet finish. Preserve the original lighting and shadows on the cabinets.`,

  "Front Door": `Repaint ONLY the front door panels and door slab to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the door frame, casing, sidelights, transom, walls, porch floor, or any other surfaces. Apply a smooth, professional paint finish. Preserve the original lighting, door hardware, and shadows.`,

  "Trim": `Repaint ONLY the trim — including baseboards, crown molding, window casings, door casings, and any other decorative moldings — to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the walls, ceiling, floors, doors, or any other surfaces. Apply a smooth, clean finish. Preserve the original lighting and shadows.`,

  "Ceiling": `Repaint ONLY the ceiling to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the walls, trim, crown molding, light fixtures, fans, or any other surfaces. Apply a smooth, flat finish. Preserve the original lighting and any existing shadows or texture.`,

  "Shutters": `Repaint ONLY the window shutters to {brandLabel} {colorName} ({colorNumber}, hex #{colorHex}). Do NOT paint the house siding, windows, window frames, trim, doors, or any other surfaces. Apply a smooth, professional finish. Preserve the original lighting and shadows.`,
};

const MAX_CUSTOM_INSTRUCTION_LENGTH = 80;
const IMAGE_EDIT_GUARDRAILS =
  "Edit the provided photo only. Keep the original camera angle, framing, depth, and lighting unchanged. Do not add, remove, or reshape objects, architecture, furniture, decor, people, sky, or landscaping. Preserve all surface textures and shadows; only change paint color on the requested surface.";

function withImageEditGuardrails(surfaceInstruction: string): string {
  return `${IMAGE_EDIT_GUARDRAILS} ${surfaceInstruction}`;
}

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

function sanitizePromptValue(value: string): string {
  return value.replace(/[\r\n\t]+/g, " ").replace(/\s+/g, " ").trim();
}

export function normalizeCustomInstruction(
  customInstruction?: string | null
): string | undefined {
  if (!customInstruction) return undefined;

  const normalized = customInstruction
    .replace(/[<>`{}[\]]/g, " ")
    .replace(/[\r\n\t]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, MAX_CUSTOM_INSTRUCTION_LENGTH);

  return normalized.length > 0 ? normalized : undefined;
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
  const colorHex = sanitizePromptValue(params.colorHex).replace(/^#/, "");
  const colorName = sanitizePromptValue(params.colorName);
  const colorNumber = sanitizePromptValue(params.colorNumber);

  const brandLabel = getBrandLabel(params.brand);
  const colorDescription = `${brandLabel} ${colorName} (${colorNumber}, hex #${colorHex})`;
  const customInstruction = normalizeCustomInstruction(params.customInstruction);

  // Custom instruction overrides surface lookup
  if (customInstruction) {
    return withImageEditGuardrails(
      `Repaint ONLY the ${customInstruction} to ${colorDescription}. Apply a smooth, professional paint finish. Keep all other elements completely unchanged. Preserve the original camera angle, lighting, shadows, and textures.`
    );
  }

  // Guard against surface="custom" with no customInstruction
  // (UI prevents this via disabled button, but be defensive)
  if (params.surface === "custom") {
    return withImageEditGuardrails(
      `Repaint ONLY the selected surface to ${colorDescription}. Apply a smooth, professional paint finish. Keep all other elements completely unchanged. Preserve the original camera angle, lighting, shadows, and textures.`
    );
  }

  const tokens = {
    brandLabel,
    colorName,
    colorNumber,
    colorHex,
  };

  const template = SURFACE_PROMPT_MAP[params.surface];
  if (template) {
    return withImageEditGuardrails(fillTemplate(template, tokens));
  }

  // Fallback for any unknown surface key
  const normalizedSurface = sanitizePromptValue(params.surface);
  return withImageEditGuardrails(
    `Repaint ONLY the ${normalizedSurface} to ${colorDescription}. Apply a smooth, professional paint finish. Keep all other elements completely unchanged. Preserve the original camera angle, lighting, shadows, and textures.`
  );
}
