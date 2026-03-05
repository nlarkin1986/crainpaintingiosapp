"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { createClient } from "@/lib/supabase/client";
import { Loader2, Search, FileText, ExternalLink } from "lucide-react";
import Link from "next/link";

interface ReportResult {
  id: string;
  access_token: string;
  created_at: string;
  order: {
    package_type: string;
    report_status: string;
  };
}

export default function LookupPage() {
  const [email, setEmail] = useState("");
  const [results, setResults] = useState<ReportResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState("");

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;

    setLoading(true);
    setError("");
    setSearched(true);

    try {
      const supabase = createClient();

      // Find orders by email, then their reports
      const { data: orders } = await supabase
        .from("orders")
        .select("id, package_type, report_status")
        .eq("email", email.trim().toLowerCase())
        .eq("payment_status", "paid")
        .order("created_at", { ascending: false });

      if (!orders?.length) {
        setResults([]);
        return;
      }

      const orderIds = orders.map((o) => o.id);
      const { data: reports } = await supabase
        .from("reports")
        .select("id, access_token, created_at, order_id")
        .in("order_id", orderIds);

      const mapped = (reports || []).map((r) => ({
        id: r.id,
        access_token: r.access_token,
        created_at: r.created_at,
        order: orders.find((o) => o.id === r.order_id) || {
          package_type: "unknown",
          report_status: "unknown",
        },
      }));

      setResults(mapped);
    } catch {
      setError("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const formatPackage = (type: string) => {
    const names: Record<string, string> = {
      quick_review: "Quick Color Review",
      video_consultation: "Detailed Color Analysis",
      whole_home: "Whole Home Color Plan",
    };
    return names[type] || type;
  };

  return (
    <div className="mx-auto max-w-lg px-4 py-12">
      <h1 className="mb-2 font-heading text-3xl font-bold">Find Your Report</h1>
      <p className="mb-8 text-lg text-muted-foreground">
        Enter the email address you used when ordering your consultation
      </p>

      <form onSubmit={handleSearch} className="mb-8 flex gap-2">
        <Input
          type="email"
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="flex-1 text-lg"
          required
        />
        <Button type="submit" disabled={loading}>
          {loading ? <Loader2 className="size-4 animate-spin" /> : <Search className="size-4" />}
        </Button>
      </form>

      {error && <p className="mb-4 text-sm text-red-500">{error}</p>}

      {searched && results.length === 0 && !loading && (
        <div className="rounded-lg border border-dashed border-border p-8 text-center">
          <FileText className="mx-auto mb-3 size-8 text-muted-foreground/50" />
          <p className="text-muted-foreground">
            No reports found for this email address.
          </p>
        </div>
      )}

      {results.length > 0 && (
        <div className="flex flex-col gap-3">
          {results.map((report) => (
            <Card key={report.id} className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <div className="font-medium">{formatPackage(report.order.package_type)}</div>
                  <div className="text-sm text-muted-foreground">
                    {new Date(report.created_at).toLocaleDateString("en-US", {
                      month: "long",
                      day: "numeric",
                      year: "numeric",
                    })}
                  </div>
                </div>
                <Button asChild size="sm">
                  <Link href={`/consultation/report/${report.id}?token=${report.access_token}`}>
                    View
                    <ExternalLink className="size-3.5" />
                  </Link>
                </Button>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
