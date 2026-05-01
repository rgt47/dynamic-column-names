# Data Development Workflow Guide

## Overview

This guide outlines the complete workflow for data receipt, preparation, validation, and testing in a zzcollab project. Follow this process to ensure reproducible, well-tested data pipelines that meet research standards.

## Why Data Testing is Critical for Reproducible Research

**Data testing is fundamental to scientific integrity and reproducible research.** Raw datasets often contain unexpected issues: missing values, encoding errors, duplicates, or values outside expected ranges. Without systematic validation, these problems can silently propagate through your analysis, leading to incorrect conclusions that appear statistically significant but are actually artifacts of data quality issues. For example, a single miscoded body mass measurement (e.g., 37500g instead of 3750g for a penguin) could dramatically skew regression results or correlation analyses.

**The consequences of inadequate data testing compound throughout the research pipeline.** When you process raw data without validation, transformation errors can introduce systematic biases that are difficult to detect later. Missing validation of derived datasets means you cannot verify that your processing logic worked correctly - you might unknowingly exclude important subgroups, incorrectly handle missing values, or introduce computational errors during transformations. These issues become particularly problematic in collaborative research environments where team members rely on processed datasets without understanding their provenance. Furthermore, without comprehensive testing, you cannot confidently share your data processing pipeline with other researchers, undermining the reproducibility that is essential for scientific credibility.

