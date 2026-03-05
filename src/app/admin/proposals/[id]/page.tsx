import Image from 'next/image';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getProposal } from '@/lib/db';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { PrintButton } from './print/print-button';

export default async function ProposalDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const proposal = await getProposal(id);
  if (!proposal) notFound();

  return (
    <main className="min-h-dvh bg-background">
      <div className="mx-auto max-w-4xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Button asChild variant="ghost" size="sm">
            <Link href={`/admin/clients/${proposal.client.id}`}>← Back</Link>
          </Button>
          <div className="flex-1">
            <h1 className="text-xl font-bold text-foreground">{proposal.title || 'Untitled Proposal'}</h1>
            <p className="text-sm text-muted-foreground">{proposal.client.name} · {proposal.client.address}</p>
          </div>
          <PrintButton proposalId={id} />
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {proposal.results.map((r) => (
            <Card key={r.id} className="overflow-hidden p-0">
              <div className="grid grid-cols-2">
                <div className="relative aspect-[4/3]">
                  <Image src={r.original_url} alt="Before" fill className="object-cover" sizes="25vw" />
                  <span className="absolute left-2 top-2 rounded-full bg-black/60 px-2 py-0.5 text-xs text-white">Before</span>
                </div>
                <div className="relative aspect-[4/3]">
                  <Image src={r.result_url} alt="After" fill className="object-cover" sizes="25vw" />
                  <span className="absolute right-2 top-2 rounded-full bg-white/80 px-2 py-0.5 text-xs text-foreground">After</span>
                </div>
              </div>
              <div className="flex items-center gap-3 p-3">
                <div className="h-8 w-8 shrink-0 rounded-md border border-black/10" style={{ backgroundColor: `#${r.color_hex}` }} />
                <div>
                  <p className="text-sm font-semibold">{r.color_name}</p>
                  <p className="text-xs text-muted-foreground">{r.color_number}</p>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </div>
    </main>
  );
}
