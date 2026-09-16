# script to clean data for UHS patient ID14 and homogenise it with the main dataset

library(tidyverse)
library(readxl)

# load ID14 data
id14_data <- read_excel("data/MecroxStudyID14.xlsx") %>%
    # select only relevant variables for SpO2
    select(MECROXStudy, IMVStart, UKRoxTime, SpO2Time, SpO2Value, Treatment) %>%
    filter(!is.na(MECROXStudy), !is.na(SpO2Time), !is.na(SpO2Value)) %>%
    mutate(
        SpO2Value = as.numeric(SpO2Value),
        # convert times to character format to match main dataset
        IMVStart = as.character(as.POSIXct(IMVStart)),
        UKRoxTime = as.character(as.POSIXct(UKRoxTime)),
        SpO2Time = as.character(as.POSIXct(SpO2Time))
    )

#### PFRatio data for ID14
id14_data_pfratio <- read_excel("data/MecroxStudyID14.xlsx") %>%
    # select only relevant variables
    rename(
        PFRatio_pre  = `PFRatio_Between_IMVStartTime_&_UKRoxTime`,
        PFRatio_post = `PFRatio_Between_UKRoxTime_+_5DaysUKRoxTime`
    ) %>%
    filter(!is.na(MECROXStudy)) %>%
    distinct(MECROXStudy, .keep_all = TRUE) %>%
    # combine both PFRatio columns, handling NAs
    mutate(PFRatio = case_when(
        !is.na(PFRatio_pre) & !is.na(PFRatio_post) ~ paste(PFRatio_pre, PFRatio_post, sep = ", "),
        !is.na(PFRatio_pre)  ~ PFRatio_pre,
        !is.na(PFRatio_post) ~ PFRatio_post,
        TRUE ~ NA_character_
    )) %>%
    filter(!is.na(PFRatio)) %>%
    # split comma-separated "(datetime)value" entries into individual rows
    mutate(PFRatio_entries = str_split(PFRatio, ",\\s*")) %>%
    unnest(PFRatio_entries) %>%
    mutate(
        PFRatioTime  = as.POSIXct(str_extract(PFRatio_entries, "(?<=\\().*?(?=\\))"), format = "%d/%m/%Y %H:%M"),
        PFRatioValue = as.numeric(str_extract(PFRatio_entries, "(?<=\\))[0-9.]+"))
    ) %>%
    mutate(
        UKRoxTime = as.character(as.POSIXct(UKRoxTime)),
        IMVStart = as.character(as.POSIXct(IMVStart))
    ) %>%
    select(MECROXStudy, UKRoxTime, IMVStart, Treatment, PFRatioTime, PFRatioValue)
