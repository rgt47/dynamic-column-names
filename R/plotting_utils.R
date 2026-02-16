#' Plotting Utilities for Blog Analysis
#'
#' A collection of reusable plotting functions and themes for consistent
#' visualization across blog posts.
#'
#' @keywords internal
NULL

#' Set Default Plotting Theme
#'
#' Configures a minimal, clean ggplot2 theme suitable for publication.
#'
#' @param base_size Base font size in points (default: 12)
#'
#' @return Invisibly returns the theme object
#'
#' @examples
#' \dontrun{
#'   setup_plot_theme()
#'   ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
#' }
#'
#' @export
setup_plot_theme <- function(base_size = 12) {
  ggplot2::theme_set(ggplot2::theme_minimal(base_size = base_size))
  invisible()
}

#' Get Analysis Color Palette
#'
#' Returns a named vector of colors for consistent use across visualizations.
#' Named colors allow flexible specification of which colors to use.
#'
#' @return Named character vector of hex colors:
#'   - primary: "#FF6B6B" (red)
#'   - secondary: "#4ECDC4" (teal)
#'   - tertiary: "#45B7D1" (blue)
#'   - quaternary: "#96CEB4" (green)
#'
#' @examples
#' \dontrun{
#'   library(ggplot2)
#'   colors <- get_analysis_colors()
#'   ggplot(mtcars, aes(x = cyl, fill = factor(cyl))) +
#'     geom_bar() +
#'     scale_fill_manual(values = colors[1:3])
#' }
#'
#' @export
get_analysis_colors <- function() {
  c(
    primary = "#FF6B6B",
    secondary = "#4ECDC4",
    tertiary = "#45B7D1",
    quaternary = "#96CEB4"
  )
}

#' Save ggplot with Consistent Settings
#'
#' Wrapper around ggplot2::ggsave() that applies consistent settings
#' (DPI, format, etc.) across all blog post figures.
#'
#' @param filename Output filename (should include directory, e.g., "figures/plot.png")
#' @param plot ggplot object to save (default: last plot)
#' @param width Width in inches (default: 8)
#' @param height Height in inches (default: 5)
#' @param dpi Resolution in dots per inch (default: 300 for publication quality)
#'
#' @return Invisibly returns the filename
#'
#' @details
#' Creates parent directories if needed. Uses png format by default
#' (inferred from filename extension).
#'
#' @examples
#' \dontrun{
#'   p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
#'     geom_point() +
#'     theme_minimal()
#'   save_plot("figures/scatter.png", p)
#' }
#'
#' @export
save_plot <- function(filename, plot = ggplot2::last_plot(),
                      width = 8, height = 5, dpi = 300) {

  if (is.null(plot)) {
    stop("No plot to save. Either provide 'plot' argument or create a plot first.")
  }

  # Create directory if needed
  dir <- dirname(filename)
  if (dir != "." && !dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Save with consistent settings
  ggplot2::ggsave(
    filename,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    device = "png"
  )

  cat("Saved:", filename, "\n")
  invisible(filename)
}

#' Create a Publication-Ready Figure Grid
#'
#' Combines multiple plots into a grid with consistent spacing and legend handling.
#'
#' @param ... ggplot objects to combine
#' @param ncol Number of columns in grid
#' @param heights Relative heights of rows (passed to patchwork)
#'
#' @return patchwork object
#'
#' @examples
#' \dontrun{
#'   p1 <- ggplot(mtcars, aes(x = mpg)) + geom_histogram()
#'   p2 <- ggplot(mtcars, aes(x = wt, y = mpg)) + geom_point()
#'   combine_plots(p1, p2, ncol = 2)
#' }
#'
#' @export
combine_plots <- function(..., ncol = 2, heights = NULL) {
  plots <- list(...)

  if (length(plots) == 0) {
    stop("No plots provided")
  }

  if (!requireNamespace("patchwork", quietly = TRUE)) {
    stop("patchwork package required. Install with: install.packages('patchwork')")
  }

  # Use Reduce to combine plots with patchwork +
  combined <- Reduce(function(p1, p2) p1 + p2, plots)

  if (is.null(heights)) {
    combined + patchwork::plot_layout(ncol = ncol)
  } else {
    combined + patchwork::plot_layout(ncol = ncol, heights = heights)
  }
}

#' Extract Numeric Values from ggplot Layer
#'
#' Utility function to extract aesthetic or data values from a ggplot layer
#' for testing purposes.
#'
#' @param plot ggplot object
#' @param layer_index Which layer to extract from (default: 1)
#' @param aesthetic Which aesthetic to extract (e.g., "x", "y", "fill")
#'
#' @return Vector of values from specified aesthetic
#'
#' @keywords internal
extract_plot_data <- function(plot, layer_index = 1, aesthetic = "x") {
  layer <- plot$layers[[layer_index]]
  data <- layer$data %||% plot$data
  aesthetic_var <- layer$mapping[[aesthetic]]

  if (is.null(aesthetic_var)) {
    return(NULL)
  }

  if (is.symbol(aesthetic_var)) {
    return(data[[rlang::as_string(aesthetic_var)]])
  }

  return(NULL)
}
