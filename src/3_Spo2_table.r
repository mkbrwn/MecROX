#run previous script for cleaning data
source("src/1_clean_data.r")
library(gtsummary)

# summarise SpO2 every 12 hours since randomisation for each MECROXStudy ID
spo2_12h_summary <- data %>%
    filter(!is.na(TimeSinceRandomisation), !is.na(SpO2Value)) %>%
    mutate(TimeWindow = ifelse(
        TimeSinceRandomisation < 0,
        -12,
        floor(TimeSinceRandomisation / 12) * 12
    )) %>%
    group_by(MECROXStudy, TimeWindow) %>%
    summarise(
        n          = n(),
        mean_SpO2  = mean(SpO2Value, na.rm = TRUE),
        .groups = "drop"
    )

# pivot wide so each TimeWindow becomes a column (one row per MECROXStudy)
spo2_12h_wide <- spo2_12h_summary %>%
    pivot_wider(
        id_cols     = MECROXStudy,
        names_from  = TimeWindow,
        values_from = c(n, mean_SpO2),
        names_glue  = "{.value}_h{TimeWindow}"
    )|> 
    select(-mean_SpO2_h120)
    

# produce table for SPO2 values stratified by treatment group
summary_spo2 <- spo2_12h_wide %>%
    select(MECROXStudy, starts_with("mean_SpO2")) %>%
    rename_with(~ gsub("mean_SpO2_h", "", .x), starts_with("mean_SpO2")) %>%
    left_join(data %>% distinct(MECROXStudy, Treatment), by = "MECROXStudy") %>%
    select(-MECROXStudy) %>%
        tbl_summary(
        by         = Treatment,
        statistic  = list(all_continuous() ~ "{mean} ({sd})"),
        digits     = all_continuous() ~ 2,
        missing    = "no"
    ) %>%
    modify_header(label ~ "**Time Since Randomisation (hours)**")

summary_spo2 %>%
    as_gt() %>%
    gt::gtsave("output/tables/spo2_12h_by_treatment.html")

summary_spo2 %>%
    as_gt() %>%
    gt::gtsave("output/tables/spo2_12h_by_treatment.png")

summary_spo2 %>%
    as_hux_xlsx("output/tables/spo2_12h_by_treatment.xlsx")