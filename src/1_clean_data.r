# this script cleans data for analysis of SPo2 within the UkRox dataset

#load libraries             
library(tidyverse)
library(gtsummary)
library(readxl)

#load data 
data <- read_excel("data/UKRoxData.xlsx")

# run cleaning script for plymouth data
source("src/1_1_plymouth_clean_data.R")
#clean data
data <- data %>%
    #select only relevant variables
    select( MECROXStudy, IMVStart, UKRoxTime, SpO2Time, SpO2Value, Treatment) %>% 
    filter( !is.na(MECROXStudy), !is.na(SpO2Time), !is.na(SpO2Value)) %>% 
    mutate( SpO2Value = as.numeric(SpO2Value)) 

#append plymouth data to the main dataset
data <- bind_rows(data, plymouth_data)

# remove spot less than 80 
data <- data %>%
    filter(SpO2Value >= 80)


#calculate time since randomisation from entry to the study 
data <- data %>%
    mutate( TimeSinceRandomisation = as.numeric(difftime(SpO2Time, UKRoxTime, units = "hours")))    

#max time since randomisation is 168 hours (7 days) so remove any values above this
data <- data %>%
    group_by(MECROXStudy) %>%
    mutate( Maxtime = max(TimeSinceRandomisation, na.rm = T)) 

#filter if time since randomisation is greater than 120 and < -12 (elibilitycriteria is 12 hours pre-randomisation)
data <- data %>%
    filter(TimeSinceRandomisation <= 120 & TimeSinceRandomisation >= -12)

# recode treatment labels
data <- data %>%
    mutate(Treatment = recode(Treatment, "Usual" = "Usual care"))


#### addition of PF ratio data
# UKRoxData_V3.xlsx packs each patient's PF ratio readings into one row as a
# comma-separated string, which is unnested below into one row per reading -
# plymouth_data_pfratio is already in that one-row-per-reading long format, so
# it's bound in afterwards rather than before (binding it in first would drop
# it entirely, since distinct()/PFRatio_pre/PFRatio_post below don't apply to it)
data_pfratio <- read_excel("data/UKRoxData_V3.xlsx") %>%
    #select only relevant variables
    rename(
        PFRatio_pre  = `PFRatio_Between_IMVStartTime_&_UKRoxTime`,
        PFRatio_post = `PFRatio_Between_UKRoxTime_+_5DaysUKRoxTime`
    ) %>%
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
    select(MECROXStudy, UKRoxTime, IMVStart, Treatment, PFRatioTime, PFRatioValue)

#append plymouth PF ratio data
data_pfratio <- bind_rows(data_pfratio, plymouth_data_pfratio)

# recode treatment labels
data_pfratio <- data_pfratio %>%
    mutate(Treatment = recode(Treatment, "Usual" = "Usual care"))

# calculate time since randomisation and apply same window as SpO2 data
data_pfratio <- data_pfratio %>%
    mutate(TimeSinceRandomisation = as.numeric(difftime(PFRatioTime, UKRoxTime, units = "hours"))) %>%
    filter(TimeSinceRandomisation <= 120 & TimeSinceRandomisation >= -12)
