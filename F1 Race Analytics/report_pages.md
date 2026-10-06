# Report pages

Eight pages, 1280 × 720 canvas (16:9). Theme: `theme_f1.json` (View > Themes > Browse for themes). All measures live in `_Measures`.

---

## 0. Model prep (do once, before building pages)

### 0.1 Measure edits (only these four need changing / adding)

Career view (Season slicer cleared) breaks two position measures (they take the max round across *all* seasons) and the season summary (MAX picks an arbitrary text). Guard them:

```DAX
Championship Position =
IF (
    HASONEVALUE ( dim_season[season_year] ),
    VAR LastRound = CALCULATE ( MAX ( fact_driver_standings[round] ) )
    RETURN CALCULATE ( MIN ( fact_driver_standings[championship_position] ), fact_driver_standings[round] = LastRound )
)

Constructor Championship Position =
IF (
    HASONEVALUE ( dim_season[season_year] ),
    VAR LastRound = CALCULATE ( MAX ( fact_constructor_standings[round] ) )
    RETURN CALCULATE ( MIN ( fact_constructor_standings[championship_position] ), fact_constructor_standings[round] = LastRound )
)

Driver Season Summary =
IF (
    HASONEVALUE ( dim_season[season_year] ) && HASONEVALUE ( dim_driver[driver_id] ),
    MAX ( narr_driver_season[narrative_text] ),
    "Pick one season to read the summary."
)
```

New measure for page 7 conditional formatting (a boolean column cannot drive a colour rule directly):

```DAX
Beats Baseline Color =
VAR b = SELECTEDVALUE ( ml_model_metrics[beats_baseline] )
RETURN SWITCH ( TRUE (), ISBLANK ( b ), BLANK (), b, "#229971", "#E10600" )
```

### 0.2 Format strings + display folders

