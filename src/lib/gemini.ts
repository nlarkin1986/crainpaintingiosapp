import { GoogleGenAI } from "@google/genai";

const MODEL_ID = "gemini-2.5-flash-image";

let _ai: GoogleGenAI | null = null;

function getClient(): GoogleGenAI {
  if (!_ai) {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY environment variable is not set");
    }
    _ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }
  return _ai;
}

/**
 * Send an image + text prompt to Gemini and return the generated image.
 * Returns { data: string (base64), mimeType: string } or throws.
 */
export async function generatePaintVisualization(
  prompt: string,
  imageBase64: string,
  imageMimeType: string
): Promise<{ data: string; mimeType: string }> {
  const ai = getClient();
  const response = await ai.models.generateContent({
    model: MODEL_ID,
    contents: [
      {
        role: "user",
        parts: [
          { text: prompt },
          {
            inlineData: {
              mimeType: imageMimeType,
              data: imageBase64,
            },
          },
        ],
      },
    ],
    config: {
      responseModalities: ["TEXT", "IMAGE"],
    },
  });

  const parts = response.candidates?.[0]?.content?.parts;
  if (!parts) {
    throw new Error("No response parts returned from Gemini");
  }

  const imagePart = parts.find(
    (p: { inlineData?: { data?: string; mimeType?: string } }) => p.inlineData?.data
  );

  if (!imagePart?.inlineData?.data || !imagePart?.inlineData?.mimeType) {
    throw new Error("Gemini did not return an image in the response");
  }

  return {
    data: imagePart.inlineData.data,
    mimeType: imagePart.inlineData.mimeType,
  };
}
