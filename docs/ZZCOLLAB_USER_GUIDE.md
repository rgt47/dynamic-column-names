# ZZCOLLAB Framework User Guide v4.1

## Table of Contents
1. [What is ZZCOLLAB?](#what-is-zzcollab)
2. [Quick Start](#quick-start)
3. [Docker Profile System](#docker-profile-system)
4. [Team Lead Workflow](#team-lead-workflow)
5. [Team Member Workflow](#team-member-workflow)
6. [Solo Developer Workflow](#solo-developer-workflow)
7. [Package Management](#package-management)
8. [Development Environments](#development-environments)
9. [Build System with Make](#build-system-with-make)
10. [GitHub Actions CI/CD](#github-actions-cicd)
11. [Configuration System](#configuration-system)
12. [Troubleshooting](#troubleshooting)
13. [Platform-Specific Notes](#platform-specific-notes)

## What is ZZCOLLAB?

**ZZCOLLAB** is a framework for creating **reproducible research compendia** - self-contained research projects that combine code, data, documentation, and computational environment specifications to enable complete reproducibility.

### Key Features

- **Docker-based reproducibility**: Isolated computational environments
- **Two-layer architecture**: Team Docker profiles + dynamic package management
- **Unified research structure**: Single flexible workflow from data to publication
- **Automated CI/CD**: GitHub Actions for testing and validation
- **Team collaboration**: Automated workflows for multiple researchers
- **14+ Docker profiles**: From lightweight Alpine (~200MB) to full-featured environments (~3GB)

### Architecture Overview

ZZCOLLAB uses a **two-layer reproducibility architecture**:

#### Layer 1: Docker Profile (Team/Shared)
- **Controlled by**: Team lead via `--profile-name`, `-b`, `--libs`, `--pkgs` flags
- **Purpose**: Defines foundational Docker environment
- **Components**: Base R version, system dependencies, pre-installed packages
- **Fixed**: Once selected, shared by all team members

#### Layer 2: Dynamic Packages (Personal/Independent)
- **Controlled by**: Any team member using standard R commands inside containers
- **Purpose**: Add packages as needed for specific analyses
- **Flexible**: Each member can add packages independently
- **Collaborative**: renv.lock accumulates packages from all contributors

## Quick Start

### Prerequisites
- **Docker** installed and running
- **Git** for version control
- **GitHub CLI** (`gh`) for repository management (optional)
- **Docker Hub account** for team image publishing (team workflows only)

### One-Time Configuration (30 seconds)

```bash
# Initialize configuration
zzcollab --config init

# Set your defaults
zzcollab --config set team-name "myteam"
zzcollab --config set github-account "myusername"
zzcollab --config set dotfiles-dir "~/dotfiles"
```

### Create First Project (3-4 minutes)

```bash
# Create project directory
mkdir my-analysis && cd my-analysis

# Initialize project (uses config defaults)
zzcollab

# Build Docker image
make docker-build

# Enter development environment
make docker-zsh
```

## Docker Profile System

ZZCOLLAB's Docker profile system provides three ways to specify your computational environment:

### 1. Complete Profiles (`--profile-name`)

**Predefined combinations** of base image + system libraries + R packages:

| Profile | Base Image | System Libs | R Packages | Size | Use Case |
|---------|------------|-------------|------------|------|----------|
| `minimal` | rocker/r-ver | minimal | renv, devtools, usethis | ~780MB | Essential development |
| `rstudio` | rocker/rstudio | minimal | renv, devtools, usethis | ~980MB | GUI development |
| `analysis` | rocker/tidyverse | minimal | tidyverse ecosystem | ~1.18GB | Data analysis |
| `modeling` | rocker/r-ver | modeling | tidymodels, xgboost | ~1.48GB | Machine learning |
| `bioinformatics` | bioconductor/bioconductor_docker | bioinfo | DESeq2, edgeR, limma | ~1.98GB | Genomics |
| `geospatial` | rocker/geospatial | geospatial | sf, terra, leaflet | ~2.48GB | Spatial analysis |
| `publishing` | rocker/verse | publishing | quarto, bookdown, LaTeX | ~3GB | Manuscripts |
| `alpine_minimal` | velaco/alpine-r | alpine | renv, devtools | ~200MB | Ultra-lightweight |
| `alpine_analysis` | velaco/alpine-r | alpine | tidyverse | ~400MB | Lightweight analysis |

**Usage:**

```bash
# Method 1: Set in config (recommended)
zzcollab --config set profile-name "bioinformatics"
mkdir study && cd study
zzcollab  # Uses bioinformatics profile
make docker-build

# Method 2: Use flag for one-time selection
mkdir analysis && cd analysis
zzcollab --profile-name geospatial
make docker-build

# List all available profiles
zzcollab --list-profiles
```

### 2. Custom Composition (Bundles)

**Build custom environments** by combining components:

```bash
# Custom composition: bioconductor base + geospatial libraries + modeling packages
mkdir custom-project && cd custom-project
zzcollab -b bioconductor/bioconductor_docker --libs geospatial --pkgs modeling
make docker-build
```

**Available bundles:**

System Library Bundles (`--libs`):
- `minimal`: Essential development libraries
- `geospatial`: GDAL, PROJ, GEOS for spatial analysis
- `bioinfo`: Genomics libraries (zlib, libbz2, liblzma)
- `modeling`: Statistical modeling libraries (libgsl)
- `publishing`: LaTeX, pandoc for manuscripts
- `alpine`: Alpine Linux libraries (different package manager)

R Package Bundles (`--pkgs`):
- `minimal`: renv, devtools, usethis, testthat
- `tidyverse`: tidyverse ecosystem + data tools
- `modeling`: tidymodels, xgboost, randomForest
- `bioinfo`: Bioconductor genomics packages
- `geospatial`: sf, terra, leaflet mapping tools
- `publishing`: quarto, bookdown, blogdown
- `shiny`: Shiny web applications

```bash
# View all available bundles
zzcollab --list-libs   # System library bundles
zzcollab --list-pkgs   # R package bundles
```

### 3. Custom Base Images

**Use any Docker base image**:

```bash
# Use custom or alternative base image
mkdir project && cd project
zzcollab -b "my-organization/custom-r:latest" --libs minimal --pkgs tidyverse
make docker-build
```

### How Dockerfiles are Generated

ZZCOLLAB creates Dockerfiles dynamically based on your profile/bundle choices:

#### Profile Expansion Process

1. **Parse Profile**: If `--profile-name` specified, load from `bundles.yaml`
   ```yaml
   # Example: bioinformatics profile
   bioinformatics:
     base_image: "bioconductor/bioconductor_docker"
     libs: bioinfo
     pkgs: bioinfo
   ```

2. **Expand Bundles**: Convert bundle names to actual dependencies
   ```yaml
   # libs: bioinfo expands to:
   library_bundles:
     bioinfo:
       deps:
         - zlib1g-dev
         - libbz2-dev
         - liblzma-dev

   # pkgs: bioinfo expands to:
   package_bundles:
     bioinfo:
       packages:
         - renv
         - BiocManager
         - DESeq2
         - edgeR
   ```

3. **Generate Dockerfile**: Create Dockerfile with expanded specifications

#### Example: Generated Dockerfile for Bioinformatics Profile

```dockerfile
# Command: zzcollab --profile-name bioinformatics
FROM bioconductor/bioconductor_docker:latest

# Set environment variables for reproducibility
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC \
    OMP_NUM_THREADS=1

# Install system dependencies (from bioinfo libs bundle)
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages (from bioinfo pkgs bundle)
RUN R -e "install.packages(c('renv', 'devtools'))" && \
    R -e "BiocManager::install(c('DESeq2', 'edgeR', 'limma', 'GenomicRanges', 'Biostrings'))"

# Create analyst user with sudo access
RUN useradd -m -s /bin/bash analyst && \
    echo "analyst:analyst" | chpasswd && \
    usermod -aG sudo analyst

# Set working directory
WORKDIR /home/analyst/project

USER analyst
```

#### Example: Custom Composition

```bash
# Command: zzcollab -b rocker/r-ver --libs geospatial --pkgs modeling
```

Generated Dockerfile:
```dockerfile
FROM rocker/r-ver:latest

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC \
    OMP_NUM_THREADS=1

# Install system dependencies (from geospatial libs bundle)
RUN apt-get update && apt-get install -y \
    gdal-bin \
    proj-bin \
    libgeos-dev \
    libproj-dev \
    libgdal-dev \
    libudunits2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages (from modeling pkgs bundle)
RUN R -e "install.packages(c('renv', 'devtools', 'tidyverse', 'tidymodels', 'xgboost', 'randomForest', 'glmnet', 'caret'))"

# ... rest of Dockerfile
```

### Validation and Compatibility

ZZCOLLAB validates profile/bundle combinations:

```yaml
# From bundles.yaml compatibility_rules:
compatibility_rules:
  geospatial_pkgs_require_libs:
    condition: "pkgs == 'geospatial'"
    requires_libs: ["geospatial"]
    error: "Geospatial packages require --libs geospatial (GDAL/PROJ libraries)"
```

**Example validation:**
```bash
# This will fail validation:
zzcollab -b rocker/r-ver --pkgs geospatial
# Error: Geospatial packages require --libs geospatial

# Correct usage:
zzcollab -b rocker/r-ver --libs geospatial --pkgs geospatial
```

## Team Lead Workflow

### Complete Team Setup

**Scenario:** You are Developer 1 creating a new team project with specialized Docker environment.

#### Step 1: Choose Docker Profile

```bash
# Option A: Use predefined profile
zzcollab --config set profile-name "bioinformatics"

# Option B: Use custom composition
# (set via flags in step 2)
```

#### Step 2: Create Project Structure

```bash
mkdir genomics-study && cd genomics-study

# Option A: Using profile from config
zzcollab -t mylab -p genomics-study -D ~/dotfiles

# Option B: Using custom composition
zzcollab -t mylab -p genomics-study -b bioconductor/bioconductor_docker \
  --libs bioinfo --pkgs bioinfo -D ~/dotfiles
```

**What happens:**
- Creates complete R package structure (R/, analysis/, tests/, etc.)
- Generates Dockerfile from selected profile/bundles
- Sets up CI/CD workflows (.github/workflows/)
- Initializes renv for dependency tracking
- Creates development environment files

#### Step 3: Customize Dockerfile (Optional)

```bash
# If you need additional system dependencies or packages:
vim Dockerfile

# Example additions:
# RUN apt-get install -y additional-library
# RUN R -e "install.packages('specialized-package')"
```

#### Step 4: Build and Share Team Image

```bash
# Build Docker image with your profile
make docker-build

# Push to Docker Hub for team access
make docker-push-team

# Commit project structure to GitHub
git add .
git commit -m "Initial project setup with bioinformatics profile"
git push -u origin main
```

**What team members will get:**
- Identical Docker environment via `mylab/genomics-study:latest` image
- Complete project structure from GitHub
- Base Bioconductor packages pre-installed
- System dependencies for genomics work

#### Step 5: Development

```bash
# Enter Docker environment
make docker-zsh

# Inside container: add packages as needed
renv::install("ComplexHeatmap")
renv::install("clusterProfiler")

# Exit (auto-snapshot + validation happen automatically!)
exit

# Run tests
make docker-test

# Commit changes
git add renv.lock DESCRIPTION
git commit -m "Add heatmap and pathway analysis packages"
git push
```

### Team Lead Responsibilities

1. **Select Docker profile**: Choose appropriate environment for team's research domain
2. **Build team image**: Create and push Docker image to Docker Hub
3. **Manage base environment**: Decide which packages to pre-install in Docker vs add via renv
4. **Add collaborators**: Grant GitHub repository access
5. **Maintain infrastructure**: Update team image when base dependencies change

## Team Member Workflow

### Joining Existing Project

**Scenario:** You are Developer 2+ joining a team project.

#### Step 1: Clone Repository

```bash
git clone https://github.com/mylab/genomics-study.git
cd genomics-study
```

#### Step 2: Pull Team Image

```bash
# Pull and use team's Docker image
zzcollab --use-team-image -D ~/dotfiles
```

**What happens:**
- Downloads `mylab/genomics-study:latest` from Docker Hub
- Uses team's Docker profile (bioinformatics environment)
- Creates personal development layer on top of team image
- Copies your dotfiles into container

#### Step 3: Start Development

```bash
# Enter identical Docker environment as team lead
make docker-zsh

# Inside container: work on analysis
renv::restore()  # Install all team packages from renv.lock

# Add your own packages as needed
renv::install("pheatmap")

# Exit container (auto-snapshot + validation happen automatically!)
exit

# Run tests (optional)
make docker-test

# Commit
git add renv.lock DESCRIPTION
git commit -m "Add pheatmap for visualization"
git push
```

### Team Member Capabilities

✅ **Can do:**
- Add R packages via `install.packages()` (Layer 2)
- Create analysis scripts and functions
- Run tests and CI/CD workflows
- Commit changes to renv.lock
- Propose modifications to team image via pull requests

❌ **Cannot do:**
- Change Docker profile (fixed by team lead in Layer 1)
- Modify base image
- Add system libraries (requires team lead to rebuild team image)
- Change R version (fixed in team's Dockerfile)

### Requesting New System Dependencies

If you need system libraries:

```bash
# Option 1: Request via GitHub issue
gh issue create --title "Request: Add libgsl-dev for modeling" \
  --body "Need GSL library for statistical modeling packages"

# Option 2: Submit pull request
vim Dockerfile  # Add: RUN apt-get install -y libgsl-dev
git checkout -b add-gsl-library
git add Dockerfile
git commit -m "Add GSL library for statistical modeling"
gh pr create --title "Add GSL system library"
```

## Solo Developer Workflow

### Quick Start

Solo developers get streamlined workflow without team image management:

```bash
# One-time config
zzcollab --config init
zzcollab --config set team-name "myusername"
zzcollab --config set profile-name "analysis"

# Create project
mkdir penguin-analysis && cd penguin-analysis
zzcollab
make docker-build

# Daily development
make docker-zsh
# ... work inside container ...
# Install packages: install.packages("package")
exit  # Auto-snapshot + validation happen automatically!

# Test and commit
make docker-test
git add . && git commit -m "Add analysis" && git push
```

### Transitioning to Team

Solo projects are inherently team-ready:

```bash
# Push team image for others to use
make docker-push-team

# Share repository
gh repo edit --add-collaborator colleague

# Colleague joins:
git clone https://github.com/myusername/penguin-analysis.git
cd penguin-analysis
zzcollab --use-team-image
make docker-zsh
```

## Package Management

**✨ NEW: Auto-Snapshot Architecture**

ZZCOLLAB now features **automatic snapshot-on-exit**:
- **No manual `renv::snapshot()` required**: Automatically runs when you exit any Docker container
- **Automatic validation**: Pure shell validation runs after container exit (no host R needed!)
- **RSPM timestamp optimization**: Adjusts renv.lock timestamp for binary packages (10-20x faster builds)
- **Accurate git history**: Timestamp restored to current time after validation

**Simply work and exit** - reproducibility is automatic!

### Two-Layer Package Management

#### Layer 1: Docker Image (Pre-installed, Team/Shared)

**Controlled by:** Team lead's profile/bundle choice

**Purpose:** Fast container startup with base packages

**Example:**
```bash
# Team lead chooses bioinformatics profile
zzcollab --profile-name bioinformatics
# Docker image includes: BiocManager, DESeq2, edgeR, limma
```

**Benefits:**
- Faster container startup (packages already compiled)
- Consistent base environment across team
- System dependencies bundled correctly

#### Layer 2: renv.lock (Dynamic, Personal/Collaborative)

**Controlled by:** Any team member using standard R commands

**Purpose:** Source of truth for reproducibility

**Example:**
```bash
# Inside container:
install.packages("ComplexHeatmap")  # Alice adds heatmap package
install.packages("clusterProfiler")  # Bob adds pathway analysis
exit  # Auto-snapshot on exit!
```

**Key principle:** renv.lock is the source of truth, NOT the Docker image.

**For GitHub packages:**
```r
install.packages("remotes")
remotes::install_github("user/package")
```

**Alternative:** `renv::install()` works for both CRAN and GitHub:
```r
renv::install("package")         # CRAN
renv::install("user/package")    # GitHub
```

### Package Workflow

#### Adding Packages

```bash
# Enter container
make docker-zsh

# Inside container - add packages using standard R
R
> install.packages("tidymodels")
> quit()

# Exit container (auto-snapshot + validation happen automatically!)
exit

# Optional: Manually validate (pure shell, no R required)
make check-renv

# Run tests
make docker-test

# Commit if validation passed
git add renv.lock DESCRIPTION
git commit -m "Add tidymodels for modeling workflow"
git push
```

**For GitHub packages:**
```bash
# Inside container
R
> install.packages("remotes")
> remotes::install_github("tidyverse/dplyr")
> quit()
exit
```

**What happens automatically on exit:**
1. `renv::snapshot()` captures dependencies
2. Timestamp adjusted to "7 days ago" for RSPM binary packages
3. `modules/validation.sh` validates DESCRIPTION ↔ renv.lock consistency
4. Timestamp restored to current time for accurate git history

#### Package Accumulation (Team Collaboration)

```bash
# Alice adds packages
install.packages("tidymodels")
exit  # Auto-snapshot: renv.lock now has [tidymodels]

# Bob adds packages
git pull  # Gets Alice's changes
install.packages("sf")
exit  # Auto-snapshot: renv.lock now has [tidymodels, sf]

# Charlie reproduces
git pull
# Next docker build automatically runs renv::restore()
# Installs both tidymodels AND sf
```

**Final renv.lock contains packages from ALL contributors.**

### When to Update Team Image

Update team Docker image when:
- Base R version changes
- System dependencies needed (GDAL, PROJ, LaTeX)
- Core packages used by everyone (tidyverse, Bioconductor)

Don't update team image for:
- Individual analysis packages (add via renv)
- Experimental packages
- Personal workflow tools

## Development Environments

### Available Environments

| Environment | Command | Use Case | Access |
|-------------|---------|----------|--------|
| **Enhanced Shell** | `make docker-zsh` | Vim/tmux development | Terminal |
| **RStudio Server** | `make docker-rstudio` | GUI-based development | http://localhost:8787 |
| **R Console** | `make docker-r` | Interactive R work | Terminal |
| **Bash Shell** | `make docker-bash` | File management, git | Terminal |
| **Paper Rendering** | `make docker-render` | Generate manuscript | Automated |
| **Package Testing** | `make docker-test` | Run unit tests | Automated |

### Daily Development Cycle

```bash
# Morning: Sync with team
git pull
docker pull mylab/project:latest  # If using team image

# Enter development environment
make docker-zsh

# Work inside container
vim R/my_function.R
vim analysis/paper/paper.Rmd

# Test as you go
R
devtools::load_all()
devtools::test()
quit()

# Exit container
exit

# Validate before committing
make docker-test
make check-renv-ci

# Commit and push
git add .
git commit -m "Add new analysis function with tests"
git push
```

### GUI Support (Optional)

For interactive graphics on macOS:

```bash
# One-time XQuartz setup
brew install --cask xquartz
open -a XQuartz
# XQuartz > Preferences > Security > Enable "Allow connections from network clients"

# Each session
export DISPLAY=:0
/opt/X11/bin/xhost +localhost

# Launch container with GUI
make docker-zsh-gui

# Test inside container
R
plot(1:10, 1:10)  # Graphics window appears
```

## Build System with Make

### Docker Commands

```bash
make docker-build              # Build Docker image
make docker-push-team          # Push team image to Docker Hub
make docker-zsh                # Enter zsh development environment
make docker-zsh-gui            # Enter zsh with GUI support (X11)
make docker-rstudio            # Start RStudio Server
make docker-r                  # Interactive R console
make docker-bash               # Bash shell in container
make docker-render             # Render paper in container
make docker-test               # Run tests in container
make docker-check              # R CMD check in container
make docker-clean              # Remove Docker images/volumes
```

### Package Validation (NO HOST R REQUIRED!)

**NEW: Pure shell validation**

```bash
make check-renv                # Validate dependencies (pure shell, fast!)
make check-renv-strict         # Strict mode (scan tests/, vignettes/)
```

**Note:** All `docker-*` targets now automatically validate packages after container exit!

### Native R Commands

*(Require local R installation - rarely needed now!)*

```bash
make document                  # Generate documentation
make build                     # Build package
make check                     # R CMD check
make install                   # Install package locally
make test                      # Run tests
make vignettes                 # Build vignettes
make check-renv-ci             # Legacy R-based validation (for CI with R pre-installed)
```

### Cleanup Commands

```bash
make clean                     # Remove build artifacts
make docker-clean              # Remove Docker images/volumes
```

## GitHub Actions CI/CD

### Automated Team Image Management

When any team member adds packages:

1. **Push triggers GitHub Actions** → detects renv.lock changes
2. **New Docker image built** → includes all team packages
3. **Image pushed to Docker Hub** → available to all team members
4. **Team notification** → commit comment with update instructions
5. **Team members sync** → `docker pull` gets new environment

### Workflow Triggers

```yaml
# Automatic triggers in .github/workflows/update-team-image.yml
on:
  push:
    branches: [main]
    paths:
      - 'renv.lock'      # R package changes
      - 'DESCRIPTION'    # Package metadata changes
      - 'Dockerfile'     # Container definition changes
  workflow_dispatch:      # Manual triggering
```

### Security and Privacy Model

**🔒 PRIVATE GitHub Repository:**
- Protects unpublished research
- Secures proprietary analysis
- Controls access to collaborators only

**🌍 PUBLIC Docker Images (Docker Hub):**
- Enables reproducible research
- Shares computational environments
- No sensitive data - only software

### Repository Secrets Setup

For automated Docker Hub publishing:

```bash
# In GitHub: Settings → Secrets and variables → Actions
DOCKERHUB_USERNAME: your-dockerhub-username
DOCKERHUB_TOKEN: your-dockerhub-access-token
```

Create access token at: https://hub.docker.com/settings/security

## Configuration System

### Multi-Level Hierarchy

Settings at more specific levels override broader defaults:

1. **Project config** (`./zzcollab.yaml`) - Team-specific settings
2. **User config** (`~/.zzcollab/config.yaml`) - Personal defaults
3. **System config** (`/etc/zzcollab/config.yaml`) - Organization-wide
4. **Built-in defaults** - Fallback values

### Configuration Commands

```bash
zzcollab --config init                      # Create config file
zzcollab --config set team-name "myteam"    # Set values
zzcollab --config get team-name             # Get values
zzcollab --config list                      # List all configuration
zzcollab --config validate                  # Validate YAML syntax
```

### Common Configuration

```bash
# One-time setup
zzcollab --config init
zzcollab --config set team-name "myteam"
zzcollab --config set github-account "myusername"
zzcollab --config set profile-name "analysis"
zzcollab --config set dotfiles-dir "~/dotfiles"
```

### Project-Level Configuration

Create `zzcollab.yaml` in project root:

```yaml
team:
  name: "datasci-lab"
  project: "customer-churn"
  description: "ML analysis of retention patterns"

build:
  use_config_profiles: true
  profile_library: "bundles.yaml"

  docker:
    platform: "auto"              # auto, linux/amd64, linux/arm64

collaboration:
  github:
    auto_create_repo: false
    default_visibility: "private"

  development:
    default_profile: "analysis"
```

## Troubleshooting

### Docker Problems

```bash
# Docker not running
Error: Docker daemon not running
Solution: Start Docker Desktop

# Permission denied
Error: Permission denied
Solution: Check directory permissions, run as correct user

# Out of disk space
Error: No space left on device
Solution: make docker-clean && docker system prune
```

### Package Issues

```bash
# Package installation fails
Error: Package 'xyz' not available
Solution: Check package name, try renv::install("xyz")

# Dependency conflicts
Error: Dependencies not synchronized
Solution: make docker-check-renv-fix

# renv cache issues
Error: renv cache corrupted
Solution: renv::restore() && renv::rebuild()
```

### Team Collaboration Issues

```bash
# Team image not found
Error: Unable to pull team/project:latest
Solution:
  1. Check Docker Hub permissions
  2. Verify team member has access
  3. Ensure team lead pushed image

# GitHub repository creation fails
Error: Repository creation failed
Solution: gh auth login

# Environment inconsistency
Error: Package versions differ between team members
Solution: All team members run:
  git pull && docker pull team/project:latest
```

### Build Issues

```bash
# Make targets fail
Error: make: *** [target] Error 1
Solution:
  1. Check Docker is running
  2. Try make docker-build

# Paper rendering fails
Error: Pandoc not found
Solution: Use make docker-render instead

# Tests fail
Error: Test failures
Solution:
  1. Check function implementations
  2. Update tests
  3. Run make docker-test for clean environment
```

### Profile/Bundle Issues

```bash
# Incompatible combination
Error: Geospatial packages require --libs geospatial
Solution: zzcollab -b rocker/r-ver --libs geospatial --pkgs geospatial

# Alpine/Debian mismatch
Error: Alpine base images require --libs alpine
Solution: zzcollab -b velaco/alpine-r --libs alpine --pkgs minimal

# Profile not found
Error: Unknown profile 'xyz'
Solution: zzcollab --list-profiles  # See available profiles
```

## Platform-Specific Notes

### ARM64 Compatibility (Apple Silicon)

**Architecture Support:**

✅ **ARM64 and AMD64 Compatible:**
- rocker/r-ver
- rocker/rstudio
- velaco/alpine-r

❌ **AMD64 Only:**
- rocker/verse
- rocker/tidyverse
- rocker/geospatial
- rocker/shiny

**Solutions for ARM64:**

1. **Use compatible profiles:**
```bash
zzcollab --profile-name minimal     # ✅ Works on ARM64
zzcollab --profile-name rstudio     # ✅ Works on ARM64
zzcollab --profile-name alpine_analysis  # ✅ Works on ARM64
```

2. **Automatic emulation:**
```bash
# ZZCOLLAB automatically uses --platform linux/amd64 on ARM64 for:
zzcollab --profile-name publishing  # Uses AMD64 emulation
zzcollab --profile-name geospatial  # Uses AMD64 emulation
```

3. **Build custom ARM64 images:**
```bash
# Create custom publishing environment for ARM64
mkdir project && cd project
zzcollab -b rocker/r-ver --libs publishing --pkgs publishing
make docker-build  # Native ARM64 build
```

### Platform Configuration

```bash
# Auto-detect (default)
zzcollab --config set docker.platform "auto"

# Force AMD64 (works on both architectures)
zzcollab --config set docker.platform "amd64"

# Force ARM64 (only on ARM64 systems)
zzcollab --config set docker.platform "arm64"

# Use native platform
zzcollab --config set docker.platform "native"
```

## Summary

ZZCOLLAB provides comprehensive reproducible research infrastructure:

### For Team Leads
1. Choose Docker profile for research domain
2. Build and share team image
3. Manage base environment dependencies
4. Coordinate team collaboration

### For Team Members
1. Clone repository and pull team image
2. Develop in identical environment
3. Add packages dynamically via renv
4. Contribute to collaborative renv.lock

### For Solo Developers
1. Configure once, use everywhere
2. Choose appropriate Docker profile
3. Add packages as needed
4. Transition to team when ready

### Key Principles
- **Two-layer architecture**: Team Docker profile + dynamic packages
- **renv.lock is source of truth**: Not the Docker image
- **Package accumulation**: renv.lock contains packages from all contributors
- **Profile flexibility**: 14+ profiles from 200MB to 3GB
- **Complete reproducibility**: Dockerfile + renv.lock + .Rprofile + source code + data

For comprehensive technical details, see `docs/` directory.
