# MecROX — SpO2 & PF Ratio Analysis

Analysis of SpO2 and PF ratio values over time since randomisation in the UKRox dataset.

## Project Structure

```
data/               # Raw input data files (gitignored)
src/                # Analysis scripts (run in order)
output/
  figures/          # Generated plots (.png)
  tables/           # Generated summary tables (.html, .png, .xlsx)
```

## Package management

This project uses [`renv`](https://rstudio.github.io/renv/) to pin package versions. On first opening the project, run:

```r
renv::restore()
```

to install the exact package versions recorded in `renv.lock`. After adding or updating a package, run `renv::snapshot()` to update the lockfile.

## Scripts

Run scripts in numerical order. Each script sources `1_clean_data.r` automatically.

### `src/1_clean_data.r`
Loads and cleans both raw datasets, sourcing `src/1_1_plymouth_clean_data.r` to bring in the Plymouth patients:

**SpO2 data** (`UKRoxData.xlsx` + Plymouth `MecRox_Data_Plymouth_reorganised.xlsx`) → `data`
- Selects `MECROXStudy`, `IMVStart`, `UKRoxTime`, `SpO2Time`, `SpO2Value`, `Treatment`
- Removes SpO2 values below 80 and missing records
- Calculates `TimeSinceRandomisation` (hours); filters to −12 to +120 h

**PF ratio data** (`UKRoxData_V3.xlsx` + Plymouth `MecRox_Data_Plymouth_reorganised.xlsx`) → `data_pfratio`
- Combines `PFRatio_Between_IMVStartTime_&_UKRoxTime` and `PFRatio_Between_UKRoxTime_+_5DaysUKRoxTime` per patient
- Parses comma-separated `(datetime)value` entries into individual rows
- Calculates `TimeSinceRandomisation`; filters to −12 to +120 h

### `src/1_1_plymouth_clean_data.r`
Loads and reshapes the Plymouth site data (`MecRox_Data_Plymouth_reorganised.xlsx`) to match the main UK-ROX variable names, producing `plymouth_data` and `plymouth_data_pfratio`, which are appended to the main datasets in `1_clean_data.r`.

---

### `src/2_Spo2_figures.r`
Exploratory SpO2 figures stratified by treatment group.

| Output | Description |
|---|---|
| `lowess_spo2.png` | Lowess curve, post-randomisation only |
| `lowess_spo2_dot.png` | Lowess curve with individual data points |
| `lowess_spo2_split.png` | Linear pre-randomisation trend + Lowess post-randomisation |
| `lowess_spo2_dots_split.png` | As above with individual data points |
| `gam_spo2.png` | GAM curve, post-randomisation only |
| `gam_me_spo2.png` | Mixed effects GAM (random intercept + slope per `MECROXStudy`) |

### `src/2_1_Spo2_figure_final.r`
Final publication-ready SpO2 figure.

| Output | Description |
|---|---|
| `lowess_spo2_split.png` | Linear pre-randomisation trend + Lowess post-randomisation, by treatment |

- Pre-randomisation: single combined linear trend (grey, 95% CI)
- Post-randomisation: separate Lowess curves per treatment (span = 0.75, 95% CI)
- x-axis: −12 to 120 h; y-axis: 88–100% in 2% steps
- Legend inside top-right; open axis style; base font size 16

### `src/2_2_PFRatio_figure.r`
Final publication-ready PF ratio figure with patient count table.

| Output | Description |
|---|---|
| `lowess_pfratio_split.png` | Linear pre-randomisation trend + Lowess post-randomisation, by treatment, with n per 12-hour interval below |

- Same style as SpO2 figure; y-axis: PF ratio (kPa)
- Count panel below shows number of distinct patients per treatment per 12-hour bin

---

### `src/3_Spo2_table.r`
Summary table of mean SpO2 (SD) per 12-hour window, by treatment group.

| Output | Description |
|---|---|
| `spo2_12h_by_treatment_obs.html/.png/.xlsx` | Observation-level summary |
| `spo2_12h_by_treatment_patient_level.html/.png/.xlsx` | Patient-level means summary |

### `src/4_PFRatio_table.r`
Summary table of mean PF ratio (SD) per 12-hour window, by treatment group.

| Output | Description |
|---|---|
| `pfratio_12h_by_treatment_obs.html/.png/.xlsx` | Observation-level summary |
| `pfratio_12h_by_treatment_patient_level.html/.png/.xlsx` | Patient-level means summary |

---

## Notes
- All figures and tables stratify by `Treatment`
- Pre-randomisation window is collapsed to a single bin (−12 to 0 h)
- Mixed effects GAM fitted using `mgcv::gamm`
- Tables use `gtsummary`; figures combined with `patchwork`; Excel export requires `huxtable`
