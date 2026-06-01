# output/

Generated outputs from the analysis scripts. All files here are reproducible — delete and re-run the scripts to regenerate.

## figures/

PNG plots produced by the figure scripts.

| File | Script | Description |
|---|---|---|
| `lowess_spo2_split.png` | `2_1_Spo2_figure_final.r` | Final SpO2 figure: linear pre-randomisation trend + Lowess post-randomisation, by treatment |
| `lowess_pfratio_split.png` | `2_2_PFRatio_figure.r` | Final PF ratio figure with patient count table below |
| `lowess_spo2.png` | `2_Spo2_figures.r` | Exploratory SpO2 Lowess curve |
| `lowess_spo2_dot.png` | `2_Spo2_figures.r` | Exploratory SpO2 Lowess curve with data points |
| `lowess_spo2_dots_split.png` | `2_Spo2_figures.r` | Split Lowess with data points |
| `gam_spo2.png` | `2_Spo2_figures.r` | GAM curve for SpO2 |
| `gam_me_spo2.png` | `2_Spo2_figures.r` | Mixed effects GAM for SpO2 |

## tables/

Summary tables in HTML, PNG, and Excel formats.

| File prefix | Script | Description |
|---|---|---|
| `spo2_12h_by_treatment_obs` | `3_Spo2_table.r` | SpO2 by 12-hour window — observation level |
| `spo2_12h_by_treatment_patient_level` | `3_Spo2_table.r` | SpO2 by 12-hour window — patient-level means |
| `pfratio_12h_by_treatment_obs` | `4_PFRatio_table.r` | PF ratio by 12-hour window — observation level |
| `pfratio_12h_by_treatment_patient_level` | `4_PFRatio_table.r` | PF ratio by 12-hour window — patient-level means |
