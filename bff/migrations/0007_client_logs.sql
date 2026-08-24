-- Client diagnostics, persisted durably (ADR-0063). The apps ship their warning
-- and error records here, so the operator sees failures that happen on a
-- patron's device (which never reach the server otherwise). Operator-plane
-- data, not tenant data: it is global (no RLS). The operator reads across
-- venues. venue_id is a plain column for filtering, not a tenant boundary.
CREATE TABLE IF NOT EXISTS client_logs (
  id          bigserial   PRIMARY KEY,
  received_at timestamptz NOT NULL DEFAULT now(),
  level       text        NOT NULL,
  message     text        NOT NULL,
  venue_id    text,
  context     text
);

CREATE INDEX IF NOT EXISTS client_logs_recent ON client_logs (received_at DESC);
