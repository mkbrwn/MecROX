# this script cleans data for analysis of SPo2 within the UkRox dataset

#load libraries             
library(tidyverse, gtsummary, readxl)

#load data 
data <- read_excel("data/UKRoxData.xlsx")

#clean data
data <- data %>%
    #select only relevant variables
    select( MECROXStudy, IMVStart, UKRoxTime, SpO2Time, SpO2Value, Treatment) %>% 
    filter( !is.na(MECROXStudy), !is.na(SpO2Time), !is.na(SpO2Value)) %>% 
    mutate( SpO2Value = as.numeric(SpO2Value)) 

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