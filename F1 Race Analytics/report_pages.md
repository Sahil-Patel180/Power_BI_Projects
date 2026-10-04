# Report pages

Eight pages. Every page carries the same left rail: **Season** slicer (`dim_season[season_year]`, dropdown, single select, default latest completed season) and an **Era** slicer (`dim_season[era]`). Card titles use `[Selected Season]` / `[Selected Race]` so the page says what it shows.

Canvas: 16:9, 1280 × 720. Theme: `theme_f1.json` (View > Themes > Browse for themes).

---

## 1. Season Overview

**Question it answers:** who won the season and how the title fight unfolded.

| Visual | Fields |
| --- | --- |
| Card | `[Champion]`, title from `[Champion Label]` |
| Cards (row of 4) | `[Races Held]`, `[Winners]`, `[Drivers]`, `[Constructors]` |
| Line chart: championship battle | X `dim_race[round]`, Y `[Championship Points]`, Legend `dim_driver[driver_code]`; visual filter: Top N 5 drivers by `[Championship Points]` |
| Bar chart: wins by driver | Y `dim_driver[full_name]`, X `[Wins]`, sort descending, Top N 10 |
| Bar chart: constructors' points | Y `dim_constructor[constructor_name]`, X `[Constructor Championship Points]` |
| Table: race winners | `dim_race[round]`, `dim_race[race_name]`, `dim_driver[full_name]`, `dim_constructor[constructor_name]`; visual filter `fact_results[is_win] = 1`, `fact_results[session_type] = Race` |

## 2. Driver Profile

Add a **Driver** slicer (`dim_driver[full_name]`, searchable, single select). Season slicer optional here: cleared = career view.

| Visual | Fields |
| --- | --- |
| Cards | `[Race Starts]`, `[Wins]`, `[Podiums]`, `[Poles]`, `[Points]`, `[Titles]` |
| Cards (rates) | `[Win Rate]`, `[Podium Rate]`, `[DNF Rate]`, format % |
| Column chart: results by season | X `dim_season[season_year]`, Y `[Points]`; secondary line `[Championship Position]` (invert axis) |
| Column chart: finish distribution | X `fact_results[finish_position]` (Race only), Y `[Race Entries]` |
| Donut: retirement reasons | Legend `dim_status[status_group]`, Values `[DNFs]`; filter status_group not in Finished, Lapped |
| Text box / card: season summary | `[Driver Season Summary]` (LLM) |

## 3. Constructor Profile

Add a **Constructor** slicer (`dim_constructor[constructor_name]`).

| Visual | Fields |
| --- | --- |
| Cards | `[Wins]`, `[Podiums]`, `[Points]`, `[Constructor Championship Position]` |
| Line chart: points per season | X `dim_season[season_year]`, Y `[Constructor Championship Points]` |
| Stacked bar: reliability | Y `dim_season[season_year]`, X `[Race Entries]`, Legend `dim_status[status_group]` |
| Bar: driver contribution | Y `dim_driver[full_name]`, X `[Points]` |
| Card: pit crew | `[Avg Pit Stop (s)]`, `[Fastest Pit Stop (s)]` |

## 4. Race Detail

Add a **Race** slicer (`dim_race[race_label]`, single select). Enable drill-through to this page on `dim_race[race_label]` from pages 1 and 6.

| Visual | Fields |
| --- | --- |
| Title card | `[Selected Race]`, subtitle `dim_circuit[circuit_name]`, `dim_race[race_date]` |
| Table: classification | `fact_results[position_order]`, `dim_driver[full_name]`, `dim_constructor[constructor_name]`, `[Grid]`, `[Result]`, `[Points]`, `[Positions Gained]`, `dim_status[status]`; filter session_type = Race; conditional icons on Positions Gained |
| Line chart: lap chart | X `fact_lap_times[lap]`, Y `[Lap Position]` (invert axis), Legend `dim_driver[driver_code]` |
| Scatter: grid vs finish | X `[Grid]`, Y `fact_results[finish_position]`, Details `dim_driver[driver_code]` |
| Bar: pit stops | Y `dim_driver[driver_code]`, X `[Pit Stops]`, tooltip `[Avg Pit Stop (s)]` |
| Card: recap | `[Race Recap]`, footer `[Narrative Source]` |

## 5. Circuits

| Visual | Fields |
| --- | --- |
| Map | Latitude `dim_circuit[latitude]`, Longitude `dim_circuit[longitude]`, Size `[Races Held]`, Tooltip `dim_circuit[circuit_name]`, `[Avg Positions Gained]` |
| Table | `dim_circuit[circuit_name]`, `dim_circuit[country]`, `[Races Held]`, `[Avg Positions Gained]`, `[Stops per Driver]`, `[Best Lap]` |
| Bar: overtaking | Y `dim_circuit[circuit_name]`, X `[Avg Positions Gained]`, Top N 15 |

## 6. Predictions vs Actual

Season slicer limited to seasons with predictions (2023 onward). Race slicer optional.

| Visual | Fields |
| --- | --- |
| Cards | `[Top-3 Pick Hit Rate]` (format %), `[Podium Probability]` |
| Matrix: race × driver | Rows `dim_race[race_label]`, `dim_driver[full_name]`; values `[Podium Probability]` (data bars), `[Result]`, `[DNF Risk]`, `[Predicted Finish Rank]`; filter `[Podium Probability]` is not blank |
| Scatter: calibration | X `[Podium Probability]`, Y `[Podium Rate]`, Details `dim_driver[driver_code]` |
| Card: explanation | `[Prediction Explanation]` (driver + race selected) |

## 7. Model Performance

No season slicer.

| Visual | Fields |
| --- | --- |
| Card | `[Models Beating Baseline]` |
| Table | `ml_model_metrics[model_name]`, `[metric]`, `[model_value]`, `[baseline_value]`, `[beats_baseline]` (conditional formatting: green true, red false) |
| Slicer | `narr_model[model_name]` (filters the metrics through relationship 30) |
| Clustered bar | Y `ml_model_metrics[metric]`, X `model_value` vs `baseline_value` |
| Card | `narr_model[narrative_text]` |

## 8. About

Text: data source (Kaggle Formula 1 Race Data, Ergast format), the architecture (warehouse → ML → LLM → Power BI), refresh date, links to the `SQL_Projects` and `f1-analytics-ml` repos.
