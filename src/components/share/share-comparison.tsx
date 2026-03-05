"use client";

import {
  ReactCompareSlider,
  ReactCompareSliderImage,
} from "react-compare-slider";

interface ShareComparisonProps {
  originalUrl: string;
  resultUrl: string;
  colorName: string;
}

export function ShareComparison({
  originalUrl,
  resultUrl,
  colorName,
}: ShareComparisonProps) {
  return (
    <div className="relative overflow-hidden rounded-xl border border-border shadow-sm">
      <ReactCompareSlider
        changePositionOnHover={false}
        itemOne={
          <ReactCompareSliderImage src={originalUrl} alt="Original photo" />
        }
        itemTwo={
          <ReactCompareSliderImage
            src={resultUrl}
            alt={`Room visualized in ${colorName}`}
          />
        }
        className="aspect-[4/3] w-full"
      />
      <span className="pointer-events-none absolute left-3 top-3 rounded-md bg-black/60 px-2 py-1 text-sm font-medium text-white">
        Before
      </span>
      <span className="pointer-events-none absolute right-3 top-3 rounded-md bg-black/60 px-2 py-1 text-sm font-medium text-white">
        After
      </span>
    </div>
  );
}
