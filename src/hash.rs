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


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bag_hashes() {
        assert_eq!(make_bag_hash(Some("Morgon Coffee Roasters"), 42), "MCR-0042");
    }
}


