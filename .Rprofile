# ==========================================
# ZZCOLLAB .Rprofile - Three-Part Structure
# ==========================================
# Part 1: User Personal Settings (from ~/.Rprofile)
# Part 2: renv Activation + Reproducibility Options
# Part 3: Auto-Snapshot on Exit
# ==========================================

# ==========================================
# Part 1: User Personal Settings (always)
# ==========================================
q <- function(save="no", ...) quit(save=save, ...)

# Package installation behavior (non-interactive)
options(
  install.packages.check.source = "no",
  install.packages.compile.from.source = "never",
  Ncpus = parallel::detectCores()
)

# ==========================================
# Part 2: Container Detection
# ==========================================
# Set ZZCOLLAB_CONTAINER=true in Dockerfile to enable renv
in_container <- Sys.getenv("ZZCOLLAB_CONTAINER") == "true"

# Set repos based on environment
if (in_container) {
  # Use Posit Package Manager for pre-compiled binaries in container
  # Set both repos AND renv.repos.cran (renv uses this option as its default)
  options(
    repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"),
    renv.repos.cran = "https://packagemanager.posit.co/cran/__linux__/noble/latest"
  )
} else {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}

if (!in_container) {
  # ==========================================
  # Host R: Skip renv
  # ==========================================
  message("ℹ️ Host R session (renv skipped - use container for reproducibility)")

} else {
  # ==========================================
  # Container R: Full renv workflow
  # ==========================================

  # renv Cache Path Configuration
  # If RENV_PATHS_CACHE already set (e.g., via docker -e), use it
  # Otherwise use project-local cache
  if (Sys.getenv("RENV_PATHS_CACHE") == "") {
    Sys.setenv(RENV_PATHS_CACHE = file.path(getwd(), ".cache/R/renv"))
  }

  # Activate renv (set project-local library paths)
  if (file.exists("renv/activate.R")) {
    source("renv/activate.R")
  }

  # renv consent (skips first-time prompts)
  options(
    renv.consent = TRUE,
    renv.config.install.prompt = FALSE,
    renv.config.auto.snapshot = FALSE
  )

  # Helper function for initializing renv without prompts
  renv_init_quiet <- function() {
    renv::init(
      bare = TRUE,
      settings = list(snapshot.type = "implicit"),
      force = TRUE,
      restart = FALSE,
      load = FALSE
    )

    message("✅ renv initialized")
    message("   Install packages with: install.packages('package')")
  }

  # ==========================================
  # Auto-Initialize renv (New Projects)
  # ==========================================
  if (!file.exists("renv.lock")) {
    auto_init <- Sys.getenv("ZZCOLLAB_AUTO_INIT", "true")
    is_project <- file.exists("DESCRIPTION") || getwd() == "/home/analyst/project"

    if (tolower(auto_init) %in% c("true", "t", "1") && is_project) {
      message("\n🔧 ZZCOLLAB: Auto-initializing renv for new project...")
      tryCatch({
        renv_init_quiet()
      }, error = function(e) {
        warning("⚠️  Auto-init failed: ", conditionMessage(e),
                "\n   Run manually: renv_init_quiet()", call. = FALSE)
      })
    }
  } else {
    # ==========================================
    # Recover renv infrastructure if missing
    # ==========================================
    # This handles: renv.lock exists but renv/ doesn't (e.g., git clone)
    if (!file.exists("renv/activate.R")) {
      message("\n🔧 ZZCOLLAB: renv.lock found but renv/ missing - recovering...")
      tryCatch({
        renv_init_quiet()
        if (file.exists("renv/activate.R")) {
          source("renv/activate.R")
        }
      }, error = function(e) {
        warning("⚠️  renv recovery failed: ", conditionMessage(e), call. = FALSE)
      })
    }

    # ==========================================
    # Auto-Restore Missing Packages
    # ==========================================
    auto_restore <- Sys.getenv("ZZCOLLAB_AUTO_RESTORE", "true")

    if (tolower(auto_restore) %in% c("true", "t", "1")) {
      in_lsp <- !interactive() || nzchar(Sys.getenv("NVIM_LISTEN_ADDRESS")) ||
                nzchar(Sys.getenv("RSTUDIO"))

      tryCatch({
        if (in_lsp) {
          invisible(suppressMessages(suppressWarnings({
            sink("/dev/null", type = "output")
            sink("/dev/null", type = "message")
            on.exit({
              sink(type = "message")
              sink(type = "output")
            }, add = TRUE)
            renv::restore(prompt = FALSE)
            sink(type = "message")
            sink(type = "output")
          })))
        } else {
          renv::restore(prompt = FALSE)
        }
      }, error = function(e) {
        if (!in_lsp && !grepl("already synchronized|consistent state", conditionMessage(e))) {
          warning("⚠️  Auto-restore failed: ", conditionMessage(e), call. = FALSE)
        }
        invisible(NULL)
      })
    }
  }

  # ==========================================
  # Auto-Snapshot on R Exit (Container only)
  # ==========================================
  .Last <- function() {
    auto_snapshot <- Sys.getenv("ZZCOLLAB_AUTO_SNAPSHOT", "true")

    if (tolower(auto_snapshot) %in% c("true", "t", "1")) {
      if (file.exists("renv.lock") && file.exists("renv/activate.R")) {
        message("\n📸 Auto-snapshot: Updating renv.lock...")

        snapshot_result <- tryCatch({
          renv::snapshot(prompt = FALSE)
          TRUE
        }, error = function(e) {
          warning("Auto-snapshot failed: ", conditionMessage(e), call. = FALSE)
          FALSE
        })

        if (snapshot_result) {
          message("✅ renv.lock updated successfully")
          message("   Commit changes: git add renv.lock && git commit -m 'Update packages'")
        }
      }
    }

    if (exists(".Last.user", mode = "function", envir = .GlobalEnv)) {
      tryCatch(
        .Last.user(),
        error = function(e) warning("User .Last failed: ", conditionMessage(e))
      )
    }
  }

  # Re-apply Posit PM repos AFTER renv::load() (which overrides from lockfile)
  options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))
}

# ==========================================
# Part 3: Reproducibility Options (always)
# ==========================================
# These ensure consistent behavior on both host and container
options(
  stringsAsFactors = FALSE,
  contrasts = c("contr.treatment", "contr.poly"),
  na.action = "na.omit",
  digits = 7,
  OutDec = "."
)

# ==========================================
# Part 4: Personal Customizations (always)
# ==========================================
if (file.exists(".Rprofile.local")) {
  tryCatch(
    source(".Rprofile.local"),
    error = function(e) {
      warning(".Rprofile.local failed to load: ", conditionMessage(e))
    }
  )
}
