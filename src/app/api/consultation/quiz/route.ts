import { NextRequest, NextResponse } from 'next/server';
import Anthropic from '@anthropic-ai/sdk';
import { getAllColors, searchColors } from '@/lib/colors';

const anthropic = new Anthropic();

export const maxDuration = 30;

export async function POST(request: NextRequest) {
  try {
    const { roomType, mood, selectedColors, round } = await request.json();

    if (!roomType || !mood) {
      return NextResponse.json(
        { error: 'Room type and mood are required' },
        { status: 400 }
      );
    }

    const allColors = getAllColors();
    // Get a sample of colors for context (too many to send all)
    const popularFamilies = ['White', 'Gray', 'Blue', 'Green', 'Beige', 'Brown'];
    const sampleColors = popularFamilies.flatMap(family =>
      allColors.filter(c => c.family === family).slice(0, 8)
    );

    const previousSelections = selectedColors?.length
      ? `\nThe user has already selected: ${selectedColors.join(', ')}. Suggest complementary colors that work with these.`
      : '';

    const roundContext = round > 0
      ? `\nThis is refinement round ${round}. Offer new options the user hasn't seen.`
      : '';

    const nudge = round >= 5
      ? '\nThe user has done several rounds of refinement. Add a brief encouraging message like "Great selections! These colors will create a beautiful palette."'
      : '';

    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-5-20250929',
      max_tokens: 1024,
      messages: [
        {
          role: 'user',
          content: `You are an expert color consultant for Benjamin Moore paints. Suggest 4-6 colors for a ${roomType} with a "${mood}" vibe.${previousSelections}${roundContext}${nudge}

Available Benjamin Moore colors (sample): ${JSON.stringify(sampleColors.map(c => ({ number: c.number, name: c.name, family: c.family, hex: c.hex })))}

Return a JSON object with:
- "suggestions": array of objects with { "number": "BM color number", "name": "color name", "hex": "hex without #", "family": "color family" }
- "message": a brief, friendly message explaining why these colors work for this space

IMPORTANT: Only suggest real Benjamin Moore colors from the catalog. Each suggestion must have a valid BM color number.`
        }
      ],
    });

    const textContent = response.content.find(c => c.type === 'text');
    if (!textContent || textContent.type !== 'text') {
      throw new Error('No text response from Claude');
    }

    // Extract JSON from response
    const jsonMatch = textContent.text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error('Could not parse color suggestions');
    }

    const parsed = JSON.parse(jsonMatch[0]);

    // Validate suggestions against our color catalog
    const validatedSuggestions = parsed.suggestions
      .map((s: { number: string }) => {
        const catalogColor = allColors.find(c => c.number === s.number);
        return catalogColor || null;
      })
      .filter(Boolean);

    return NextResponse.json({
      suggestions: validatedSuggestions.length > 0 ? validatedSuggestions : parsed.suggestions,
      message: parsed.message || 'Here are some great options for your space!',
    });
  } catch (error) {
    console.error('Quiz suggestion error:', error);
    return NextResponse.json(
      { error: 'Failed to generate color suggestions. Please try again.' },
      { status: 500 }
    );
  }
}
