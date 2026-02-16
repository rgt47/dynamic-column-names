#!/usr/bin/env Rscript
#
# 03_generate_figures.R
# Purpose: Generate publication-quality figures from analysis
# Input: analysis/data/derived_data/mtcars_clean.csv and model results
# Output: analysis/figures/*.png
#
# This script is part of the reproducible blog post pipeline.
# Run independently: Rscript analysis/scripts/03_generate_figures.R

library(tidyverse)
library(patchwork)

# Load custom utilities
source("R/plotting_utils.R")

# Configuration
DATA_FILE <- "analysis/data/derived_data/mtcars_clean.csv"
DIAG_FILE <- "analysis/data/derived_data/model_diagnostics.csv"
OUTPUT_DIR <- "analysis/figures"

# Verify inputs exist
if (!file.exists(DATA_FILE)) {
  stop("Data file not found: ", DATA_FILE, "\n",
       "Run 01_prepare_data.R first")
}

if (!file.exists(DIAG_FILE)) {
  stop("Diagnostics file not found: ", DIAG_FILE, "\n",
       "Run 02_fit_models.R first")
}

# Create output directory
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
}

# ==============================================================================
# Load Data and Setup
# ==============================================================================
cat("Loading data and setting up visualization...\n")

mtcars_clean <- read_csv(DATA_FILE, show_col_types = FALSE)
diagnostics <- read_csv(DIAG_FILE, show_col_types = FALSE)

# Setup theme and colors
setup_plot_theme()
colors <- get_analysis_colors()

cat("  - Loaded:", nrow(mtcars_clean), "observations\n")
cat("  - Color palette: Primary/Secondary/Tertiary/Quaternary\n\n")

# ==============================================================================
# Figure 1: EDA Overview (Distribution + Boxplot)
# ==============================================================================
cat("Generating Figure 1: EDA Overview\n")

p1_dist <- ggplot(mtcars_clean, aes(x = mpg)) +
  geom_histogram(bins = 15, fill = colors["primary"], alpha = 0.7, color = "white") +
  labs(
    title = "Distribution of Fuel Efficiency",
    x = "Miles Per Gallon (MPG)",
    y = "Count"
  ) +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    panel.grid.minor = element_blank()
  )

p1_box <- ggplot(mtcars_clean, aes(x = cyl_factor, y = mpg, fill = cyl_factor)) +
  geom_boxplot(alpha = 0.7, color = "gray30", size = 0.5) +
  scale_fill_manual(
    values = c("4-cyl" = colors["primary"],
               "6-cyl" = colors["secondary"],
               "8-cyl" = colors["tertiary"]),
    guide = "none"
  ) +
  labs(
    title = "MPG by Engine Cylinders",
    x = "Number of Cylinders",
    y = "Miles Per Gallon (MPG)"
  ) +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    panel.grid.minor = element_blank()
  )

eda_overview <- p1_dist + p1_box + plot_layout(ncol = 2)
save_plot(file.path(OUTPUT_DIR, "eda-overview.png"), eda_overview, width = 10, height = 4)

# ==============================================================================
# Figure 2: Weight vs Fuel Efficiency (Correlation)
# ==============================================================================
cat("Generating Figure 2: Correlation Plot\n")

correlation_plot <- ggplot(mtcars_clean, aes(x = wt, y = mpg, color = cyl_factor)) +
  geom_point(size = 3, alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dashed", size = 0.8) +
  scale_color_manual(
    values = c("4-cyl" = colors["primary"],
               "6-cyl" = colors["secondary"],
               "8-cyl" = colors["tertiary"]),
    name = "Cylinders"
  ) +
  labs(
    title = "Weight vs Fuel Efficiency",
    x = "Vehicle Weight (1000 lbs)",
    y = "Miles Per Gallon (MPG)"
  ) +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

save_plot(file.path(OUTPUT_DIR, "correlation-plot.png"), correlation_plot, width = 8, height = 5)

# ==============================================================================
# Figure 3: Model Fit Visualization
# ==============================================================================
cat("Generating Figure 3: Model Fit\n")

model_plot <- ggplot(mtcars_clean, aes(x = wt, y = mpg)) +
  geom_point(aes(color = cyl_factor), size = 3, alpha = 0.6) +
  geom_smooth(method = "lm", color = "black", fill = "gray80", alpha = 0.3) +
  scale_color_manual(
    values = c("4-cyl" = colors["primary"],
               "6-cyl" = colors["secondary"],
               "8-cyl" = colors["tertiary"]),
    name = "Cylinders"
  ) +
  labs(
    title = "Linear Model: MPG ~ Weight",
    subtitle = "Gray band represents 95% confidence interval",
    x = "Vehicle Weight (1000 lbs)",
    y = "Miles Per Gallon (MPG)"
  ) +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

save_plot(file.path(OUTPUT_DIR, "model-plot.png"), model_plot, width = 8, height = 5)

# ==============================================================================
# Figure 4: Residual Diagnostics
# ==============================================================================
cat("Generating Figure 4: Diagnostics\n")

# Prepare diagnostics for plotting with cylinder factor
# Convert cyl to factor since it was read as character from CSV
diagnostics <- diagnostics %>%
  mutate(cyl_factor = factor(cyl, levels = c(4, 6, 8), labels = c("4-cyl", "6-cyl", "8-cyl")))

diagnostics_plot <- ggplot(diagnostics, aes(x = predicted, y = std_resid)) +
  geom_point(aes(color = cyl_factor), size = 3, alpha = 0.6) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", size = 0.8) +
  geom_hline(yintercept = c(-2, 2),
             linetype = "dashed", color = "red", size = 0.5, alpha = 0.7) +
  scale_color_manual(
    values = c("4-cyl" = colors["primary"],
               "6-cyl" = colors["secondary"],
               "8-cyl" = colors["tertiary"]),
    name = "Cylinders"
  ) +
  labs(
    title = "Residual Diagnostics",
    subtitle = "Red lines mark ±2 standard deviations",
    x = "Predicted MPG",
    y = "Standardized Residuals"
  ) +
  theme(
    plot.title = element_text(size = 12, face = "bold"),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

save_plot(file.path(OUTPUT_DIR, "diagnostics-plot.png"), diagnostics_plot, width = 8, height = 5)

# ==============================================================================
# Summary
# ==============================================================================
cat("\n")
cat("SUCCESS: All figures generated\n")
cat("---\n")

figures <- c(
  "eda-overview.png" = "Distribution and boxplot of fuel efficiency",
  "correlation-plot.png" = "Weight vs MPG relationship",
  "model-plot.png" = "Linear regression fit with confidence bands",
  "diagnostics-plot.png" = "Standardized residuals"
)

for (i in seq_along(figures)) {
  fig_path <- file.path(OUTPUT_DIR, names(figures)[i])
  if (file.exists(fig_path)) {
    file_size_kb <- round(file.size(fig_path) / 1024, 1)
    cat(sprintf("  ✓ %s (%s KB) - %s\n",
                names(figures)[i], file_size_kb, figures[i]))
  }
}

cat("\nFigures saved to:", OUTPUT_DIR, "\n")