All measures currently have an empty format → rates show as `0.3333`. Run `format_measures.csx` in Tabular Editor (External tools > Tabular Editor > C# Script > Run > Ctrl+S), or set by hand: Model view > Data pane > Ctrl-click measures > Properties > Format.

| Format | Measures |
| --- | --- |
| `#,0` | Race Entries, Race Starts, Wins, Podiums, DNFs, Points Finishes, Fastest Laps, Sprint Wins, Races Held, Drivers, Constructors, Winners, Poles, Titles, Pit Stops, Best Finish, Grid, Championship Position, Constructor Championship Position, Predicted Finish Rank, Models Beating Baseline |
| `#,0.##` | Points, Race Points, Sprint Points, Championship Points, Constructor Championship Points, Champion Points |
| `0.0%` | Win Rate, Podium Rate, DNF Rate, Q3 Rate, Podium Probability, DNF Risk, Top-3 Pick Hit Rate |
| `0.00` | Points per Start, Avg Finish, Avg Grid, Avg Positions Gained, Avg Quali Position, Stops per Driver, Predicted Finish Score, Avg Pit Stop (s), Fastest Pit Stop (s), Predicted Pit Stop (s) |
| `0.000` | Avg Gap to Fastest (s), Avg Lap (s), Best Lap (s), Model Value, Baseline Value |
| `+0;-0;0` | Positions Gained |
| `+0.0;-0.0;0.0` | Predicted Positions Gained |

Hide (helpers, not dragged onto visuals): `Predicted Finish Score`, `Champion Points`.

### 0.3 Columns
- `dim_race[round]`, `dim_season[season_year]`, `fact_results[finish_position]`, `fact_lap_times[lap]`: Properties > Summarize by = None.
- `ml_model_metrics[model_value]`, `[baseline_value]`: Summarize by = None.
- `dim_race[race_label]`: Sort by column = `dim_race[race_date]`.

---

## Shared layout

Coordinates are `x, y, w, h` in px (Format > General > Properties > Size and position).

**Left rail** (every page): rectangle shape `0, 0, 200, 720`, fill `#15151E`.

| Item | Position | Setup |
| --- | --- | --- |
| Title text box "F1 RACE ANALYTICS" | `16, 16, 168, 48` | white, Segoe UI Semibold 14 |
| Season slicer | `16, 80, 168, 56` | `dim_season[season_year]`, Style Dropdown, Single select on, sort descending |
| Era slicer | `16, 148, 168, 56` | `dim_season[era]`, Dropdown, multi select |
| Page slicer slot | `16, 216, 168, 56` | Driver / Constructor / Race slicer per page |
| Page navigator | `16, 400, 168, 304` | Insert > Buttons > Navigator > Page navigator, Orientation vertical |

**Content area:** `216 → 1264` horizontally, `16 → 704` vertically, 16 px gutters.

**Sync slicers** (View > Sync slicers):

| Slicer | Sync + visible on | Notes |
| --- | --- | --- |
| Season (group `season`) | 1, 4, 5 | single select |
| Season (group `season_multi`) | 2, 3 | separate copy, **Single select off** so clearing = career view |
| Season (group `season_pred`) | 6 | separate copy, visual filter `season_year >= 2023` |
| Era (group `era`) | 1–6 | |
| — | 7, 8 | no season/era slicer |

Default season: select latest completed season on page 1 before saving; the saved state becomes the default.

**Dynamic titles:** Format > General > Title > Text > **fx** > Format style *Field value* > pick measure (`[Selected Season]`, `[Selected Race]`, `[Champion Label]`).

**Multi-value KPI rows** use **Card (new)**: drop several measures into *Data*, Format > Callout values; Layout > Arrangement *Grid* or *Single row*.

---

## 1. Season Overview

**Question:** who won the season and how the title fight unfolded. Page title text box `216, 16, 1048, 40` → bind via card with `[Selected Season]` (callout 20 pt, left aligned).

| Visual | Position | Fields | Settings |
| --- | --- | --- | --- |
| Card (new): champion | `216, 72, 400, 120` | Data `[Champion]`; Reference label `[Champion Points Label]` | Label fx → `[Champion Label]`; callout 24 pt |
| Card (new): season KPIs | `632, 72, 632, 120` | `[Races Held]`, `[Winners]`, `[Drivers]`, `[Constructors]` | Single row, 4 callouts |
| Line chart: championship battle | `216, 208, 640, 288` | X `dim_race[round]` (type Categorical), Y `[Championship Points]`, Legend `dim_driver[driver_code]` | Filter pane: `driver_code` Top N 5 by `[Championship Points]`; markers off; legend bottom; title "Championship battle" |
| Bar: wins by driver | `872, 208, 392, 288` | Y `dim_driver[full_name]`, X `[Wins]` | Top N 10 by `[Wins]`; sort desc; data labels on |
| Bar: constructors' points | `216, 512, 400, 192` | Y `dim_constructor[constructor_name]`, X `[Constructor Championship Points]` | sort desc; data labels on |
| Table: race winners | `632, 512, 632, 192` | `dim_race[round]`, `dim_race[race_name]`, `dim_driver[full_name]`, `dim_constructor[constructor_name]` | Visual filters `fact_results[is_win] = 1`, `fact_results[session_type] = Race`; sort by round asc; right-click a row → Drill through → Race Detail |

## 2. Driver Profile

Rail: **Driver** slicer in page slot (`dim_driver[full_name]`, Dropdown, search on, single select). Season slicer from group `season_multi`: cleared = career view.

| Visual | Position | Fields | Settings |
| --- | --- | --- | --- |
| Card (new): headline | `216, 16, 1048, 96` | `[Race Starts]`, `[Wins]`, `[Podiums]`, `[Poles]`, `[Points]`, `[Titles]` | Single row; title fx `[Selected Season]` |
| Card (new): rates | `216, 128, 1048, 88` | `[Win Rate]`, `[Podium Rate]`, `[DNF Rate]`, `[Points per Start]`, `[Avg Finish]`, `[Best Finish]`, `[Fastest Laps]`, `[Sprint Wins]` | Single row; callout 18 pt |
| Line and stacked column: results by season | `216, 232, 624, 224` | X `dim_season[season_year]`; Column y `[Race Points]`, `[Sprint Points]`; Line y `[Championship Position]` | Secondary Y axis on, **Invert range** on; Format > Edit interactions: Season slicer → **None** on this chart (always shows full career) |
| Card (new): qualifying | `856, 232, 408, 224` | `[Avg Quali Position]`, `[Q3 Rate]`, `[Avg Gap to Fastest (s)]`, `[Avg Grid]` | Grid 2 × 2; title "Qualifying" |
| Column: finish distribution | `216, 472, 400, 232` | X `fact_results[finish_position]` (Categorical), Y `[Race Entries]` | Visual filters `session_type = Race`, `finish_position` is not blank |
| Donut: retirement reasons | `632, 472, 280, 232` | Legend `dim_status[status_group]`, Values `[DNFs]` | Filter `status_group` not in Finished, Lapped; detail labels: percent |
| Text box: season summary | `928, 472, 336, 232` | Insert > Text box > **+ Value** → `Driver Season Summary` | Heading line "Season summary" above; text 10 pt |

## 3. Constructor Profile

Rail: **Constructor** slicer in page slot (`dim_constructor[constructor_name]`, Dropdown, search on, single select). Season from group `season_multi`.

| Visual | Position | Fields | Settings |
| --- | --- | --- | --- |
| Card (new): headline | `216, 16, 1048, 96` | `[Wins]`, `[Podiums]`, `[Points]`, `[Constructor Championship Position]`, `[Points Finishes]`, `[DNF Rate]`, `[Q3 Rate]`, `[Avg Grid]` | Single row; position shows blank in career view (intended) |
| Line: points per season | `216, 128, 624, 272` | X `dim_season[season_year]`, Y `[Constructor Championship Points]` | Season slicer interaction → None |
| Card (new): pit crew | `856, 128, 408, 120` | `[Avg Pit Stop (s)]`, `[Fastest Pit Stop (s)]`, `[Stops per Driver]` | title "Pit crew" |
| Line: quali vs race | `856, 264, 408, 136` | X `dim_season[season_year]`, Y `[Avg Grid]`, `[Avg Finish]` | Y Invert range on; Season interaction → None |
| 100% stacked bar: reliability | `216, 416, 624, 288` | Y `dim_season[season_year]`, X `[Race Entries]`, Legend `dim_status[status_group]` | Season interaction → None; sort Y desc |
| Bar: driver contribution | `856, 416, 408, 288` | Y `dim_driver[full_name]`, X `[Points]` | sort desc; Top N 10 |

## 4. Race Detail

Rail: **Race** slicer in page slot (`dim_race[race_label]`, Dropdown, search on, single select), filtered by synced Season. Drill-through: Visualizations > Build > Drill through > add `dim_race[race_label]`, Keep all filters on. Auto back button appears top-left; move to `1216, 16, 32, 32`.

| Visual | Position | Fields | Settings |
| --- | --- | --- | --- |
| Card (new): race title | `216, 16, 648, 72` | `[Selected Race]` | callout 22 pt, no label |
| Multi-row card: race info | `880, 16, 384, 72` | `dim_circuit[circuit_name]`, `dim_race[race_date]`, `[Best Lap]` (rename on visual: "Fastest lap") | |
| Table: classification | `216, 104, 560, 600` | `fact_results[position_order]`, `dim_driver[full_name]`, `dim_constructor[constructor_name]`, `[Grid]`, `[Result]`, `[Positions Gained]`, `[Race Points]`, `[Fastest Laps]`, `[Best Lap]`, `dim_status[status]` | Visual filter `session_type = Race`; sort position_order asc; Cell elements: Positions Gained → Icons (rules: >0 up green, 0 dash grey, <0 down red); Fastest Laps → Background color rule =1 → `#A020F0`, font white |
| Line: lap chart | `792, 104, 472, 232` | X `fact_lap_times[lap]`, Y `[Lap Position]`, Legend `dim_driver[driver_code]`, Tooltip `[Avg Lap (s)]` (rename "Lap time (s)") | Y Invert range on, min 1; markers off; stroke 2 |
| Text box: recap | `792, 352, 472, 120` | + Value `Race Recap`; second line + Value `Narrative Source` (8 pt, grey) | |
| Scatter: grid vs finish | `792, 488, 228, 216` | X `[Grid]`, Y `[Avg Finish]`, Values `dim_driver[driver_code]` | Category labels on; Analytics > X and Y constant lines at 10 as quadrant guides |
| Bar: pit stops | `1036, 488, 228, 216` | Y `dim_driver[driver_code]`, X `[Pit Stops]`, Tooltips `[Avg Pit Stop (s)]`, `[Predicted Stops]` | sort desc |

## 5. Circuits

| Visual | Position | Fields | Settings |
| --- | --- | --- | --- |
| Map | `216, 16, 640, 400` | Latitude `dim_circuit[latitude]`, Longitude `dim_circuit[longitude]`, Size `[Races Held]`, Tooltips `dim_circuit[circuit_name]`, `[Avg Positions Gained]` | If map disabled: File > Options > Global > Security > Map and Filled Map visuals on; bubble color `#E10600`; style Grayscale |
| Bar: overtaking | `872, 16, 392, 400` | Y `dim_circuit[circuit_name]`, X `[Avg Positions Gained]` | Top N 15; sort desc |
| Table | `216, 432, 1048, 272` | `dim_circuit[circuit_name]`, `dim_circuit[country]`, `[Races Held]`, `[Avg Positions Gained]`, `[Stops per Driver]`, `[Best Lap]` | Data bars on Avg Positions Gained; note lap data only from 1996 |

## 6. Predictions vs Actual

Rail: Season from group `season_pred` (2023+). Race slicer optional in page slot (same field as page 4, separate sync group).

| Visual | Position | Fields | Settings |
| --- | --- | --- | --- |
| Card (new): KPIs | `216, 16, 1048, 88` | `[Top-3 Pick Hit Rate]`, `[Podium Probability]`, `[DNF Risk]` | rename on visual: "Top-3 pick hit rate", "Avg podium probability", "Avg DNF risk" |
| Matrix: race × driver | `216, 120, 520, 584` | Rows `dim_race[race_label]` > `dim_driver[full_name]`; Values `[Podium Probability]`, `[Result]`, `[Predicted Finish Rank]`, `[DNF Risk]` | Filter `[Podium Probability]` is not blank; Podium Probability → Data bars `#E10600`; DNF Risk → Background gradient green→red; Row subtotals off; expand all one level |
| Scatter: calibration | `752, 120, 512, 232` | X `[Podium Probability]`, Y `[Podium Rate]`, Values `dim_driver[driver_code]` | X and Y 0–100%; good calibration → points near the diagonal |
| Table: predicted vs actual | `752, 368, 512, 200` | `dim_driver[driver_code]`, `[Predicted Positions Gained]`, `[Positions Gained]`, `[Predicted Stops]`, `[Pit Stops]`, `[Predicted Pit Stop (s)]`, `[Avg Pit Stop (s)]` | Meaningful with one race selected; title fx `[Selected Race]` |
| Text box: explanation | `752, 584, 512, 120` | + Value `Prediction Explanation` | Click a driver row in matrix → cross-filters to that race + driver |

## 7. Model Performance

No season/era slicers (hidden via Sync slicers). Rail page slot: **Model** slicer `narr_model[model_name]`, Style Vertical list, single select (filters metrics via relationship 30).

| Visual | Position | Fields | Settings |
| --- | --- | --- | --- |
| Card (new) | `216, 16, 256, 120` | `[Models Beating Baseline]` | label "models beat baseline" |
| Card (new): narrative | `488, 16, 776, 120` | `narr_model[narrative_text]` (aggregation First) | callout 10 pt, left aligned, text wrap on |
| Table: metrics | `216, 152, 520, 552` | `ml_model_metrics[model_name]`, `[metric]`, `[model_value]`, `[baseline_value]`, `[beats_baseline]` | Cell elements on beats_baseline: Font color fx → Field value → `[Beats Baseline Color]` |
| Clustered bar | `752, 152, 512, 552` | Y `ml_model_metrics[metric]`, X `[Model Value]`, `[Baseline Value]` | Needs one model selected. Metrics on mixed scales (AUC vs MAE ms) → swap for a table with data bars if bars look flat |

## 8. About

No slicers. Text boxes:

- Data source: Kaggle Formula 1 Race Data (Ergast format).
- Architecture: SQL Server warehouse (bronze → silver → gold) → Python ML → local LLM narratives → Power BI.
- Refresh date (update manually at each refresh).
- Links: `SQL_Projects`, `f1-analytics-ml` repos (Insert > Buttons > Blank, Action Web URL).