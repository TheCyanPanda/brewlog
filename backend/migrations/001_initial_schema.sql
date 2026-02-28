-- migrations/001_initial_schema.sql
-- Full schema. Drop and recreate the DB to apply from scratch:
--   sqlx database drop && sqlx database create && sqlx migrate run

-- ============================================================
-- USERS
-- ============================================================

CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    username        TEXT NOT NULL UNIQUE,
    display_name    TEXT,
    email           TEXT UNIQUE,
    password_hash   TEXT NOT NULL,          -- argon2id hash, never store plaintext
    is_admin        BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Long-lived bearer tokens for mobile clients (stateful so they can be revoked)
CREATE TABLE user_tokens (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,       -- hash of the raw token, never store raw
    label       TEXT,                       -- e.g. "Pixel 9 Pro", "home server"
    expires_at  TIMESTAMPTZ,               -- NULL = non-expiring
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- EQUIPMENT
-- Each piece of equipment belongs to one user
-- ============================================================

CREATE TABLE grinders (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,              -- e.g. "ZP6 Special"
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE brewers (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,              -- e.g. "Hario Glass V60"
    brew_method TEXT NOT NULL,             -- 'filter' | 'espresso' | 'immersion' | 'other'
    brew_type   TEXT,                      -- 'v60' | 'chemex' | 'aeropress' | 'espresso' | etc
    brand       TEXT,
    model       TEXT,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- COFFEE BAGS
-- One row = one bag in a user's collection.
-- bag_hash is unique per user, not globally.
-- ============================================================

CREATE TABLE coffee_bags (
    id                      SERIAL PRIMARY KEY,
    user_id                 INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Human-friendly hash: e.g. "MCR-0042" (roaster initials + sequential per user)
    bag_hash                TEXT,
    CONSTRAINT coffee_bags_user_bag_hash UNIQUE (user_id, bag_hash),

    -- Roaster info
    roaster                 TEXT,           -- "Morgon Coffee Roasters"
    roaster_origin_city     TEXT,           -- "Gothenburg"
    roaster_origin_country  TEXT,           -- "Sweden"

    -- Bean info
    origin_country          TEXT,           -- "Ethiopia"
    origin_region           TEXT,           -- "Yirgacheffe"
    roast_level             TEXT,           -- "Light", "Dark" etc
    variety                 TEXT,           -- "Heirloom", "Gesha", "Typica"
    process                 TEXT,           -- "Washed", "Natural", "Honey"
    taste_notes             TEXT[],         -- ["blueberry", "dark chocolate"]
    bean_type               TEXT,           -- "Heirloom", "SL28", etc

    -- Dates
    harvest_date            DATE,
    roast_date              DATE,

    -- Advanced / optional
    caffeine_free           BOOLEAN NOT NULL DEFAULT false,
    batch_id                TEXT,           -- roaster's own batch number
    image_path              TEXT,           -- path to photo on server

    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- BREWS
-- One row = one brew session. brew_hash is unique per user.
-- ============================================================

CREATE TABLE brews (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- e.g. "MCR-0042-B003" — inherits bag_hash + per-bag brew counter
    brew_hash       TEXT,
    CONSTRAINT brews_user_brew_hash UNIQUE (user_id, brew_hash),

    coffee_bag_id   INT REFERENCES coffee_bags(id) ON DELETE SET NULL,

    -- When
    brew_datetime   TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Equipment
    grinder_id      INT REFERENCES grinders(id) ON DELETE SET NULL,
    grind_setting   TEXT,                   -- "4.5" — text because settings vary by grinder
    brewer_id       INT REFERENCES brewers(id) ON DELETE SET NULL,
    filter_paper    TEXT,                   -- "Cafec Abaca"

    -- Measurements (store canonical values; conversions done in UI)
    coffee_grams    FLOAT8,                 -- e.g. 15.0
    water_grams     FLOAT8,                 -- e.g. 250.0
    -- ratio is DERIVED: water_grams / coffee_grams — not stored to avoid staleness
    water_temp_c    FLOAT8,                 -- always store Celsius; convert in UI
    brew_time_secs  INT,                    -- store as seconds; display as mm:ss in UI

    -- Brew steps: structured array or free text
    -- [{"name":"Bloom","duration_secs":45,"water_ml":50,"notes":"Swirl gently"}, ...]
    brew_steps      JSONB,

    -- Review
    rating          TEXT CHECK (rating IN ('excellent','good','ok','so-so','bad')),
    review          TEXT,
    notes           TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- INDEXES
-- user_id indexes on every table (all queries are user-scoped).
-- ============================================================

CREATE INDEX idx_user_tokens_user_id    ON user_tokens(user_id);

CREATE INDEX idx_grinders_user_id       ON grinders(user_id);

CREATE INDEX idx_brewers_user_id        ON brewers(user_id);

CREATE INDEX idx_coffee_bags_user_id    ON coffee_bags(user_id);
CREATE INDEX idx_coffee_bags_roaster    ON coffee_bags(user_id, roaster);
CREATE INDEX idx_coffee_bags_origin     ON coffee_bags(user_id, origin_country, origin_region);

CREATE INDEX idx_brews_user_id          ON brews(user_id);
CREATE INDEX idx_brews_coffee_bag       ON brews(user_id, coffee_bag_id);
CREATE INDEX idx_brews_datetime         ON brews(user_id, brew_datetime DESC);
CREATE INDEX idx_brews_rating           ON brews(user_id, rating);
