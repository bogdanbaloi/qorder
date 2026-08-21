-- Venue configuration persisted server-side (owner Settings, ADR-0060). The
-- config is DATA: branding, table policy, loyalty and the rest of a venue's
-- AppConfig, stored as one JSON document per venue. The owner edits it and it
-- takes effect with no app release. The BFF keeps the document opaque (jsonb),
-- so the client owns the AppConfig shape and the BFF stays decoupled from it.

CREATE TABLE IF NOT EXISTS venue_config (
  venue_id   text        PRIMARY KEY,
  doc        jsonb       NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Tenant-scoped like every other venue table (ADR-0059). The owner reads and
-- writes only their own venue's document.
GRANT SELECT, INSERT, UPDATE, DELETE ON venue_config TO qorder_app;
ALTER TABLE venue_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON venue_config;
CREATE POLICY tenant_isolation ON venue_config
  USING (venue_id = current_setting('app.venue_id', true)
         OR current_setting('app.venue_id', true) = '__all__')
  WITH CHECK (venue_id = current_setting('app.venue_id', true)
         OR current_setting('app.venue_id', true) = '__all__');
