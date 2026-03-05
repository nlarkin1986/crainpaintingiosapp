"use client";

import type { SunData } from "@/types/consultation";

interface SunTimelineProps {
  sunData: SunData;
}

function formatTime(iso: string): string {
  try {
    return new Date(iso).toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
    });
  } catch {
    return iso;
  }
}

/** Map an ISO time to a 0-1 fraction between sunrise and sunset. */
function timeFraction(iso: string, sunrise: Date, sunset: Date): number {
  const t = new Date(iso).getTime();
  const span = sunset.getTime() - sunrise.getTime();
  if (span <= 0) return 0.5;
  return Math.max(0, Math.min(1, (t - sunrise.getTime()) / span));
}

export function SunTimeline({ sunData }: SunTimelineProps) {
  const sunrise = new Date(sunData.sunrise);
  const sunset = new Date(sunData.sunset);
  const noonFrac = timeFraction(sunData.solarNoon, sunrise, sunset);
  const goldenFrac = timeFraction(sunData.goldenHour, sunrise, sunset);

  const svgW = 600;
  const svgH = 100;
  const barY = 60;
  const barH = 8;
  const padX = 40;
  const barW = svgW - padX * 2;

  const toX = (frac: number) => padX + frac * barW;

  return (
    <div className="w-full overflow-x-auto">
      <svg
        viewBox={`0 0 ${svgW} ${svgH}`}
        className="w-full max-w-[600px] mx-auto"
        role="img"
        aria-label={`Sun timeline: sunrise at ${formatTime(sunData.sunrise)}, solar noon at ${formatTime(sunData.solarNoon)}, golden hour at ${formatTime(sunData.goldenHour)}, sunset at ${formatTime(sunData.sunset)}`}
      >
        {/* Background bar */}
        <rect
          x={padX}
          y={barY}
          width={barW}
          height={barH}
          rx={barH / 2}
          fill="#E2E8F0"
        />

        {/* Daylight gradient fill */}
        <defs>
          <linearGradient id="dayGradient" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stopColor="#FCD34D" stopOpacity={0.6} />
            <stop offset="40%" stopColor="#FBBF24" stopOpacity={0.9} />
            <stop offset="70%" stopColor="#F59E0B" stopOpacity={0.9} />
            <stop offset="100%" stopColor="#F97316" stopOpacity={0.7} />
          </linearGradient>
        </defs>
        <rect
          x={padX}
          y={barY}
          width={barW}
          height={barH}
          rx={barH / 2}
          fill="url(#dayGradient)"
        />

        {/* Golden hour highlight */}
        <rect
          x={toX(goldenFrac)}
          y={barY - 2}
          width={toX(1) - toX(goldenFrac)}
          height={barH + 4}
          rx={(barH + 4) / 2}
          fill="#F97316"
          opacity={0.35}
        />

        {/* Sunrise marker */}
        <circle cx={toX(0)} cy={barY + barH / 2} r={6} fill="#FBBF24" stroke="#fff" strokeWidth={2} />
        <text x={toX(0)} y={barY + barH + 18} textAnchor="middle" className="text-[10px]" fill="#64748b" fontSize={10}>
          {formatTime(sunData.sunrise)}
        </text>
        <text x={toX(0)} y={barY - 10} textAnchor="middle" fill="#0f172a" fontSize={10} fontWeight={500}>
          Sunrise
        </text>

        {/* Solar noon marker */}
        <circle cx={toX(noonFrac)} cy={barY + barH / 2} r={7} fill="#F59E0B" stroke="#fff" strokeWidth={2} />
        <text x={toX(noonFrac)} y={barY + barH + 18} textAnchor="middle" fill="#64748b" fontSize={10}>
          {formatTime(sunData.solarNoon)}
        </text>
        <text x={toX(noonFrac)} y={barY - 10} textAnchor="middle" fill="#0f172a" fontSize={10} fontWeight={500}>
          Solar Noon
        </text>

        {/* Golden hour marker */}
        <circle cx={toX(goldenFrac)} cy={barY + barH / 2} r={5} fill="#F97316" stroke="#fff" strokeWidth={2} />
        <text x={toX(goldenFrac)} y={barY + barH + 18} textAnchor="middle" fill="#64748b" fontSize={10}>
          {formatTime(sunData.goldenHour)}
        </text>
        <text x={toX(goldenFrac)} y={barY - 10} textAnchor="middle" fill="#0f172a" fontSize={10} fontWeight={500}>
          Golden Hour
        </text>

        {/* Sunset marker */}
        <circle cx={toX(1)} cy={barY + barH / 2} r={6} fill="#F97316" stroke="#fff" strokeWidth={2} />
        <text x={toX(1)} y={barY + barH + 18} textAnchor="middle" fill="#64748b" fontSize={10}>
          {formatTime(sunData.sunset)}
        </text>
        <text x={toX(1)} y={barY - 10} textAnchor="middle" fill="#0f172a" fontSize={10} fontWeight={500}>
          Sunset
        </text>
      </svg>

      <p className="text-center text-xs text-muted-foreground mt-1">
        {sunData.dayLengthHours.toFixed(1)} hours of daylight
      </p>
    </div>
  );
}
