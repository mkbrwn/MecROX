# MecROX — SpO2 Analysis

Analysis of SpO2 values over time since randomisation in the UKRox dataset.

## Project Structure

```
data/               # Raw data (gitignored)
src/                # Analysis scripts
output/figures/     # Generated plots
```

## Scripts

### `src/1_clean_data.r`
Cleans the raw UKRox dataset:
- Selects relevant variables: `MECROXStudy`, `IMVStart`, `UKRoxTime`, `SpO2Time`, `SpO2Value`, `Treatment`
- Removes rows with missing `MECROXStudy`, `SpO2Time`, or `SpO2Value`
- Calculates `TimeSinceRandomisation` (hours from `UKRoxTime` to `SpO2Time`)
- Filters to `TimeSinceRandomisation <= 120` hours (5 days)

### `src/2_Spo2_figures.r`
Produces the following figures, all stratified by treatment group:

| Output file | Description |
|---|---|
| `lowess_spo2.png` | Lowess curve (post-randomisation only), y: 88–100%, x: ≤120 h |
| `lowess_spo2_dot.png` | Lowess curve with individual data points |
| `lowess_spo2_split.png` | trend pre-randomisation + Lowess post-randomisation |
| `lowess_spo2_dots_split.png` | As above with individual data points (grey pre-, coloured post-randomisation) |
| `gam_spo2.png` | GAM curve (post-randomisation only) |
| `gam_me_spo2.png` | Mixed effects GAM with random intercept and slope per `MECROXStudy` |

## Notes
- All figures use `Treatment` as the stratifying variable
- Pre-randomisation period (`TimeSinceRandomisation < 0`) uses a single combined linear trend where shown
- Mixed effects GAM fitted using `mgcv::gamm`
