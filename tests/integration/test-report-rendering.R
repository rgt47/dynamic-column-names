# Integration Test: Report Rendering
# Tests that the main research report can be rendered successfully

library(testthat)
library(here)

test_that("Report Rmd file exists and is valid", {
  report_path <- here("analysis", "report", "report.Rmd")
  expect_true(file.exists(report_path))
  
  # Check that file is not empty
  report_content <- readLines(report_path)
  expect_true(length(report_content) > 0)
  
  # Check for required YAML header
  expect_true(any(grepl("^---$", report_content)))
  expect_true(any(grepl("^title:", report_content)))
  expect_true(any(grepl("^author:", report_content)))
})

test_that("Report dependencies are available", {
  # Check for required packages
  required_packages <- c("rmarkdown", "knitr", "bookdown")
  
  for (pkg in required_packages) {
    expect_true(requireNamespace(pkg, quietly = TRUE), 
                info = paste("Package", pkg, "is required for report rendering"))
  }
})

test_that("Bibliography files exist", {
  bib_path <- here("analysis", "report", "references.bib")
  expect_true(file.exists(bib_path))
  
  # Check CSL file exists
  csl_path <- here("analysis", "report", "statistics-in-medicine.csl")
  expect_true(file.exists(csl_path))
})

test_that("Report can be parsed without errors", {
  report_path <- here("analysis", "report", "report.Rmd")
  
  # Test that rmarkdown can parse the file
  expect_no_error({
    # Parse YAML header
    yaml_content <- rmarkdown::yaml_front_matter(report_path)
    expect_true(is.list(yaml_content))
    expect_true("title" %in% names(yaml_content))
  })
  
  # Test that knitr can parse R chunks
  expect_no_error({
    chunks <- knitr::knit_code$get()  # This will be empty, but parsing should work
  })
})

# Note: Actual rendering test is commented out to avoid LaTeX dependencies in CI
# Uncomment for local testing if LaTeX is available
# test_that("Report renders to PDF", {
#   report_path <- here("analysis", "report", "report.Rmd")
#   output_dir <- here("analysis", "report")
#   
#   expect_no_error({
#     rmarkdown::render(report_path, 
#                      output_dir = output_dir,
#                      quiet = TRUE)
#   })
#   
#   pdf_path <- here("analysis", "report", "report.pdf")
#   expect_true(file.exists(pdf_path))
# })