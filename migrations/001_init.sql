CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE clients (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(255) NOT NULL,
  address     VARCHAR(512) NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_clients_name_trgm ON clients USING GIN (name gin_trgm_ops);
CREATE INDEX idx_clients_created_at ON clients (created_at DESC);

CREATE TABLE proposals (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id   UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  title       VARCHAR(255),
  notes       TEXT,
  deleted_at  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_proposals_client_id ON proposals (client_id);
CREATE INDEX idx_proposals_created_at ON proposals (created_at DESC);

CREATE TABLE proposal_results (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_id   UUID NOT NULL REFERENCES proposals(id) ON DELETE CASCADE,
  share_id      TEXT NOT NULL,
  original_url  TEXT NOT NULL,
  result_url    TEXT NOT NULL,
  color_name    VARCHAR(255) NOT NULL,
  color_number  VARCHAR(50)  NOT NULL,
  color_hex     VARCHAR(6)   NOT NULL,
  brand         VARCHAR(50)  NOT NULL DEFAULT 'benjamin_moore',
  surface       VARCHAR(255),
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_proposal_results_proposal_id ON proposal_results (proposal_id);
