-- migrations/002_demo_features.sql
-- Bag status/rating, recipes and equipment maintenance (features from the pitch deck).

-- ============================================================
-- COFFEE BAGS: status, the bag's own rating, favorite, buy link
-- ============================================================

ALTER TABLE coffee_bags
    ADD COLUMN status   TEXT NOT NULL DEFAULT 'opened'
        CHECK (status IN ('unopened','opened','finished')),
    ADD COLUMN favorite BOOLEAN NOT NULL DEFAULT false,
    -- Overall rating of the bag, separate from the rating of each brew
    ADD COLUMN rating   TEXT CHECK (rating IN ('excellent','good','ok','so-so','bad')),
    ADD COLUMN buy_url  TEXT;               -- "Buy again" link to the roaster

-- ============================================================
-- RECIPES
-- Saved once, picked when logging a brew. is_default = pre-selected.
-- ============================================================

CREATE TABLE recipes (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,          -- "Morning V60"
    brew_type       TEXT,                   -- 'v60' | 'aeropress' | 'espresso' | ...
    coffee_grams    FLOAT8,
    water_grams     FLOAT8,
    water_temp_c    FLOAT8,
    brew_time_secs  INT,
    -- [{"name":"Bloom","duration_secs":45,"water_ml":50}, ...]
    steps           JSONB,
    notes           TEXT,
    source          TEXT,                   -- who it came from, e.g. a roaster or another user
    is_default      BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_recipes_user_id ON recipes(user_id);

ALTER TABLE brews
    ADD COLUMN recipe_id INT REFERENCES recipes(id) ON DELETE SET NULL;

-- ============================================================
-- EQUIPMENT: purchase date and maintenance ("like Strava tracks your shoes")
-- ============================================================

ALTER TABLE grinders
    ADD COLUMN purchased_at     DATE,
    ADD COLUMN last_cleaned_at  TIMESTAMPTZ;

ALTER TABLE brewers
    ADD COLUMN purchased_at     DATE,
    ADD COLUMN last_cleaned_at  TIMESTAMPTZ,
    ADD COLUMN last_descaled_at TIMESTAMPTZ;
