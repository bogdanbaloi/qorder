-- Reward redemptions, tenant-scoped by venue_id (persistence slice 3). Spending
-- loyalty points is not an order and never touches the POS. The id is a random
-- uuid (globally unique). Only the short human code is shown to the staff.
CREATE TABLE IF NOT EXISTS redemptions (
  id            text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  seq           bigserial NOT NULL,
  venue_id      text    NOT NULL,
  client_id     text    NOT NULL,
  reward        text    NOT NULL,
  cost          int     NOT NULL,
  code          text    NOT NULL,
  created_at_ms bigint  NOT NULL,
  consumed      boolean NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS redemptions_by_customer
  ON redemptions (venue_id, client_id);
CREATE INDEX IF NOT EXISTS redemptions_by_code ON redemptions (code);
