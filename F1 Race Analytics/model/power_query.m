// =============================================================================
// F1 Race Analytics - Power Query (M) queries
// =============================================================================
// How to use (Power BI Desktop):
//   1. Home > Transform data > opens Power Query Editor.
//   2. Create the two parameters first: Home > Manage Parameters > New
//        ServerName    Text   SAHIL\SQLEXPRESS     (your SSMS server name)
//        DatabaseName  Text   F1_DB2
//   3. For every query below: Home > New Source > Blank Query, rename it to the
//      name in the header (exactly, the DAX measures use these names), open
//      Advanced Editor, paste the block between "let" and "in <step>".
//   4. Close & Apply. Choose "Import" if asked. First refresh takes a minute
//      (fact_lap_times is ~620k rows).
//
// Warehouse objects come from the F1 Data Warehouse (SQL_Projects repo);
// ml.* tables are filled by the f1-analytics-ml repo.
// =============================================================================


// ---------------------------------------------------------------- dim_driver
let
    Source = Sql.Database(ServerName, DatabaseName),
    dim_driver = Source{[Schema = "gold", Item = "dim_driver"]}[Data]
in
    dim_driver


// ---------------------------------------------------------------- dim_constructor
let
    Source = Sql.Database(ServerName, DatabaseName),
    dim_constructor = Source{[Schema = "gold", Item = "dim_constructor"]}[Data]
in
    dim_constructor


// ---------------------------------------------------------------- dim_circuit
let
    Source = Sql.Database(ServerName, DatabaseName),
    dim_circuit = Source{[Schema = "gold", Item = "dim_circuit"]}[Data]
in
    dim_circuit


// ---------------------------------------------------------------- dim_race
let
    Source = Sql.Database(ServerName, DatabaseName),
    dim_race = Source{[Schema = "gold", Item = "dim_race"]}[Data]
in
    dim_race


// ---------------------------------------------------------------- dim_season
// One row per season, built from dim_race (era / decade are constant per season).
// The season slicer uses this table so it can filter both races and
// season-level tables (agg_driver_season, narr_driver_season).
let
    Source = dim_race,
    Kept = Table.SelectColumns(Source, {"season_year", "era", "decade"}),
    Seasons = Table.Distinct(Kept, {"season_year"}),
    Sorted = Table.Sort(Seasons, {{"season_year", Order.Ascending}})
in
    Sorted


// ---------------------------------------------------------------- dim_status
let
    Source = Sql.Database(ServerName, DatabaseName),
    dim_status = Source{[Schema = "gold", Item = "dim_status"]}[Data]
in
    dim_status


// ---------------------------------------------------------------- dim_date
let
    Source = Sql.Database(ServerName, DatabaseName),
    dim_date = Source{[Schema = "gold", Item = "dim_date"]}[Data]
in
    dim_date


// ---------------------------------------------------------------- fact_results
let
    Source = Sql.Database(ServerName, DatabaseName),
    fact_results = Source{[Schema = "gold", Item = "fact_results"]}[Data]
in
    fact_results


// ---------------------------------------------------------------- fact_qualifying
let
    Source = Sql.Database(ServerName, DatabaseName),
    fact_qualifying = Source{[Schema = "gold", Item = "fact_qualifying"]}[Data]
in
    fact_qualifying


// ---------------------------------------------------------------- fact_lap_times
let
    Source = Sql.Database(ServerName, DatabaseName),
    fact_lap_times = Source{[Schema = "gold", Item = "fact_lap_times"]}[Data]
in
    fact_lap_times


// ---------------------------------------------------------------- fact_pit_stops
let
    Source = Sql.Database(ServerName, DatabaseName),
    fact_pit_stops = Source{[Schema = "gold", Item = "fact_pit_stops"]}[Data]
in
    fact_pit_stops


// ---------------------------------------------------------------- fact_driver_standings
let
    Source = Sql.Database(ServerName, DatabaseName),
    fact_driver_standings = Source{[Schema = "gold", Item = "fact_driver_standings"]}[Data]
in
    fact_driver_standings


// ---------------------------------------------------------------- fact_constructor_standings
let
    Source = Sql.Database(ServerName, DatabaseName),
    fact_constructor_standings = Source{[Schema = "gold", Item = "fact_constructor_standings"]}[Data]
in
    fact_constructor_standings


// ---------------------------------------------------------------- fact_constructor_results
let
    Source = Sql.Database(ServerName, DatabaseName),
    fact_constructor_results = Source{[Schema = "gold", Item = "fact_constructor_results"]}[Data]
in
    fact_constructor_results


// ---------------------------------------------------------------- agg_driver_season
let
    Source = Sql.Database(ServerName, DatabaseName),
    agg_driver_season = Source{[Schema = "gold", Item = "agg_driver_season"]}[Data]
in
    agg_driver_season


