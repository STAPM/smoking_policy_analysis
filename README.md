# Example workflow for smoking policy analysis
The code in this repo is part of the STAPM programme of modelling. STAPM was created as part of a programme of work on the health economics of tobacco and alcohol at the School of Health and Related Research (ScHARR), The University of Sheffield. This programme is based around the construction of the Sheffield Tobacco and Alcohol Policy Model (STAPM), which aims to use comparable methodologies to evaluate the impacts of tobacco and alcohol policies, and investigate the consequences of clustering and interactions between tobacco and alcohol consumption behaviours. See the [STAPM webpage](https://stapm.gitlab.io/).   

The code in this repo is designed to support our analyst team to understand how to run the model for the purposes of understanding the effects of smoking policies - by providing a worked example of the entire workflow. This example shows how to model the effect of a policy that changes either the proportion of smokers in the population. Outcomes are forecast over the remaining lifetimes of the people who are exposed to the policy change.   

Developments are still being worked through, so the code in this repo is likely to change. The code and documentation are still undergoing internal review by the analyst team. At the moment only members of our project team are able to run this code because it depends on a number of private R packages.    

## Code
The code depends on a number of private R packages. To access these packages you will need to sign-up for a Gitlab account and then let Duncan Gillespie know your username so that you can be added to our team. You can then install the packages by running the code file `src/05_install_packages.R`. Note that you will need to replace the username in the code with your own and you will then need to type your Gitlab password into the box when it appears. See our [range of R packages](https://stapm.gitlab.io/software.html).       

To run the model yourself, you will need to 'clone' the code in this repo to your own computer -- we have made [a video to show how to do this](https://digitalmedia.sheffield.ac.uk/media/1_ji3vrs1s). If you can get this example running on your own machine, then you are ready to move onto more complex things that can be done with the smoking model.      

## Data
There are two options for getting access to the data required to run the code in this repo.  

**If you want to create the data inputs from the raw data**, then you will need to be given access to the University of Sheffield's X-drive folders `PR_Consumption_TA` and `PR_mortality_data_TA`. This will allow you to run the code files `10_clean_hse.R`, `15_prep_mortality.R` and `20_estimate_smoking_transition_probabilities.R`.    

**You can use ready-made data to run the model**. The data files that you will need are stored in the X-drive folder `PR_STAPM/Data/smoking_forecast`. Copy the files there to the folder `intermediate_data`. You can then run the code `30_run_simulation.R` without having to run the code files that create the data inputs.  

The **inputs** are:   

1.  A population data sample with details of tobacco consumption from the Health Survey for England. These data are for ages 11--89 years and years 2001--2016. The data have had missing values for key socio-economic variables imputed.   
2.  Smoking transition probabilities - three files covering smoking initiation, quitting and relapse.   
3.  Cause-specific rates of mortality that have been forecast into the future.  

## Model processes
The model is run by the function `stapmr::SmokeSim_forecast()`. This function can recapitulate the past trends in smoking observed in the HSE, allowing validation of the model predictions against the observed data. It also allows the forecasting of future smoking, based on our forecasts of the continuing trends in mortality and in the smoking transition probabilities.    

The smoking model is an individual-based simulation of the population dynamics of smoking (see the [mathematical model framework](https://stapm.gitlab.io/stapmr/articles/smoking_model_maths.html)). The model simulates individual movements among current, former and never smoking states as they age. The simulation proceeds in one year time steps. At each time step, a sample of new individuals are added to the simulated population at the youngest age of 11 years. In each year of the simulation, **survival** is simulated by assigning each individual a relative risk for each disease based on their smoking state; individuals are then removed from the population according to their probabilities of death from each disease, accounting for differential risk by smoking status. **Behaviour change** is simulated in terms of individual transitions among smoking states, and time since quitting for former smokers is updated; each individual is assigned the smoking transition probability that matches their age, sex and IMD quintile for the year being simulated. **Demographic change** is simulated by ageing individuals by one year, and adding new individuals at the youngest age; the number of individuals added at the youngest age in each year is proportional to either the observed or [projected population sizes](https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationprojections) (based on the primary population projection) for that age and year.    

The whole model is stratified by sex and socio-economic conditions (where we define socio-economic conditions in terms of Index of Multiple Deprivation quintiles).     

## Health economic evaluation and appraisal
A partial cost-benefit analysis approach is taken, with valuation of population health effects (quality adjusted life years (QALYs)) and the direct monetary costs to the NHS of smoking-related secondary care treatment (hospital admitted patient care). The default setting in STPM is to discount both QALYs and healthcare costs at 3.5\%.  

### Health states
Since we consider 52 smoking related diseases, there would be a vast array of health states if we attempted to track all co-morbid disease combinations. Therefore, to track how morbidity responds to changes in smoking, we define health states in terms of **person-specific single morbidity** (PSSM), which means that **we assign each individual to one of 53 mutually exclusive health states, one for each smoking-related disease and one for "no smoking-related diseases". To estimate the distribution of individuals among these PSSM health states, we use data from the Admitted Patient Care component of the Hospital Episode Statistics (HES) of patients in England.    

### Hospital admissions
For individuals assigned to each tobacco-related disease, we use the HES data to calculate the average number of times in a year that they would be expected to have an admission to hospital associated with that disease. We refer to this as the **multiplier** because multiplying it by the number of individuals in each health state gives the total number of admissions associated with that health state in a year.   

### Costs of hospital care
The unit costs used in STPM consider only the costs of episodes of care within the admission that have a primary diagnosis matching the disease assigned to the admission. Unit costs for episodes of care were derived from the NHS reference costs, which we linked to resource use codes in HES produced by the Secondary Uses Service (SUS) under the national system for reimbursement of care costs. Additional costs were included for days in bed beyond the number considered standard in the reference costs.    

For chemotherapy, radiotherapy and renal dialysis, many episodes are assigned a zero cost code for same day treatment. For episodes with a primary diagnosis of cancer, we added chemotherapy and/or radiotherapy costs, as these are costed separately as high-cost treatments. For episodes with a primary diagnosis of chronic kidney disease or end-stage renal failure, we included additional renal dialysis costs. Episodes therefore include a cost based on the SUS generated code and one or more procedures.   

### Health state utilities
To value health outcomes, a quality adjusted life years (QALY) approach is used. Health state utility values (HSUV) are estimated for each of the 53 health states in STPM (one for each of the 52 smoking-related diseases and one for "no smoking-related diseases").       

HSUVs are estimated using the [EQ-5D](https://euroqol.org/eq-5d-instruments/), a widely used generic quality of life instrument. Utility scores usually range between 1 (perfect health) and 0 (a state equivalent to death), though it is possible for some extreme conditions to be valued as worse than death. The utility scores are an expression of societal preference for health states.     

## Modelling policy effects on costs and QALYs
To estimate how a policy or intervention changes the distribution of individuals among health states, STPM simulates a version of the population in which smoking has changed due to the policy or intervention (the 'treatment' arm) and a version of the population in which smoking is unaffected (the 'control' or 'business-as-usual' arm). To minimise the variance in the comparison, we keep the random components of the simulation the same between the control and treatment arms (by using the same random seeds).      

Changes to the distribution of individuals among health states are then estimated based on the **potential impact fraction** ($PIF$), which we take to represent the proportion of people who move from each smoking-related health state to the "no smoking-related diseases" health state. The $PIF$ summarises the difference between the treatment and control arms in the relative risks of smoking-related disease (that differ between arms due to the difference in the distribution of individuals among smoking states).

## Distributional effects
Population size, the distribution of individuals among smoking states and their distribution among health states are all stratified by period, age, sex and IMD quintile. The relative risks of smoking-related disease associated with each smoking state are generally held constant, except for Ischaemic Heart Disease and Stroke, for which the best available evidence was stratified by age and sex. The paramaters that we use to estimate the change to costs and QALYs (number and unit costs of hospital admissions, and health state utility values) are held constant over time in order to focus on the effects of changes to smoking, and to express results in terms of a particular cost-year. Our health state utility values are currently stratified by age and sex but not IMD quintile, but this could be addressed in future versions of STPM.

## Output
There are are range of outputs of the code in this repo that show the effects on:   
### Population trajectories of smoking behaviour

- The proportion of the population who currently smoke (i.e. smoking prevalence) and by extension the number of smokers.   
- The proportion of ever-smokers at ages 12--89, i.e. considering all ages in our simulation rather than just particular index ages.  
- Quit ratios at ages 12--89, which are the number of former smokers divided by the number of ever smokers, and indicate the extent to which everybody who started to smoke has now quit.   

### Mortality
We present mortality effects in terms of the change to the distribution of deaths among causes and the corresponding changes to the remaining years of life lost to death.    

### Health and economic effects

- Years of life lived, with and without adjusting each year of life for its estimated utility (see Section \@ref(utilitydata)).           

- The prevalence of smoking related diseases (in terms of the number of person-specific hospitalisations), number of hospital admissions, and the cost of hospital admissions to the NHS (see Section \@ref(hesdata)).    

We disaggregate health effects into the outcomes observed for cancers, cardiovascular, respiratory, mental health, kidney disease, type II diabetes, other adult diseases, and diseases that are less common due to smoking (i.e. for which smoking has protective effects). In our default reporting of results we do not assign quality adjusted life years (QALYs) a financial value in £. We discount costs and QALYs by 3.5\%.      

### Timeframes of reporting {#timeframes}
The time-trend nature of our analysis means that we can report findings in terms of graphs that show the annual effect-size and the annual cumulative effect size. For the purposes of clear communication of findings (and results tables) of policy effects, we also report these effects at key time-points: 1, 5 and 10 years after policy implementation, and the lifetime effect or "full effect" that we define as the year when someone aged 12 in the first cohort exposed to the policy reached the oldest age in our model (i.e. $89 - 12 = 77$ years from baseline, so to assess a policy introduced in 2016 would require a population project to 2093).    

## Distributional effects
The primary stratification variables in STPM are age-group (which for our default reporting we define as 12-19, 20-29, 30-49, 50-69, 70-89), sex and IMD quintile. In our default reporting, we investigate distributional effects across two sets of 10 subgroups: combinations of our default age-groups and sex; combinations of IMD quintiles and sex.  

It is important to bear in mind that distributional effects are likely to change over time after implementation of the policy e.g. as delayed effects on diseases emerge. Our primary reporting of distributional effects is based on the UK's current smokefree target of 2030, but where appropriate we report the distributional effects at different time points.  

Summaries of the socio-economic inequalities in policy effects are an important communication tool. There are a range of metrics to choose from when it comes to computing these summaries. Currently in STPM, we report absolute inequality across IMD quintiles in terms of the Slope Index of Inequality (SII), and relative inequality in terms the Relative Index of Inequality (RII), which is derived from the SII.    



