'use client';

interface PrintButtonProps {
  proposalId?: string;
}

export function PrintButton({ proposalId }: PrintButtonProps) {
  if (proposalId) {
    return (
      <button
        onClick={() => window.open(`/admin/proposals/${proposalId}/print`, '_blank')}
        className="rounded-md border border-border bg-background px-3 py-1.5 text-sm font-medium hover:bg-muted"
      >
        Download PDF
      </button>
    );
  }

  return (
    <button
      onClick={() => window.print()}
      className="rounded-lg bg-primary-fill px-4 py-2 text-sm font-medium text-primary-fill-foreground shadow-lg hover:bg-primary-fill/90"
    >
      Print / Save as PDF
    </button>
  );
}
