# Flood frequency analysis
# developed by Mohamed Ahmed @ UCalgary
# Install the LMoFit package to fit different distributions to your data
# install.packages("LMoFit")
# Load the required the library
library('LMoFit')
library('tidyhydat')
library('reshape2')
library('ggplot2')
library('dplyr')

#set working directory
#setwd('C:/Labs/Lab_8_R_frequency_analysis')
# retrieve annual maximas for the Bow River watershed
ann_max_flow <- hy_annual_stats(station_number = '05BB001') %>% 
                filter(Sum_stat=='MAX', !is.na(Value), Parameter=='Flow')  #select MAX only
                
# select flows only as the sample
sample <- ann_max_flow$Value 
#estimate sample L-moments since we will be using the L-moments for fitting a distribution 
#(i.e., we want the distribution L-moments to match the sample L-moments).
samlmoms <- get_sample_lmom(x = sample) 
samlmoms
# This function returns a dataframe containting the following:
# 1st l-moment: Mean
# 2nd l-moment: Variance σ^2
# 3rd l-moment: Skewness
# 4th l-moment: Kurtosis (measures the heaviness of tail)
#Those are extra moments (expressed as ratios)
# 2nd l-moment ratio "L-variation", 
# 3rd l-moment ratio "L-skewness", 
# 4th l-moment ratio "L-kurtosis"

# Sort the flows
sample_sorted <- sort(sample, decreasing = T)
#get Empirical Cumulative Distribution Function
ecdf_sample_fun <- ecdf(sample)


#create a df with value and empirical probabilities (non-exceedance)
ecdf_df <- data.frame(flow_ordered=sample_sorted, 
                      emp_prob=ecdf_sample_fun(sample_sorted))

# Fitting a distribution means estimating its correct parameters that provide the best possible fit to the sample
# Fit the GEV distribution by estimating its parameters
parameters_gev <- fit_gev(sl1 = samlmoms$sl1, sl2 = samlmoms$sl2, st3 = samlmoms$st3)


#get theoretical probabilities from the distribution at the same flow values
# It is better to use a finer increment of flow values between min and max to generate smoother CDF
# create a vector of values from max to min
# This is done to plot high resolution theoretical CDF (smooth line)
incr_flow <- seq(from = max(sample), to = min(sample), length.out = 1000) #generate 1000 values between min and max
#create a new dataframe that contains the theoretical CDF
theor_cdf_df <- data.frame(flow=incr_flow) # or incr_flow if you are using the finer step
#estimate the probabilities that correspond to the sample_sorted or incr_flow (i.e., get theoretical CDF)
theor_cdf_df$gev_prob <- pgev(x = theor_cdf_df$flow, 
                           para = as.numeric(parameters_gev[1:3]))

# Repeat the above steps (fit_xxx, pxxx) fit another distribution and obtain the theoretical CDF. LMoFit supports the following distributions:
# 1.	Burr Type-III (BrIII)
# 2.	Burr Type-XII (BrXII)
# 3.	Generalized Gamma (GG)
# 4.	Normal (nor)
# 5.	Log-Normal (ln3)
# 6.	Pearson Type-3 (pe3)
# 7.	Generalized Normal (gno)
# 8.	Generalized Pareto (gpa)
# 9.	Generalized Logistic (glo)
# 10.	Gamma (gam)
# 11.	Generalized Extreme Value (gev)

# Another example for pe3:
parameters_pe3 <- fit_pe3(sl1 = samlmoms$sl1, sl2 = samlmoms$sl2, st3 = samlmoms$st3, st4 = samlmoms$st4)
# Estimate the theoretical probabilities
theor_cdf_df$pe3_prob <- ppe3(x = theor_cdf_df$flow, 
                         para = as.numeric(parameters_pe3[1:3]))


# Another example for Gamma:
parameters_gamma <- fit_gam(sl1 = samlmoms$sl1, sl2 = samlmoms$sl2, st3 = samlmoms$st3, st4 = samlmoms$st4)
# Estimate the theoretical probabilities
theor_cdf_df$gamma_prob <- pgam(x = theor_cdf_df$flow, 
                               para = as.numeric(parameters_gamma[1:2]))

# Another example for normal:
parameters_normal <- fit_nor(sl1 = samlmoms$sl1, sl2 = samlmoms$sl2, st3 = samlmoms$st3, st4 = samlmoms$st4)
# quantile_normal <- qnor(RP = c(5, 10, 25, 50, 100), 
#                            para = c(parameters_normal[1], parameters_normal[2])) # Step 3

theor_cdf_df$normal_prob <- pnor(x =theor_cdf_df$flow, 
                            para = as.numeric(parameters_normal[1:2]))

# Plot the emp and theor CDF

#melt the data
theor_cdf_df_melt <- melt(theor_cdf_df, id.vars = 'flow')
#Plot the data
ggplot(data = ecdf_df, aes(x=flow_ordered, y=emp_prob))+geom_point()+
  geom_line(data = theor_cdf_df_melt, aes(x=flow, y=value, color=variable))+
  labs(x='Flow (cms)', y='Non-exceedance probability (-)')

#calculate goodness of fit using ks.test
ks_test_results <- data.frame(distribution=c('GEV', 'PE3', 'Gamma', 'Normal'), 
                              KS_test_D=c(
                                          ks.test(ecdf_df$emp_prob, theor_cdf_df$gev_prob)$statistic,
                                          ks.test(ecdf_df$emp_prob, theor_cdf_df$pe3_prob)$statistic,
                                          ks.test(ecdf_df$emp_prob, theor_cdf_df$gamma_prob)$statistic,
                                          ks.test(ecdf_df$emp_prob, theor_cdf_df$normal_prob)$statistic))

cat('KS test results \n')
print(ks_test_results)

cat('The best fit distribution is:', ks_test_results$distribution[which.min(ks_test_results$KS_test_D)], '\n')

#The best distribution is PE3 and gam
#Get quantiles (magnitude) for specific return periods

quantile_pe3 <- qpe3(RP = c(5, 10, 25, 50, 100),
                     para = as.numeric(parameters_pe3[1:3]))

quantile_gamma <- qgam(RP = c(5, 10, 25, 50, 100), 
                     para = as.numeric(parameters_gamma[1:2])) 



