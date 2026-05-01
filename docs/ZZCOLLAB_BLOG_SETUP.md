# ZZCOLLAB Blog Post Development Guide

## Overview

This guide documents how to create a **reproducible blog post** using ZZCOLLAB within the Quarto blog ecosystem. Each blog post becomes a self-contained research compendium that readers can clone and execute independently.

**Key Philosophy**: Blog posts with data analysis should be as reproducible as academic papers. Each post directory is a complete ZZCOLLAB project with Docker, renv, and full reproducibility.

## Quick Start

```bash
cd ~/prj/qblog/posts/your_post_name

# Initialize as zzcollab project with publishing profile
zzcollab -r publishing --force

# Set up blog-specific symlink structure
modules/setup_symlinks.sh

# Enter development environment
make docker-build
make docker-zsh

# Work on analysis and post
# When done, exit container (auto-snapshots packages)
exit

# Render the blog post
make docker-post-render
```

## Step 1: Initialize ZZCOLLAB Project

### Prerequisites
- You already have a post directory in `/posts/your_post_name/`
- Git is initialized in the parent blog repository
- Docker is installed and running

### Initialization

Run this command in your post directory:

```bash
zzcollab -r publishing --force
```

**What this does:**
- Creates `Dockerfile` (publishing environment with LaTeX, Quarto, knitr)
- Creates `Makefile` with standard build targets
- Creates `.Rprofile` (R session configuration)
- Creates `DESCRIPTION` (project metadata)
- Creates `NAMESPACE` (R package namespace)
- Creates `.gitignore` (sensible defaults)
- Creates `renv.lock` (empty, will be populated when you install packages)
- Creates `analysis/` directory structure
- Initializes as an R package project (compendium-style)

### Verify Initialization

```bash
ls -la
# Should see: Dockerfile, Makefile, DESCRIPTION, .Rprofile, renv.lock, analysis/, R/
```

## Step 2: Set Up Blog Structure with Symlinks

ZZCOLLAB places blog content in `analysis/paper/index.qmd`, but Quarto expects it at the root level. The solution is a **dual-symlink system**:

### Create Symlink Structure

