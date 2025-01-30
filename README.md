# Flood Frequency Analysis Tutorial
A tutorial on flood frequency analysis using R for the Bow River at Banff gauge `05BB001`.

# Used packages

This script uses the following packages
* `LMoFit`: Fit different distributions to your data
* `tidyhydat`: Access of Water Survey of Canada (WSC) observed streamflow database
* `dplyr`: Data manupilation
* `reshape2`: Data reshaping
* `ggplot2`: Plotting library

You can install the packages using

    install.packages('LMoFit', 'tidyhydat', 'dplyr', 'reshape2', 'ggplot2')

Once you download the packages, you need to download the WSC's observed streamflow sqlite database, used by tidyhydat.

    tidyhydat::download_hydat()
This process will take time to download the database (~ 1.5GB)

# How to use the script

The script only needs a WSC gauge id and it will extract the annual maximum timeseries and fit the following distributions: `Generalized Extreme Value`, `Pearson Type-3`, `Gamma`, and `Normal`

The script also provides different quantiles calculated bt `Generalized Extreme Value` and `Pearson Type-3` (best-fit distributions for this case) for the following return periods: 5, 10, 25, 50, and 100 years.

Users can fit other distributions available within the `LMoFit` package.

The script contains a detailed description of each step along with extensive comments.
