import Image from 'next/image';
import { getProposal } from '@/lib/db';
import { notFound } from 'next/navigation';
import { PrintButton } from './print-button';

export default async function PrintPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const proposal = await getProposal(id);
  if (!proposal) notFound();

  const date = new Date(proposal.created_at).toLocaleDateString('en-US', {
    month: 'long', day: 'numeric', year: 'numeric',
  });

  return (
    <>
      <style dangerouslySetInnerHTML={{ __html: `
        @media print {
          @page { margin: 0.75in; }
          body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
          .no-print { display: none !important; }
          .page-break { page-break-before: always; }
        }
        body { font-family: system-ui, sans-serif; background: white; color: #17252A; margin: 0; padding: 0; }
      `}} />

      {/* Cover / Header */}
      <div className="px-8 pt-10 pb-6">
        <div className="mb-8 flex items-start justify-between border-b border-gray-200 pb-6">
          <div>
            <h1 className="text-3xl font-bold text-foreground">Color Proposal</h1>
            <p className="mt-1 text-lg font-semibold text-primary">{proposal.client.name}</p>
            <p className="text-sm text-muted-foreground">{proposal.client.address}</p>
          </div>
          <div className="text-right">
            <p className="text-sm font-medium text-muted-foreground">Crain Painting Contractors</p>
            <p className="text-xs text-muted-foreground">crainpaintingcontractors.com</p>
            <p className="mt-2 text-xs text-muted-foreground">{date}</p>
          </div>
        </div>

        {proposal.title && (
          <p className="mb-6 text-base text-muted-foreground">{proposal.title}</p>
        )}
        {proposal.notes && (
          <p className="mb-6 text-sm text-muted-foreground">{proposal.notes}</p>
        )}
      </div>

      {/* Color pages */}
      {proposal.results.map((r, i) => (
        <div key={r.id} className={`px-8 pb-8 ${i > 0 ? 'page-break pt-10' : ''}`}>
          <div className="mb-4 flex items-center gap-3">
            <div
              className="h-8 w-8 rounded-md border border-black/10"
              style={{ backgroundColor: `#${r.color_hex}` }}
            />
            <div>
              <p className="font-bold text-lg">{r.color_name}</p>
              <p className="text-sm text-muted-foreground">{r.color_number} {r.brand === 'sherwin_williams' ? '- Sherwin-Williams' : '- Benjamin Moore'}</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="mb-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">Before</p>
              <div className="relative aspect-[4/3] overflow-hidden rounded-lg">
                <Image src={r.original_url} alt="Before" fill className="object-cover" sizes="40vw" />
              </div>
            </div>
            <div>
              <p className="mb-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">After</p>
              <div className="relative aspect-[4/3] overflow-hidden rounded-lg">
                <Image src={r.result_url} alt={`After: ${r.color_name}`} fill className="object-cover" sizes="40vw" />
              </div>
            </div>
          </div>
        </div>
      ))}

      {/* Print button (hidden in print) */}
      <div className="no-print fixed bottom-6 right-6">
        <PrintButton />
      </div>
    </>
  );
}
