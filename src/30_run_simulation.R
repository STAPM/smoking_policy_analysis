
# The aim of this code is to run the simulation of smoking prevalence

library(data.table)
library(stapmr)
library(tobalcepi)

# Load data ----------------

# Load the prepared data on tobacco consumption
survey_data <- readRDS("intermediate_data/HSE_2001_to_2016_tobacco_imputed.rds")

# Transition probabilities
init_data <- readRDS("intermediate_data/init_data.rds")
quit_data <- readRDS("intermediate_data/quit_data.rds")
relapse_data <- readRDS("intermediate_data/relapse_data.rds")

# Mortality data
mort_data <- readRDS("intermediate_data/tob_mort_data_cause.rds")

# Construct the variables by which the policy effect could vary
effect_data <- data.frame(expand.grid(
  sex = c("Male", "Female"),
  ageband = c("<18", "18-24", "25-34", "35-44", "45-54", "55-64", "65+"),
  imd_quintile = c("1_least_deprived", "2", "3", "4", "5_most_deprived"),
  year = 2001:2100
))
setDT(effect_data)

# Set the policy effect
policy_effect_period <- 2013:2014

effect_data[ , rel_change := 1]
effect_data[year %in% policy_effect_period, rel_change := 0.95]


# Run simulation ----------------


testrun <- SmokeSim_prevadj(
  survey_data = survey_data,
  init_data = init_data,
  quit_data = quit_data,
  relapse_data = relapse_data,
  mort_data = mort_data,
  baseline_year = 2010,
  baseline_sample_years = 2009:2011, # synth pop is drawn from 3 years
  time_horizon = 2017,
  pop_size = 1e5, # 200,000 people is about the minimum to reduce noise for a single run
  pop_data = stapmr::pop_counts,
  two_arms = TRUE,
  policy_effect_period = policy_effect_period,
  rel_change_data = effect_data,
  seed_sim = NULL,
  pop_seed = 1,
  iter = NULL,
  write_outputs = "output",
  label = "policytest"
)

# Check the "output" folder for the saved model outputs
# these are forecast individual-level data on smoking
# and forecast mortality rates











