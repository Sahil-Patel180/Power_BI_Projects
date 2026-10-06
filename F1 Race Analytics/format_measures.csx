// Tabular Editor C# script: sets format strings, display folders, hidden flags on _Measures.
// Run: External tools > Tabular Editor > C# Script tab > paste > Run (F5) > Ctrl+S to save back to Power BI.

var fmt = new Dictionary<string, string[]> {
    { "#,0", new[] { "Race Entries","Race Starts","Wins","Podiums","DNFs","Points Finishes","Fastest Laps","Sprint Wins",
                     "Races Held","Drivers","Constructors","Winners","Poles","Titles","Pit Stops","Best Finish","Grid",
                     "Championship Position","Constructor Championship Position","Predicted Finish Rank","Models Beating Baseline" } },
    { "#,0.##", new[] { "Points","Race Points","Sprint Points","Championship Points","Constructor Championship Points","Champion Points" } },
    { "0.0%", new[] { "Win Rate","Podium Rate","DNF Rate","Q3 Rate","Podium Probability","DNF Risk","Top-3 Pick Hit Rate" } },
    { "0.00", new[] { "Points per Start","Avg Finish","Avg Grid","Avg Positions Gained","Avg Quali Position","Stops per Driver",
                      "Predicted Finish Score","Avg Pit Stop (s)","Fastest Pit Stop (s)","Predicted Pit Stop (s)" } },
    { "0.000", new[] { "Avg Gap to Fastest (s)","Avg Lap (s)","Best Lap (s)","Model Value","Baseline Value" } },
    { "+0;-0;0", new[] { "Positions Gained" } },
    { "+0.0;-0.0;0.0", new[] { "Predicted Positions Gained" } }
};

var folders = new Dictionary<string, string[]> {
    { "Results", new[] { "Race Entries","Race Starts","Wins","Podiums","DNFs","Points Finishes","Fastest Laps","Sprint Wins",
                         "Points","Race Points","Sprint Points","Win Rate","Podium Rate","DNF Rate","Points per Start",
                         "Avg Finish","Avg Grid","Positions Gained","Avg Positions Gained","Best Finish","Result","Grid",
                         "Races Held","Drivers","Constructors","Winners" } },
    { "Qualifying", new[] { "Poles","Avg Quali Position","Q3 Rate","Avg Gap to Fastest (s)" } },
    { "Standings", new[] { "Championship Points","Championship Position","Constructor Championship Points",
                           "Constructor Championship Position","Champion","Champion Label","Titles","Champion Points","Champion Points Label" } },
    { "Pit & Laps", new[] { "Pit Stops","Avg Pit Stop (s)","Fastest Pit Stop (s)","Stops per Driver","Avg Lap (s)","Best Lap (s)","Best Lap","Lap Position" } },
    { "ML", new[] { "Podium Probability","DNF Risk","Predicted Positions Gained","Predicted Pit Stop (s)","Predicted Stops",
                    "Predicted Finish Score","Predicted Finish Rank","Top-3 Pick Hit Rate","Model Value","Baseline Value",
                    "Models Beating Baseline","Beats Baseline Color" } },
    { "Narrative", new[] { "Race Recap","Prediction Explanation","Driver Season Summary","Narrative Source" } },
    { "UI", new[] { "Selected Season","Selected Race" } }
};

var hidden = new[] { "Predicted Finish Score", "Champion Points", "Beats Baseline Color" };

foreach (var m in Model.Tables["_Measures"].Measures)
{
    foreach (var kv in fmt)     if (kv.Value.Contains(m.Name)) m.FormatString  = kv.Key;
    foreach (var kv in folders) if (kv.Value.Contains(m.Name)) m.DisplayFolder = kv.Key;
    if (hidden.Contains(m.Name)) m.IsHidden = true;
}
