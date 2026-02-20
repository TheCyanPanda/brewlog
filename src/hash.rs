// This file contains hash functions
use sqlx::PgPool;
use crate::error::Result;

// Generate a bag hash from roaster name and bag ID
// e.g "Morgon Coffee Roasters", 24 -> "MCR-0024"
pub fn make_bag_hash(roaster: Option<&str>, bag_id: i32) -> String {
    let code: String = roaster_code(roaster);
    format!("{}-{:04}", code, bag_id)
}

// Use three letters if single word, else take the first letter from each word in the roaster
// name, eg: "HEART" -> "HRT". "Morgon Coffee Roasters" -> "MCR", "Tim Wendelboe" -> "TW".
// Returns "XYZ" if the input string is empty
fn roaster_code(roaster: Option<&str>) -> String {
    let name = match roaster {
        Some(n) if !n.is_empty() => n,
        _ => return "XYZ".to_string(),
    };

    let words: Vec<&str> = name.split_whitespace().collect();
    let code = if words.len() == 1 {
        let upper: String = words[0].chars()
            .filter(|c: &char| c.is_alphanumeric())
            .take(4)
            .collect::<String>()
            .to_uppercase();
        upper
    } else {
        words.iter()
            .filter_map(|w: &&str| w.chars().next())
            .take(4)
            .collect::<String>()
            .to_uppercase()
    };

    if code.is_empty() { "XYZ".to_string() } else { code }
}


// Generate a brew hash from a bag has + brew number
// eg "MCR-0042", 3 -> "MCR-0042-B003"
pub fn make_brew_hash(bag_hash: &str, brew_number: i64) -> String {
    format!("{}-B{:03}", bag_hash, brew_number)
}


// Count existing brews for a bag and return the next brew number
pub async fn next_brew_number(pool: &PgPool, coffee_bag_id: i32) -> Result<i64> {
    let count: i64 = sqlx::query_scalar!(
        "SELECT COUNT(*) FROM brews WHERE coffee_bag_id = $1",
        coffee_bag_id
    )
    .fetch_one(pool)
    .await?
    .unwrap_or(0);

    Ok(count + 1)
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bag_hashes() {
        assert_eq!(make_bag_hash(Some("Morgon Coffee Roasters"), 42), "MCR-0042");
    }
}


