# --------------------------------------------
# Automatically install and load required packages
# --------------------------------------------
# Define the necessary packages for network meta-analysis modeling.
required_packages <- c("MBNMAdose", "rjags", "R2jags")
# Loop through each package: install it (with dependencies) if it's not already available, then load it.
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

# --------------------------------------------
# Load Dataset and Build Network Model
# --------------------------------------------
# Load the CSV file containing the dose-response data.
data.ab <- read.csv("data/drc_28-30d-mortality.csv")
# Print the dataset to verify its contents.
print(data.ab)

# Build the network model from the loaded dataset.
# This function organizes the data into the required format for subsequent meta-analysis.
network <- mbnma.network(data.ab = data.ab)

# --------------------------------------------
# Compare 9 Dose-Response Models
# --------------------------------------------
# The following sections run different dose-response models on the network data.
# Each model is run using mbnma.run() with specified function settings,
# and then the model summary is printed.

# 1) Emax model
# Uses a model with relative Emax and ED50 parameters.
emax <- mbnma.run(
  network,
  fun = demax(emax = "rel", ed50 = "rel"),
  n.burnin = 5000, n.iter = 25000, n.thin = 10,
  method = "random"
)
summary(emax)

# 2) Polynomial model: Degree 1 (linear)
# Fits a linear model using a polynomial function of degree 1.
poly1 <- mbnma.run(
  network,
  fun = dpoly(
    degree = 1,
    beta.1 = "rel",
    beta.2 = "rel",
    beta.3 = "rel",
    beta.4 = "rel"
  ),
  n.burnin = 5000, n.iter = 25000, n.thin = 10,
  method = "random"
)
summary(poly1)

# 3) Polynomial model: Degree 2 (nonlinear)
# Fits a nonlinear polynomial model of degree 2.
poly2 <- mbnma.run(
  network,
  fun = dpoly(
    degree = 2,
    beta.1 = "rel",
    beta.2 = "rel",
    beta.3 = "rel",
    beta.4 = "rel"
  ),
  n.burnin = 5000, n.iter = 25000, n.thin = 10,
  method = "random"
)
summary(poly2)

# 4) Exponential dose-response model
# Fits an exponential model where Emax is relative and no onset parameter is set.
dexp <- mbnma.run(
  network,
  fun = dexp(emax = "rel", onset = NULL, p.expon = FALSE),
  n.burnin = 5000, n.iter = 25000, n.thin = 10,
  method = "random"
)
summary(dexp)

# 5) Fractional polynomial dose-response model
# Fits a fractional polynomial model with degree 1 and fixed power terms (both set to 0).
dfpoly <- mbnma.run(
  network,
  fun = dfpoly(degree = 1, beta.1 = "rel", beta.2 = "rel", power.1 = 0, power.2 = 0),
  n.burnin = 5000, n.iter = 25000, n.thin = 10,
  method = "random"
)
summary(dfpoly)

# 6) Integrated Two-Component Prediction (ITP) model
# Fits an ITP model with relative Emax and rate parameters.
dtip <- mbnma.run(
  network,
  fun = ditp(emax = "rel", rate = "rel", p.expon = FALSE),
  n.burnin = 5000, n.iter = 25000, n.thin = 10,
  method = "random"
)
summary(dtip)

# 7) Log-linear (exponential) dose-response model
# Fits a log-linear model, an exponential model with a logarithmic link function.
dloglin <- mbnma.run(
  network,
  fun = dloglin(),
  n.burnin = 5000, n.iter = 25000, n.thin = 10,
  method = "random"
)
summary(dloglin)

# 8) Non-parametric dose-response model
# Fits a non-parametric model with the assumption of decreasing response.
dnonparam <- mbnma.run(
  network,
  fun = dnonparam(direction = "decreasing"),
  n.burnin = 5000, n.iter = 25000, n.thin = 10,
  method = "random"
)
# Print the model object (dnonparam might not have a summary method)
print(dnonparam)

# 9) Spline dose-response model
# Fits a spline model using a natural spline (ns) with 1 knot and degree 1.
dspline <- mbnma.run(
  network,
  fun = dspline(
    type = "ns",
    knots = 1,
    degree = 1,
    beta.1 = "rel",
    beta.2 = "rel",
    beta.3 = "rel",
    beta.4 = "rel"
  ),
  n.burnin = 5000, n.iter = 25000, n.thin = 10,
  method = "random"
)
summary(dspline)

# --------------------------------------------
# Prediction and Plotting
# --------------------------------------------
# Use the spline model to generate predictions.
pred <- predict(
  dspline,
  E0 = 0.394, # Set baseline risk (placebo effect)
  synth = "random", # Use random synthesis for prediction
  n.doses = 15, # Specify number of dose levels to predict
  lim = "cred" # Use credible intervals for uncertainty
)

# Plot the prediction results along with observed data.
# The plot displays a forest plot overlay with split model results.
plot(pred, disp.obs = TRUE, overlay.split = TRUE, method = "common")
