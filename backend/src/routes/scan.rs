//   POST /bags/scan - read a photo of a coffee bag and return the label as bag fields
//
// Sends the image to the Claude API and asks for JSON matching CreateCoffeeBag.
// Without ANTHROPIC_API_KEY (or if the call fails) it returns example values with
// "demo": true, so the app's scan flow always works in a demo.

use axum::{
    Router, Json,
    extract::{DefaultBodyLimit, State},
    routing::post,
};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sqlx::PgPool;
use tracing::warn;

use crate::auth::AuthUser;
use crate::error::{AppError, Result};

const CLAUDE_URL: &str = "https://api.anthropic.com/v1/messages";
const CLAUDE_MODEL: &str = "claude-opus-5-5";

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/bags/scan", post(scan_bag))
        .layer(DefaultBodyLimit::max(12 * 1024 * 1024)) // photos are bigger than the 2 MB default
}

#[derive(Debug, Deserialize)]
pub struct ScanRequest {
    pub image_base64: String,
    pub media_type: String, // image/jpeg | image/png | image/webp
}

#[derive(Debug, Serialize)]
pub struct ScanResponse {
    pub fields: Value, // CreateCoffeeBag-shaped object, unknown fields are null
    pub demo: bool,    // true = example values, not read from the photo
}

// Bag fields we ask Claude to read from the label
const FIELDS: [&str; 11] = [
    "roaster", "roaster_origin_city", "roaster_origin_country",
    "origin_country", "origin_region", "roast_level", "variety",
    "process", "roast_date", "harvest_date", "batch_id",
];

// POST /bags/scan
async fn scan_bag(
    State(_pool): State<PgPool>,
    _auth: AuthUser,
    Json(body): Json<ScanRequest>,
) -> Result<Json<ScanResponse>> {
    if !matches!(body.media_type.as_str(), "image/jpeg" | "image/png" | "image/webp" | "image/gif") {
        return Err(AppError::BadRequest(format!("Unsupported image type '{}'", body.media_type)));
    }

    let api_key = match std::env::var("ANTHROPIC_API_KEY") {
        Ok(k) if !k.is_empty() => k,
        _ => return Ok(Json(ScanResponse { fields: demo_fields(), demo: true })),
    };

    match read_label(&api_key, &body).await {
        Ok(fields) => Ok(Json(ScanResponse { fields, demo: false })),
        Err(e) => {
            warn!("Bag scan failed, returning demo values: {e}");
            Ok(Json(ScanResponse { fields: demo_fields(), demo: true }))
        }
    }
}

// JSON schema for the structured output: every field is a string or null
fn output_schema() -> Value {
    let mut props = serde_json::Map::new();
    for f in FIELDS {
        props.insert(f.into(), json!({ "type": ["string", "null"] }));
    }
    props.insert("taste_notes".into(), json!({ "type": "array", "items": { "type": "string" } }));
    let mut required: Vec<&str> = FIELDS.to_vec();
    required.push("taste_notes");
    json!({
        "type": "object",
        "properties": props,
        "required": required,
        "additionalProperties": false
    })
}

async fn read_label(api_key: &str, body: &ScanRequest) -> anyhow::Result<Value> {
    let prompt = "This is a photo of a specialty coffee bag. Read the label and fill in the fields. \
        Use English names for countries and processes (e.g. \"Ethiopia\", \"Washed\", \"Natural\"). \
        roast_level is one of Light, Medium-light, Medium, Medium-dark, Dark if stated or clearly implied. \
        Dates as YYYY-MM-DD; if only a month is given use the first of that month. \
        taste_notes are the flavour notes printed on the bag, lowercase. \
        Use null for anything that is not on the label - do not guess.";

    let request = json!({
        "model": CLAUDE_MODEL,
        "max_tokens": 16000,
        "fallbacks": "default",
        "output_config": {
            "effort": "low",
            "format": { "type": "json_schema", "schema": output_schema() }
        },
        "messages": [{
            "role": "user",
            "content": [
                { "type": "image", "source": {
                    "type": "base64", "media_type": body.media_type, "data": body.image_base64 } },
                { "type": "text", "text": prompt }
            ]
        }]
    });

    let response: Value = reqwest::Client::new()
        .post(CLAUDE_URL)
        .header("x-api-key", api_key)
        .header("anthropic-version", "2023-06-01")
        .header("anthropic-beta", "server-side-fallback-2026-07-01")
        .timeout(std::time::Duration::from_secs(90))
        .json(&request)
        .send()
        .await?
        .error_for_status()?
        .json()
        .await?;

    if response["stop_reason"] == "refusal" {
        anyhow::bail!("model declined the request");
    }

    // The JSON answer is in the text block (thinking blocks may come before it)
    let text: &str = response["content"]
        .as_array()
        .and_then(|blocks| blocks.iter().find(|b| b["type"] == "text"))
        .and_then(|b| b["text"].as_str())
        .ok_or_else(|| anyhow::anyhow!("no text block in response"))?;

    Ok(serde_json::from_str(text)?)
}

// Example label used when no API key is configured
fn demo_fields() -> Value {
    json!({
        "roaster": "Morgon Coffee Roasters",
        "roaster_origin_city": "Gothenburg",
        "roaster_origin_country": "Sweden",
        "origin_country": "Ethiopia",
        "origin_region": "Yirgacheffe",
        "roast_level": "Light",
        "variety": "Heirloom",
        "process": "Washed",
        "roast_date": chrono::Utc::now().date_naive().pred_opt().map(|d| d.to_string()),
        "harvest_date": null,
        "batch_id": null,
        "taste_notes": ["blueberry", "jasmine", "bergamot"]
    })
}
