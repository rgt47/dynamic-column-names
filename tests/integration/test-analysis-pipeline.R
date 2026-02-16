#!/usr/bin/env Rscript
#
# Integration tests for the complete analysis pipeline
# Tests that scripts run successfully and produce expected outputs
#
# Run with: Rscript tests/integration/test-analysis-pipeline.R

library(testthat)
library(tidyverse)

# Test context
test_dir <- "tests/integration"
cat("Running integration tests for analysis pipeline...\n\n")

# ==============================================================================
# Test 1: Data Preparation Script
# ==============================================================================
test_that("01_prepare_data.R produces clean data CSV", {
  # Run the script
  source("analysis/scripts/01_prepare_data.R", local = TRUE)

  # Check output file exists
  output_file <- "analysis/data/derived_data/mtcars_clean.csv"
  expect_true(file.exists(output_file))

  # Load and validate output
  data <- read_csv(output_file, show_col_types = FALSE)

  # Structural checks
  expect_equal(nrow(data), 32)
  expect_gte(ncol(data), 18)  # Should have original + derived variables

  # Original variables present
  expect_true(all(c("model", "mpg", "cyl", "disp", "hp", "drat", "wt") %in% names(data)))

  # Derived variables present
  expect_true(all(c("weight_kg", "power_kw", "cyl_factor", "am_label") %in% names(data)))

  # Data quality checks
  expect_true(all(!is.na(data$mpg)))
  expect_true(all(data$mpg > 0))
  expect_true(all(data$wt > 0))

  # Type checks - note: CSV files don't preserve factors, so they come back as characters
  expect_true(is.character(data$cyl_factor))  # Converted from factor
  expect_true(is.character(data$am_label))    # Converted from factor

  cat("✓ Data preparation test passed\n")
})

# ==============================================================================
# Test 2: Model Fitting Script
# ==============================================================================
test_that("02_fit_models.R produces model outputs", {
  # Ensure data exists first
  if (!file.exists("analysis/data/derived_data/mtcars_clean.csv")) {
    skip("Data file not found - run 01_prepare_data.R first")
  }

  # Run the script
  source("analysis/scripts/02_fit_models.R", local = TRUE)

  # Check all expected output files
  expected_files <- c(
    "analysis/data/derived_data/model_coefficients.csv",
    "analysis/data/derived_data/model_metrics.csv",
    "analysis/data/derived_data/model_diagnostics.csv",
    "analysis/data/derived_data/simple_model.rds"
  )

  for (file in expected_files) {
    expect_true(file.exists(file))
  }

  # Load and validate coefficients
  coef_df <- read_csv(expected_files[1], show_col_types = FALSE)
  expect_equal(nrow(coef_df), 2)
  expect_true("estimate" %in% names(coef_df))
  expect_true("p.value" %in% names(coef_df))

  # Load and validate metrics
  metrics_df <- read_csv(expected_files[2], show_col_types = FALSE)
  expect_true("r.squared" %in% names(metrics_df))
  expect_gte(metrics_df$r.squared, 0)
  expect_lte(metrics_df$r.squared, 1)

  # Load and validate diagnostics
  diag_df <- read_csv(expected_files[3], show_col_types = FALSE)
  expect_equal(nrow(diag_df), 32)
  expect_true(all(c("predicted", "residuals", "std_resid") %in% names(diag_df)))

  # Load and validate model object
  model <- readRDS(expected_files[4])
  expect_s3_class(model, "lm")
  expect_equal(length(coef(model)), 2)

  cat("✓ Model fitting test passed\n")
})

# ==============================================================================
# Test 3: Figure Generation Script
# ==============================================================================
test_that("03_generate_figures.R produces publication-quality figures", {
  # Ensure dependencies exist
  required_files <- c(
    "analysis/data/derived_data/mtcars_clean.csv",
    "analysis/data/derived_data/model_diagnostics.csv"
  )

  for (file in required_files) {
    if (!file.exists(file)) {
      skip(paste("Required file not found:", file))
    }
  }

  # Run the script
  source("analysis/scripts/03_generate_figures.R", local = TRUE)

  # Check all expected figure files
  expected_figures <- c(
    "analysis/figures/eda-overview.png",
    "analysis/figures/correlation-plot.png",
    "analysis/figures/model-plot.png",
    "analysis/figures/diagnostics-plot.png"
  )

  for (fig in expected_figures) {
    expect_true(file.exists(fig))

    # Validate PNG format (check magic bytes)
    raw <- readBin(fig, "raw", n = 4)
    png_sig <- as.raw(c(0x89, 0x50, 0x4E, 0x47))
    expect_equal(raw, png_sig)

    # Check file size (PNG should be at least 1KB)
    file_size <- file.size(fig)
    expect_gt(file_size, 1000)
  }

  cat("✓ Figure generation test passed\n")
})

# ==============================================================================
# Test 4: Pipeline Consistency
# ==============================================================================
test_that("Pipeline outputs are consistent and non-empty", {
  # Check that diagnostics match data
  data <- read_csv("analysis/data/derived_data/mtcars_clean.csv",
                   show_col_types = FALSE)
  diag <- read_csv("analysis/data/derived_data/model_diagnostics.csv",
                   show_col_types = FALSE)

  # Same number of observations
  expect_equal(nrow(data), nrow(diag))

  # Diagnostics contain expected statistics
  expect_true(!all(is.na(diag$predicted)))
  expect_true(!all(is.na(diag$std_resid)))

  # Residual mean should be close to 0
  mean_resid <- mean(diag$residuals, na.rm = TRUE)
  expect_lt(abs(mean_resid), 0.01)

  cat("✓ Pipeline consistency test passed\n")
})

# ==============================================================================
# Test 5: Utility Function Loading
# ==============================================================================
test_that("Plotting utilities load and function correctly", {
  source("R/plotting_utils.R", local = TRUE)

  # Test setup_plot_theme
  expect_no_error(setup_plot_theme())

  # Test get_analysis_colors
  colors <- get_analysis_colors()
  expect_equal(length(colors), 4)
  expect_named(colors, c("primary", "secondary", "tertiary", "quaternary"))
  expect_true(all(grepl("^#[0-9A-F]{6}$", colors, ignore.case = TRUE)))

  cat("✓ Utility function test passed\n")
})

# ==============================================================================
# Summary
# ==============================================================================
cat("\n")
cat("Integration tests complete!\n")
cat("All pipeline steps verified:\n")
cat("  ✓ Data preparation\n")
cat("  ✓ Model fitting\n")
cat("  ✓ Figure generation\n")
cat("  ✓ Output consistency\n")
cat("  ✓ Utility functions\n")
