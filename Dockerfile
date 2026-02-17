# syntax=docker/dockerfile:1.4
#======================================================================
# ZZCOLLAB Ubuntu X11 Analysis Profile
#======================================================================
# Profile: ubuntu_x11_analysis (~2.5GB)
# Purpose: Data analysis with tidyverse and X11 support
# Base: rocker/tidyverse (R + tidyverse packages)
# Packages: renv, tidyverse (dplyr, purrr, ggplot2, etc.)
#
# Build: DOCKER_BUILDKIT=1 docker build \
#          -f Dockerfile.ubuntu_x11_analysis \
#          -t myteam/project:x11-analysis .
# Run: Requires XQuartz (macOS) or X11 (Linux)
#======================================================================

# ARGs before FROM are available only for FROM instruction
ARG R_VERSION=4.5.2

FROM rocker/tidyverse:4.5.2

# Re-declare ARGs after FROM for use in build stages
ARG USERNAME=analyst
ARG RENV_VERSION=1.1.5
ARG DEBIAN_FRONTEND=noninteractive

# Reproducibility-critical environment variables (Pillar 1)
# ZZCOLLAB_CONTAINER enables renv workflow in .Rprofile
# RENV_CONFIG_REPOS_OVERRIDE forces renv to use Posit PM binaries (ignores lockfile repos)
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC \
    OMP_NUM_THREADS=1 \
    RENV_PATHS_CACHE=/home/analyst/.cache/R/renv \
    RENV_CONFIG_REPOS_OVERRIDE="https://packagemanager.posit.co/cran/__linux__/noble/latest" \
    ZZCOLLAB_CONTAINER=true

# Install runtime and build dependencies
# Version pins removed — base image (rocker/r-ver:4.5.2) pins the OS
# snapshot; unpinned packages track the latest patch for that release.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        jq \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libwebp-dev \
        xauth \
        libx11-6 \
        libxt6 \
        libcairo2 \
        libfontconfig1-dev \
        libfreetype-dev \
        libpng-dev \
        libjpeg-dev \
        libicu-dev \
        pandoc \
        wget \
        gdebi-core

# Install Quarto from official binary (not in standard repositories)
ARG QUARTO_VERSION=1.6.43
RUN set -ex && \
    wget -q "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" && \
    gdebi -n "quarto-${QUARTO_VERSION}-linux-amd64.deb" && \
    rm "quarto-${QUARTO_VERSION}-linux-amd64.deb"

# Configure R to use Posit Package Manager (pre-compiled Ubuntu binaries)
RUN echo "options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/noble/latest'))" \
        >> /usr/local/lib/R/etc/Rprofile.site

# Install renv from CRAN
RUN --mount=type=cache,target=/tmp/R-cache/4.5.2 \
    R -e "install.packages('renv')"

# Copy project files and restore packages (before USER for root access)
COPY renv.lock renv.lock
RUN Rscript -e "renv::restore(prompt=FALSE)"

# Create non-root user and set up environment
RUN useradd --create-home --shell /bin/bash analyst && \
    chown -R analyst:analyst /usr/local/lib/R/site-library && \
    mkdir -p /home/analyst/.cache/R/renv && \
    chown -R analyst:analyst /home/analyst/.cache

# Fix permissions for mounted volumes (GitHub Actions compatibility)
# Mount may be owned by root; allow analyst to write
RUN mkdir -p /home/analyst/project && \
    chown -R analyst:analyst /home/analyst/project

# Switch to non-root user
USER analyst

# WORKDIR automatically creates directory with correct ownership
WORKDIR /home/analyst/project

# Health check: Verify R is functional
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=2 \
    CMD R --quiet --slave -e "quit(status = 0)" || exit 1

# Note: Project files mounted at runtime via -v $(pwd):/home/analyst/project
# This keeps image reusable across projects. Run renv::restore() in first session.
# For project-specific images, add COPY renv.lock and RUN renv::restore() before USER

CMD ["R", "--quiet"]
