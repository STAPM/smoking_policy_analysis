
# The aim of this code is to make some basic plots to 
# view the effects of the policy on mortality

library(data.table)
library(stapmr)
library(ggplot2)
library(mort.tools)

# Distribution effects by year, sex and disease group

mort_data <- MortCalc(
  path = "output/",
  label = "policytest",
  two_arms = TRUE,
  baseline_year = 2002,
  baseline_population_size = 1e5,
  #strat_vars = c("age", "year", "sex", "imd_quintile", "condition"))
  strat_vars = c("year", "sex", "condition"))

mort_data[ , `:=`(n_deaths_diff = n_deaths_treatment - n_deaths_control,
                  yll_diff = yll_treatment - yll_control)]

saveRDS(mort_data, "output/mort_data_year_sex_condition.rds")

# Years of life lost plot

yll_temp <- mort_data[year %in% 2014:2091]

yll_temp <- merge(yll_temp, tobalcepi::disease_groups, by = "condition")

yll_temp <- yll_temp[disease_type != "Less_common"]

yll_temp <- yll_temp[ , .(yll_diff = sum(yll_diff)), by = c("year", "sex", "disease_type")]

yll_temp[ , disease_type := plyr::revalue(disease_type, c(
  "Mental_health" = "Other adult diseases",
  "Other" = "Other adult diseases",
  "Less_common" = "Other adult diseases",
  "Kidney_disease" = "Other adult diseases",
  "Type_II_diabetes" = "Other adult diseases"))]

yll_temp[ , disease_type := factor(disease_type, levels = c("Other adult diseases", "Respiratory","Cardiovascular", "Cancers"))]

yll_temp[ , yll_diff_temp := yll_diff]
yll_temp[yll_diff_temp > 0, yll_diff_temp := 0]
yll_temp[sex == "Male", yll_diff_temp := -yll_diff_temp]

ggplot(yll_temp) +
  geom_bar(aes(x = year, y = yll_diff_temp / 1e3, fill = disease_type), stat = "identity", position = "stack") +
  geom_hline(yintercept = 0) +
  ylab("Difference in life years lost / thousand") +
  scale_y_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 15), labels = c(-15, -10, -5, 0, -5, -10, -15)) +
  coord_flip() +
  theme_minimal() +
  geom_text(aes(x = 2090, y = -5), label = "Female", size = 4) +
  geom_text(aes(x = 2090, y = 5), label = "Male", size = 4) +
  scale_fill_manual(name = "Type", values = c('#e7298a','#66a61e','#e6ab02','#a6761d','#666666')) +
  NULL

# Distribution effects by year, sex and IMD quintile

mort_data <- MortCalc(
  path = "output/",
  label = "policytest",
  two_arms = TRUE,
  baseline_year = 2002,
  baseline_population_size = 3e5,
  strat_vars = c("year", "sex", "imd_quintile"))

mort_data[ , `:=`(n_deaths_diff = n_deaths_treatment - n_deaths_control,
                  yll_diff = yll_treatment - yll_control)]

saveRDS(mort_data, "output/mort_data_year_sex_imd_quintile.rds")

# Years of life lost plot
mort_data <- readRDS("model_runs/prevalenceanalysis/mort_data_year_sex_imd_quintile.rds")

yll_temp <- mort_data[year %in% 2014:2091]

yll_temp[ , yll_diff_temp := yll_treatment - yll_control]
yll_temp[yll_diff_temp > 0, yll_diff_temp := 0]
yll_temp[sex == "Male", yll_diff_temp := -yll_diff_temp]

ggplot(yll_temp) +
  geom_bar(aes(x = year, y = yll_diff_temp / 1e3, fill = imd_quintile), stat = "identity", position = "stack") +
  geom_hline(yintercept = 0) +
  ylab("Difference in life years lost / thousand") +
  scale_y_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 15), labels = c(-15, -10, -5, 0, -5, -10, -15)) +
  coord_flip() +
  theme_minimal() +
  geom_text(aes(x = 2090, y = -5), label = "Female", size = 4) +
  geom_text(aes(x = 2090, y = 5), label = "Male", size = 4) +
  scale_fill_manual(name = "IMD quintile", values = c("#fcc5c0", "#fa9fb5", "#f768a1", "#c51b8a", "#7a0177")) +
  NULL


# Cumulative effect on years of life lost by year, sex and IMD quintile

mort_data <- readRDS("model_runs/prevalenceanalysis/mort_data_year_sex_imd_quintile.rds")

yll_temp <- mort_data[year %in% 2014:2091]

yll_temp[ , yll_diff := yll_treatment - yll_control]

yll_temp[ , cum_diff := cumsum(yll_diff), by = c("sex", "imd_quintile")]

yll_temp[cum_diff > 0, cum_diff := 0]
yll_temp[sex == "Male", cum_diff := -cum_diff]

ggplot() +
  geom_area(data = yll_temp[sex == "Male"], aes(x=year, y=cum_diff / 1e3, fill = imd_quintile)) +
  geom_area(data = yll_temp[sex == "Female"], aes(x=year, y=cum_diff / 1e3, fill = imd_quintile)) +
  geom_hline(yintercept = 0) +
  scale_y_continuous(breaks = c(-200, -100, 0, 100, 200), labels = c(-200, -100, 0, -100, -200)) +
  coord_flip() +
  theme_minimal() +
  ylab("Cumulative difference in years of life lost / thousand") +
  scale_fill_manual(name = "IMD quintile", values = c("#fcc5c0", "#fa9fb5", "#f768a1", "#c51b8a", "#7a0177")) +
  geom_text(aes(x = 2095, y = -150), label = "Female", size = 4) +
  geom_text(aes(x = 2095, y = 150), label = "Male", size = 4) +
  NULL

# Table

mort_data <- readRDS("output/mort_data_year_sex_imd_quintile.rds")

yll_temp <- mort_data[year %in% 2014:2091]

yll_temp[ , yll_diff := yll_treatment - yll_control]

yll_temp[ , cum_diff := round(cumsum(yll_diff), 0), by = c("sex", "imd_quintile")]

mort_tab <- yll_temp[year %in% c(2035, 2091), c("year", "sex", "imd_quintile", "cum_diff")]
mort_tab <- dcast(mort_tab, sex + imd_quintile ~ year, value.var = "cum_diff")

mort_tab[ , imd_quintile := plyr::revalue(imd_quintile, c(
  "1_least_deprived" = "1 (least deprived)",
  "5_most_deprived" = "5 (most deprived)"
))]

setnames(mort_tab, c("sex", "imd_quintile"), c("Sex", "IMD quintile"))

write.table(mort_tab, "output/dist_effects_yll.csv", row.names = F, sep = ",")


  

