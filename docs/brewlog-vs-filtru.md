# Brewlog vs Filtru

*Research date: 11 Oct 2026. Filtru facts come from its website, App Store listings and its roaster page (see Sources). Where we couldn't verify something, the table says so.*

## Summary

Filtru (Spirograph Ltd, since 2016) is a mature **brew-guide app** for iPhone and iPad. Its core is guided timers, AR equipment guides and recipes from barista champions. It connects to 14+ Bluetooth scales and has an espresso shot tracker. Around that it has a coffee journal, a bean library with bag scanning (added July 2026, runs on the phone), community recipes, and a roaster programme with brand pages and Shopify ordering. In short, Filtru is excellent at **helping you brew the next cup by following a guide**.

Brewlog's angle is different. It **remembers what made each cup good and learns from it**:
- logging that takes seconds
- analytics built around each bag, and suggestions based on how you rated your own cups
- a Strava-like social layer where every brew can be repeated
- a roaster product that sells privacy-safe insights into how coffees are actually brewed and rated at home

The two apps overlap in journal, bag scan and roaster pages. They differ in *what the app is for*.

## Feature comparison

Brewlog column: **✅ demo** = working in today's demo · **🧪 mock** = screen built, example data · **🗺 planned** = in the deck, not built.

| Area | Brewlog | Filtru |
|---|---|---|
| **Logging speed & UX** | ✅ demo: one screen pre-filled from your last brew of that bag (bag, brewer, grinder, recipe, grind, dose, temperature). Rate and save in about 2 taps. "Same as last" and "Brew again" buttons. Timer is not the main flow. | Built around guided step-by-step timers, plus Live Activities, widgets and Siri shortcuts. Journal entry per brew with beans, method, dose, grind, time, rating, notes and "what you'd change". Number of taps not verified. |
| **Bags / beans** | ✅ demo: bag status, favourites, the **bag's own rating** separate from each brew, best brew, rating vs **days since roast**, grind vs rating chart, "Buy again" link. | Bean library linked to each brew, with ratings and notes per bean, searchable. Roast date, freshness and stock tracking are not mentioned on the site. |
| **Equipment** | ✅ demo: grinders and brewers with purchase date, total brews, and cleaned/descaled reminders ("like Strava tracks your shoes"). | AR equipment guides. Whether it tracks your gear or maintenance: not found. |
| **Recipes** | ✅ demo: saved recipes with a default, used to pre-fill a brew. "Discover" list 🧪 mock. | ✅ Large library: 15+ methods, barista-champion recipes, community recipes, sharing. Clearly ahead. |
| **Insights & analytics** | ✅ demo: monthly stats, streak, grind-vs-rating and rest-day charts, brews per method, top-rated process and origin, **"Coffee year" summary**. | Brew graphs from a connected scale, a cup profile in SCA style, an Activity tab. Broader stats or charts: not mentioned. |
| **AI: bag photo scan** | ✅ demo: photo is read by Claude on the server and fills the form. Shows example values if no API key is set. | ✅ On the phone (AbolBuna scanning, v4.7, July 2026): reads roaster, origin, variety, process and notes. **They have this too.** |
| **AI: "what should I change?"** | ✅ demo (rules today): choose a goal (fruitiness, sweetness, body, less bitter) and get tweaks based on **your own higher-rated brews** of the bag, then "Try in next brew". 🗺 planned: ML trained on community data. | Not found. The journal has a free-text "what you'd change" field. |
| **AI: start point for a new bag** | ✅ demo: grind and temperature from your good brews of similar coffees (same process and roast). | Not found. |
| **AI: taste profile** | ✅ demo: "You like: light roast, washed, East Africa…" from your ratings. | Not found. Tasting notes and cup profile are kept per brew. |
| **Community** | 🧪 mock: Strava-style feed where each post links to grinder, recipe and settings so it can be repeated. Map of roasters, cafés and shops. Featured roaster page. | Community recipes, roaster pages and in-app ordering. A feed of people's brews or a map: not found. |
| **Roaster side** | 🧪 mock, with its own **roaster login**: per-coffee **insights panel** (average rating, best temperature, best days after roast, brew-method share, counted taste tags) shown only above a minimum number of users. 🗺 planned: Profile (free), Insights 299–499 kr/mo, Pro 990–1 490 kr/mo, Featured placements. | ✅ Live: brand page, Shopify integration (WooCommerce coming), branded brew guides, orders in the app, roaster pages searchable by origin, process, taste and so on. Mentions "consumption statistics" and "how well was your product received", but no details. |
| **Privacy & data ownership** | ✅ demo: open backend you can self-host, data scoped per user. 🗺 planned: works offline first, relay plus your own node, opt-in per brew, only aggregated and anonymised data reaches roasters. | Account optional. Data processed in the UK. Analytics can be turned off. Privacy policy last updated Aug 2019. Self-hosting: no. |
| **Hardware** | 🗺 planned (step 2): own scale (ESP32) that logs automatically and can act as your server. ✅ backend already has Home Assistant endpoints. | ✅ Supports 14+ scale brands (Acaia, Felicita, Decent, Timemore, …) with live weight and flow graphs. Clearly ahead. |
| **Platforms** | ✅ demo: installable web app (PWA) that works offline on any OS, including Android and desktop. A native Flutter build is possible. | iPhone, iPad and Vision Pro (iOS 18+). An Android version existed earlier; current Play Store status unverified. |
| **Business model** | 🗺 planned: free core and self-hosting; Plus at 39–49 kr/mo (AI, scan, advanced insights); roaster tiers; commission on buy-again. | Free download. Pro costs $3.49/mo, $32.99/yr or $79.99 lifetime, and brew-guide packs are $4.99 (US prices, Jul 2026). The journal, espresso dial-in and shot recording are Pro features. Roaster pricing not published. |

