# Architecture Review: index.qmd Refactoring

## Executive Summary

The current `index.qmd` contains all analysis code inline, which violates rrtools/zzcollab separation of concerns principles. Following best practices, we should extract:

1. **Utility functions → R/plotting_utils.R**
2. **Data processing → analysis/scripts/01_prepare_data.R**
3. **Model fitting → analysis/scripts/02_fit_models.R**
4. **Figure generation → analysis/scripts/03_generate_figures.R**
5. **Data documentation → analysis/data/raw_data/README.md**

This allows:
- ✅ Reproducible, independently runnable scripts
- ✅ Cleaner blog post focused on narrative
- ✅ Reusable utilities across multiple posts
- ✅ Clear separation of concerns (analysis vs presentation)
- ✅ Easy testing and validation
- ✅ Readers can run pipeline independently

---

## Current Problems

### 1. **All Code Embedded in Blog Post** (Lines 145-347)
Everything is inline - no extraction into pipeline scripts.

**Current structure:**
```
index.qmd contains:
├── Data loading (line 146)
├── Data exploration (lines 157-168)
├── EDA plots (lines 184-204)
├── Correlation analysis (lines 214-223)
├── Scatter plots (lines 229-239)
├── Model fitting (lines 259-269)
├── Predictions (lines 276-282)
├── Diagnostic plots (lines 318-347)
└── Results display (scattered throughout)
```

**Problem:** Blog post does analysis AND presentation simultaneously. Violates separation of concerns.

---

## Extraction Plan

### Component 1: Utility Functions → R/plotting_utils.R

**Extract from index.qmd lines 116-120:**

```r
# Current (embedded in .qmd)
theme_set(theme_minimal(base_size = 12))
custom_colors <- c("#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4")
```

**Extract to R/plotting_utils.R:**

```r
# R/plotting_utils.R - Plotting utilities and themes
library(ggplot2)

#' Set default plotting theme
#' @export
setup_plot_theme <- function() {
  ggplot2::theme_set(ggplot2::theme_minimal(base_size = 12))
}

#' Palmer Penguins color palette (or analysis-specific palette)
#' @export
get_analysis_colors <- function() {
  c(
    primary = "#FF6B6B",    # Red
    secondary = "#4ECDC4",  # Teal
    tertiary = "#45B7D1",   # Blue
    quaternary = "#96CEB4"  # Green
  )
}

#' Safely save ggplot with consistent settings
#' @export
save_plot <- function(filename, plot, width = 8, height = 5, dpi = 300) {
  ggplot2::ggsave(
    filename,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi
  )
}
```

**Usage in index.qmd becomes:**
```r
library(plotting_utils)
setup_plot_theme()
colors <- get_analysis_colors()
```

**Benefits:**
- Reusable across posts
- Consistent styling
- Easier to update theme globally
- Testable independently

---

### Component 2: Data Preparation → analysis/scripts/01_prepare_data.R

**Extract from index.qmd lines 146-151, 156-168:**

The current code just loads mtcars. For a real analysis, this would include:

```r
# analysis/scripts/01_prepare_data.R
# Purpose: Load and prepare data for analysis
# Output: analysis/data/derived_data/mtcars_clean.csv

library(tidyverse)

# Load source data
raw_data <- mtcars %>%
  rownames_to_column("model")

# Data cleaning/preparation
clean_data <- raw_data %>%
  mutate(
    # Add any derived variables
    weight_kg = wt * 453.6,
    power_kw = hp * 0.746,
    # Add categorical versions if helpful
    cyl_factor = factor(cyl, levels = c(4, 6, 8)),
    am_label = factor(am, levels = 0:1, labels = c("Automatic", "Manual"))
  )

# Export for downstream use
dir.create("analysis/data/derived_data", showWarnings = FALSE)
write_csv(clean_data, "analysis/data/derived_data/mtcars_clean.csv")

cat("Prepared", nrow(clean_data), "observations\n")
```

**Usage in index.qmd becomes:**
```r
mtcars_clean <- read_csv("data/derived_data/mtcars_clean.csv")
glimpse(mtcars_clean)
```

