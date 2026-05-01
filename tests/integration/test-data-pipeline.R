# Integration Test: Data Pipeline
# Tests the complete data processing pipeline from raw data to analysis

library(testthat)
library(here)
library(palmerpenguins)

test_that("Data pipeline runs successfully", {
  # Test data import
  expect_no_error({
    data(penguins, package = "palmerpenguins")
  })
  
  # Check data structure
  expect_true(nrow(penguins) > 0)
  expect_true(ncol(penguins) >= 7)
  expect_true("bill_length_mm" %in% names(penguins))
  expect_true("body_mass_g" %in% names(penguins))
  
  # Test data cleaning
  clean_penguins <- penguins[complete.cases(penguins), ]
  expect_true(nrow(clean_penguins) > 0)
  expect_true(nrow(clean_penguins) <= nrow(penguins))
  
  # Test that analysis functions work
  expect_no_error({
    model <- lm(body_mass_g ~ bill_length_mm + species, data = clean_penguins)
  })
  
  # Verify model output
  expect_s3_class(model, "lm")
  expect_true(length(coef(model)) >= 2)
  expect_true(summary(model)$r.squared > 0)
})

test_that("Data validation passes", {
  data(penguins, package = "palmerpenguins")
  
  # Check expected species
  expected_species <- c("Adelie", "Chinstrap", "Gentoo")
  actual_species <- unique(penguins$species)
  expect_true(all(actual_species %in% expected_species))
  
  # Check measurement ranges
  clean_penguins <- penguins[!is.na(penguins$bill_length_mm), ]
  expect_true(all(clean_penguins$bill_length_mm > 0))
  expect_true(all(clean_penguins$bill_length_mm < 100))  # Reasonable upper bound
  
  clean_mass <- penguins[!is.na(penguins$body_mass_g), ]
  expect_true(all(clean_mass$body_mass_g > 0))
  expect_true(all(clean_mass$body_mass_g < 10000))  # Reasonable upper bound
})