// ---------------------------------------------------------------- ml_predictions
// Latest run per model and version only, so re-running training never
// duplicates predictions in the report.
let
    Source = Sql.Database(ServerName, DatabaseName, [Query = "
        WITH latest AS (
            SELECT model_name, model_version, MAX(run_id) AS run_id
            FROM ml.model_runs
            GROUP BY model_name, model_version
        )
        SELECT p.run_id, l.model_name, l.model_version,
               p.race_id, p.driver_id,
               p.predicted_value, p.predicted_class, p.probability
        FROM ml.predictions AS p
        JOIN latest AS l ON l.run_id = p.run_id"]),
    Typed = Table.TransformColumnTypes(Source, {
        {"predicted_value", type number}, {"probability", type number}})
in
    Typed


// ---------------------------------------------------------------- ml_model_metrics
// One row per model x metric (latest eval run), model vs baseline,
// unpacked from ml.model_runs.metrics_json.
let
    Source = Sql.Database(ServerName, DatabaseName, [Query = "
        SELECT r.model_name, r.train_from_season, r.train_to_season,
               r.test_from_season, r.test_to_season, r.metrics_json
        FROM ml.model_runs AS r
        JOIN (SELECT model_name, MAX(run_id) AS run_id
              FROM ml.model_runs WHERE model_version = 'eval'
              GROUP BY model_name) AS l ON l.run_id = r.run_id"]),
    Parsed = Table.AddColumn(Source, "metrics", each Json.Document([metrics_json])),
    Rows = Table.AddColumn(Parsed, "metric_rows", each
        let
            m = [metrics][model],
            b = [metrics][baseline],
            names = List.Select(Record.FieldNames(m), each _ <> "positive_rate")
        in
            Table.FromRecords(List.Transform(names, (n) => [
                metric = n,
                model_value = Record.Field(m, n),
                baseline_value = if Record.HasFields(b, n) then Record.Field(b, n) else null
            ]))),
    Kept = Table.SelectColumns(Rows, {"model_name", "train_from_season", "train_to_season",
                                      "test_from_season", "test_to_season", "metric_rows"}),
    Expanded = Table.ExpandTableColumn(Kept, "metric_rows",
                                       {"metric", "model_value", "baseline_value"}),
    Typed = Table.TransformColumnTypes(Expanded, {
        {"model_value", type number}, {"baseline_value", type number}}),
    LowerIsBetter = Table.AddColumn(Typed, "lower_is_better", each
        List.Contains({"mae", "rmse", "brier", "log_loss", "mae_places"}, [metric]), type logical),
    Beats = Table.AddColumn(LowerIsBetter, "beats_baseline", each
        if [baseline_value] = null then null
        else if [lower_is_better] then [model_value] < [baseline_value]
        else [model_value] > [baseline_value], type logical)
in
    Beats


// ---------------------------------------------------------------- narr_race
// Latest race recaps and prediction explanations (relate to dim_race, dim_driver).
let
    Source = Sql.Database(ServerName, DatabaseName, [Query = "
        SELECT narrative_type, race_id, driver_id, narrative_text,
               llm_model, is_verified, created_at
        FROM (
            SELECT n.*, ROW_NUMBER() OVER (
                       PARTITION BY narrative_type, race_id, driver_id
                       ORDER BY narrative_id DESC) AS rn
            FROM ml.narratives AS n
            WHERE narrative_type IN ('race_recap', 'prediction')
        ) AS x
        WHERE rn = 1"])
in
    Source


// ---------------------------------------------------------------- narr_driver_season
// Latest driver-season summaries (relate to dim_driver, dim_season).
let
    Source = Sql.Database(ServerName, DatabaseName, [Query = "
        SELECT driver_id, season_year, narrative_text, llm_model, is_verified, created_at
        FROM (
            SELECT n.*, ROW_NUMBER() OVER (
                       PARTITION BY driver_id, season_year
                       ORDER BY narrative_id DESC) AS rn
            FROM ml.narratives AS n
            WHERE narrative_type = 'driver_season'
        ) AS x
        WHERE rn = 1"])
in
    Source


// ---------------------------------------------------------------- narr_model
// Latest model-report narratives (no relationships; filter by model_name text).
let
    Source = Sql.Database(ServerName, DatabaseName, [Query = "
        SELECT r.model_name, n.narrative_text, n.llm_model, n.is_verified, n.created_at
        FROM ml.narratives AS n
        JOIN ml.model_runs AS r ON r.run_id = n.run_id
        WHERE n.narrative_id IN (
            SELECT MAX(n2.narrative_id)
            FROM ml.narratives AS n2
            JOIN ml.model_runs AS r2 ON r2.run_id = n2.run_id
            WHERE n2.narrative_type = 'model_report'
            GROUP BY r2.model_name)"])
in
    Source