**Benefits:**
- Data prep is reproducible
- Can be run independently: `Rscript analysis/scripts/01_prepare_data.R`
- Easy to modify cleaning steps
- Auto-snapshots packages to renv.lock

---

### Component 3: Model Fitting → analysis/scripts/02_fit_models.R

**Extract from index.qmd lines 259-269, 276-282, 318-327:**

```r
# analysis/scripts/02_fit_models.R
# Purpose: Fit regression models
# Output: analysis/data/derived_data/model_results.csv, simple_model.rds

library(tidyverse)
library(broom)

# Load prepared data
mtcars_clean <- read_csv("analysis/data/derived_data/mtcars_clean.csv")

# Fit simple linear model
simple_model <- lm(mpg ~ wt, data = mtcars_clean)

# Create output directory
dir.create("analysis/data/derived_data", showWarnings = FALSE)

# Save model coefficients
model_results <- list(
  summary = tidy(simple_model, conf.int = TRUE),
  metrics = glance(simple_model),
  diagnostics = mtcars_clean %>%
    mutate(
      predicted = predict(simple_model),
      residuals = residuals(simple_model),
      std_resid = rstandard(simple_model),
      outlier = abs(rstandard(simple_model)) > 2.5
    )
)

# Export results
write_csv(model_results$summary, "analysis/data/derived_data/model_coefficients.csv")
write_csv(model_results$metrics, "analysis/data/derived_data/model_metrics.csv")
write_csv(model_results$diagnostics, "analysis/data/derived_data/model_diagnostics.csv")

# Save model object for predictions
saveRDS(simple_model, "analysis/data/derived_data/simple_model.rds")

# Print summary
cat("\n=== Model Summary ===\n")
print(model_results$summary)
cat("\nR-squared:", round(model_results$metrics$r.squared, 3), "\n")
cat("Outliers found:", sum(model_results$diagnostics$outlier), "\n")
```

**Usage in index.qmd becomes:**
```r
# Load model results
model_summary <- read_csv("data/derived_data/model_coefficients.csv")
model_metrics <- read_csv("data/derived_data/model_metrics.csv")
model_diagnostics <- read_csv("data/derived_data/model_diagnostics.csv")

# Display in post
model_summary
model_metrics
```

**Benefits:**
- Model fitting is reproducible and traceable
- Results are saved for inspection
- Can regenerate diagnostics without re-fitting
- Easy to modify model specification

---

### Component 4: Figure Generation → analysis/scripts/03_generate_figures.R

**Extract from index.qmd lines 184-204, 229-239, 290-301, 335-347:**

