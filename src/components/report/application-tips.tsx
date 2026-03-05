"use client";

import { Paintbrush, CheckSquare } from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

interface ApplicationTipsProps {
  tips: string[];
  surfacePrep: string[];
}

export function ApplicationTips({ tips, surfacePrep }: ApplicationTipsProps) {
  return (
    <div className="grid gap-6 md:grid-cols-2">
      {/* Application tips */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Paintbrush className="size-4 text-primary" />
            Application Tips
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ol className="space-y-3">
            {tips.map((tip, i) => (
              <li key={i} className="flex gap-3 text-sm text-foreground/90">
                <span className="flex-shrink-0 flex items-center justify-center size-6 rounded-full bg-primary/10 text-primary text-xs font-semibold">
                  {i + 1}
                </span>
                <span className="pt-0.5">{tip}</span>
              </li>
            ))}
          </ol>
        </CardContent>
      </Card>

      {/* Surface prep checklist */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <CheckSquare className="size-4 text-primary" />
            Surface Preparation
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-3">
            {surfacePrep.map((step, i) => (
              <li key={i} className="flex gap-3 text-sm text-foreground/90">
                <span className="flex-shrink-0 mt-0.5 size-5 rounded border-2 border-primary/40" />
                <span>{step}</span>
              </li>
            ))}
          </ul>
        </CardContent>
      </Card>
    </div>
  );
}
