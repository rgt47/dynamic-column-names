#!/usr/bin/env Rscript
#
# 01_prepare_data.R
# Purpose: Load and prepare mtcars data for analysis
# Input: mtcars built-in dataset
# Output: analysis/data/derived_data/mtcars_clean.csv
#
# This script is part of the reproducible blog post pipeline.
# Run independently: Rscript analysis/scripts/01_prepare_data.R

library(tidyverse)

# Configuration
OUTPUT_DIR <- "analysis/data/derived_data"
OUTPUT_FILE <- file.path(OUTPUT_DIR, "mtcars_clean.csv")

# Create output directory if it doesn't exist
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
}

# Load source data
# mtcars: Motor Trend Car Road Tests (1974)
# 32 observations of 11 variables
raw_data <- mtcars %>%
  rownames_to_column("model") %>%
  as_tibble()

cat("Loaded raw data:\n")
cat("  - Observations:", nrow(raw_data), "\n")
cat("  - Variables:", ncol(raw_data), "\n\n")

# Data cleaning and preparation
clean_data <- raw_data %>%
  # Add derived variables for analysis
  mutate(
    # Convert weight to kg (1000 lbs * 453.6 kg/lbs)
    weight_kg = wt * 453.6,
    # Convert horsepower to kilowatts (hp * 0.746 kW/hp)
    power_kw = hp * 0.746,
    # Create categorical cylinder variable
    cyl_factor = factor(cyl, levels = c(4, 6, 8), labels = c("4-cyl", "6-cyl", "8-cyl")),
    # Create categorical transmission variable
    am_label = factor(am, levels = 0:1, labels = c("Automatic", "Manual")),
    # Create categorical engine type
    vs_label = factor(vs, levels = 0:1, labels = c("V-shaped", "Straight")),
    # Create speed category
    speed_category = cut(qsec,
                        breaks = c(0, 16, 18, 22),
                        labels = c("Fast", "Medium", "Slow"),
                        include.lowest = TRUE)
  ) %>%
  # Check for any missing values
  {
    missing_count <- sum(is.na(.))
    if (missing_count > 0) {
      cat("WARNING: Found", missing_count, "missing values\n")
    }
    .
  }

cat("Data preparation complete:\n")
cat("  - Original variables:", ncol(raw_data), "\n")
cat("  - Enhanced variables:", ncol(clean_data), "\n")
cat("  - New derived variables:", ncol(clean_data) - ncol(raw_data), "\n")
cat("  - Missing values:", sum(is.na(clean_data)), "\n\n")

# Summary statistics
cat("Summary of key variables:\n")
cat("  - MPG: mean =", round(mean(clean_data$mpg), 1),
    ", sd =", round(sd(clean_data$mpg), 1), "\n")
cat("  - Weight: mean =", round(mean(clean_data$wt), 2),
    " (1000 lbs) =", round(mean(clean_data$weight_kg), 0), "kg\n")
cat("  - Horsepower: mean =", round(mean(clean_data$hp), 0),
    " =", round(mean(clean_data$power_kw), 1), "kW\n")
cat("  - Cylinders: n =", table(clean_data$cyl_factor), "\n")
cat("  - Transmission: Automatic =", sum(clean_data$am == 0),
    ", Manual =", sum(clean_data$am == 1), "\n\n")

# Export clean data
write_csv(clean_data, OUTPUT_FILE)

cat("SUCCESS: Data exported to", OUTPUT_FILE, "\n")
cat("  - File size:", file.size(OUTPUT_FILE), "bytes\n")
cat("  - Rows:", nrow(clean_data), "\n")
cat("  - Columns:", ncol(clean_data), "\n")
