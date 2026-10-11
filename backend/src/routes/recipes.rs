//   GET    /recipes      - list recipes (default first)
//   POST   /recipes      - save a recipe
//   DELETE /recipes/:id  - delete a recipe

use axum::{
    Router, Json,
    extract::{Path, State},
    routing::{delete, get},
};
use sqlx::PgPool;

use crate::{
    error::{AppError, Result},
    models::{CreateRecipe, Recipe},
};
use crate::auth::AuthUser;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/recipes", get(list_recipes).post(create_recipe))
        .route("/recipes/:id", delete(delete_recipe))
}

// GET /recipes
async fn list_recipes(
    State(pool): State<PgPool>,
    auth: AuthUser,
) -> Result<Json<Vec<Recipe>>> {
    let recipes = sqlx::query_as!(
        Recipe,
        r#"SELECT * FROM recipes
        WHERE user_id = $1
        ORDER BY is_default DESC, name"#,
        auth.user_id
    )
    .fetch_all(&pool)
    .await?;
    Ok(Json(recipes))
}

// POST /recipes
async fn create_recipe(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Json(body): Json<CreateRecipe>,
) -> Result<Json<Recipe>> {
    let is_default: bool = body.is_default.unwrap_or(false);

    // Only one default recipe per user
    if is_default {
        sqlx::query!("UPDATE recipes SET is_default = false WHERE user_id = $1", auth.user_id)
            .execute(&pool)
            .await?;
    }

    let recipe = sqlx::query_as!(
        Recipe,
        r#"INSERT INTO recipes
            (user_id, name, brew_type, coffee_grams, water_grams, water_temp_c,
             brew_time_secs, steps, notes, source, is_default)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING *"#,
        auth.user_id,
        body.name, body.brew_type, body.coffee_grams, body.water_grams, body.water_temp_c,
        body.brew_time_secs, body.steps, body.notes, body.source, is_default,
    )
    .fetch_one(&pool)
    .await?;
    Ok(Json(recipe))
}

// DELETE /recipes/:id
async fn delete_recipe(
    State(pool): State<PgPool>,
    auth: AuthUser,
    Path(id): Path<i32>,
) -> Result<Json<serde_json::Value>> {
    let result: sqlx::postgres::PgQueryResult = sqlx::query!(
        "DELETE FROM recipes WHERE id = $2 AND user_id = $1",
        auth.user_id, id
    )
    .execute(&pool)
    .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound(format!("Recipe {} not found", id)));
    }

    Ok(Json(serde_json::json!({ "deleted": id })))
}
