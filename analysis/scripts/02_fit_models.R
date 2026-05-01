#!/usr/bin/env Rscript
#
# 02_fit_models.R
# Purpose: Fit regression models to prepared data
# Input: analysis/data/derived_data/mtcars_clean.csv
# Output: model coefficients, metrics, and diagnostics CSVs
#
# This script is part of the reproducible blog post pipeline.
# Run independently: Rscript analysis/scripts/02_fit_models.R

library(tidyverse)
library(broom)

# Configuration
INPUT_FILE <- "analysis/data/derived_data/mtcars_clean.csv"
OUTPUT_DIR <- "analysis/data/derived_data"

# Verify input exists
if (!file.exists(INPUT_FILE)) {
  stop("Input file not found: ", INPUT_FILE, "\n",
       "Run 01_prepare_data.R first")
}

# Create output directory
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
}

# Load prepared data
cat("Loading prepared data...\n")
mtcars_clean <- read_csv(INPUT_FILE, show_col_types = FALSE)

cat("  - Loaded:", nrow(mtcars_clean), "observations\n")
cat("  - Variables:", ncol(mtcars_clean), "\n\n")

# ==============================================================================
# Model 1: Simple Linear Model (MPG ~ Weight)
# ==============================================================================
cat("Fitting Model 1: Simple Linear Regression (mpg ~ wt)\n")
cat("---\n")

simple_model <- lm(mpg ~ wt, data = mtcars_clean)

# Extract model components
model_summary <- tidy(simple_model, conf.int = TRUE)
model_metrics <- glance(simple_model)

cat("Model Summary:\n")
print(model_summary)
cat("\nModel Metrics:\n")
print(model_metrics)
cat("\n")

# ==============================================================================
# Generate Diagnostic Data
# ==============================================================================
cat("Generating diagnostics...\n")

diagnostics <- mtcars_clean %>%
  mutate(
    # Predictions and residuals
    predicted = predict(simple_model),
    residuals = residuals(simple_model),
    std_resid = rstandard(simple_model),
    # Identify outliers (>2.5 SD)
    is_outlier = abs(rstandard(simple_model)) > 2.5,
    # Leverage
    hat_value = hatvalues(simple_model),
    # Cook's distance
    cooks_d = cooks.distance(simple_model)
  )

outlier_count <- sum(diagnostics$is_outlier)
cat("  - Residual SE:", round(sigma(simple_model), 3), "MPG\n")
cat("  - Outliers found (>2.5 SD):", outlier_count, "\n")
cat("  - Mean Cook's distance:", round(mean(diagnostics$cooks_d, na.rm = TRUE), 4), "\n\n")

# ==============================================================================
# Export Results
# ==============================================================================
cat("Exporting results...\n")

# Model coefficients
coef_file <- file.path(OUTPUT_DIR, "model_coefficients.csv")
write_csv(model_summary, coef_file)
cat("  ✓ Coefficients:", coef_file, "\n")

# Model metrics
metrics_file <- file.path(OUTPUT_DIR, "model_metrics.csv")
write_csv(model_metrics, metrics_file)
cat("  ✓ Metrics:", metrics_file, "\n")

# Diagnostics
diag_file <- file.path(OUTPUT_DIR, "model_diagnostics.csv")
write_csv(diagnostics, diag_file)
cat("  ✓ Diagnostics:", diag_file, "\n")

# Save model object for later use
model_file <- file.path(OUTPUT_DIR, "simple_model.rds")
saveRDS(simple_model, model_file)
cat("  ✓ Model object:", model_file, "\n\n")

# ==============================================================================
# Model Validation Summary
# ==============================================================================
cat("Model Validation Summary:\n")
cat("---\n")

cat("\nCoefficients:\n")
cat("  - Intercept: ", round(coef(simple_model)[1], 3), " MPG\n")
cat("  - Weight effect: ", round(coef(simple_model)[2], 3), " MPG per 1000 lbs\n")

cat("\nFit Quality:\n")
cat("  - R²: ", round(model_metrics$r.squared, 4), "\n")
cat("  - Adjusted R²: ", round(model_metrics$adj.r.squared, 4), "\n")
cat("  - F-statistic: ", round(model_metrics$statistic, 2), "\n")
cat("  - p-value: ", model_metrics$p.value, "\n")

cat("\nAssumption Checks:\n")
cat("  - Residuals: N(0, σ²)?")
cat("    Mean of residuals:", round(mean(diagnostics$residuals), 6), " (should ≈ 0)\n")

# Shapiro-Wilk test for normality
if (nrow(diagnostics) >= 3 && nrow(diagnostics) <= 5000) {
  shapiro_test <- shapiro.test(diagnostics$std_resid)
  cat("    Shapiro-Wilk p-value:", round(shapiro_test$p.value, 4),
      if (shapiro_test$p.value > 0.05) "(✓ Normal)" else "(⚠ Non-normal)", "\n")
}

cat("  - Heteroscedasticity: Constant variance?\n")
cat("    Min residual SE:", round(min(abs(diagnostics$std_resid)), 3), "\n")
cat("    Max residual SE:", round(max(abs(diagnostics$std_resid)), 3), "\n")

cat("\nOutlier Assessment:\n")
cat("  - Outliers (>2.5 SD):", outlier_count, "/", nrow(diagnostics), "\n")

if (outlier_count > 0) {
  outlier_models <- diagnostics %>%
    filter(is_outlier) %>%
    select(model, mpg, wt, predicted, std_resid)
  cat("\n  Outlier details:\n")
  print(outlier_models)
}

cat("\n")
cat("SUCCESS: All models fitted and exported\n")
