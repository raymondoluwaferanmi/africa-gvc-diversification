## Paper: GVC Participation and Industrial Diversification in Africa
## Author: Raymond Oluwaferanmi
## Purpose: Download World Bank controls + Harvard ECI, merge into a panel
## Inputs: WDI API, Atlas ECI CSV (data/raw/eci_country_year.csv)
## Outputs: data/processed/panel_controls_eci.rds

library(here)
i_am("R/01_download_wdi.R")

library(WDI)
library(dplyr)
library(tidyr)
library(readr)
library(countrycode)

# ---------------------------------------------------------------
# 1. Download World Bank controls
# ---------------------------------------------------------------

africa_iso2 <- c(
  "DZ","AO","BJ","BW","BF","BI","CV","CM","CF","TD","KM","CG","CD","CI",
  "DJ","EG","GQ","ER","SZ","ET","GA","GM","GH","GN","GW","KE","LS","LR",
  "LY","MG","MW","ML","MR","MU","MA","MZ","NA","NE","NG","RW","ST","SN",
  "SC","SL","SO","ZA","SS","SD","TZ","TG","TN","UG","ZM","ZW"
)

controls <- WDI(
  country   = africa_iso2,
  indicator = c(
    gdp_pc      = "NY.GDP.PCAP.KD",
    population  = "SP.POP.TOTL",
    trade_open  = "NE.TRD.GNFS.ZS",
    industry_va = "NV.IND.TOTL.ZS"
  ),
  start = 2000,
  end   = 2023
) %>%
  select(iso2c, country, year, gdp_pc, population, trade_open, industry_va)

# ---------------------------------------------------------------
# 2. Load ECI data
# ---------------------------------------------------------------

eci_path <- here("data", "raw", "eci_country_year.csv")

if (file.exists(eci_path)) {
  eci <- read_csv(eci_path, show_col_types = FALSE) %>%
    select(
      iso3_code = country_iso3_code,
      year,
      eci      = eci_hs12,
      eci_rank = eci_rank_hs12
    ) %>%
    mutate(iso2c = countrycode(iso3_code, origin = "iso3c",
                               destination = "iso2c")) %>%
    filter(!is.na(iso2c))
} else {
  message("ECI file not found at ", eci_path)
  eci <- NULL
}

# ---------------------------------------------------------------
# 3. Merge
# ---------------------------------------------------------------

if (!is.null(eci)) {
  panel <- controls %>%
    left_join(eci %>% select(iso2c, year, eci, eci_rank),
              by = c("iso2c", "year"))
} else {
  panel <- controls
  panel$eci <- NA_real_
  panel$eci_rank <- NA_real_
}

# ---------------------------------------------------------------
# 4. Save
# ---------------------------------------------------------------

dir.create(here("data", "processed"), showWarnings = FALSE, recursive = TRUE)
saveRDS(panel, here("data", "processed", "panel_controls_eci.rds"))

cat("Rows:", nrow(panel), "\n")
cat("Countries:", n_distinct(panel$iso2c), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("Non-missing ECI rows:", sum(!is.na(panel$eci)), "\n")
cat("Non-missing GDP pc rows:", sum(!is.na(panel$gdp_pc)), "\n")
