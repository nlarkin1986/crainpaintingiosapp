'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Card } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import type { Client } from '@/types/proposals';
import { Search } from 'lucide-react';

interface ClientListProps {
  clients: (Client & { proposal_count: number })[];
}

export function ClientList({ clients }: ClientListProps) {
  const [query, setQuery] = useState('');

  const filtered = query.trim()
    ? clients.filter(c =>
        c.name.toLowerCase().includes(query.toLowerCase()) ||
        c.address.toLowerCase().includes(query.toLowerCase())
      )
    : clients;

  return (
    <div>
      <div className="relative mb-4">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          placeholder="Search clients..."
          value={query}
          onChange={e => setQuery(e.target.value)}
          className="pl-9"
        />
      </div>

      {filtered.length === 0 ? (
        <p className="py-8 text-center text-sm text-muted-foreground">
          {query ? 'No clients match your search.' : 'No proposals yet.'}
        </p>
      ) : (
        <div className="flex flex-col gap-3">
          {filtered.map((client) => (
            <Link key={client.id} href={`/admin/clients/${client.id}`}>
              <Card className="cursor-pointer p-4 transition-shadow hover:shadow-md">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-semibold text-foreground">{client.name}</p>
                    <p className="text-sm text-muted-foreground">{client.address}</p>
                  </div>
                  <div className="text-right">
                    <span className="text-sm font-medium text-primary">
                      {client.proposal_count} {client.proposal_count === 1 ? 'proposal' : 'proposals'}
                    </span>
                    <p className="text-xs text-muted-foreground">View →</p>
                  </div>
                </div>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
