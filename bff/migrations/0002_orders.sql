-- Orders, tenant-scoped by venue_id (persistence slice 2).
--
-- Each venue numbers its own orders from 1. That per-venue sequence comes from an
-- atomic counter row, so concurrent submits at one venue never collide. The
-- server_order_id is 'BFF-<venue>-<seq>', globally unique because (venue, seq) is
-- unique. Orders are kept after delivery, for owner metrics.

CREATE TABLE IF NOT EXISTS venue_order_counters (
  venue_id text PRIMARY KEY,
  last_seq int NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS orders (
  server_order_id text PRIMARY KEY,
  venue_id        text  NOT NULL,
  table_number    int   NOT NULL,
  sequence        int   NOT NULL,
  stage           text  NOT NULL,
  lines           jsonb NOT NULL DEFAULT '[]',
  customer_name   text,
  client_id       text,
  idempotency_key text,
  total_minor     int   NOT NULL DEFAULT 0,
  stamps          jsonb NOT NULL DEFAULT '{}',
  UNIQUE (venue_id, sequence)
);

CREATE INDEX IF NOT EXISTS orders_by_venue ON orders (venue_id);
CREATE INDEX IF NOT EXISTS orders_by_client ON orders (venue_id, client_id);

-- Idempotency is per venue: the same client key at two venues is two orders.
CREATE UNIQUE INDEX IF NOT EXISTS orders_idempotency
  ON orders (venue_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;
