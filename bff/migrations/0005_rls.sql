-- Row-Level Security: DB-level tenant isolation, defence in depth (ADR-0059).
--
-- App-level filtering already scopes every tenant query by venue_id. RLS makes
-- the database itself refuse a cross-venue row even when a query forgets the
-- filter. The catch: a superuser (and a table owner) BYPASSES RLS. So the app
-- never queries as the owner. Every tenant transaction drops to the
-- non-superuser role qorder_app (SET LOCAL ROLE) and sets app.venue_id, then the
-- policy keys on that. The sentinel '__all__' opens every venue for the operator
-- plane. Identity tables stay GLOBAL and out of RLS by design.

-- A login-less role reached via SET ROLE, not by connecting. There is no
-- CREATE ROLE IF NOT EXISTS, so guard on pg_roles for idempotency.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'qorder_app') THEN
    CREATE ROLE qorder_app NOLOGIN;
  END IF;
END
$$;

-- The connecting role must be a member of qorder_app to SET ROLE to it. A
-- superuser can regardless. A managed admin needs the membership.
GRANT qorder_app TO CURRENT_USER;

-- qorder_app runs the app's data operations, so it needs schema access, DML on
-- the tables it touches and USAGE on their sequences (bigserial columns). It
-- covers the global identity tables too, since a tenant transaction may relink
-- a customer's identity.
GRANT USAGE ON SCHEMA public TO qorder_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON
  consent, orders, venue_order_counters, redemptions,
  customers, auth_tokens, otp_challenges, otp_starts
  TO qorder_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO qorder_app;

-- Enable RLS on the tenant tables. Not FORCE: the app never queries as the
-- table owner (it SET ROLEs to qorder_app first). A plain ENABLE already
-- applies to a non-owner role.
ALTER TABLE consent              ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders               ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue_order_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE redemptions          ENABLE ROW LEVEL SECURITY;

-- One policy per tenant table: a row is visible and writable when its venue_id
-- matches app.venue_id, or when app.venue_id is the cross-venue sentinel. A
-- missing GUC reads as NULL (current_setting with missing_ok), so nothing
-- matches: fail closed. DROP first so the migration re-runs cleanly.
DROP POLICY IF EXISTS tenant_isolation ON consent;
CREATE POLICY tenant_isolation ON consent
  USING (venue_id = current_setting('app.venue_id', true)
         OR current_setting('app.venue_id', true) = '__all__')
  WITH CHECK (venue_id = current_setting('app.venue_id', true)
         OR current_setting('app.venue_id', true) = '__all__');

DROP POLICY IF EXISTS tenant_isolation ON orders;
CREATE POLICY tenant_isolation ON orders
  USING (venue_id = current_setting('app.venue_id', true)
         OR current_setting('app.venue_id', true) = '__all__')
  WITH CHECK (venue_id = current_setting('app.venue_id', true)
         OR current_setting('app.venue_id', true) = '__all__');

DROP POLICY IF EXISTS tenant_isolation ON venue_order_counters;
CREATE POLICY tenant_isolation ON venue_order_counters
  USING (venue_id = current_setting('app.venue_id', true)
         OR current_setting('app.venue_id', true) = '__all__')
  WITH CHECK (venue_id = current_setting('app.venue_id', true)
         OR current_setting('app.venue_id', true) = '__all__');

DROP POLICY IF EXISTS tenant_isolation ON redemptions;
CREATE POLICY tenant_isolation ON redemptions
  USING (venue_id = current_setting('app.venue_id', true)
         OR current_setting('app.venue_id', true) = '__all__')
  WITH CHECK (venue_id = current_setting('app.venue_id', true)
         OR current_setting('app.venue_id', true) = '__all__');
