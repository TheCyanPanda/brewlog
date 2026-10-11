#!/usr/bin/env node
// Seeds a demo account with realistic equipment, recipes, bags and ~3 months of brews.
// Grind, temperature and days-since-roast drive the ratings, so the insights,
// charts and suggestions in the app have a story to tell.
//
// Usage: node scripts/seed-demo.mjs [base_url]     (default http://localhost:3001)
// Logins: demo / demo1234 (home brewer), nordlys / demo1234 (roaster portal).
// Skips the brews if the demo user already has bags.
//
// Roaster accounts can't be self-registered, so the roaster role is granted
// with psql using DATABASE_URL (from the environment or .env).

import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const BASE = process.argv[2] ?? 'http://localhost:3001';
const USER = { username: 'demo', password: 'demo1234' };
const ROASTER = { username: 'nordlys', password: 'demo1234', display_name: 'Nordlys Kafferosteri' };
const DAY = 24 * 60 * 60 * 1000;

// Deterministic pseudo-random numbers, so every seed gives the same data
let rngState = 42;
function rand() {
  rngState = (rngState * 1664525 + 1013904223) % 4294967296;
  return rngState / 4294967296;
}
const pick = (arr) => arr[Math.floor(rand() * arr.length)];
const round1 = (x) => Math.round(x * 10) / 10;
const isoDate = (daysAgo) => new Date(Date.now() - daysAgo * DAY).toISOString().slice(0, 10);

