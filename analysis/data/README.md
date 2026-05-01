# Data Directory

This directory contains all data files for the project, organized by processing stage.

## Directory Structure

```
data/
├── raw_data/           # Original, untouched data files
├── derived_data/       # Cleaned and processed data files
└── README.md          # This file - data documentation
```

## Raw Data (`raw_data/`)

**Source**: Palmer Station Antarctica LTER and K. Gorman (CSV export)  
**Date collected**: 2007-2009  
**Collected by**: Dr. Kristen Gorman, Palmer Station Antarctica LTER

| File | Description | Size | Format |
|------|-------------|------|---------|
| `penguins.csv` | Palmer Penguins dataset with morphometric measurements | ~8 KB | CSV |

### Important Notes:
- **DO NOT MODIFY** files in `raw_data/` - these are the source of truth
- Original data from palmerpenguins R package, exported as CSV
- Missing values coded as: `NA`
- Contains 344 observations of 8 variables

## Derived Data (`derived_data/`)

Processed data files created by analysis scripts. These can be regenerated from raw data.

| File | Source Script | Description | Created |
|------|---------------|-------------|---------|
| `penguins_subset.csv` | `scripts/01_data_preparation.R` | First 50 records with log-transformed body mass | [Date] |

### Processing Steps Applied:
- Selected first 50 records from original dataset
- Created log-transformed body mass variable (`log_body_mass_g`)
- Retained all original variables for reference
- Filtered out any records with missing body mass values

## Data Dictionary

### Raw Penguin Data Fields (`penguins.csv`)
| Column | Type | Description | Valid Values | Missing Code |
|--------|------|-------------|--------------|--------------|
| `species` | character | Penguin species | Adelie, Chinstrap, Gentoo | NA |
| `island` | character | Island in Palmer Archipelago | Biscoe, Dream, Torgersen | NA |
| `bill_length_mm` | numeric | Bill length in millimeters | 32.1-59.6 | NA |
| `bill_depth_mm` | numeric | Bill depth in millimeters | 13.1-21.5 | NA |
| `flipper_length_mm` | integer | Flipper length in millimeters | 172-231 | NA |
| `body_mass_g` | integer | Body mass in grams | 2700-6300 | NA |
| `sex` | character | Penguin sex | male, female | NA |
| `year` | integer | Study year | 2007, 2008, 2009 | None |

### Derived Penguin Data Fields (`penguins_subset.csv`)
| Column | Type | Description | Units | Range | Missing Code |
|--------|------|-------------|-------|-------|--------------|
| `species` | character | Penguin species (unchanged) | - | Adelie, Chinstrap, Gentoo | NA |
| `island` | character | Island location (unchanged) | - | Biscoe, Dream, Torgersen | NA |
| `bill_length_mm` | numeric | Bill length (unchanged) | mm | 32.1-59.6 | NA |
| `bill_depth_mm` | numeric | Bill depth (unchanged) | mm | 13.1-21.5 | NA |
| `flipper_length_mm` | integer | Flipper length (unchanged) | mm | 172-231 | NA |
| `body_mass_g` | integer | Body mass (unchanged) | g | 2700-6300 | NA |
| `log_body_mass_g` | numeric | Natural log of body mass | log(g) | ~7.9-8.7 | NA |
| `sex` | character | Penguin sex (unchanged) | - | male, female | NA |
| `year` | integer | Study year (unchanged) | - | 2007, 2008, 2009 | None |

## Data Quality Notes

### Known Issues:
- Original dataset has some missing values in `bill_length_mm`, `bill_depth_mm`, `flipper_length_mm`, and `sex` variables
- Missing body mass values are excluded from subset (log transformation requires non-missing, positive values)
- Subset represents only first 50 records, may not be representative of full dataset

### Quality Checks Performed:
- Verified all body mass values are positive before log transformation
- Confirmed subset maintains original data types and relationships
- Validated log transformation produces reasonable values (7.9-8.7 range)

## Example Usage

### Load and explore subset data:
```r
library(here)
library(dplyr)

# Load processed data
penguins_subset <- read.csv(here("data", "derived_data", "penguins_subset.csv"))

# Quick summary
summary(penguins_subset$log_body_mass_g)

# Compare original vs log-transformed
plot(penguins_subset$body_mass_g, penguins_subset$log_body_mass_g)
```

## Reproducibility

To regenerate all derived data:
```r
source("scripts/01_data_preparation.R")
```

Example data preparation script:
```r
# scripts/01_data_preparation.R
library(here)
library(dplyr)

# Read raw penguins data
penguins_raw <- read.csv(here("data", "raw_data", "penguins.csv"))

# Create subset with first 50 records and log transformation
penguins_subset <- penguins_raw %>%
  slice_head(n = 50) %>%                    # First 50 records
  filter(!is.na(body_mass_g)) %>%           # Remove missing body mass
  mutate(log_body_mass_g = log(body_mass_g)) # Add log transformation

# Save processed data
write.csv(penguins_subset, 
         here("data", "derived_data", "penguins_subset.csv"),
         row.names = FALSE)
```

## References

- Gorman KB, Williams TD, Fraser WR (2014). Ecological sexual dimorphism and environmental variability within a community of Antarctic penguins (genus Pygoscelis). PLoS ONE 9(3):e90081. https://doi.org/10.1371/journal.pone.0090081
- Horst AM, Hill AP, Gorman KB (2020). palmerpenguins: Palmer Archipelago (Antarctica) penguin data. R package version 0.1.0. https://allisonhorst.github.io/palmerpenguins/

## Contact

For questions about this data, contact:
- **Original data source**: Dr. Kristen Gorman, kgorman@ucsd.edu  
- **Data analyst**: [Your name, email]
- **Project lead**: [Your name, email]

---
*Last updated*: [YYYY-MM-DD]  
*Generated by*: [Your name]