-- migrations/004_bag_photos.sql
-- One photo per coffee bag (taken when scanning or adding the bag).
-- Kept in its own table so listing bags never loads image bytes.

CREATE TABLE bag_photos (
    bag_id      INT PRIMARY KEY REFERENCES coffee_bags(id) ON DELETE CASCADE,
    media_type  TEXT NOT NULL CHECK (media_type IN ('image/jpeg', 'image/png', 'image/webp')),
    data        BYTEA NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
