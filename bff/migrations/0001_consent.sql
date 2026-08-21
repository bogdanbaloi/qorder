-- Multi-tenant persistence, slice 1 (proof of pattern: consent).
--
-- Every tenant-scoped table carries venue_id, and every query filters on it. The
-- store ports already require venueId, so the store layer cannot forget the
-- filter; a cross-tenant test proves one venue never sees another's rows.
-- Row-Level Security (DB-level enforcement, defence in depth) lands in 0005_rls.
--
-- Identity (phone -> customer -> token) stays GLOBAL, not tenant-scoped: a person
-- is the same at any venue; their per-venue data links by customer_id + venue_id.

-- Consent: a customer's per-purpose choices at a venue. (venue_id, customer_id,
-- purpose) is unique, so recording a purpose replaces the prior choice (upsert).
CREATE TABLE IF NOT EXISTS consent (
  venue_id    text        NOT NULL,
  customer_id text        NOT NULL,
  purpose     text        NOT NULL,
  granted     boolean     NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (venue_id, customer_id, purpose)
);
