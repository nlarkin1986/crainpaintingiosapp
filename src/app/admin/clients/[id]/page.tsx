'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import type { Proposal, Client } from '@/types/proposals';

export default function ClientProposalsPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [client, setClient] = useState<Client | null>(null);
  const [proposals, setProposals] = useState<Proposal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    async function load() {
      try {
        const [clientRes, proposalsRes] = await Promise.all([
          fetch(`/api/clients/${id}`),
          fetch(`/api/proposals?clientId=${id}`),
        ]);
        if (!clientRes.ok || !proposalsRes.ok) {
          setError(true);
          setLoading(false);
          return;
        }
        const [clientData, proposalsData] = await Promise.all([
          clientRes.json(),
          proposalsRes.json(),
        ]);
        setClient(clientData);
        setProposals(proposalsData);
        setLoading(false);
      } catch {
        setError(true);
        setLoading(false);
      }
    }
    load();
  }, [id]);

  const handleDelete = async (proposalId: string) => {
    if (!confirm('Delete this proposal?')) return;
    await fetch(`/api/proposals/${proposalId}`, { method: 'DELETE' });
    setProposals(prev => prev.filter(p => p.id !== proposalId));
  };

  if (loading) {
    return <div className="flex min-h-dvh items-center justify-center text-muted-foreground">Loading...</div>;
  }

  if (error) {
    return (
      <div className="flex min-h-dvh flex-col items-center justify-center gap-4 text-muted-foreground">
        <p>Could not load client data.</p>
        <Button variant="outline" onClick={() => router.push('/admin/dashboard')}>Back to Dashboard</Button>
      </div>
    );
  }

  return (
    <main className="min-h-dvh bg-background">
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Button variant="ghost" size="sm" onClick={() => router.push('/admin/dashboard')}>← Back</Button>
          <div>
            <h1 className="text-xl font-bold text-foreground">{client?.name ?? 'Client'}</h1>
            <p className="text-sm text-muted-foreground">{client?.address}</p>
          </div>
        </div>

        {proposals.length === 0 ? (
          <p className="py-12 text-center text-muted-foreground">No proposals for this client.</p>
        ) : (
          <div className="flex flex-col gap-3">
            {proposals.map((p) => (
              <Card key={p.id} className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium text-foreground">{p.title || 'Untitled Proposal'}</p>
                    <p className="text-sm text-muted-foreground">
                      {new Date(p.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/proposals/${p.id}`}>View →</Link>
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-destructive hover:text-destructive"
                      onClick={() => handleDelete(p.id)}
                    >
                      Delete
                    </Button>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>
    </main>
  );
}