```r
# analysis/scripts/03_generate_figures.R
# Purpose: Generate publication-quality figures
# Output: analysis/figures/*.png

library(tidyverse)
library(patchwork)
source("R/plotting_utils.R")

# Load prepared data and model results
mtcars_clean <- read_csv("analysis/data/derived_data/mtcars_clean.csv")
model_diagnostics <- read_csv("analysis/data/derived_data/model_diagnostics.csv")

# Create output directory
dir.create("analysis/figures", showWarnings = FALSE)

# Set theme and get colors
setup_plot_theme()
colors <- get_analysis_colors()

# FIGURE 1: EDA Overview (distribution + boxplot)
p1 <- ggplot(mtcars_clean, aes(x = mpg)) +
  geom_histogram(bins = 15, fill = colors[1], alpha = 0.7) +
  labs(title = "Distribution of MPG", x = "Miles Per Gallon", y = "Count")

p2 <- ggplot(mtcars_clean, aes(x = factor(cyl), y = mpg, fill = factor(cyl))) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_manual(values = colors) +
  labs(title = "MPG by Cylinder Count", x = "Number of Cylinders", y = "Miles Per Gallon") +
  theme(legend.position = "none")

eda_overview <- p1 + p2
save_plot("analysis/figures/eda-overview.png", eda_overview, width = 10, height = 5)

# FIGURE 2: Correlation scatter plot
correlation_plot <- ggplot(mtcars_clean, aes(x = wt, y = mpg, color = factor(cyl))) +
  geom_point(size = 3, alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linetype = "dashed") +
  scale_color_manual(values = colors, name = "Cylinders") +
  labs(
    title = "Weight vs Fuel Efficiency",
    x = "Weight (1000 lbs)",
    y = "Miles Per Gallon"
  )

save_plot("analysis/figures/correlation-plot.png", correlation_plot, width = 8, height = 5)

# FIGURE 3: Model fit visualization
model_plot <- ggplot(mtcars_clean, aes(x = wt, y = mpg)) +
  geom_point(aes(color = factor(cyl)), size = 3, alpha = 0.6) +
  geom_smooth(method = "lm", color = "black", fill = "gray80") +
  scale_color_manual(values = colors, name = "Cylinders") +
  labs(
    title = "Linear Model: MPG ~ Weight",
    subtitle = "Gray band shows 95% confidence interval",
    x = "Weight (1000 lbs)",
    y = "Miles Per Gallon"
  )

save_plot("analysis/figures/model-plot.png", model_plot, width = 8, height = 5)

# FIGURE 4: Diagnostic plot
diagnostics_plot <- ggplot(model_diagnostics, aes(x = predicted, y = std_resid)) +
  geom_point(aes(color = factor(cyl_factor)), size = 3, alpha = 0.6) +
  geom_hline(yintercept = c(-2, 0, 2),
             linetype = c("dashed", "solid", "dashed"),
             color = c("red", "black", "red")) +
  scale_color_manual(values = colors, name = "Cylinders") +
  labs(
    title = "Residual Diagnostics",
    x = "Predicted MPG",
    y = "Standardized Residuals"
  )

save_plot("analysis/figures/diagnostics-plot.png", diagnostics_plot, width = 8, height = 5)

cat("All figures saved to analysis/figures/\n")
```

**Usage in index.qmd becomes:**
```r
# Figures are already generated - just include them
```

**Benefits:**
- All figures generated in one place
- Easy to regenerate with changes
- Consistent styling across all figures
- Independent of narrative

---

### Component 5: Data Documentation → analysis/data/raw_data/README.md

**Create analysis/data/raw_data/README.md:**

```markdown
# Raw Data: mtcars Dataset

## Source
- **Dataset**: mtcars (Motor Trend Car Road Tests)
- **Built-in R dataset**: `data(mtcars)`
- **Original source**: Motor Trend magazine, 1974
- **Publication**: Henderson and Velleman (1981), "Building multiple regression models interactively"

## Variables
```r
mpg     Miles/(US) gallon
cyl     Number of cylinders
disp    Displacement (cu.in.)
hp      Gross horsepower
drat    Rear axle ratio
wt      Weight (1000 lbs)
qsec    1/4 mile time
vs      Engine (0 = V-shaped, 1 = straight)
am      Transmission (0 = automatic, 1 = manual)
gear    Number of forward gears
carb    Number of carburetors
```

## Data Quality Notes
- **Sample size**: 32 observations
- **Time period**: 1974
- **Scope**: Passenger cars from Major U.S. manufacturers
- **Missing values**: None
- **Known limitations**:
  - Old data (pre-fuel crisis impacts)
  - Small sample size
  - Limited to specific vehicle types
  - May not generalize to modern vehicles

## Citation
Henderson and Velleman (1981), "Building multiple regression models interactively," Biometrics, 37, 391-411.

## Loading in R
```r
# Auto-loads from mtcars dataset
data(mtcars)

# Or with tidyverse
mtcars_clean <- mtcars %>%
  rownames_to_column("model") %>%
  as_tibble()
```

## See Also
- `help(mtcars)` - Built-in documentation
- `?mtcars` - R documentation
```

---

## Refactored Structure

### Before (Current)
```
analysis/paper/index.qmd (578 lines)
├── All analysis code inline
├── All plotting code inline
├── All data loading inline
└── Narrative mixed with code
```

