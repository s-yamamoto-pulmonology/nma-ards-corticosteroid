# Comparison of Corticosteroid Regimens for Acute Respiratory Distress Syndrome

This repository contains R code and datasets for a dose-response network meta-analysis (NMA) performed to identify the optimal corticosteroid regimen for Acute Respiratory Distress Syndrome (ARDS).

## Repository Structure

```         
nma-ards-corticosteroid/
├── data/
│   ├── drc_28-30d-mortality.csv
│   ├── drc_90d-mortality.csv
│   ├── drc_barotrauma.csv
│   ├── drc_bleeding.csv
│   ├── drc_hospital-mortality.csv
│   ├── drc_hyperglycemia.csv
│   ├── drc_icu-mortality.csv
│   ├── drc_last-follow-up-mortality.csv
│   ├── drc_superinfection.csv
│   ├── drc_ventilator-free-days.csv
│   ├── drc_weakness.csv
│   ├── np_28-30d-mortality_equal-dose_model.csv
│   └── np_28-30d-mortality_exchangeable-dose_model.csv
├── src
│   ├── MBNMAdose_model-fitting_DRC.R      # Code to compare models and DRC
│   └── NetworkPlot.R                      # Code to generate network plots
├── LICENSE                                # License file about codes
├── DATA_LICENSE                           # License file about dataset usage
├── README.md                              # This file
└── nma-ards-corticosteroid.Rproj          # R project file
```

## Usage Instructions

### Main Analyses: Model Fitting and Dose-response Curve

-   **Data loading and preprocessing**
-   **Building a dose-response network model**
-   **Comparing nine different dose-response models:**
    1.  Emax model
    2.  Polynomial model (Degree 1: linear)
    3.  Polynomial model (Degree 2: nonlinear)
    4.  Exponential model
    5.  Fractional polynomial model
    6.  Integrated Two-Component Prediction (ITP) model
    7.  Log-linear (exponential) model
    8.  Non-parametric model
    9.  Spline model
-   **Prediction and visualization** using the selected spline model.

### Generating Network Plots

-   **Dataset Loading:**
    -   For the equal-dose effects model, use the file `np_28-30d-mortality_equal-dose_model.csv`.
    -   Uncomment the relevant sections in the code (from Step 4-b onward in `NetworkPlot.R`).
    -   The default code runs an exchangeable dose effects model. Ensure you use the correct dataset (`np_28-30d-mortality_exchangeable-dose_model.csv`) when running the default code sections.

## Required Packages

The provided scripts automatically install and load these R packages if not already available:

-   `MBNMAdose`
-   `rjags`
-   `R2jags`
-   `dplyr`
-   `tidyr`
-   `purrr`
-   `igraph`
-   `ggraph`
-   `ggplot2`
-   `ggview`

### Key Package

-   **MBNMAdose Version 0.5.0**\
    This package is available on [CRAN](https://cran.r-project.org/web/packages/MBNMAdose/index.html) or on [Github](https://github.com/cran/MBNMAdose).

## Development Environment

-   **RStudio:** Version 2024.12.1+563\
-   **R:** Version 4.4.2

## Usage

-   **Data Files:** Place all dataset files in the `data/` directory.
-   **Scripts:** Run the scripts located in the `src/` directory.
-   Ensure all required R packages are installed (this is handled automatically by the provided code).

## License

This project is licensed under the MIT License.\
For details, please refer to [LICENSE](LICENSE).\
For using these datasets, please refer to [DATA_LICENSE](DATA_LICENSE).
