# script to clean data and homogenise it with the data in the main script src/1_clean_data.r

    # load plymouth data
        plymouth_patients <- read_excel("data/MecRox_Data_Plymouth_reorganised.xlsx", sheet = "Patient Summary")
        plymouth_hourly   <- read_excel("data/MecRox_Data_Plymouth_reorganised.xlsx", sheet = "Hourly Readings")

    # strip non-numeric characters from MecRox No. so IDs match across sheets
        plymouth_patients <- plymouth_patients %>%
            mutate(`MecRox No.` = gsub("[^0-9]", "", `MecRox No.`))
        plymouth_hourly <- plymouth_hourly %>%
            mutate(`MecRox No.` = gsub("[^0-9]", "", `MecRox No.`))

    # exclude patient 101
        plymouth_patients <- plymouth_patients %>%
            filter(`MecRox No.` != "101")
        plymouth_hourly <- plymouth_hourly %>%
            filter(`MecRox No.` != "101")

    # bring patient-level randomisation info onto each hourly reading and rename
    # columns to match the main UKRoxData variable names
        plymouth_patients_ukrox <- plymouth_patients %>%
            select(`MecRox No.`, IMVStart = `IMV Start`, UKRoxTime = `UK ROX Enrolled`)

        # UK ROX Enrolled is sometimes read as character (mix of Excel serial
        # numbers and stray text) rather than a parsed date-time, depending on
        # the cell formatting in the source spreadsheet - only convert from an
        # Excel serial number when it wasn't already parsed as a date-time
        if (!inherits(plymouth_patients_ukrox$UKRoxTime, "POSIXct")) {
            plymouth_patients_ukrox <- plymouth_patients_ukrox %>%
                mutate(UKRoxTime = as.POSIXct(as.numeric(UKRoxTime) * 86400, origin = "1899-12-30", tz = "UTC"))
        }

        plymouth_hourly <- plymouth_hourly %>%
            left_join(
                plymouth_patients_ukrox,
                by = "MecRox No."
            ) %>%
            rename(MECROXStudy = `MecRox No.`, SpO2Value = `SpO2 (%)`) %>%
            mutate(
                # exact SpO2 reading time when recorded, otherwise fall back to the hour of the shift
                SpO2Time = as.POSIXct(paste(as.Date(`Date (best estimate)`), coalesce(`SpO2 reading time`, sprintf("%02d:00", Hour))), format = "%Y-%m-%d %H:%M"),
                # ABG (PaO2/FiO2) reading time, when recorded
                PFRatioTime = as.POSIXct(paste(as.Date(`Date (best estimate)`), `ABG reading time`), format = "%Y-%m-%d %H:%M"),
                # PF ratio (kPa) = PaO2 (kPa) / FiO2 (fraction), matching the units used in the main UK-ROX dataset
                PFRatioValue = `PaO2 (kPa)` / (`FiO2 (%)` / 100),
                # match treatment arm labels used in the main UK-ROX dataset
                Treatment = recode(Treatment, "Control" = "Usual", "Intervention" = "Conservative"),
                IMVStart  = format(IMVStart, "%Y-%m-%d %H:%M"),
                UKRoxTime = format(UKRoxTime, "%Y-%m-%d %H:%M"),
                SpO2Time  = format(SpO2Time, "%Y-%m-%d %H:%M")
            )

    #clean data
    plymouth_data <- plymouth_hourly %>%
        #select only relevant variables
        select( MECROXStudy, IMVStart, UKRoxTime, SpO2Time, SpO2Value, Treatment) %>%
        filter( !is.na(MECROXStudy), !is.na(SpO2Time), !is.na(SpO2Value)) %>%
        mutate( SpO2Value = as.numeric(SpO2Value))

    #### addition of PF ratio data
    plymouth_data_pfratio <- plymouth_hourly %>%
        select(MECROXStudy, UKRoxTime, IMVStart, Treatment, PFRatioTime, PFRatioValue) %>%
        filter(!is.na(PFRatioTime), !is.na(PFRatioValue))
