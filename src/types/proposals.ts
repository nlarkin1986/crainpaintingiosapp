export interface Client {
  id: string;
  name: string;
  address: string;
  created_at: string;
}

export interface Proposal {
  id: string;
  client_id: string;
  title?: string;
  notes?: string;
  deleted_at?: string;
  created_at: string;
}

export interface ProposalResult {
  id: string;
  proposal_id: string;
  share_id: string;
  original_url: string;
  result_url: string;
  color_name: string;
  color_number: string;
  color_hex: string;
  brand: string;
  surface?: string;
  created_at: string;
}

export interface SaveProposalPayload {
  clientName: string;
  clientAddress: string;
  existingClientId?: string;
  forceCreate?: boolean;
  proposalTitle?: string;
  notes?: string;
  results: Array<{
    shareId: string;
    originalUrl: string;
    resultUrl: string;
    colorName: string;
    colorNumber: string;
    colorHex: string;
    brand: string;
    surface: string;
  }>;
}