## Where Brewlog is unique

1. **It learns from how you rated your own cups.** Suggestions and new-bag start points come from *your* rated brews, not from generic guides. In the demo, the "Improve" screen cites the brews it is based on. Filtru records "what you'd change" as free text.
2. **The bag is the unit of memory.** Each bag has its own rating, a best-brew card and a curve of rating against days since roast. That answers "what did I do last time with this coffee?", which is the problem in the pitch deck.
3. **Roaster insights as a product, not just a shop window.** Filtru sells roasters reach and orders. Brewlog sells *knowledge*: how each coffee is brewed and how it tastes at home, from aggregated and anonymised data shown only above a minimum number of users. That is a separate revenue line and a reason for roasters to join.
4. **A social feed you can actually reproduce.** Every post carries grinder @ setting, recipe, ratio and temperature, the way Strava links a run to a pair of shoes. "Inspiration from others brewing the same origin" sits next to your own bag.
5. **Privacy by design, self-hosting allowed.** An open backend you can run at home, opt-in sharing per brew, and roasters never see individuals. This attracts the technical early-adopter crowd and lowers our GDPR exposure.
6. **Logging comes first, the timer is optional.** Most brews take about 2 taps because the last setup of that bag is pre-filled. That's the main reason people keep logging.
7. **Human-readable IDs.** `MCR-0042-B003` means roaster, bag 42, brew 3. It's easy to share and quote in a post.

## Where Filtru is ahead / risks

- **Maturity and distribution:** about 10 years on the market, press in TIME and Caffeine Magazine, a James Hoffmann video, 15 languages, and a polished native iOS app.
- **Brewing help:** guided timers, AR guides, champion recipes and espresso dial-in. Brewlog has no timer or guided-brew experience.
- **Scales:** 14+ brands with live flow graphs. Brewlog's hardware is still a plan.
- **Overlap is growing:** Filtru already has bag scanning (on the phone, so no AI cost per scan), a journal, community recipes and roaster pages. Our scan and roaster pages alone are **not** differentiators.
- **Roaster commerce is live:** Shopify ordering is already running. Our roaster side is a mockup, and the insights need opt-in data from enough users before they can be shown.
- **Our gaps today:** the community, map and roaster portal use example data. No native app, no timer, no scale. Suggestions are rules, not ML.

## Pitch lines

- *"Filtru helps you brew the next cup. Brewlog remembers why the last one was great, and tells you what to change."*
- *"Strava for coffee: every brew is tied to bag, grinder and recipe, so anyone can repeat it."*
- *"For roasters: not another shop window. Find out how your coffee is actually brewed and how it tastes at home."*
- *"Your data stays yours: self-host it, share one brew at a time, and roasters only ever see anonymised totals."*
- *"Log a brew in two taps; everything else is pre-filled from last time."*

## Sources

- Filtru website (features, platforms, scales, roaster section): https://getfiltru.com
- Filtru coffee journal page: https://getfiltru.com/coffee-journal-app/
- Filtru bean tracker page (bag scanning, beans linked to brews): https://getfiltru.com/coffee-bean-tracker/
- Filtru for Roasters (Shopify, brand pages, ordering, "consumption statistics"): https://business.filtru.coffee/
- Filtru privacy policy (UK processing, optional account, updated Aug 2019): https://getfiltru.com/privacy-policy/
- App Store listing, KR storefront (features, Pro list, scales, version history incl. v4.7.0 bag scanning 15 Jul, rating 4.6 / 89 ratings, privacy labels): https://apps.apple.com/KR/app/id1150921819
- App Store listing, US: https://apps.apple.com/us/app/1150921819
- In-app purchase prices (US, checked 17 Jul 2026): https://apppricinglab.com/iap/apple/1150921819
- Android history (earlier package `com.przemyslawbobak.filtrucoffee`): https://bluestacks.com/campaign/com.przemyslawbobak.filtrucoffee/tr and https://www.androidheadlines.com/best-coffee-android-apps.html
- Reviews and coverage: https://fueled.com/blog/app-of-the-week-filtru-coffee-timer-app, https://thespoon.tech/filtru-is-a-one-stop-app-for-coffee-obsessives-or-aspiring-obsessives/
