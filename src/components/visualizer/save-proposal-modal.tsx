'use client';

import { useState, useEffect, useRef } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { X, Loader2, Search } from 'lucide-react';
import type { ColorResult } from '@/types/colors';
import type { Client } from '@/types/proposals';

interface SaveProposalModalProps {
  results: Array<Extract<ColorResult, { status: 'complete' }>>;
  onClose: () => void;
  onSaved: (proposalId: string) => void;
  surface: string;
}

export function SaveProposalModal({ results, onClose, onSaved, surface }: SaveProposalModalProps) {
  const [clientName, setClientName] = useState('');
  const [clientAddress, setClientAddress] = useState('');
  const [proposalTitle, setProposalTitle] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [suggestions, setSuggestions] = useState<Client[]>([]);
  const [existingClient, setExistingClient] = useState<Client | null>(null);
  const [clientSearch, setClientSearch] = useState('');
  const [clientSearchResults, setClientSearchResults] = useState<Client[]>([]);
  const [searchLoading, setSearchLoading] = useState(false);
  const [showSearch, setShowSearch] = useState(false);
  const searchTimeout = useRef<ReturnType<typeof setTimeout>>(undefined);

  useEffect(() => {
    if (!clientSearch.trim() || !showSearch) {
      setClientSearchResults([]);
      return;
    }
    clearTimeout(searchTimeout.current);
    searchTimeout.current = setTimeout(async () => {
      setSearchLoading(true);
      const res = await fetch(`/api/clients?q=${encodeURIComponent(clientSearch)}`);
      if (res.ok) setClientSearchResults(await res.json());
      setSearchLoading(false);
    }, 300);
  }, [clientSearch, showSearch]);

  const handleSubmit = async (forceCreate = false) => {
    setSaving(true);
    setError('');
    setSuggestions([]);

    const mappedResults = results.map(r => ({
      shareId: r.shareId,
      originalUrl: r.originalUrl,
      resultUrl: r.resultUrl,
      colorName: r.color.name,
      colorNumber: r.color.number,
      colorHex: r.color.hex,
      brand: r.color.brand ?? 'benjamin_moore',
      surface,
    }));

    const payload = existingClient
      ? {
          clientName: existingClient.name,
          clientAddress: existingClient.address,
          existingClientId: existingClient.id,
          proposalTitle: proposalTitle || undefined,
          results: mappedResults,
        }
      : {
          clientName: clientName.trim(),
          clientAddress: clientAddress.trim(),
          proposalTitle: proposalTitle || undefined,
          forceCreate,
          results: mappedResults,
        };

    const res = await fetch('/api/proposals', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (res.status === 422) {
      const data = await res.json();
      setSuggestions(data.suggestions || []);
      setSaving(false);
      return;
    }

    if (!res.ok) {
      const data = await res.json();
      setError(data.error || 'Failed to save');
      setSaving(false);
      return;
    }

    const data = await res.json();
    setSaving(false);
    onSaved(data.proposalId);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-4 sm:items-center" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="w-full max-w-md rounded-2xl bg-background p-6 shadow-xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-bold text-foreground">Save as Proposal</h2>
          <button onClick={onClose} className="rounded-full p-1 text-muted-foreground hover:bg-muted">
            <X className="h-4 w-4" />
          </button>
        </div>

        {/* Colors being saved */}
        <div className="mb-4 flex flex-wrap gap-1.5">
          {results.map(r => (
            <span key={r.color.number} className="inline-flex items-center gap-1.5 rounded-full border border-border bg-muted/50 px-2.5 py-1 text-xs">
              <span className="h-3 w-3 rounded-full border border-black/10" style={{ backgroundColor: `#${r.color.hex}` }} />
              {r.color.name}
            </span>
          ))}
        </div>

        {/* Existing client toggle */}
        <button
          type="button"
          className="mb-4 flex items-center gap-1.5 text-sm text-primary hover:underline"
          onClick={() => setShowSearch(s => !s)}
        >
          <Search className="h-3.5 w-3.5" />
          {showSearch ? 'Enter new client instead' : 'Attach to existing client'}
        </button>

        {showSearch ? (
          <div className="mb-4">
            {existingClient ? (
              <div className="flex items-center justify-between rounded-lg border border-primary/30 bg-primary/5 p-3">
                <div>
                  <p className="text-sm font-semibold">{existingClient.name}</p>
                  <p className="text-xs text-muted-foreground">{existingClient.address}</p>
                </div>
                <button onClick={() => setExistingClient(null)} className="text-muted-foreground hover:text-foreground">
                  <X className="h-4 w-4" />
                </button>
              </div>
            ) : (
              <div>
                <Input
                  placeholder="Search by client name..."
                  value={clientSearch}
                  onChange={e => setClientSearch(e.target.value)}
                />
                {searchLoading && <p className="mt-1 text-xs text-muted-foreground">Searching...</p>}
                {clientSearchResults.length > 0 && (
                  <div className="mt-1 rounded-lg border border-border bg-background shadow-md">
                    {clientSearchResults.map(c => (
                      <button
                        key={c.id}
                        className="w-full px-3 py-2 text-left text-sm hover:bg-muted"
                        onClick={() => { setExistingClient(c); setClientSearch(''); setClientSearchResults([]); }}
                      >
                        <span className="font-medium">{c.name}</span>
                        <span className="ml-2 text-xs text-muted-foreground">{c.address}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        ) : (
          <div className="mb-4 flex flex-col gap-3">
            <Input
              placeholder="Client name *"
              value={clientName}
              onChange={e => setClientName(e.target.value)}
              maxLength={255}
            />
            <Input
              placeholder="Client address *"
              value={clientAddress}
              onChange={e => setClientAddress(e.target.value)}
              maxLength={512}
            />
          </div>
        )}

        <Input
          placeholder="Proposal title (optional)"
          value={proposalTitle}
          onChange={e => setProposalTitle(e.target.value)}
          maxLength={255}
          className="mb-4"
        />

        {/* "Did you mean?" suggestions */}
        {suggestions.length > 0 && (
          <div className="mb-4 rounded-lg border border-amber-200 bg-amber-50 p-3">
            <p className="text-sm font-medium text-amber-900">Similar clients found:</p>
            {suggestions.map(s => (
              <button
                key={s.id}
                className="mt-1 block text-sm text-amber-800 hover:underline"
                onClick={() => { setExistingClient(s); setShowSearch(true); setSuggestions([]); }}
              >
                {s.name} -- {s.address}
              </button>
            ))}
            <div className="mt-2 flex gap-2">
              <Button variant="outline" size="sm" onClick={() => handleSubmit(true)}>
                Save as New Client
              </Button>
            </div>
          </div>
        )}

        {error && <p className="mb-3 text-sm text-destructive">{error}</p>}

        <Button
          className="w-full"
          onClick={() => handleSubmit(false)}
          disabled={saving || (!existingClient && (!clientName.trim() || !clientAddress.trim()))}
        >
          {saving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          {saving ? 'Saving...' : 'Save Proposal'}
        </Button>
      </div>
    </div>
  );
}
