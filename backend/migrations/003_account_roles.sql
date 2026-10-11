-- migrations/003_account_roles.sql
-- Account types: home brewers ('user') and partner roasters ('roaster').
-- Roaster accounts are granted by us (not self-registered) and open the
-- roaster portal instead of the brew log.

ALTER TABLE users
    ADD COLUMN role         TEXT NOT NULL DEFAULT 'user'
        CHECK (role IN ('user', 'roaster')),
    ADD COLUMN roaster_name TEXT;           -- the roastery a roaster account represents
