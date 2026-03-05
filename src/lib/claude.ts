import Anthropic from '@anthropic-ai/sdk';
import type { ColorRecommendation } from '@/types/consultation';

const anthropic = new Anthropic();

export interface ReportGenerationInput {
  roomType: string;
  mood: string;
  selectedColors: string[];
  surfaceType: string;
  windowDirection: string;
  sunData: {
    sunrise: string;
    sunset: string;
    dayLengthHours: number;
    lightingDescription: string;
  };
  photoDescriptions?: string[];
  packageType: string;
}

export interface GeneratedReport {
  executiveSummary: string;
  recommendations: ColorRecommendation[];
  applicationTips: string[];
  surfacePrep: string[];
}

export async function generateReport(input: ReportGenerationInput): Promise<GeneratedReport> {
  const recCount = input.packageType === 'quick_review' ? '2-3'
    : input.packageType === 'video_consultation' ? '4-5'
    : '6-8';

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-5-20250929',
    max_tokens: 4096,
    messages: [
      {
        role: 'user',
        content: `You are Curt Crain, a professional painter, fine artist, and Benjamin Moore color specialist with 20+ years of experience. Generate a detailed color consultation report.

## Context
- Room type: ${input.roomType}
- Desired mood: ${input.mood}
- Colors of interest: ${input.selectedColors.join(', ')}
- Surface: ${input.surfaceType}
- Window direction: ${input.windowDirection}
- Sunrise: ${input.sunData.sunrise}
- Sunset: ${input.sunData.sunset}
- Day length: ${input.sunData.dayLengthHours} hours
- Lighting: ${input.sunData.lightingDescription}

## Instructions
Generate ${recCount} color recommendations. For each:
1. Choose a Benjamin Moore color (must be a real BM color with valid number)
2. Write a detailed rationale (2-3 sentences) explaining WHY this color works for this specific room, considering lighting, mood, and existing preferences
3. Specify finish/sheen recommendation
4. Consider how the color shifts from morning to evening light

Return a JSON object with this exact structure:
{
  "executiveSummary": "2-3 paragraph executive summary of the consultation",
  "recommendations": [
    {
      "colorName": "BM color name",
      "colorNumber": "BM color number like HC-172",
      "hex": "hex without #",
      "rationale": "detailed rationale",
      "finishSheen": "e.g. Eggshell, Satin, Semi-Gloss"
    }
  ],
  "applicationTips": ["tip1", "tip2", "tip3"],
  "surfacePrep": ["prep step 1", "prep step 2"]
}

Write in a warm, expert tone. Be specific about lighting conditions and how they interact with each color.`
      }
    ],
  });

  const textContent = response.content.find(c => c.type === 'text');
  if (!textContent || textContent.type !== 'text') {
    throw new Error('No text response from Claude');
  }

  const jsonMatch = textContent.text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error('Could not parse report from Claude response');
  }

  return JSON.parse(jsonMatch[0]);
}
