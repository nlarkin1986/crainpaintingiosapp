"use client";

import { useEffect, useState, use } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Loader2, CheckCircle2, AlertCircle, Paintbrush, Sun, Palette, FileText } from "lucide-react";
import { cn } from "@/lib/utils";

const PROGRESS_STAGES = [
  { key: "analyzing", label: "Analyzing your lighting...", icon: Sun },
  { key: "generating", label: "Generating color recommendations...", icon: Palette },
  { key: "visualizing", label: "Creating visualizations...", icon: Paintbrush },
  { key: "assembling", label: "Assembling your report...", icon: FileText },
];

export default function StatusPage({ params }: { params: Promise<{ orderId: string }> }) {
  const { orderId } = use(params);
  const router = useRouter();
  const searchParams = useSearchParams();
  const [status, setStatus] = useState<string>("generating");
  const [progressIndex, setProgressIndex] = useState(0);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const supabase = createClient();

    const checkStatus = async () => {
      const { data: order } = await supabase
        .from("orders")
        .select("report_status")
        .eq("id", orderId)
        .single();

      if (order?.report_status === "complete") {
        // Find the report to redirect
        const { data: report } = await supabase
          .from("reports")
          .select("id, access_token")
          .eq("order_id", orderId)
          .single();

        if (report) {
          router.push(`/consultation/report/${report.id}?token=${report.access_token}`);
        }
      } else if (order?.report_status === "failed") {
        setStatus("failed");
        setError("We encountered an issue generating your report. Our team has been notified and will have it ready shortly.");
      }
    };

    // Poll every 5 seconds
    checkStatus();
    const pollInterval = setInterval(checkStatus, 5000);

    return () => clearInterval(pollInterval);
  }, [orderId, router]);

  // Cycle through progress stages for visual effect
  useEffect(() => {
    if (status !== "generating") return;
    const interval = setInterval(() => {
      setProgressIndex((prev) => (prev + 1) % PROGRESS_STAGES.length);
    }, 4000);
    return () => clearInterval(interval);
  }, [status]);

  return (
    <div className="flex min-h-[80dvh] flex-col items-center justify-center px-4 py-12">
      <div className="w-full max-w-md text-center">
        {status === "generating" && (
          <>
            <div className="mb-8 flex flex-col items-center gap-4">
              {PROGRESS_STAGES.map((stage, i) => {
                const Icon = stage.icon;
                const isActive = i === progressIndex;
                const isDone = i < progressIndex;
                return (
                  <div
                    key={stage.key}
                    className={cn(
                      "flex items-center gap-3 transition-all duration-500",
                      isActive ? "text-primary scale-105" : isDone ? "text-primary/50" : "text-muted-foreground/40"
                    )}
                  >
                    {isActive ? (
                      <Loader2 className="size-5 animate-spin" />
                    ) : isDone ? (
                      <CheckCircle2 className="size-5" />
                    ) : (
                      <Icon className="size-5" />
                    )}
                    <span className={cn("text-base", isActive ? "font-semibold" : "")}>
                      {stage.label}
                    </span>
                  </div>
                );
              })}
            </div>

            <h1 className="mb-3 font-heading text-2xl font-bold">
              Creating Your Color Report
            </h1>
            <p className="text-lg text-muted-foreground">
              This usually takes about 60-90 seconds. We&apos;ll redirect you automatically when it&apos;s ready.
            </p>
          </>
        )}

        {status === "failed" && (
          <>
            <AlertCircle className="mx-auto mb-4 size-12 text-amber-500" />
            <h1 className="mb-3 font-heading text-2xl font-bold">
              We&apos;re Working On It
            </h1>
            <p className="mb-6 text-lg text-muted-foreground">
              {error}
            </p>
            <p className="text-sm text-muted-foreground">
              You&apos;ll receive an email at the address you provided when your report is ready.
              If you have questions, contact us at support@crainpainting.com
            </p>
          </>
        )}
      </div>
    </div>
  );
}
