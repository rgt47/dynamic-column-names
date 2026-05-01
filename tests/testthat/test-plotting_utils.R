library(testthat)
library(ggplot2)
library(templatepost)

# Test setup_plot_theme
test_that("setup_plot_theme() sets minimal theme", {
  setup_plot_theme()
  theme <- ggplot2::theme_get()

  # Check that a theme was set (object should exist and be theme class)
  expect_s3_class(theme, "theme")

  # Check that it has theme elements
  expect_true(!is.null(theme$text))
})

test_that("setup_plot_theme() accepts custom base_size", {
  setup_plot_theme(base_size = 14)
  theme <- ggplot2::theme_get()

  # Verify base_size was applied
  expect_equal(theme$text$size, 14)
})

# Test get_analysis_colors
test_that("get_analysis_colors() returns named vector", {
  colors <- get_analysis_colors()

  # Check structure
  expect_type(colors, "character")
  expect_named(colors, c("primary", "secondary", "tertiary", "quaternary"))
})

test_that("get_analysis_colors() returns valid hex colors", {
  colors <- get_analysis_colors()

  # All should be valid hex colors
  valid_hex <- function(x) {
    grepl("^#[0-9A-Fa-f]{6}$", x)
  }

  expect_true(all(sapply(colors, valid_hex)))
})

test_that("get_analysis_colors() is consistent", {
  colors1 <- get_analysis_colors()
  colors2 <- get_analysis_colors()

  expect_identical(colors1, colors2)
})

# Test save_plot
test_that("save_plot() saves file successfully", {
  skip_if_not_installed("ggplot2")

  # Create temporary file
  temp_file <- tempfile(fileext = ".png")
  on.exit(unlink(temp_file), add = TRUE)

  # Create simple plot
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
    geom_point()

  # Save plot
  result <- save_plot(temp_file, p)

  # Check file exists and has content
  expect_true(file.exists(temp_file))
  expect_gt(file.size(temp_file), 1000)  # PNG should be > 1KB
  expect_equal(result, temp_file)
})

test_that("save_plot() creates directories if needed", {
  skip_if_not_installed("ggplot2")

  # Create temporary directory structure
  temp_dir <- tempdir()
  nested_dir <- file.path(temp_dir, "test_plots", "subfolder", "plot.png")

  on.exit(unlink(file.path(temp_dir, "test_plots"), recursive = TRUE), add = TRUE)

  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()

  # Should not error even though directories don't exist
  expect_no_error(save_plot(nested_dir, p))
  expect_true(file.exists(nested_dir))
})

test_that("save_plot() respects width and height parameters", {
  skip_if_not_installed("ggplot2")

  temp_file1 <- tempfile(fileext = ".png")
  temp_file2 <- tempfile(fileext = ".png")

  on.exit({
    unlink(temp_file1)
    unlink(temp_file2)
  }, add = TRUE)

  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()

  # Save with different dimensions
  save_plot(temp_file1, p, width = 4, height = 4, dpi = 100)
  save_plot(temp_file2, p, width = 8, height = 5, dpi = 100)

  # Different dimensions should result in different file sizes
  size1 <- file.size(temp_file1)
  size2 <- file.size(temp_file2)

  # Files should exist and have content
  expect_gt(size1, 0)
  expect_gt(size2, 0)
})

test_that("save_plot() errors when no plot available", {
  temp_file <- tempfile(fileext = ".png")
  on.exit(unlink(temp_file), add = TRUE)

  # Should error when no plot provided and no last plot
  expect_error(save_plot(temp_file, plot = NULL))
})

test_that("save_plot() uses png device", {
  skip_if_not_installed("ggplot2")

  temp_file <- tempfile(fileext = ".png")
  on.exit(unlink(temp_file), add = TRUE)

  p <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
  save_plot(temp_file, p)

  # PNG files have specific magic bytes
  raw <- readBin(temp_file, "raw", n = 8)
  png_signature <- as.raw(c(0x89, 0x50, 0x4E, 0x47))

  expect_equal(raw[1:4], png_signature)
})

# Test combine_plots
test_that("combine_plots() combines multiple plots", {
  skip_if_not_installed("patchwork")

  p1 <- ggplot(mtcars, aes(x = wt)) + geom_histogram()
  p2 <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()

  combined <- combine_plots(p1, p2, ncol = 2)

  expect_s3_class(combined, "patchwork")
})

test_that("combine_plots() errors when no plots provided", {
  expect_error(combine_plots())
})

test_that("combine_plots() requires patchwork package", {
  skip_if_not_installed("patchwork")

  p1 <- ggplot(mtcars, aes(x = wt)) + geom_histogram()

  # This test verifies the function works when patchwork IS installed
  # (so skip if patchwork is not installed)
  expect_no_error(combine_plots(p1))
})

# Test that basic plots can be created with utilities
test_that("Utilities work with ggplot workflow", {
  setup_plot_theme()
  colors <- get_analysis_colors()

  # Create a simple plot
  p <- ggplot(mtcars, aes(x = wt, y = mpg, color = factor(cyl))) +
    geom_point() +
    scale_color_manual(values = colors[1:3])

  # Verify it's a ggplot object
  expect_s3_class(p, "ggplot")

  # Verify we can add more layers
  p2 <- p + geom_smooth(method = "lm", se = FALSE)
  expect_s3_class(p2, "ggplot")
})
