-- Identity is GLOBAL, not tenant-scoped (persistence slice 4). A person is the
-- same at any venue, so the phone identifies the human, not the human-at-a-venue.
-- There is no venue_id here. Per-venue data (consent, orders, redemptions) links
-- to this global customer by customer_id.

CREATE TABLE IF NOT EXISTS customers (
  customer_id   text   PRIMARY KEY,
  phone         text   UNIQUE NOT NULL,
  created_at_ms bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_tokens (
  token         text   PRIMARY KEY,
  customer_id   text   NOT NULL REFERENCES customers (customer_id),
  created_at_ms bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS otp_challenges (
  challenge_id  text   PRIMARY KEY DEFAULT gen_random_uuid()::text,
  phone         text   NOT NULL,
  code          text   NOT NULL,
  expires_at_ms bigint NOT NULL
);

-- One row per start attempt, so the rate limiter counts recent starts per phone
-- (a challenge is deleted on verify, so it cannot be the rate-limit record).
CREATE TABLE IF NOT EXISTS otp_starts (
  id            bigserial PRIMARY KEY,
  phone         text   NOT NULL,
  started_at_ms bigint NOT NULL
);

CREATE INDEX IF NOT EXISTS otp_starts_by_phone
  ON otp_starts (phone, started_at_ms);