**Systematic data testing provides the foundation for trustworthy research outputs.** By implementing validation checks for both raw and processed datasets, you create a documented trail that demonstrates data quality and transformation correctness. This testing framework enables you to catch errors early (when they're easier to fix), provides confidence in your results, and creates transparent documentation that allows others to understand and reproduce your work. In collaborative settings, data tests serve as contracts between team members, ensuring that everyone can rely on shared datasets and processing functions to behave consistently and correctly.

## Documentation Structure and Best Practices

All documentation follows a structured approach for reproducible research:

### Primary Documentation Hub
- **`data/README.md`** - Central documentation for all data-related information with these sections:
  - **Data Source** - Origin, collection method, date received
  - **Known Issues** - Problems identified by source or during assessment  
  - **File Information** - File sizes, record counts, basic structure
  - **Data Dictionary** - Column descriptions, types, valid ranges
  - **Data Quality Assessment** - Missing data patterns, validation results
  - **Processing Plan** - Planned transformations and logic
  - **Processing Decisions** - Choices made for missing values, outliers
  - **Derived Data Dictionary** - New variables created during processing
  - **Processing Summary** - Final transformation details
  - **Reproduction** - Step-by-step instructions to recreate data
  - **Scripts** - Links to processing scripts
  - **Testing** - Links to validation tests

### Supporting Documentation Locations
- **`data/correspondence/`** - Email communications, data transfer notes
- **`figures/data_quality/`** - Diagnostic plots, quality assessment visualizations
- **`R/data_prep.R`** - Function documentation (roxygen2 comments)
- **`scripts/01_data_preparation.R`** - Inline processing comments
- **`tests/testthat/test-data_prep.R`** - Test documentation and examples

### Documentation Workflow
1. **Immediate documentation** (during data receipt) → `data/README.md`
2. **Ongoing updates** (during analysis) → Add to appropriate sections
3. **Final documentation** (before deployment) → Complete all sections

### Example README Section Structure (Palmer Penguins)
```markdown
# Palmer Penguins Data Documentation

## Data Source
- **Origin**: palmerpenguins R package, Allison Horst et al.
- **Collection**: Palmer Station LTER penguin census data (2007-2009)
- **Date Received**: 2024-08-19 (via R package installation)
- **Contact**: Dr. Kristen Gorman, Palmer Station LTER
- **Citation**: Horst AM, Hill AP, Gorman KB (2020). palmerpenguins: Palmer Archipelago (Antarctica) penguin data.

## Known Issues
- Missing sex data for 11 penguins 
- Missing bill measurements for 2 penguins (rows 4, 272)
- Missing body mass for 2 penguins (rows 4, 272)
- Missing flipper length for 2 penguins (rows 4, 272)

## File Information
- **Raw file**: `data/raw_data/penguins.csv`
- **File size**: 13.8 KB
- **Records**: 344 penguins
- **Columns**: 8 variables
- **Years**: 2007, 2008, 2009

## Data Dictionary
| Column | Type | Description | Valid Range | Missing Code |
|--------|------|-------------|-------------|--------------|
| species | character | Penguin species | Adelie, Chinstrap, Gentoo | NA |
| island | character | Island name | Biscoe, Dream, Torgersen | NA |
| bill_length_mm | numeric | Bill length in millimeters | 32.1-59.6 | NA |
| bill_depth_mm | numeric | Bill depth in millimeters | 13.1-21.5 | NA |
| flipper_length_mm | integer | Flipper length in millimeters | 172-231 | NA |
| body_mass_g | integer | Body mass in grams | 2700-6300 | NA |
| sex | character | Penguin sex | female, male | NA |
| year | integer | Study year | 2007, 2008, 2009 | NA |

## Processing Decisions
- Create subset with first 50 records for initial analysis
- Remove penguins with missing body mass (affects 2 records)
- Add log transformation: log_body_mass_g = log(body_mass_g)
- Retain all species (Adelie: 152, Chinstrap: 68, Gentoo: 124)
- Keep original units (grams) for body mass
```

## Workflow Phases

1. **Data Receipt & Initial Setup**
2. **Data Exploration & Validation**  
3. **Data Preparation Development**
4. **Unit Testing & Validation**
5. **Integration Testing & Documentation**
6. **Final Validation & Deployment**

---

## Phase 1: Data Receipt & Initial Setup

> **HOST SYSTEM OPERATIONS** - All Phase 1 tasks are performed on your host system, outside of Docker containers.

### 📥 Data Receipt Checklist

- [ ] **Create project structure (HOST)**
  ```bash
  # If new project - run on host system
  zzcollab -p your-project-name
  cd your-project-name
  ```

- [ ] **Receive and document data source (HOST)**
  - [ ] Obtain data files from collaborator/source
  - [ ] **Document data origin, collection method, date received** → `data/README.md` (Data Source section)
  - [ ] **Note any known issues or preprocessing by source** → `data/README.md` (Known Issues section)
  - [ ] **Save email/communication about data context** → `data/correspondence/` directory (create if needed)

- [ ] **Place raw data in proper location (HOST)**
  ```bash
  # Copy Palmer Penguins data to raw_data directory - NEVER modify these files
  # This creates persistent storage on host filesystem
  cp /path/to/received/penguins.csv data/raw_data/
  
  # Or if extracting from R package:
  # R -e "write.csv(palmerpenguins::penguins, 'data/raw_data/penguins.csv', row.names = FALSE)"
  ```

- [ ] **Update data README with source information (HOST)**
  ```bash
  # Edit on host system using your preferred editor
  vim data/README.md    # or nano, code, etc.
  
  # Create correspondence directory for communications
  mkdir -p data/correspondence
  ```
  - [ ] **Edit `data/README.md` with actual data source details** → Data Source section
  - [ ] **Document expected vs. actual column names and types** → Data Dictionary section  
  - [ ] **Note file size, number of records received** → File Information section
  - [ ] **Document any known data quality issues from source** → Known Issues section

- [ ] **Enter Docker container for data analysis**
  ```bash
  # NOW enter container - data files are automatically mounted and available
  make docker-zsh     # or make docker-rstudio for RStudio interface
  ```

- [ ] **Initial data inspection (CONTAINER)**
  ```r
  # Inside container - quick look at Palmer Penguins data structure
  library(here)
  penguins_raw <- read.csv(here("data", "raw_data", "penguins.csv"))
  
  head(penguins_raw)
  str(penguins_raw)
  summary(penguins_raw)
  
  # Check specific penguin data characteristics
  table(penguins_raw$species)      # Species counts
  table(penguins_raw$island)       # Island distribution
  sum(is.na(penguins_raw))         # Total missing values
  
  # Exit container when done with initial inspection
  # Type 'exit' to return to host system
  ```

### 📋 Initial Assessment Questions

- [ ] Does data match expectations from collaborator description?
- [ ] Are column names and types as expected?
- [ ] Are there obvious data quality issues (negative values, extreme outliers)?
- [ ] Is the data complete or are there systematic missing patterns?

---

## Phase 2: Data Exploration & Validation

> **CONTAINER OPERATIONS** - All Phase 2+ tasks are performed inside Docker containers with your R environment.

### 🔍 Data Quality Assessment Checklist

- [ ] **Enter container if not already inside**
  ```bash
  # On host system
  make docker-zsh     # or make docker-rstudio
  ```

- [ ] **Run basic data validation (CONTAINER)**
  ```r
  # Inside container
  library(here)
  source(here("R", "data_prep.R"))
  
  # Load Palmer Penguins raw data
  penguins_raw <- read.csv(here("data", "raw_data", "penguins.csv"))
  
  # Run validation (using actual Palmer Penguins validation function)
  is_valid <- validate_penguin_data(penguins_raw)
  if (!is_valid) {
    cat("Validation errors:\n")
    cat(paste(attr(penguins_raw, "validation_errors"), collapse = "\n"))
  }
  
  # Specific Palmer Penguins checks
  cat("Species found:", paste(unique(penguins_raw$species), collapse = ", "), "\n")
  cat("Islands found:", paste(unique(penguins_raw$island), collapse = ", "), "\n")
  cat("Year range:", min(penguins_raw$year, na.rm = TRUE), "-", max(penguins_raw$year, na.rm = TRUE), "\n")
  ```

- [ ] **Generate data quality report (CONTAINER)**
  ```r
  # Palmer Penguins specific quality checks
  missing_summary <- sapply(penguins_raw, function(x) sum(is.na(x)))
  print(missing_summary)
  
  # Check for duplicates
  duplicate_count <- nrow(penguins_raw) - nrow(unique(penguins_raw))
  cat("Duplicate rows:", duplicate_count, "\n")
  
  # Check value ranges for Palmer Penguins numeric columns
  numeric_cols <- c("bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g")
  summary(penguins_raw[numeric_cols])
  
  # Palmer Penguins specific checks
  cat("Body mass range:", min(penguins_raw$body_mass_g, na.rm = TRUE), "-", 
      max(penguins_raw$body_mass_g, na.rm = TRUE), "grams\n")
  cat("Bill length range:", min(penguins_raw$bill_length_mm, na.rm = TRUE), "-",
      max(penguins_raw$bill_length_mm, na.rm = TRUE), "mm\n")
  ```

- [ ] **Document data quality findings (HOST/CONTAINER)**
  ```bash
  # Exit container to edit documentation on host
  exit
  
  # Edit on host system
  vim data/README.md    # Add quality assessment results
  
  # Re-enter container to continue analysis
  make docker-zsh
  ```
  - [ ] **Update `data/README.md` with quality assessment results** → Data Quality Assessment section
  - [ ] **Note any data cleaning needs identified** → Processing Notes section
  - [ ] **Document decisions about handling missing values, outliers** → Processing Decisions section
  - [ ] **Save quality assessment plots/reports** → `figures/data_quality/` directory

- [ ] **Create initial data visualization (CONTAINER)**
  ```r
  # Palmer Penguins exploratory plots
  library(ggplot2)
  
  # Create figures directory if needed
  if (!dir.exists("figures/data_quality")) {
    dir.create("figures/data_quality", recursive = TRUE)
  }
  
  # Body mass distribution by species
  p1 <- ggplot(penguins_raw, aes(x = body_mass_g, fill = species)) + 
    geom_histogram(bins = 30, alpha = 0.7) + 
    labs(title = "Palmer Penguins: Body Mass Distribution by Species",
         x = "Body Mass (g)", y = "Count") +
    facet_wrap(~species)
  ggsave("figures/data_quality/body_mass_distribution.png", p1, width = 10, height = 6)
  
  # Bill dimensions scatter plot
  p2 <- ggplot(penguins_raw, aes(x = bill_length_mm, y = bill_depth_mm, color = species)) +
    geom_point(alpha = 0.7) +
    labs(title = "Palmer Penguins: Bill Dimensions by Species",
         x = "Bill Length (mm)", y = "Bill Depth (mm)")
  ggsave("figures/data_quality/bill_dimensions.png", p2, width = 8, height = 6)
  
  # Missing data pattern
  library(dplyr)
  missing_pattern <- penguins_raw %>%
    summarise(across(everything(), ~sum(is.na(.))))
  print(missing_pattern)
  ```
  - [ ] **Save diagnostic plots** → `figures/data_quality/` directory
  - [ ] **Reference plots in README** → `data/README.md` Data Quality section

### ❓ Quality Assessment Questions

- [ ] What percentage of data is missing overall?
- [ ] Are missing values random or systematic?
- [ ] Do numeric values fall in expected ranges?
- [ ] Are categorical variables using expected values?
- [ ] Do relationships between variables make sense?

---

## Phase 3: Data Preparation Development

> **CONTAINER OPERATIONS** - Development work happens inside containers, with documentation updates on host.

### 🛠 Data Processing Development Checklist

- [ ] **Design data processing pipeline (CONTAINER)**
  - [ ] Define transformation requirements (subset, aggregation, derivation)
  - [ ] Identify which columns need processing
  - [ ] Plan handling of missing values and outliers
  - [ ] **Document expected output structure** → `data/README.md` Processing Plan section
  - [ ] **Document transformation logic** → Function documentation in `R/data_prep.R`

- [ ] **Develop data preparation functions (CONTAINER)** 
  ```r
  # Inside container - edit R/data_prep.R for Palmer Penguins processing
  # Actual Palmer Penguins data preparation function:
  prepare_penguin_data <- function(data, n_records = 50) {
    # Input validation
    if (!is.data.frame(data)) {
      stop("Input must be a data frame")
    }
    
    # Required columns check for Palmer Penguins
    required_cols <- c("species", "island", "bill_length_mm", "bill_depth_mm", 
                       "flipper_length_mm", "body_mass_g", "sex", "year")
    missing_cols <- setdiff(required_cols, names(data))
    if (length(missing_cols) > 0) {
      stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
    }
    
    # Palmer Penguins specific processing steps
    library(dplyr)
    result <- data %>%
      slice_head(n = n_records) %>%                    # First n records
      filter(!is.na(body_mass_g)) %>%                  # Remove missing body mass
      mutate(log_body_mass_g = log(body_mass_g)) %>%   # Add log transformation
      mutate(species = as.factor(species),             # Ensure factors
             island = as.factor(island),
             sex = as.factor(sex))
    
    return(result)
  }
  ```

- [ ] **Create data processing script (CONTAINER)**
  ```r
  # Inside container - create scripts/01_data_preparation.R
  library(here)
  library(dplyr)
  
  source(here("R", "data_prep.R"))
  
  # Load Palmer Penguins raw data
  penguins_raw <- read.csv(here("data", "raw_data", "penguins.csv"))
  
  # Apply Palmer Penguins processing (first 50 records with log transformation)
  penguins_subset <- prepare_penguin_data(penguins_raw, n_records = 50)
  
  # Save processed data
  write.csv(penguins_subset, 
           here("data", "derived_data", "penguins_subset.csv"),
           row.names = FALSE)
  
  # Generate processing summary
  cat("Palmer Penguins processing completed:\n")
  cat("Input rows:", nrow(penguins_raw), "\n")
  cat("Output rows:", nrow(penguins_subset), "\n")
  cat("Species distribution:", table(penguins_subset$species), "\n")
  cat("Columns added:", setdiff(names(penguins_subset), names(penguins_raw)), "\n")
  cat("Log body mass range:", min(penguins_subset$log_body_mass_g), "-", 
      max(penguins_subset$log_body_mass_g), "\n")
  ```

- [ ] **Test data processing interactively (CONTAINER)**
  - [ ] Run processing on small sample first
  - [ ] Verify transformations produce expected results
  - [ ] Check edge cases (empty data, single row, all missing)

### Development Best Practices

- [ ] Write functions that do one thing well
- [ ] Include comprehensive input validation
- [ ] Use meaningful parameter names and defaults  
- [ ] Add informative error messages
- [ ] Document function parameters and return values

---

## Phase 4: Unit Testing & Validation

> **CONTAINER OPERATIONS** - Test development and execution happens inside containers.

### Test Development Checklist

- [ ] **Create unit tests for data functions (CONTAINER)**
  ```r
  # Inside container - edit tests/testthat/test-data_prep.R
  test_that("prepare_penguin_data works with valid Palmer Penguins input", {
    # Create Palmer Penguins test data
    test_penguins <- data.frame(
      species = c("Adelie", "Chinstrap", "Gentoo"),
      island = c("Torgersen", "Dream", "Biscoe"),
      bill_length_mm = c(39.1, 48.7, 46.1),
      bill_depth_mm = c(18.7, 14.1, 13.2),
      flipper_length_mm = c(181, 196, 211),
      body_mass_g = c(3750, 3800, 4500),
      sex = c("male", "female", "male"),
      year = c(2007, 2008, 2009)
    )
    
    # Test Palmer Penguins function
    result <- prepare_penguin_data(test_penguins, n_records = 3)
    
    # Palmer Penguins specific assertions
    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), 3)
    expect_true("log_body_mass_g" %in% names(result))
    expect_true(all(result$species %in% c("Adelie", "Chinstrap", "Gentoo")))
    expect_true(is.factor(result$species))
    expect_true(all(result$log_body_mass_g > 0))  # Log values should be positive
  })
  ```

- [ ] **Test input validation (CONTAINER)**
  ```r
  test_that("prepare_penguin_data validates inputs correctly", {
    # Test invalid input types
    expect_error(
      prepare_penguin_data("not a dataframe"),
      "Input must be a data frame"
    )
    
    # Test missing required Palmer Penguins columns
    incomplete_penguins <- data.frame(species = "Adelie", island = "Torgersen")
    expect_error(
      prepare_penguin_data(incomplete_penguins),
      "Missing required columns"
    )
    
    # Test with missing body_mass_g column specifically
    no_body_mass <- data.frame(
      species = "Adelie", island = "Torgersen", bill_length_mm = 39.1,
      bill_depth_mm = 18.7, flipper_length_mm = 181, sex = "male", year = 2007
    )
    expect_error(
      prepare_penguin_data(no_body_mass),
      "Missing required columns.*body_mass_g"
    )
  })
  ```

- [ ] **Test edge cases (CONTAINER)**
  ```r
  test_that("prepare_penguin_data handles edge cases", {
    # Empty Palmer Penguins data
    empty_penguins <- data.frame(
      species = character(0), island = character(0), bill_length_mm = numeric(0),
      bill_depth_mm = numeric(0), flipper_length_mm = integer(0), 
      body_mass_g = integer(0), sex = character(0), year = integer(0)
    )
    result <- prepare_penguin_data(empty_penguins)
    expect_equal(nrow(result), 0)
    expect_true("log_body_mass_g" %in% names(result))
    
    # Single penguin
    single_penguin <- data.frame(
      species = "Adelie", island = "Torgersen", bill_length_mm = 39.1,
      bill_depth_mm = 18.7, flipper_length_mm = 181, body_mass_g = 3750,
      sex = "male", year = 2007
    )
    result <- prepare_penguin_data(single_penguin, n_records = 1)
    expect_equal(nrow(result), 1)
    expect_equal(result$log_body_mass_g, log(3750))
    
    # Penguins with missing body mass (should be filtered out)
    penguins_with_na <- data.frame(
      species = c("Adelie", "Chinstrap"), island = c("Torgersen", "Dream"),
      bill_length_mm = c(39.1, NA), bill_depth_mm = c(18.7, 14.1),
      flipper_length_mm = c(181, 196), body_mass_g = c(3750, NA),
      sex = c("male", "female"), year = c(2007, 2008)
    )
    result <- prepare_penguin_data(penguins_with_na, n_records = 2)
    expect_equal(nrow(result), 1)  # Only one penguin with valid body mass
    expect_equal(result$species, factor("Adelie"))
  })
  ```

- [ ] **Create data file validation tests (CONTAINER)**
  ```r
  # Edit tests/testthat/test-data_files.R
  test_that("Palmer Penguins raw data file has expected structure", {
    data_file <- here("data", "raw_data", "penguins.csv")
    skip_if_not(file.exists(data_file), "Palmer Penguins data file not found")
    
    penguins_raw <- read.csv(data_file, stringsAsFactors = FALSE)
    
    # Test Palmer Penguins structure
    expect_s3_class(penguins_raw, "data.frame")
    expect_equal(nrow(penguins_raw), 344)  # Known Palmer Penguins count
    
    # Test expected Palmer Penguins columns
    expected_cols <- c("species", "island", "bill_length_mm", "bill_depth_mm", 
                       "flipper_length_mm", "body_mass_g", "sex", "year")
    expect_true(all(expected_cols %in% names(penguins_raw)))
    
    # Test species values
    expect_true(all(penguins_raw$species %in% c("Adelie", "Chinstrap", "Gentoo")))
    
    # Test island values
    expect_true(all(penguins_raw$island %in% c("Torgersen", "Biscoe", "Dream")))
    
    # Test year range
    expect_true(all(penguins_raw$year %in% c(2007, 2008, 2009)))
  })
  ```

- [ ] **Run unit tests (CONTAINER or HOST)**
  ```bash
  # Option 1: Inside container
  make test
  R -e "testthat::test_file('tests/testthat/test-data_prep.R')"
  
  # Option 2: From host system (runs in clean container)
  exit  # Exit current container first
  make docker-test  # Run tests in clean environment
  ```

### ✅ Unit Testing Standards

- [ ] Test happy path (valid inputs, expected outputs)
- [ ] Test input validation (invalid types, missing columns)
- [ ] Test edge cases (empty data, single row, extreme values)
- [ ] Test error handling (meaningful error messages)
- [ ] Achieve >90% code coverage for data functions

---

## Phase 5: Integration Testing & Documentation

> **CONTAINER + HOST OPERATIONS** - Testing in containers, documentation updates on host.

### 🔄 Integration Testing Checklist

- [ ] **Create full pipeline tests (CONTAINER)**
  ```r
  # Inside container - edit tests/integration/test-data_pipeline.R
  test_that("complete data pipeline runs successfully", {
    # Load raw data
    raw_data_file <- here("data", "raw_data", "your_data.csv")
    skip_if_not(file.exists(raw_data_file), "Raw data not available")
    
    raw_data <- read.csv(raw_data_file, stringsAsFactors = FALSE)
    
    # Run full pipeline
    processed_data <- prepare_your_data(raw_data)
    
    # Test pipeline results
    expect_s3_class(processed_data, "data.frame")
    expect_gt(nrow(processed_data), 0)
    # Add specific expectations for your transformations
  })
  ```

- [ ] **Test file consistency**
  ```r
  test_that("derived data file matches pipeline output", {
    raw_file <- here("data", "raw_data", "your_data.csv")
    derived_file <- here("data", "derived_data", "processed_data.csv")
    
    skip_if_not(file.exists(raw_file) && file.exists(derived_file))
    
    # Load both datasets
    raw_data <- read.csv(raw_file, stringsAsFactors = FALSE)
    derived_data_file <- read.csv(derived_file, stringsAsFactors = FALSE)
    
    # Recreate derived data using pipeline
    derived_data_pipeline <- prepare_your_data(raw_data)
    
    # Compare key characteristics
    expect_equal(nrow(derived_data_file), nrow(derived_data_pipeline))
    expect_equal(sort(names(derived_data_file)), sort(names(derived_data_pipeline)))
  })
  ```

- [ ] **Run integration tests (CONTAINER)**
  ```bash
  # Inside container
  R -e "testthat::test_file('tests/integration/test-data_pipeline.R')"
  ```

- [ ] **Update documentation (HOST)**
  ```bash
  # Exit container to edit documentation
  exit
  
  # Edit comprehensive documentation on host
  vim data/README.md
  
  # Re-enter container if needed for more testing
  make docker-zsh
  ```
  - [ ] **Complete `data/README.md` with final processing details** → Processing Summary section
  - [ ] **Document all derived variables and their creation** → Derived Data Dictionary section
  - [ ] **Include data quality assessment results** → Data Quality section
  - [ ] **Add reproduction instructions** → Reproduction section
  - [ ] **Link to processing scripts** → Scripts section (`scripts/01_data_preparation.R`)
  - [ ] **Reference test files** → Testing section (`tests/testthat/test-data_prep.R`)

### Integration Requirements

- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Derived data files match pipeline output
- [ ] Documentation is complete and accurate
- [ ] Processing is reproducible

---

## Phase 6: Final Validation & Deployment

> **CONTAINER + HOST OPERATIONS** - Final validation uses both environments.

### Final Validation Checklist

- [ ] **Run complete test suite (HOST)**
  ```bash
  # From host system - runs all tests in clean environment
  make docker-test
  
  # Check test coverage inside container
  make docker-zsh
  R -e "covr::package_coverage()"
  exit
  ```

- [ ] **Validate reproducibility (HOST)**
  ```bash
  # Delete derived data and recreate - on host system
  rm data/derived_data/*
  
  # Enter container to recreate data
  make docker-zsh
  source("scripts/01_data_preparation.R")
  exit
  
  # Run tests again to ensure consistency
  make docker-test
  ```

- [ ] **Generate final data quality report (CONTAINER)**
  ```bash
  # Enter container for final reporting
  make docker-zsh
  ```
  ```r
  # Inside container
  source(here("R", "data_prep.R"))
  
  # Load final processed data
  final_data <- read.csv(here("data", "derived_data", "processed_data.csv"))
  
  # Generate comprehensive summary
  summary_stats <- summarize_your_data(final_data)  # Use your summary function
  print(summary_stats)
  
  # Save quality report
  write.csv(summary_stats, here("data", "derived_data", "quality_report.csv"))
  ```

- [ ] **Create data processing log (CONTAINER)**
  ```r
  # Inside container - document processing metadata
  processing_log <- data.frame(
    step = c("data_received", "quality_check", "processing", "validation"),
    date = Sys.Date(),
    status = c("complete", "complete", "complete", "complete"),
    notes = c("Data from collaborator X", "See quality_report.csv", "Applied transformations", "All tests pass")
  )
  
  write.csv(processing_log, here("data", "processing_log.csv"), row.names = FALSE)
  
  # Exit container
  exit
  ```

- [ ] **Final checklist review**
  - [ ] All tests pass (unit + integration)
  - [ ] Documentation complete
  - [ ] Code follows project style standards  
  - [ ] Data quality acceptable for analysis
  - [ ] Processing is reproducible
  - [ ] Files are properly organized

### 📋 Deployment Standards

- [ ] Test coverage >90%
- [ ] No failing tests
- [ ] Documentation complete
- [ ] Code review completed (if team project)
- [ ] Data quality meets research standards

---

## Summary Checklist

### For New Data Receipt (HOST SYSTEM):
1. [ ] **HOST**: Place raw data in `data/raw_data/`
2. [ ] **HOST**: Update `data/README.md` with source info
3. [ ] **CONTAINER**: Enter container (`make docker-zsh`)
4. [ ] **CONTAINER**: Run initial inspection (`str()`, `summary()`)
5. [ ] **HOST**: Document quality issues in README

### For Data Processing (CONTAINER):
1. [ ] **CONTAINER**: Design processing pipeline
2. [ ] **CONTAINER**: Develop functions in `R/data_prep.R` 
3. [ ] **CONTAINER**: Create processing script `scripts/01_data_preparation.R`
4. [ ] **CONTAINER**: Test interactively with sample data
5. [ ] **CONTAINER**: Save processed data to `data/derived_data/`

### For Testing (CONTAINER + HOST):
1. [ ] **CONTAINER**: Write unit tests in `tests/testthat/test-data_prep.R`
2. [ ] **CONTAINER**: Write data validation tests in `tests/testthat/test-data_files.R`
3. [ ] **CONTAINER**: Write integration tests in `tests/integration/test-data_pipeline.R`
4. [ ] **HOST**: Run all tests: `make docker-test`
5. [ ] **CONTAINER**: Achieve >90% test coverage

### For Final Validation (HOST + CONTAINER):
1. [ ] **HOST**: All tests pass (`make docker-test`)
2. [ ] **HOST**: Documentation complete in `data/README.md`
3. [ ] **HOST**: Processing reproducible (delete + recreate test)
4. [ ] **CONTAINER**: Data quality acceptable
5. [ ] **READY**: Code ready for analysis phase

---

## 🛠 Useful Commands

### Host System Commands
```bash
# Enter/exit Docker containers
make docker-zsh      # Enter shell container
make docker-rstudio  # Enter RStudio container (localhost:8787)
exit                 # Exit any container

# Run tests from host (clean environment)
make docker-test     # All tests in clean container
make test           # Tests in current container (if inside one)

# File operations
cp /path/to/data.csv data/raw_data/  # Copy data files
vim data/README.md                   # Edit documentation

# Reproducibility validation
rm data/derived_data/*  # Delete derived data for testing
```

### Container Commands
```bash
# Inside container - R development
R                    # Start R session
devtools::load_all() # Load package functions
devtools::test()     # Run tests

# Inside container - run scripts
Rscript scripts/01_data_preparation.R

# Inside container - specific test files
R -e "testthat::test_file('tests/testthat/test-data_prep.R')"
R -e "testthat::test_file('tests/integration/test-data_pipeline.R')"

# Inside container - test coverage
R -e "covr::package_coverage()"
```

## 📞 Troubleshooting

**Tests failing?**
- Check that raw data file exists in `data/raw_data/`
- Verify column names match expectations
- Check for missing required packages

**Data validation errors?**
- Review data quality report
- Check for unexpected values or missing data
- Verify data types match expectations

**Pipeline not reproducible?**
- Ensure all random seeds are set
- Check file paths use `here::here()`
- Verify no hard-coded absolute paths

---

*Follow this workflow to ensure robust, tested, and reproducible data processing in your zzcollab projects!*