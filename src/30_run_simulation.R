
# The aim of this code is to run the simulation of a policy effect on smoking prevalence

# This is the example used in the first version of the STPM technical report

library(data.table)
library(stapmr)
library(tobalcepi)


#####################################################
# Load data ----------------

# Load the prepared data on tobacco consumption
survey_data <- readRDS("intermediate_data/HSE_2001_to_2016_tobacco_imputed.rds")

# Transition probabilities
init_data <- readRDS("intermediate_data/init_data.rds")
quit_data <- readRDS("intermediate_data/quit_data.rds")
relapse_data <- readRDS("intermediate_data/relapse_data.rds")

# Mortality data
mort_data <- readRDS("intermediate_data/tob_mort_data_cause.rds")

# Morbidity data
morb_data <- readRDS("intermediate_data/morb_rates.rds")


#####################################################
# Prepare policy effect ----------------

# Construct the variables by which the policy effect could vary
effect_data <- data.frame(expand.grid(
  sex = c("Male", "Female"),
  ageband = c("<18", "18-24", "25-34", "35-44", "45-54", "55-64", "65+"),
  imd_quintile = c("1_least_deprived", "2", "3", "4", "5_most_deprived"),
  year = 2001:2100
))
setDT(effect_data)

# Set the policy effect
k_2014 <- -0.05
k_2015 <- -0.1

effect_data[ , rel_change := 1]
effect_data[year == 2014, rel_change := 1 + k_2014]
effect_data[year == 2015, rel_change := 1 + k_2015]


#####################################################
# Run simulation ----------------

testrun <- SmokeSim(
  survey_data = survey_data,
  init_data = init_data,
  quit_data = quit_data,
  relapse_data = relapse_data,
  mort_data = mort_data,
  morb_data = morb_data,
  baseline_year = 2002,
  baseline_sample_years = 2001:2003,
  time_horizon = 2050,
  trend_limit_morb = 2016,
  trend_limit_mort = 2016,
  trend_limit_smoke = 2016,
  pop_size = 1e5, # 200,000 people is about the minimum to reduce noise for a single run
  two_arms = TRUE,
  policy_effect_period = 2014:2015,
  rel_change_data = effect_data,
  write_outputs = "output",
  label = "policytest"
)

# Check the "output" folder for the saved model outputs
# these are forecast individual-level data on smoking
# and forecast mortality and morbidity rates











