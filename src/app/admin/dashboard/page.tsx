import Link from 'next/link';
import { listClients } from '@/lib/db';
import { Button } from '@/components/ui/button';
import { ClientList } from './client-list';

export default async function AdminDashboard() {
  let clients: Awaited<ReturnType<typeof listClients>> = [];
  try {
    clients = await listClients();
  } catch {
    // DB not configured yet
  }

  return (
    <main className="min-h-dvh bg-background">
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="mb-8 flex items-center justify-between">
          <h1 className="text-2xl font-bold text-foreground">Proposals</h1>
          <div className="flex gap-2">
            <Button asChild variant="outline" size="sm">
              <Link href="/" target="_blank">Open Visualizer ↗</Link>
            </Button>
            <Button asChild variant="ghost" size="sm">
              <a href="/api/admin/logout">Logout</a>
            </Button>
          </div>
        </div>

        {clients.length === 0 ? (
          <div className="rounded-xl border border-border bg-muted/30 py-16 text-center">
            <p className="text-muted-foreground">No proposals yet.</p>
            <Button asChild variant="outline" className="mt-4">
              <Link href="/" target="_blank">Open Visualizer →</Link>
            </Button>
          </div>
        ) : (
          <ClientList clients={clients} />
        )}
      </div>
    </main>
  );
}