### After (Proposed)
```
R/plotting_utils.R (50 lines)
├── setup_plot_theme()
├── get_analysis_colors()
└── save_plot()

analysis/scripts/01_prepare_data.R (40 lines)
├── Load mtcars
├── Clean/prepare data
└── Export mtcars_clean.csv

analysis/scripts/02_fit_models.R (60 lines)
├── Load prepared data
├── Fit models
├── Save model objects
└── Export diagnostics

analysis/scripts/03_generate_figures.R (80 lines)
├── Load data and model results
├── Generate Figure 1: EDA
├── Generate Figure 2: Correlation
├── Generate Figure 3: Model fit
└── Generate Figure 4: Diagnostics

analysis/data/raw_data/README.md (50 lines)
├── Data source documentation
├── Variable definitions
├── Quality notes
└── Citation info

analysis/paper/index.qmd (300 lines, refactored)
├── Load library(plotting_utils)
├── Load processed data: read_csv("data/...")
├── Load model results: read_csv("data/...")
├── Display results (no re-computation)
├── Narrative and interpretation
└── Educational content
```

---

## Implementation Steps

### Step 1: Create R/plotting_utils.R
Move theme setup and color palette into reusable function.

### Step 2: Create analysis/scripts/01_prepare_data.R
Extract data loading and any cleaning from lines 146-151.

### Step 3: Create analysis/scripts/02_fit_models.R
Extract model fitting (lines 259-269, 318-327) and save results to CSV.

### Step 4: Create analysis/scripts/03_generate_figures.R
Extract all plotting code (lines 184-204, 229-239, 290-301, 335-347).

### Step 5: Update analysis/paper/index.qmd
- Add `library(plotting_utils)` header
- Replace inline data loading with `read_csv("data/...")`
- Replace inline plotting with figure includes: `![](figures/plot.png)`
- Replace inline model fitting with `read_csv("data/derived_data/model_coefficients.csv")`
- Keep only narrative, interpretation, and display code

### Step 6: Create analysis/data/raw_data/README.md
Document the mtcars dataset and its source.

### Step 7: Test the Pipeline
```bash
make docker-zsh
Rscript analysis/scripts/01_prepare_data.R
Rscript analysis/scripts/02_fit_models.R
Rscript analysis/scripts/03_generate_figures.R
exit

quarto render index.qmd
```

---

## Benefits of Refactoring

### 1. **Separation of Concerns**
- Analysis (scripts/) separate from narrative (paper/index.qmd)
- Utilities (R/) reusable across posts
- Data documentation (data/) discoverable

### 2. **Reproducibility**
- Scripts can run independently
- Clear execution order
- Easy to audit analysis

### 3. **Maintainability**
- Change theme once in R/plotting_utils.R, applies everywhere
- Update model in one place (analysis/scripts/02_fit_models.R)
- Blog post focuses on interpretation

### 4. **Reusability**
- plotting_utils.R used across all blog posts
- Analysis scripts become template for similar analyses
- Readers can adapt scripts to their own data

### 5. **Testing**
- Scripts can be unit tested
- Results can be validated
- Model assumptions can be verified independently

### 6. **Documentation**
- Script comments explain "why" not just "what"
- Data README provides context
- Code tells the full story

---

## rrtools/zzcollab Principles Applied

✅ **Compendium structure**: Clear separation of analysis/output/narrative
✅ **Reproducibility**: Scripts can run in fresh environment
✅ **Pipeline architecture**: Numbered scripts with clear dependencies
✅ **Utility reuse**: R/ functions used across multiple analyses
✅ **Data documentation**: Source data clearly documented
✅ **Version control**: All code and data tracked
✅ **Docker isolation**: Exact environment replicated

---

## Next Steps

1. Implement refactoring in small chunks (one script at a time)
2. Test each script independently
3. Update blog post incrementally
4. Document extraction decisions in commit messages
5. Use this as template for future posts

---

**Created**: 2025-12-08
**Status**: Proposed - ready for implementation
**Impact**: Improves architecture, maintainability, and reusability
