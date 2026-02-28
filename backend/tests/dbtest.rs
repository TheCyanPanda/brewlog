// TEST: wipes the DB, seeds dummy data, reads it back, asserts correctness.
// Data persists after the run so you can inspect the DB.
//
// Run:
//   cargo test --test dbtest -- --nocapture

use sqlx::postgres::PgPoolOptions;

#[tokio::test]
async fn db_round_trip() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    let db_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");

    let pool = PgPoolOptions::new()
        .max_connections(2)
        .connect(&db_url)
        .await?;

    sqlx::migrate!("./migrations").run(&pool).await?;

    // Wipe everything and reset all sequences. Truncating users cascades to all
    // other tables since they all reference users with ON DELETE CASCADE.
    println!("Truncating all tables...");
    sqlx::query!("TRUNCATE users RESTART IDENTITY CASCADE")
        .execute(&pool)
        .await?;

    // NOTE: Password hash is a placeholder — argon2id integration comes later.
    // Insert user in DB
    let user = sqlx::query!(
        r#"INSERT INTO users (username, display_name, email, password_hash)
           VALUES ($1, $2, $3, $4)
           RETURNING id, username, display_name"#,
        "chris",
        "Chris",
        "chris@example.com",
        "$argon2id$v=19$m=65536,t=3,p=4$placeholder-hash",
    )
    .fetch_one(&pool)
    .await?;
    println!(
        "  user       id={}  username={}  display_name={}",
        user.id,
        user.username,
        user.display_name.as_deref().unwrap_or(""),
    );

    // Insert grinder
    let grinder = sqlx::query!(
        r#"INSERT INTO grinders (user_id, name, notes)
           VALUES ($1, $2, $3)
           RETURNING id, name"#,
        user.id,
        "ZP6 Special",
        "stepless, usually between 4–5 for filter",
    )
    .fetch_one(&pool)
    .await?;
    println!(
        "  grinder    id={}  name={}",
        grinder.id, grinder.name,
    );

    // Insert brewer
    let brewer = sqlx::query!(
        r#"INSERT INTO brewers (user_id, name, brew_method, brew_type)
           VALUES ($1, $2, $3, $4)
           RETURNING id, name, brew_method"#,
        user.id,
        "Hario Glass V60",
        "filter",
        "v60",
    )
    .fetch_one(&pool)
    .await?;
    println!(
        "  brewer     id={}  name={}  method={}",
        brewer.id, brewer.name, brewer.brew_method,
    );

    // Insert a coffee bag
    let bag = sqlx::query!(
        r#"INSERT INTO coffee_bags
            (user_id, bag_hash, roaster, roaster_origin_city, roaster_origin_country,
             origin_country, origin_region, roast_level, process, taste_notes)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
           RETURNING id, bag_hash, roaster"#,
        user.id,
        "MCR-0001",
        "Morgon Coffee Roasters",
        "Gothenburg",
        "Sweden",
        "Ethiopia",
        "Yirgacheffe",
        "Light",
        "Washed",
        &["blueberry", "jasmine", "dark chocolate"] as &[&str],
    )
    .fetch_one(&pool)
    .await?;
    println!(
        "  coffee_bag id={}  hash={}  roaster={}",
        bag.id,
        bag.bag_hash.as_deref().unwrap_or(""),
        bag.roaster.as_deref().unwrap_or(""),
    );

    // Add a brew to the DB
    let brew = sqlx::query!(
        r#"INSERT INTO brews
            (user_id, brew_hash, coffee_bag_id,
             grinder_id, grind_setting, brewer_id, filter_paper,
             coffee_grams, water_grams, water_temp_c, brew_time_secs,
             rating, review, brew_steps)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
           RETURNING id, brew_hash"#,
        user.id,
        "MCR-0001-B001",
        bag.id,
        grinder.id,
        "4.5",
        brewer.id,
        "Cafec Abaca",
        15.0_f64,
        250.0_f64,
        94.0_f64,
        210_i32,
        "excellent",
        "Very floral and bright, clean finish",
        serde_json::json!([
            {"name": "Bloom",  "duration_secs": 45, "water_ml":  50, "notes": "Swirl gently"},
            {"name": "Pour 1", "duration_secs": 30, "water_ml": 100, "notes": ""},
            {"name": "Pour 2", "duration_secs": 30, "water_ml": 100, "notes": ""},
        ]),
    )
    .fetch_one(&pool)
    .await?;
    println!(
        "  brew       id={}  hash={}",
        brew.id,
        brew.brew_hash.as_deref().unwrap_or(""),
    );

    // Add another brew...
    let brew2 = sqlx::query!(
        r#"INSERT INTO brews
            (user_id, brew_hash, coffee_bag_id,
             grinder_id, grind_setting, brewer_id,
             coffee_grams, water_grams, water_temp_c, brew_time_secs,
             rating, review)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
           RETURNING id, brew_hash"#,
        user.id,
        "MCR-0001-B002",
        bag.id,
        grinder.id,
        "4.2",
        brewer.id,
        15.5_f64,
        250.0_f64,
        93.0_f64,
        205_i32,
        "good",
        "Finer grind, slightly more body",
    )
    .fetch_one(&pool)
    .await?;
    println!(
        "  brew       id={}  hash={}",
        brew2.id,
        brew2.brew_hash.as_deref().unwrap_or(""),
    );

    println!();

    // REad back from DB and check all values to make sure that it all works
    println!("Reading back...");

    let u = sqlx::query!(
        "SELECT id, username, email, is_admin FROM users WHERE id = $1",
        user.id
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(u.username, "chris");
    assert_eq!(u.email.as_deref(), Some("chris@example.com"));
    assert!(!u.is_admin);
    println!("  user       id={}  username={}  admin={}", u.id, u.username, u.is_admin);

    let g = sqlx::query!(
        "SELECT id, name, notes FROM grinders WHERE id = $1",
        grinder.id
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(g.name, "ZP6 Special");
    println!("  grinder    id={}  name={}  notes={}", g.id, g.name, g.notes.as_deref().unwrap_or(""));

    let b = sqlx::query!(
        "SELECT id, name, brew_method, brew_type FROM brewers WHERE id = $1",
        brewer.id
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(b.name, "Hario Glass V60");
    assert_eq!(b.brew_method, "filter");
    assert_eq!(b.brew_type.as_deref(), Some("v60"));
    println!("  brewer     id={}  name={}  method={}  type={}", b.id, b.name, b.brew_method, b.brew_type.as_deref().unwrap_or(""));

    let cb = sqlx::query!(
        r#"SELECT id, bag_hash, roaster, origin_country, origin_region,
                  roast_level, process, taste_notes
           FROM coffee_bags WHERE id = $1"#,
        bag.id
    )
    .fetch_one(&pool)
    .await?;
    assert_eq!(cb.bag_hash.as_deref(), Some("MCR-0001"));
    assert_eq!(cb.roaster.as_deref(), Some("Morgon Coffee Roasters"));
    assert_eq!(cb.origin_country.as_deref(), Some("Ethiopia"));
    assert_eq!(cb.roast_level.as_deref(), Some("Light"));
    assert_eq!(cb.process.as_deref(), Some("Washed"));
    println!(
        "  coffee_bag id={}  hash={}  roaster={}  origin={}, {}  process={}  notes={:?}",
        cb.id,
        cb.bag_hash.as_deref().unwrap_or(""),
        cb.roaster.as_deref().unwrap_or(""),
        cb.origin_country.as_deref().unwrap_or(""),
        cb.origin_region.as_deref().unwrap_or(""),
        cb.process.as_deref().unwrap_or(""),
        cb.taste_notes.as_deref().unwrap_or(&[]),
    );

    let brews = sqlx::query!(
        r#"SELECT id, brew_hash, coffee_bag_id, grinder_id, brewer_id,
                  coffee_grams, water_grams, water_temp_c, brew_time_secs,
                  rating, review, filter_paper
           FROM brews WHERE user_id = $1 ORDER BY id"#,
        user.id
    )
    .fetch_all(&pool)
    .await?;
    assert_eq!(brews.len(), 2);
    assert_eq!(brews[0].brew_hash.as_deref(), Some("MCR-0001-B001"));
    assert_eq!(brews[0].rating.as_deref(), Some("excellent"));
    assert_eq!(brews[1].brew_hash.as_deref(), Some("MCR-0001-B002"));
    assert_eq!(brews[1].rating.as_deref(), Some("good"));
    for r in &brews {
        println!(
            "  brew       id={}  hash={}  grind={}  coffee={:.1}g  water={:.1}g  temp={}°C  time={}s  rating={}",
            r.id,
            r.brew_hash.as_deref().unwrap_or(""),
            r.grinder_id.map_or("?".to_string(), |id| format!("grinder#{id}")),
            r.coffee_grams.unwrap_or(0.0),
            r.water_grams.unwrap_or(0.0),
            r.water_temp_c.unwrap_or(0.0),
            r.brew_time_secs.unwrap_or(0),
            r.rating.as_deref().unwrap_or(""),
        );
    }

    println!("\nAll checks passed.");
    Ok(())
}