let token = null;
async function api(method, path, body) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${text}`);
  return text ? JSON.parse(text) : null;
}

// ---- Static demo content ----

const GRINDERS = [
  { name: 'ZP6 Special', notes: '1Zpresso hand grinder, filter', purchased_at: '2025-01-09' },
  { name: 'Eureka Mignon Specialita', notes: 'Espresso', purchased_at: '2024-11-02' },
];

const BREWERS = [
  { key: 'v60', name: 'Hario V60 02', brew_method: 'filter', brew_type: 'v60', brand: 'Hario', model: 'V60 02 Glass', purchased_at: '2023-05-14' },
  { key: 'aeropress', name: 'Aeropress', brew_method: 'immersion', brew_type: 'aeropress', brand: 'Aeropress', model: 'Original', purchased_at: '2022-12-24' },
  { key: 'espresso', name: 'Lelit MaraX V2', brew_method: 'espresso', brew_type: 'espresso', brand: 'Lelit', model: 'MaraX V2', purchased_at: '2024-11-02' },
];

const V60_STEPS = [
  { name: 'Bloom', duration_secs: 45, water_ml: 50 },
  { name: 'Pour 1', duration_secs: 30, water_ml: 100 },
  { name: 'Pour 2', duration_secs: 30, water_ml: 100 },
];

const RECIPES = [
  { key: 'v60', name: 'Morning V60', brew_type: 'v60', coffee_grams: 15, water_grams: 250, water_temp_c: 93, brew_time_secs: 190, steps: V60_STEPS, notes: 'Bloom + 2 pours, gentle swirl after each', is_default: true },
  { key: 'espresso', name: 'Espresso 1:2', brew_type: 'espresso', coffee_grams: 18, water_grams: 36, water_temp_c: 93, brew_time_secs: 28, notes: 'Aim for 26–30 s' },
  { key: 'aeropress', name: 'Aeropress inverted', brew_type: 'aeropress', coffee_grams: 14, water_grams: 200, water_temp_c: 85, brew_time_secs: 120, notes: 'Steep 1:30, flip, press 30 s' },
];

// days: brewing window (days ago, from → to). opt: grind/temp that give the best cup.
const BAGS = [
  { roaster: 'Morgon Coffee Roasters', roaster_origin_city: 'Gothenburg', origin_country: 'Ethiopia', origin_region: 'Yirgacheffe', process: 'Washed', variety: 'Heirloom', roast_level: 'Light', taste_notes: ['blueberry', 'jasmine', 'bergamot'], roastAgo: 98, days: [88, 72], status: 'finished', rating: 'excellent', favorite: true, method: 'filter', optGrind: 4.5, optTemp: 93 },
  { roaster: 'Drop Coffee', roaster_origin_city: 'Stockholm', origin_country: 'Kenya', origin_region: 'Nyeri', process: 'Washed', variety: 'SL28', roast_level: 'Light', taste_notes: ['blackcurrant', 'grapefruit', 'cane sugar'], roastAgo: 80, days: [71, 59], status: 'finished', rating: 'good', method: 'filter', optGrind: 4.2, optTemp: 94 },
  { roaster: 'Da Matteo', roaster_origin_city: 'Gothenburg', origin_country: 'Colombia', origin_region: 'Huila', process: 'Washed', variety: 'Caturra', roast_level: 'Medium', taste_notes: ['caramel', 'red apple', 'milk chocolate'], roastAgo: 66, days: [58, 46], status: 'finished', rating: 'good', method: 'filter', optGrind: 4.8, optTemp: 91 },
  { roaster: "Muttley & Jack's", roaster_origin_city: 'Vaxholm', origin_country: 'Kenya', origin_region: 'Kirinyaga', process: 'Washed', variety: 'SL28, SL34', roast_level: 'Light', taste_notes: ['blackberry', 'hibiscus', 'lime'], roastAgo: 52, days: [45, 31], status: 'finished', rating: 'excellent', favorite: true, method: 'filter', optGrind: 4.3, optTemp: 94 },
  { roaster: 'Standout Coffee', roaster_origin_city: 'Stockholm', origin_country: 'Ethiopia', origin_region: 'Guji', process: 'Natural', variety: 'Heirloom', roast_level: 'Light', taste_notes: ['strawberry', 'dark chocolate', 'red wine'], roastAgo: 36, days: [30, 16], status: 'finished', rating: 'good', method: 'filter', optGrind: 4.7, optTemp: 92 },
  { roaster: 'Kafferäven', roaster_origin_city: 'Gothenburg', origin_country: 'Brazil', origin_region: 'Cerrado', process: 'Natural', variety: 'Yellow Bourbon', roast_level: 'Medium-dark', taste_notes: ['hazelnut', 'cocoa', 'brown sugar'], roastAgo: 26, days: [22, 1], status: 'opened', rating: 'ok', method: 'espresso', optGrind: 8, optTemp: 93 },
  { roaster: 'Johan & Nyström', roaster_origin_city: 'Tullinge', origin_country: 'Rwanda', origin_region: 'Nyamasheke', process: 'Washed', variety: 'Red Bourbon', roast_level: 'Light', taste_notes: ['red currant', 'black tea', 'orange'], roastAgo: 19, days: [14, 0], status: 'opened', method: 'filter', optGrind: 4.4, optTemp: 93 },
  { roaster: 'Gringo Nordic', roaster_origin_city: 'Gothenburg', origin_country: 'Panama', origin_region: 'Boquete', process: 'Washed', variety: 'Gesha', roast_level: 'Light', taste_notes: ['jasmine', 'peach', 'honey'], roastAgo: 4, days: null, status: 'unopened', method: 'filter' },
];

const REVIEWS = {
  excellent: ['Super clean and sweet, everything in balance.', 'Clear {0} and {1}. Best cup of this bag so far.', 'Juicy and bright, long finish.'],
  good: ['Nice {0}, slightly muted acidity.', 'Sweet and balanced, could be a touch brighter.', 'Good body, {0} comes through as it cools.'],
  ok: ['A bit flat. {0} hard to find.', 'Drinkable but lacks clarity.', 'Some astringency in the finish.'],
  'so-so': ['Sour and thin, under-extracted.', 'Bitter finish, probably too fine.'],
  bad: ['Choked the filter, very bitter.', 'Way off, sour and hollow.'],
};

function ratingFromScore(score) {
  if (score >= 4.3) return 'excellent';
  if (score >= 3.5) return 'good';
  if (score >= 2.7) return 'ok';
  if (score >= 2.0) return 'so-so';
  return 'bad';
}

// Coffee tastes best roughly 8–25 days after roast
function restPenalty(daysSinceRoast) {
  if (daysSinceRoast < 7) return (7 - daysSinceRoast) * 0.15;
  if (daysSinceRoast > 35) return (daysSinceRoast - 35) * 0.03;
  return 0;
}

function review(rating, notes) {
  return pick(REVIEWS[rating]).replace('{0}', notes[0]).replace('{1}', notes[1] ?? notes[0]);
}

// ---- Seeding ----

function databaseUrl() {
  if (process.env.DATABASE_URL) return process.env.DATABASE_URL;
  try {
    const env = readFileSync(new URL('../.env', import.meta.url), 'utf8');
    return env.match(/^DATABASE_URL=(.*)$/m)?.[1]?.trim();
  } catch {
    return undefined;
  }
}

// Demo roaster account for the fictional Nordlys Kafferosteri
async function seedRoaster() {
  try {
    await api('POST', '/auth/register', ROASTER);
  } catch {
    // already exists
  }
  const url = databaseUrl();
  if (!url) {
    console.log('No DATABASE_URL: roaster account created but not granted the roaster role.');
    return;
  }
  execFileSync('psql', [url, '-qc',
    `UPDATE users SET role = 'roaster', roaster_name = 'Nordlys Kafferosteri' WHERE username = '${ROASTER.username}';`]);
  console.log(`Roaster account: ${ROASTER.username} / ${ROASTER.password}`);
}

async function main() {
  await seedRoaster();

  try {
    await api('POST', '/auth/register', { ...USER, display_name: 'Demo Brewer' });
    console.log('Registered user demo');
  } catch {
    console.log('User demo already exists');
  }
  token = (await api('POST', '/auth/login', USER)).token;

  if ((await api('GET', '/bags')).length > 0) {
    console.log('Demo user already has bags, nothing to do.');
    return;
  }

  const grinders = [];
  for (const g of GRINDERS) grinders.push(await api('POST', '/grinders', g));
  await api('POST', `/grinders/${grinders[0].id}/maintenance`, { action: 'cleaned' });

  const brewers = {};
  for (const { key, ...b } of BREWERS) brewers[key] = await api('POST', '/brewers', b);
  await api('POST', `/brewers/${brewers.espresso.id}/maintenance`, { action: 'cleaned' });

  const recipes = {};
  for (const { key, ...r } of RECIPES) recipes[key] = await api('POST', '/recipes', r);

  let brewCount = 0;
  for (const b of BAGS) {
    const bag = await api('POST', '/bags', {
      roaster: b.roaster,
      roaster_origin_city: b.roaster_origin_city,
      roaster_origin_country: 'Sweden',
      origin_country: b.origin_country,
      origin_region: b.origin_region,
      roast_level: b.roast_level,
      variety: b.variety,
      process: b.process,
      taste_notes: b.taste_notes,
      roast_date: isoDate(b.roastAgo),
      status: b.status,
      rating: b.rating ?? null,
      favorite: b.favorite ?? false,
      buy_url: null,
    });
    if (!b.days) continue;

    // Brew roughly every day (sometimes twice) through the bag's window, oldest first,
    // so brew numbers (…-B001, -B002) follow the timeline.
    const [from, to] = b.days;
    for (let d = from; d >= to; d -= rand() < 0.25 ? 2 : 1) {
      const when = new Date(Date.now() - d * DAY);
      when.setHours(7 + Math.floor(rand() * 3), Math.floor(rand() * 60), 0, 0);
      if (when > new Date()) when.setTime(Date.now() - 60 * 60 * 1000);
      const progress = (from - d) / Math.max(1, from - to); // 0 → 1, dialing in over time
      const daysSinceRoast = b.roastAgo - d;

      let body;
      if (b.method === 'espresso') {
        const grind = round1(b.optGrind + (rand() - 0.5) * 2 * (1 - progress * 0.7));
        const time = Math.round(28 + (b.optGrind - grind) * 4 + (rand() - 0.5) * 3);
        const score = 4.6 - Math.abs(time - 28) * 0.25 - restPenalty(daysSinceRoast) + (rand() - 0.5) * 0.6;
        const rating = ratingFromScore(score);
        body = {
          grinder_id: grinders[1].id, grind_setting: String(grind),
          brewer_id: brewers.espresso.id, recipe_id: recipes.espresso.id,
          coffee_grams: 18, water_grams: round1(36 + (rand() - 0.5) * 4),
          water_temp_c: 93, brew_time_secs: time, rating,
          review: review(rating, b.taste_notes),
        };
      } else {
        const useAeropress = d > to + 2 && rand() < 0.15;
        // Start a bit off the sweet spot and converge as the bag gets dialed in
        const grind = round1(b.optGrind + (rand() < 0.5 ? -1 : 1) * (0.5 - progress * 0.4) + (rand() - 0.5) * 0.2);
        const temp = useAeropress ? 85 : Math.round(b.optTemp + (rand() - 0.5) * 4 * (1 - progress * 0.6));
        const score = 4.7
          - Math.abs(grind - b.optGrind) * 2.8
          - (useAeropress ? 0.3 : Math.abs(temp - b.optTemp) * 0.35)
          - restPenalty(daysSinceRoast)
          + (rand() - 0.5) * 0.5;
        const rating = ratingFromScore(score);
        const recipe = useAeropress ? recipes.aeropress : recipes.v60;
        body = {
          grinder_id: grinders[0].id, grind_setting: String(grind),
          brewer_id: useAeropress ? brewers.aeropress.id : brewers.v60.id,
          recipe_id: recipe.id,
          filter_paper: useAeropress ? 'Aeropress paper' : pick(['Cafec Abaca', 'Hario Tabbed']),
          coffee_grams: recipe.coffee_grams, water_grams: recipe.water_grams, water_temp_c: temp,
          brew_time_secs: Math.round(recipe.brew_time_secs + (b.optGrind - grind) * 40 + (rand() - 0.5) * 20),
          brew_steps: useAeropress ? null : V60_STEPS,
          rating, review: review(rating, b.taste_notes),
        };
      }

      await api('POST', '/brews', { ...body, coffee_bag_id: bag.id, brew_datetime: when.toISOString() });
      brewCount++;
    }
  }

  console.log(`Seeded ${GRINDERS.length} grinders, ${BREWERS.length} brewers, ${RECIPES.length} recipes, ${BAGS.length} bags, ${brewCount} brews.`);
  console.log('Log in with demo / demo1234');
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
