
# The aim of this code is to make some basic plots to 
# view the effects of the policy

library(data.table)
library(stapmr)
library(ggplot2)

# Utility data
utility_data <- readRDS("intermediate_data/utility_data.rds")

# Hospital care unit cost data
unit_cost_data <- readRDS("intermediate_data/unit_cost_data.rds")

# Hospital care multiplier data
multiplier_data <- readRDS("intermediate_data/multiplier_data.rds")

# Calculate health outcomes
health_data <- HealthCalc(path = "output/", 
                          label = "policytest",
                          two_arms = TRUE,
                          baseline_year = 2002,
                          baseline_population_size = 1e5,
                          multiplier_data = multiplier_data,
                          unit_cost_data = unit_cost_data,
                          utility_data = utility_data,
                          strat_vars = c("year", "sex"))

saveRDS(health_data, "output/health_data_by_year_sex.rds")

hosp_temp <- copy(health_data$hosp_data)

hosp_temp <- hosp_temp[year %in% 2014:2091]

hosp_temp <- merge(hosp_temp, tobalcepi::disease_groups, by = "condition")

hosp_temp <- hosp_temp[disease_type != "Less_common"]

hosp_temp <- hosp_temp[ , .(admission_cost = sum(admission_cost)), by = c("year", "sex", "disease_type", "arm")]

hosp_temp <- dcast(hosp_temp, year + sex + disease_type ~ arm, value.var = "admission_cost")

index_year <- 2014

hosp_temp[ , years_since_index := year - index_year,]

hosp_temp[ , admis_cost_change := 0]
hosp_temp[ , admis_cost_change := (treatment - control) * (1 / ((1 + 0.035) ^ years_since_index))]

hosp_temp[ , disease_type := plyr::revalue(disease_type, c(
  "Mental_health" = "Other adult diseases",
  "Other" = "Other adult diseases",
  #"Less_common" = "Other adult diseases",
  "Kidney_disease" = "Other adult diseases",
  "Type_II_diabetes" = "Other adult diseases"))]

hosp_temp[ , disease_type := factor(disease_type, levels = c("Other adult diseases", "Respiratory","Cardiovascular", "Cancers"))]

hosp_temp[ , admis_cost_change_temp := admis_cost_change]
hosp_temp[admis_cost_change_temp > 0, admis_cost_change_temp := 0]
hosp_temp[sex == "Male", admis_cost_change_temp := -admis_cost_change_temp]

ggplot(hosp_temp) +
  geom_bar(aes(x = year, y = admis_cost_change_temp / 1e6, fill = disease_type), stat = "identity", position = "stack") +
  geom_hline(yintercept = 0) +
  ylab("Difference in hospitcal costs / Million") +
  scale_y_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 15), labels = c(-15, -10, -5, 0, -5, -10, -15)) +
  coord_flip() +
  theme_minimal() +
  geom_text(aes(x = 2085, y = -5), label = "Female", size = 4) +
  geom_text(aes(x = 2085, y = 5), label = "Male", size = 4) +
  scale_fill_manual(name = "Type", values = c('#e7298a','#66a61e','#e6ab02','#a6761d','#666666')) +
  NULL


# Annual hosp costs by sex and IMD quintile

health_data <- HealthCalc(path = "output/", 
                          label = "policytest",
                          two_arms = TRUE,
                          baseline_year = 2002,
                          baseline_population_size = 1e5,
                          multiplier_data = multiplier_data,
                          unit_cost_data = unit_cost_data,
                          utility_data = utility_data,
                          strat_vars = c("year", "sex", "imd_quintile"))

saveRDS(health_data, "output/health_data_by_year_sex_imd.rds")

hosp_temp <- copy(health_data$hosp_data)

hosp_temp <- hosp_temp[year %in% 2014:2091]

hosp_temp <- hosp_temp[ , .(admission_cost = sum(admission_cost)), by = c("year", "sex", "imd_quintile", "arm")]

hosp_temp <- dcast(hosp_temp, year + sex + imd_quintile ~ arm, value.var = "admission_cost")

index_year <- 2014

hosp_temp[ , years_since_index := year - index_year,]

hosp_temp[ , admis_cost_change := 0]
hosp_temp[ , admis_cost_change := (treatment - control) * (1 / ((1 + 0.035) ^ years_since_index))]

hosp_temp[ , admis_cost_change_temp := admis_cost_change]
hosp_temp[admis_cost_change_temp > 0, admis_cost_change_temp := 0]
hosp_temp[sex == "Male", admis_cost_change_temp := -admis_cost_change_temp]

hosp_temp[ , imd_quintile := plyr::revalue(imd_quintile, c(
  "1_least_deprived" = "1 (least deprived)",
  "5_most_deprived" = "5 (most deprived)"
))]

ggplot(hosp_temp) +
  geom_bar(aes(x = year, y = admis_cost_change_temp / 1e6, fill = imd_quintile), stat = "identity", position = "stack") +
  geom_hline(yintercept = 0) +
  ylab("Difference in hospitcal costs / Million") +
  scale_y_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 15), labels = c(-15, -10, -5, 0, -5, -10, -15)) +
  coord_flip() +
  theme_minimal() +
  geom_text(aes(x = 2085, y = -5), label = "Female", size = 4) +
  geom_text(aes(x = 2085, y = 5), label = "Male", size = 4) +
  scale_fill_manual(name = "IMD quintile", values = c("#fcc5c0", "#fa9fb5", "#f768a1", "#c51b8a", "#7a0177")) +
  NULL


