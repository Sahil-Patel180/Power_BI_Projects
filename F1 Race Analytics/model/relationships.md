# Relationships

Create these in **Model view** (drag the column from the "one" side to the "many" side, or Manage relationships > New). All are **one-to-many, single direction** (dimension filters fact), **active**. Turn off "Autodetect new relationships" first (File > Options > Current file > Data load) so Power BI does not guess.

| # | From (one side) | To (many side) |
| --- | --- | --- |
| 1 | `dim_season[season_year]` | `dim_race[season_year]` |
| 2 | `dim_season[season_year]` | `agg_driver_season[season_year]` |
| 3 | `dim_season[season_year]` | `narr_driver_season[season_year]` |
| 4 | `dim_circuit[circuit_id]` | `dim_race[circuit_id]` |
| 5 | `dim_date[date_key]` | `dim_race[race_date_key]` |
| 6 | `dim_race[race_id]` | `fact_results[race_id]` |
| 7 | `dim_race[race_id]` | `fact_qualifying[race_id]` |
| 8 | `dim_race[race_id]` | `fact_lap_times[race_id]` |
| 9 | `dim_race[race_id]` | `fact_pit_stops[race_id]` |
| 10 | `dim_race[race_id]` | `fact_driver_standings[race_id]` |
| 11 | `dim_race[race_id]` | `fact_constructor_standings[race_id]` |
| 12 | `dim_race[race_id]` | `fact_constructor_results[race_id]` |
| 13 | `dim_race[race_id]` | `ml_predictions[race_id]` |
| 14 | `dim_race[race_id]` | `narr_race[race_id]` |
| 15 | `dim_driver[driver_id]` | `fact_results[driver_id]` |
| 16 | `dim_driver[driver_id]` | `fact_qualifying[driver_id]` |
| 17 | `dim_driver[driver_id]` | `fact_lap_times[driver_id]` |
| 18 | `dim_driver[driver_id]` | `fact_pit_stops[driver_id]` |
| 19 | `dim_driver[driver_id]` | `fact_driver_standings[driver_id]` |
| 20 | `dim_driver[driver_id]` | `agg_driver_season[driver_id]` |
| 21 | `dim_driver[driver_id]` | `ml_predictions[driver_id]` |
| 22 | `dim_driver[driver_id]` | `narr_race[driver_id]` |
| 23 | `dim_driver[driver_id]` | `narr_driver_season[driver_id]` |
| 24 | `dim_constructor[constructor_id]` | `fact_results[constructor_id]` |
| 25 | `dim_constructor[constructor_id]` | `fact_qualifying[constructor_id]` |
| 26 | `dim_constructor[constructor_id]` | `fact_pit_stops[constructor_id]` |
| 27 | `dim_constructor[constructor_id]` | `fact_constructor_standings[constructor_id]` |
| 28 | `dim_constructor[constructor_id]` | `fact_constructor_results[constructor_id]` |
| 29 | `dim_status[status_id]` | `fact_results[status_id]` |
| 30 | `narr_model[model_name]` | `ml_model_metrics[model_name]` |

`narr_model` has one row per model (latest report), so it works as the model dimension: a slicer on `narr_model[model_name]` filters the metrics table too. Neither table relates to races.

## Why `dim_season` exists

A season slicer on `dim_race[season_year]` cannot reach tables that have a season but no race (`agg_driver_season`, `narr_driver_season`). `dim_season` sits above both paths, so one slicer filters everything without creating an ambiguous loop.

## Model settings

| Setting | Where | Value |
| --- | --- | --- |
| Hide key columns | Model view, right-click | Hide every `*_id` and `*_key` column on fact tables (keep them on dimensions for drill-through) |
| Sort `dim_race[race_label]` | Column tools > Sort by column | `race_date_key` |
| Sort `dim_date[month_name]` | Column tools > Sort by column | `month` |
| Mark as date table | Table tools on `dim_date` | Date column: `date` |
| Data category | Column tools | `dim_circuit[latitude]` = Latitude, `dim_circuit[longitude]` = Longitude, `dim_circuit[country]` = Country |
| Summarization | Column tools | Set `season_year`, `round`, positions and all `is_*` flags to **Don't summarize**; use the measures instead |
| Measures table | Home > Enter data | An empty table named `_Measures`; measures from `measures.dax` go there |
