# Brewlog

A coffee brew log with a Strava-like community: a Rust/Axum backend with Postgres, plus a Flutter app that also runs as a PWA.

1. Start Postgres on port 3000, then create and migrate the database: `cd backend && sqlx database setup`
2. Build the web app: `cd mobile && flutter build web --release --no-web-resources-cdn`
3. From the repo root, start the backend and app: `cargo run -p coffeelog-backend`, then open http://localhost:3001
4. Add demo data with `node scripts/seed-demo.mjs`. Logins: `demo`/`demo1234` (home brewer) and `nordlys`/`demo1234` (roaster).
5. Optional: set `ANTHROPIC_API_KEY` in `.env` so the bag photo scan is real. Without it, the scan returns example values.
6. Run the tests with `cd mobile && flutter test` and `cargo test`. Note: `cargo test --test dbtest` wipes all users.

Full setup notes are in `notes.txt`. A competitor comparison is in `docs/brewlog-vs-filtru.md`.