# Results table of hospital costs

health_data <- readRDS("output/health_data_by_year_sex_imd.rds")

hosp_temp <- copy(health_data$hosp_data)

hosp_temp <- hosp_temp[year %in% 2014:2091]

hosp_temp <- hosp_temp[ , .(admission_cost = sum(admission_cost)), by = c("year", "sex", "imd_quintile", "arm")]

hosp_temp <- dcast(hosp_temp, year + sex + imd_quintile ~ arm, value.var = "admission_cost")

index_year <- 2014

hosp_temp[ , years_since_index := year - index_year,]

hosp_temp[ , admis_cost_change := 0]
hosp_temp[ , admis_cost_change := (treatment - control) * (1 / ((1 + 0.035) ^ years_since_index))]

hosp_temp[ , cum_cost := round(cumsum(admis_cost_change), 0), by = c("sex", "imd_quintile")]

hosp_tab <- hosp_temp[year %in% c(2035, 2091), c("year", "sex", "imd_quintile", "cum_cost")]
hosp_tab <- dcast(hosp_tab, sex + imd_quintile ~ year, value.var = "cum_cost")

hosp_tab[ , imd_quintile := plyr::revalue(imd_quintile, c(
  "1_least_deprived" = "1 (least deprived)",
  "5_most_deprived" = "5 (most deprived)"
))]

setnames(hosp_tab, c("sex", "imd_quintile"), c("Sex", "IMD quintile"))

write.table(hosp_tab, "output/hosp_cost_effects.csv", row.names = F, sep = ",")


## QALYs

health_data <- readRDS("output/health_data_by_year_sex_imd.rds")

qaly_temp <- copy(health_data$qaly_data)

qaly_temp <- qaly_temp[year %in% 2014:2091]

qaly_temp <- dcast(qaly_temp, year + sex + imd_quintile ~ arm, value.var = "qaly_total")

index_year <- 2014

qaly_temp[ , years_since_index := year - index_year,]

qaly_temp[ , qaly_change := 0]
qaly_temp[year >= index_year, qaly_change := (treatment - control) * (1 / ((1 + 0.035) ^ years_since_index))]

qaly_temp[ , qaly_change_temp := qaly_change]
qaly_temp[qaly_change_temp < 0, qaly_change_temp := 0]
qaly_temp[sex == "Female", qaly_change_temp := -qaly_change_temp]

qaly_temp[ , imd_quintile := plyr::revalue(imd_quintile, c(
  "1_least_deprived" = "1 (least deprived)",
  "5_most_deprived" = "5 (most deprived)"
))]

ggplot(qaly_temp) +
  geom_bar(aes(x = year, y = qaly_change_temp / 1e3, fill = imd_quintile), stat = "identity", position = "stack") +
  geom_hline(yintercept = 0) +
  ylab("Difference in QALYs / thousand") +
  scale_y_continuous(breaks = c(-4, -3, -2, -1, 0, 1, 2, 3, 4), labels = c(-4, -3, -2, -1, 0, -1, -2, -3, -4)) +
  coord_flip() +
  theme_minimal() +
  geom_text(aes(x = 2085, y = -3), label = "Female", size = 4) +
  geom_text(aes(x = 2085, y = 3), label = "Male", size = 4) +
  scale_fill_manual(name = "IMD quintile", values = c("#fcc5c0", "#fa9fb5", "#f768a1", "#c51b8a", "#7a0177")) +
  NULL

# Results table of QALYs

health_data <- readRDS("output/health_data_by_year_sex_imd.rds")

qaly_temp <- copy(health_data$qaly_data)

qaly_temp <- qaly_temp[year %in% 2014:2091]

qaly_temp <- dcast(qaly_temp, year + sex + imd_quintile ~ arm, value.var = "qaly_total")

index_year <- 2014

qaly_temp[ , years_since_index := year - index_year,]

qaly_temp[ , qaly_change := 0]
qaly_temp[year >= index_year, qaly_change := (treatment - control) * (1 / ((1 + 0.035) ^ years_since_index))]

qaly_temp[ , cum_qaly_change := round(cumsum(qaly_change), 0), by = c("sex", "imd_quintile")]

qaly_tab <- qaly_temp[year %in% c(2035, 2091), c("year", "sex", "imd_quintile", "cum_qaly_change")]
qaly_tab <- dcast(qaly_tab, sex + imd_quintile ~ year, value.var = "cum_qaly_change")

qaly_tab[ , imd_quintile := plyr::revalue(imd_quintile, c(
  "1_least_deprived" = "1 (least deprived)",
  "5_most_deprived" = "5 (most deprived)"
))]

setnames(qaly_tab, c("sex", "imd_quintile"), c("Sex", "IMD quintile"))

write.table(qaly_tab, "output/qaly_effects.csv", row.names = F, sep = ",")








  
  