Use the setup script (once it's available in modules/):

```bash
modules/setup_symlinks.sh
```

Or manually create symlinks:

```bash
# Root-level symlinks (for Quarto)
ln -s analysis/paper/index.qmd index.qmd
ln -s analysis/figures figures
ln -s analysis/media media
ln -s analysis/data data

# Symlinks in analysis/paper/ (for intuitive editing)
cd analysis/paper
ln -s ../figures figures
ln -s ../media media
ln -s ../data data
cd ../..
```

### Verify Symlinks

```bash
# Check root level
ls -l | grep "^l"
# Should see: index.qmd -> analysis/paper/index.qmd, figures, media, data

# Check analysis/paper/
ls -l analysis/paper/ | grep "^l"
# Should see: figures, media, data
```

## Step 3: Organize Media Assets

### Directory Structure

```
analysis/media/
├── README.md              # Source documentation
├── images/
│   ├── hero.jpg          # Featured image for blog listing
│   └── supporting-*.png  # Inline images used in post
├── audio/
│   └── episode-*.mp3     # Podcasts, narration
└── video/
    └── walkthrough.mp4   # Demo videos, tutorials
```

### Add Static Images

```bash
# Copy hero image
cp ~/assets/your-hero.jpg analysis/media/images/

# Create source documentation
cat > analysis/media/images/README.md << 'EOF'
# Image Sources

## hero.jpg
- Source: [Unsplash/Wikimedia/etc]
- Photographer/Creator: [Name]
- License: [CC-BY, Unsplash License, etc]
- URL: [link if available]
EOF
```

## Step 4: Organize Analysis Code

Create numbered scripts that form a clear pipeline:

```
analysis/scripts/
├── 01_prepare_data.R      # Load, clean, export derived data
├── 02_fit_models.R        # Fit models, save results
└── 03_generate_figures.R  # Create publication-quality plots
```

### Script Template

```r
# 01_prepare_data.R
# Purpose: Load and prepare data for analysis
# Output: analysis/data/derived_data/clean_data.csv

library(tidyverse)
library(palmerpenguins)  # Example

# Load source data
raw_data <- penguins

# Clean and prepare
clean_data <- raw_data %>%
  drop_na() %>%
  mutate(across(where(is.numeric), scale))

# Export for downstream use
dir.create("analysis/data/derived_data", showWarnings = FALSE)
write_csv(clean_data, "analysis/data/derived_data/clean_data.csv")

cat("Prepared", nrow(clean_data), "observations\n")
```

### Run Pipeline in Container

```bash
make docker-zsh           # Enter container

# Run scripts
Rscript analysis/scripts/01_prepare_data.R
Rscript analysis/scripts/02_fit_models.R
Rscript analysis/scripts/03_generate_figures.R

# Exit (auto-snapshots packages to renv.lock)
exit
```

## Step 5: Write the Blog Post

Edit `analysis/paper/index.qmd` following the BLOG_POST_TEMPLATE structure:

### Key Conventions

- **Paths are relative to `analysis/paper/`** (symlinks make this work)
- Use simple paths in your markdown: `![](figures/plot.png)`, `![](media/images/hero.jpg)`
- Quarto will find these via symlinks and resolve to correct URLs in HTML

### YAML Front Matter

```yaml
---
title: "Your Blog Post Title"
subtitle: "Optional subtitle"
author: "Your Name"
date: "2025-01-15"
categories: [Category1, Category2, Category3]
description: "Brief description for blog listing"
image: "media/images/hero.jpg"
document-type: "blog"
execute:
  echo: true
  warning: false
  message: false
format:
  html:
    code-fold: false
    code-tools: false
---
```

### Image Usage in Post

```markdown
![Descriptive alt text for accessibility](media/images/hero.jpg){.img-fluid}

*Optional caption with attribution if needed.*
```

### Using Generated Figures

```markdown
![Figure caption](figures/eda-overview.png){.img-fluid}
```

### Embedding Code Results

```{r}
#| label: load-results
results_df <- read_csv("data/derived_data/model_results.csv")
results_df
```

### Video Embedding

```html
<video width="100%" controls>
  <source src="media/video/walkthrough.mp4" type="video/mp4">
</video>
```

## Step 6: Development Workflow

### Interactive Development

```bash
# Enter container
make docker-zsh

# Install packages as needed (will auto-snapshot on exit)
R
> install.packages("ggplot2")
> library(ggplot2)
> q()  # Auto-snapshots to renv.lock

# Run analysis scripts
Rscript analysis/scripts/01_prepare_data.R

# Exit container
exit
```

### Render Blog Post

```bash
# Option 1: In container (full reproducibility)
make docker-zsh
quarto render analysis/paper/index.qmd
exit

# Option 2: From host (if you have Quarto installed)
quarto render index.qmd

# Option 3: Use Makefile target
make docker-post-render
```

### Preview Before Publishing

```bash
# Build and render
make docker-post-render

# View in browser
open index.html
# or on Linux:
xdg-open index.html
```

## Step 7: Add Makefile Targets (Optional)

Add blog-specific targets to `Makefile`:

```makefile
.PHONY: post-analysis post-render docker-post-render docker-post-preview

# Run analysis pipeline
post-analysis:
	Rscript analysis/scripts/01_prepare_data.R
	Rscript analysis/scripts/02_fit_models.R
	Rscript analysis/scripts/03_generate_figures.R

# Render blog post
post-render: post-analysis
	quarto render index.qmd

# Docker versions
docker-post-render:
	docker run --rm -v "$$(pwd):/project" -w /project $(DOCKER_IMAGE) \
		make post-render

docker-post-preview:
	docker run --rm -p 8080:8080 -v "$$(pwd):/project" -w /project $(DOCKER_IMAGE) \
		quarto preview index.qmd --host 0.0.0.0 --port 8080
```

## Step 8: Version Control

### Commit Structure

```bash
# Stage all files
git add .

# Commit with clear message
git commit -m "Add [topic] blog post: reproducible compendium

Structure:
- analysis/paper/index.qmd: Blog post with narrative
- analysis/scripts/: 3-step analysis pipeline
- analysis/figures/: Generated publication-quality plots
- analysis/media/: Hero images and supporting assets
- Dual symlinks for Quarto + intuitive editing

Reproduce:
  make docker-build && make docker-post-render"
```

### .gitignore

The auto-generated `.gitignore` handles most cases:

```
# Rendered output (regenerated from source)
*.html
*_files/
*.pdf
*.tex

# R artifacts
.Rhistory
.RData
.Rproj.user/

# OS files
.DS_Store

# Keep symlinks - they're part of the structure
# Don't add patterns like "index.qmd" to gitignore
```

**Important**: Symlinks should be committed. Git tracks them as small text files containing the target path.

### Git LFS for Large Media

For video and large audio files:

```bash
git lfs install
git lfs track "analysis/media/video/*.mp4"
git lfs track "analysis/media/audio/*.mp3"
git add .gitattributes
```

## Step 9: README for Readers

Create a reader-friendly `README.md` at post root:

```markdown
# [Blog Post Title]

This blog post is a **reproducible research compendium**.

## Quick Start

```bash
git clone https://github.com/yourusername/qblog.git
cd qblog/posts/your_post_name

# Build Docker environment and render
make docker-build
make docker-post-render

# View the rendered post
open index.html
```

## Requirements

- Docker
- Make
- ~2GB disk space for Docker image

## What's Included

- **analysis/paper/index.qmd** - Blog post with narrative and code
- **analysis/scripts/** - Reproducible analysis pipeline (3 numbered scripts)
- **analysis/figures/** - Generated publication-quality plots
- **analysis/media/** - Static images, audio, video
- **Dockerfile** - Exact computational environment
- **renv.lock** - Exact R package versions

## Reproduction

All figures are generated by scripts in `analysis/scripts/`.

To re-run the analysis:

```bash
make docker-zsh
Rscript analysis/scripts/01_prepare_data.R
Rscript analysis/scripts/02_fit_models.R
Rscript analysis/scripts/03_generate_figures.R
exit

make docker-post-render
```

## Learn More

- [Blog Post Template](../BLOG_POST_TEMPLATE.qmd)
- [ZZCOLLAB Documentation](https://github.com/zzcollab/zzcollab)
- [Quarto Documentation](https://quarto.org/)
```

## Integration with Parent Blog

### How It Works

Your blog renders posts from symlinked `index.qmd` files:

```yaml
# _quarto.yml (parent blog)
listing:
  contents: posts/*/index.qmd  # Finds symlinks
  include:
    document-type: "blog"
```

### Rendering Options

**Option 1: Render posts individually** (full reproducibility)

```bash
cd posts/post1 && make docker-post-render
cd ../post2 && make docker-post-render
cd ../.. && quarto render
```

**Option 2: Batch render script** at blog root

```bash
#!/bin/bash
set -e

for post in posts/*/; do
    if [ -f "$post/Makefile" ] && [ -f "$post/Dockerfile" ]; then
        echo "=== Rendering: $post ==="
        (cd "$post" && make docker-build && make docker-post-render)
    fi
done

echo "=== Building site ==="
quarto render
```

## Directory Reference

```
posts/your_post_name/
│
├── ROOT LEVEL (Quarto compatibility)
├── index.qmd              → analysis/paper/index.qmd (symlink)
├── figures/               → analysis/figures/ (symlink)
├── media/                 → analysis/media/ (symlink)
├── data/                  → analysis/data/ (symlink)
├── README.md              # Reproduction instructions
├── .gitignore             # Git configuration
│
├── PROJECT CONFIGURATION
├── Dockerfile             # Docker environment
├── Makefile               # Build automation
├── .Rprofile              # R session config
├── DESCRIPTION            # Project metadata
├── NAMESPACE              # R package namespace
├── renv.lock              # R package versions
│
└── ANALYSIS STRUCTURE (actual content)
    └── analysis/
        ├── paper/
        │   ├── index.qmd  # Blog post (actual file)
        │   ├── figures/   → ../figures (symlink)
        │   ├── media/     → ../media (symlink)
        │   └── data/      → ../data (symlink)
        │
        ├── scripts/       # Analysis pipeline
        │   ├── 01_prepare_data.R
        │   ├── 02_fit_models.R
        │   └── 03_generate_figures.R
        │
        ├── figures/       # R-generated plots
        │   ├── eda-overview.png
        │   └── model-diagnostics.png
        │
        ├── media/         # Static assets
        │   ├── images/
        │   │   ├── README.md (source attribution)
        │   │   └── hero.jpg
        │   ├── audio/
        │   └── video/
        │
        └── data/
            ├── raw_data/  # Original data (read-only)
            │   └── README.md
            └── derived_data/  # Processed data, models
                ├── clean_data.csv
                └── model_fit.rds
```

## Best Practices

### 1. Script Organization

- **01_prepare_data.R**: Load, clean, derive variables
- **02_fit_models.R**: Fit statistical/ML models
- **03_generate_figures.R**: Create plots and visualizations

Each script should be independently runnable and produce clear output.

### 2. Path Conventions

**In your R scripts:**
```r
# Use relative paths from project root
write_csv(data, "analysis/data/derived_data/clean.csv")
read_csv("analysis/data/raw_data/original.csv")
```

**In your Quarto post (analysis/paper/index.qmd):**
```markdown
![](figures/plot.png)        # Via symlink in analysis/paper/
![](media/images/hero.jpg)   # Via symlink in analysis/paper/
```

### 3. Reproducibility Checklist

- [ ] All figures generated by `analysis/scripts/`
- [ ] Raw data documented in `analysis/data/raw_data/README.md`
- [ ] Package versions frozen in `renv.lock`
- [ ] Image sources documented in `analysis/media/images/README.md`
- [ ] Blog post README includes reproduction instructions
- [ ] Posts render without errors in Docker container

### 4. Dependencies

Track explicitly in your scripts:

```r
# Always document packages
library(tidyverse)    # Data manipulation
library(broom)        # Model tidying
library(ggplot2)      # Visualization (part of tidyverse)
```

When you `q()` from the container, renv auto-snapshots all loaded packages.

## Troubleshooting

### Symlinks Not Working

```bash
# Verify symlinks exist
ls -l index.qmd figures media data

# Check they point to correct locations
readlink index.qmd
# Should output: analysis/paper/index.qmd

# If broken, recreate
rm index.qmd
ln -s analysis/paper/index.qmd index.qmd
```

### Image Paths Not Resolving

In Quarto, paths resolve from the `.qmd` file location. Since your `.qmd` is at `analysis/paper/index.qmd`, use:

```markdown
![](figures/plot.png)     # Works via symlink
![](../figures/plot.png)  # Also works but less intuitive
```

### Docker Build Fails

```bash
# Check Docker is running
docker ps

# Build with verbose output
docker build -f Dockerfile -t template_post:latest .

# Check Dockerfile
cat Dockerfile
```

### Packages Not Persisting

```bash
# In container, exit with q() to trigger auto-snapshot
R
> install.packages("ggplot2")
> q()  # Must use q() for renv to snapshot

# Verify renv.lock was updated
git diff renv.lock
```

## Examples in This Repo

See `/posts/ls_since_utility/` for a fully realized example:
- Complete analysis pipeline
- Dual symlink structure
- Rendered HTML output
- Publication-ready figures

## Resources

- [ZZCOLLAB Documentation](https://zzcollab.dev/)
- [Quarto Blog Format](https://quarto.org/docs/websites/website-blog.html)
- [Research Compendium Best Practices](https://research-compendium.science/)
- [Renv Package Management](https://rstudio.github.io/renv/)
- [Docker for Reproducible Research](https://www.rocker-project.org/)

## Next Steps

1. Follow the Quick Start section above
2. Populate your analysis scripts
3. Write your blog post in `analysis/paper/index.qmd`
4. Test reproduction in fresh Docker container
5. Push to repository and share with readers!

---

**Created**: 2025-12-08
**Last Updated**: 2025-12-08
**Author**: Ronald G. Thomas
**License**: CC BY 4.0
