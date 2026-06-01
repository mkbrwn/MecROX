# src/

Analysis scripts. Run in numerical order — each script calls `source("src/1_clean_data.r")` automatically.

| Script | Purpose |
|---|---|
| `1_clean_data.r` | Load and clean SpO2 (`data`) and PF ratio (`data_pfratio`) datasets |
| `2_Spo2_figures.r` | Exploratory SpO2 figures by treatment group |
| `2_1_Spo2_figure_final.r` | Final publication-ready SpO2 figure |
| `2_2_PFRatio_figure.r` | Final publication-ready PF ratio figure with patient counts |
| `3_Spo2_table.r` | Summary tables of SpO2 by 12-hour window and treatment |
| `4_PFRatio_table.r` | Summary tables of PF ratio by 12-hour window and treatment |
