
# The aim of this code is to make some basic plots to 
# view the effects of the policy on smoking trajectories

library(data.table)
library(stapmr)
library(ggplot2)


###################################################################
# Overall policy effects by year

# Read the smoking simulation results
smk_data <- ReadSim(root = "output/smk_data_", two_arms = TRUE, label = "policytest")

# Summarise smoking behaviour
smoke_stats <- SmkEffects(
  data = smk_data,
  strat_vars = c("year"),
  two_arms = TRUE)

saveRDS(smoke_stats, "output/smoke_prev_by_year.rds")

png("output/overall_policy_effects.png", units="in", width=7, height=7, res=300)
ggplot(smoke_stats$prevalence) +
  geom_line(aes(x = year, y = 100 * smk_prev, linetype = arm), size = .4) +
  ylim(0, 30) + ylab("percentage smokers") +
  theme_minimal() +
  labs(title = "Policy effects on percentage smokers",
       subtitle = "Considering people aged 11-89 years", 
       caption = "The policy was assumed to have reduced the number of smokers 
       in each subgroup of age, sex and IMD quintile by 5% in 2014 and 10% in 2015. 
       The 'treatment' arm shows the predicted effects of policy introduction.")
dev.off()


###################################################################
# Policy effects by age-group and sex

smk_data <- ReadSim(root = "output/smk_data_", two_arms = TRUE, label = "policytest")

smk_data[ , ageband := c("11-19", "20-29", "30-49", "50-69", "70-89")[findInterval(age, c(-10, 20, 30, 50, 70, 1000))]]

smoke_stats <- SmkEffects(
  data = smk_data,
  strat_vars = c("year", "ageband", "sex"),
  two_arms = TRUE)

saveRDS(smoke_stats, "output/smoke_prev_by_year_age_sex.rds")

png("output/policy_effects_by_age_and_sex.png", units="in", width=12, height=4, res=300)
ggplot(smoke_stats$prevalence) +
  geom_line(aes(x = year, y = 100 * smk_prev, linetype = arm, colour = sex), size = .4) +
  scale_colour_manual(name = "Sex", values = c('#6600cc','#00cc99')) +
  facet_wrap(~ ageband, nrow = 1) +
  ylim(0, 30) + ylab("percentage smokers") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45)) +
  labs(title = "Policy effects on percentage smokers",
       subtitle = "Considering people aged 11-89 years", 
       caption = "The policy was assumed to have reduced the number of smokers in each subgroup of age, sex and IMD quintile by 5% in 2014 and 10% in 2015. 
       The 'treatment' arm shows the predicted effects of policy introduction.")
dev.off()


###################################################################
## Distributional effects

# Policy effects by IMD quintile and sex
smk_data <- ReadSim(root = "output/smk_data_", two_arms = TRUE, label = "policytest")

smoke_stats <- SmkEffects(
  data = smk_data,
  strat_vars = c("year", "imd_quintile", "sex"),
  two_arms = TRUE)

saveRDS(smoke_stats, "output/smoke_prev_by_year_imdq_sex.rds")

png("output/policy_effects_by_imdq_and_sex.png", units="in", width=12, height=4, res=300)
ggplot(smoke_stats$prevalence) +
  geom_line(aes(x = year, y = 100 * smk_prev, linetype = arm, colour = sex), size = .4) +
  scale_colour_manual(name = "Sex", values = c('#6600cc','#00cc99')) +
  facet_wrap(~ imd_quintile, nrow = 1) +
  ylim(0, 30) + ylab("percentage smokers") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45)) +
  labs(title = "Policy effects on percentage smokers",
       subtitle = "Considering people aged 11-89 years", 
       caption = "The policy was assumed to have reduced the number of smokers in each subgroup of age, sex and IMD quintile by 5% in 2014 and 10% in 2015. 
       The 'treatment' arm shows the predicted effects of policy introduction.")
dev.off()


###################################################################
# Difference in the number of smokers

smk_temp <- smoke_stats$prevalence[year %in% 2014:2035]

smk_temp <- dcast(smk_temp, year + sex + imd_quintile ~ arm, value.var = "n_smokers")

smk_temp[ , n_smokers_diff := treatment - control]

smk_temp <- smk_temp[ , c("year", "sex", "imd_quintile", "n_smokers_diff")]

smk_temp[ , n_smokers_diff_temp := n_smokers_diff]
smk_temp[sex == "Male", n_smokers_diff_temp := -n_smokers_diff_temp]

smk_temp[ , imd_quintile := plyr::revalue(imd_quintile, c(
  "1_least_deprived" = "1 (least deprived)",
  "5_most_deprived" = "5 (most deprived)"
))]

png("output/policy_effects_by_imdq_and_sex2.png", units="in", width=8, height=5, res=300)
ggplot(smk_temp) +
  geom_bar(aes(x = year, y = n_smokers_diff_temp / 1e3, fill = imd_quintile), stat = "identity", position = "stack") +
  geom_hline(yintercept = 0) +
  ylab("Difference in number of smokers / thousand") +
  scale_y_continuous(breaks = c(-400, -300, -200, -100, 0, 100, 200, 300, 400), labels = c(-400, -300, -200, -100, 0, -100, -200, -300, -400)) +
  coord_flip() +
  theme_minimal() +
  scale_fill_manual(name = "IMD quintile", values = c("#fcc5c0", "#fa9fb5", "#f768a1", "#c51b8a", "#7a0177")) +
  geom_text(aes(x = 2035, y = 250), label = "Female", size = 4) +
  geom_text(aes(x = 2035, y = -250), label = "Male", size = 4) + 
  labs(title = "Policy effects on number of smokers",
       subtitle = "Considering people aged 11-89 years", 
       caption = "The policy was assumed to have reduced the number of smokers in each subgroup 
       of age, sex and IMD quintile by 5% in 2014 and 10% in 2015.")
dev.off()

#smk_temp_tab <- dcast(smk_temp, sex + imd_quintile ~ year, value.var = "n_smokers_diff")

#setnames(smk_temp_tab, c("sex", "imd_quintile"), c("Sex", "IMD quintile"))

#write.table(smk_temp_tab, "output/dist_effects_n_smokers_diff.csv", row.names = F, sep = ",")


###################################################################
# Results table

smoke_stats <- readRDS("output/smoke_prev_by_year_imdq_sex.rds")$prevalence

smoke_stats <- smoke_stats[year %in% c(2015, 2035)]

smoke_stats <- dcast(smoke_stats, year + sex + imd_quintile ~ arm, value.var = "n_smokers")

smoke_stats[ , smokers_change := round(treatment - control, 0)]

smoke_stats <- smoke_stats[year %in% c(2015, 2035), c("year", "sex", "imd_quintile", "smokers_change")]
smoke_stats <- dcast(smoke_stats, sex + imd_quintile ~ year, value.var = "smokers_change")

smoke_stats[ , imd_quintile := plyr::revalue(imd_quintile, c(
  "1_least_deprived" = "1 (least deprived)",
  "5_most_deprived" = "5 (most deprived)"
))]

setnames(smoke_stats, c("sex", "imd_quintile"), c("Sex", "IMD quintile"))

write.table(smoke_stats, "output/smoke_effects.csv", row.names = F, sep = ",")











