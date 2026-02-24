// Shared conversion helpers used across the codebase

pub fn compute_ratio(coffee_grams: Option<f64>, water_grams: Option<f64>) -> Option<f64> {
    match (coffee_grams, water_grams) {
        (Some(c), Some(w)) if c > 0.0 => Some((w / c * 10.0).round() / 10.0),
        _ => None,
    }
}

pub fn celsius_to_fahrenheit(temp_c: Option<f64>) -> Option<f64> {
    temp_c.map(|c: f64| c * 9.0 / 5.0 + 32.0)
}

pub fn format_brew_time(brew_time_secs: Option<i32>) -> Option<String> {
    brew_time_secs.map(|s: i32| format!("{:02}:{:02}", s / 60, s % 60))
}
