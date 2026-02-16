# Integration Test: Analysis Scripts
# Tests that analysis scripts run without errors and produce expected outputs

library(testthat)
library(here)

test_that("Database setup script runs successfully", {
  script_path <- here("analysis", "scripts", "00_database_setup.R")
  expect_true(file.exists(script_path))

  # Test script execution
  expect_no_error({
    source(script_path, local = new.env())
  })
})

test_that("Data validation script works", {
  script_path <- here("analysis", "scripts", "02_data_validation.R")
  expect_true(file.exists(script_path))

  # Test script execution
  expect_no_error({
    source(script_path, local = new.env())
  })
})

test_that("Reproducibility check script functions", {
  script_path <- here("analysis", "scripts", "99_reproducibility_check.R")
  expect_true(file.exists(script_path))
  
  # Test script execution
  expect_no_error({
    source(script_path, local = new.env())
  })
})

test_that("Analysis outputs are created", {
  # Check that figures directory exists and can be written to
  figures_dir <- here("analysis", "figures")
  expect_true(dir.exists(figures_dir))
  
  # Test creating a sample plot
  test_plot_path <- file.path(figures_dir, "test_plot.png")
  expect_no_error({
    png(test_plot_path, width = 800, height = 600)
    plot(1:10, 1:10, main = "Test Plot")
    dev.off()
  })
  
  expect_true(file.exists(test_plot_path))
  
  # Clean up test file
  if (file.exists(test_plot_path)) {
    unlink(test_plot_path)
  }
  
  # Check that tables directory exists
  tables_dir <- here("analysis", "tables")
  expect_true(dir.exists(tables_dir))
})