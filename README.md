# Brewlog

A coffee brew log with a Strava-like community: a Rust/Axum backend with Postgres, plus a Flutter app that also runs as a PWA.

After the one-time setup, `./build.sh` starts Postgres, builds everything, runs the app on http://localhost:3001 (and on this computer's LAN IP, for phones) and seeds the demo data. Use `--no-web` to skip the Flutter build. The steps it runs are listed below.

```sh
# One-time setup (Arch/CachyOS)
sudo pacman -S --needed postgresql rustup && rustup default stable
git clone --depth 1 -b stable https://github.com/flutter/flutter ~/development/flutter
export PATH=$HOME/development/flutter/bin:$PATH
initdb -D ~/pgdata -U brewlog -W -A scram-sha-256    # password: test123
cargo install sqlx-cli --no-default-features --features postgres,rustls

# Start Postgres (port 3000), then create and migrate the database
pg_ctl -D ~/pgdata -o "-p 3000 -k $HOME/pgdata" -l ~/pgdata/server.log start
(cd backend && sqlx database setup)

# Build the web app, then run the backend and app on http://localhost:3001
(cd mobile && flutter build web --release --no-web-resources-cdn)
cargo run -p coffeelog-backend

# Demo data (in another terminal). Logins: demo/demo1234 (home brewer), nordlys/demo1234 (roaster)
node scripts/seed-demo.mjs
```

To make the bag photo scan real, set `ANTHROPIC_API_KEY` in `.env`. Without it, the scan returns example values. Run the tests with `cd mobile && flutter test` and `cargo test`; note that `cargo test --test dbtest` wipes all users. More notes are in `notes.txt`.
