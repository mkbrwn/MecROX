# run previous script for cleaning data
source("src/1_clean_data.r")
library(gtsummary)

# summarise PF ratio every 12 hours since randomisation for each MECROXStudy ID
pfratio_12h_summary <- data_pfratio %>%
    filter(!is.na(TimeSinceRandomisation), !is.na(PFRatioValue)) %>%
    mutate(TimeWindow = ifelse(
        TimeSinceRandomisation < 0,
        -12,
        floor(TimeSinceRandomisation / 12) * 12
    )) %>%
    group_by(MECROXStudy, TimeWindow) %>%
    summarise(
        n             = n(),
        mean_PFRatio  = mean(PFRatioValue, na.rm = TRUE),
        .groups = "drop"
    )

# pivot wide so each TimeWindow becomes a column (one row per MECROXStudy)
pfratio_12h_wide <- pfratio_12h_summary %>%
    pivot_wider(
        id_cols     = MECROXStudy,
        names_from  = TimeWindow,
        values_from = c(n, mean_PFRatio),
        names_glue  = "{.value}_h{TimeWindow}"
    ) %>%
    select(-mean_PFRatio_h120)

# produce table for PF ratio values stratified by treatment group (patient-level means)
summary_pfratio <- pfratio_12h_wide %>%
    select(MECROXStudy, starts_with("mean_PFRatio")) %>%
    rename_with(~ gsub("mean_PFRatio_h", "", .x), starts_with("mean_PFRatio")) %>%
    left_join(data_pfratio %>% distinct(MECROXStudy, Treatment), by = "MECROXStudy") %>%
    select(-MECROXStudy) %>%
    tbl_summary(
        by        = Treatment,
        statistic = list(all_continuous() ~ "{mean} ({sd})"),
        digits    = all_continuous() ~ 2,
        missing   = "no"
    ) %>%
    add_p(test = all_continuous() ~ "t.test") %>%
    add_n(col_label = "**Patients**") %>%
    modify_header(label ~ "**Time Since Randomisation (hours)**")

summary_pfratio %>%
    as_gt() %>%
    gt::gtsave("output/tables/pfratio_12h_by_treatment_patient_level.html")

summary_pfratio %>%
    as_gt() %>%
    gt::gtsave("output/tables/pfratio_12h_by_treatment_patient_level.png")

summary_pfratio %>%
    as_hux_xlsx("output/tables/pfratio_12h_by_treatment_patient_level.xlsx")

# produce table for PF ratio using individual observations (not patient-averaged)
summary_pfratio_obs <- data_pfratio %>%
    filter(!is.na(TimeSinceRandomisation), !is.na(PFRatioValue)) %>%
    mutate(TimeWindow = ifelse(
        TimeSinceRandomisation < 0,
        -12,
        floor(TimeSinceRandomisation / 12) * 12
    )) %>%
    filter(TimeWindow < 120) %>%
    ungroup() %>%
    mutate(obs_id = row_number()) %>%
    pivot_wider(
        id_cols     = c(obs_id, Treatment),
        names_from  = TimeWindow,
        values_from = PFRatioValue,
        names_prefix = "h"
    ) %>%
    select(-obs_id) %>%
    rename_with(~ gsub("^h", "", .x), starts_with("h")) %>%
    tbl_summary(
        by        = Treatment,
        statistic = list(all_continuous() ~ "{mean} ({sd})"),
        digits    = all_continuous() ~ 2,
        missing   = "no"
    ) %>%
    add_p(test = all_continuous() ~ "t.test") %>%
    add_n(col_label = "**Observations**") %>%
    modify_header(label ~ "**Time Since Randomisation (hours)**")

summary_pfratio_obs %>%
    as_gt() %>%
    gt::gtsave("output/tables/pfratio_12h_by_treatment_obs.html")

summary_pfratio_obs %>%
    as_gt() %>%
    gt::gtsave("output/tables/pfratio_12h_by_treatment_obs.png")

summary_pfratio_obs %>%
    as_hux_xlsx("output/tables/pfratio_12h_by_treatment_obs.xlsx")
