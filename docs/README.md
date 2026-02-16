# 📚 ZZCOLLAB Blog Post Template - Exemplar and Best Practices

**This is a template and exemplar** demonstrating ZZCOLLAB best practices for reproducible blog posts. Use this as a starting point for all future blog posts in this repository.

This directory is a **reproducible research compendium** for a blog post using ZZCOLLAB. It demonstrates:
- ✅ How to structure blog posts for reproducibility
- ✅ Separation of concerns (analysis code separate from narrative)
- ✅ Professional visual design with strategic image placement
- ✅ Comprehensive author guidance with detailed comments
- ✅ Integration with Quarto blog system via symlinks
- ✅ Automated testing and validation

## Quick Start

```bash
# Clone the repository
git clone <repo-url>
cd posts/template_post

# Build Docker environment (one-time setup)
make docker-build

# Run analysis and render blog post
make docker-post-render

# View the rendered post
open index.html
```

## ⚠️ Critical: Self-Containment

**Each blog post must be a self-contained project** that can be rendered independently without relying on parent blog directories.

### ✅ DO: Store Images Inside the Post

```bash
# ✓ CORRECT: Images live in analysis/media/images/
cp ~/my-hero-image.jpg analysis/media/images/

# In index.qmd:
![Description](media/images/my-hero-image.jpg){.img-fluid}
```

### ❌ DON'T: Reference External Paths

```bash
# ✗ WRONG: References parent project
![Description](../../images/posts/my-hero-image.jpg){.img-fluid}

# Problem: Post breaks if cloned independently!
```

**Why?** When readers clone just this post directory, external paths won't resolve. All assets must live in `analysis/media/`.

### Test Self-Containment

```bash
# Clone just this post (simulating independent use)
git clone --sparse <repo>
cd qblog
git sparse-checkout set posts/template_post
cd posts/template_post

# Render - should work without parent project
make docker-build
make docker-post-render
open index.html  # Images should load ✓
```

---

## What's Included

### Core Files

- **analysis/paper/index.qmd** - Blog post content (actual file)
- **analysis/scripts/** - Reproducible analysis pipeline:
  - `01_prepare_data.R` - Load and clean data
  - `02_fit_models.R` - Fit statistical models
  - `03_generate_figures.R` - Generate publication-quality plots
- **analysis/figures/** - R-generated plots
- **analysis/media/** - Static assets (images, audio, video)
- **analysis/data/** - Raw and derived data

### Root-Level Symlinks (for Quarto)

- `index.qmd` → `analysis/paper/index.qmd`
- `figures/` → `analysis/figures/`
- `media/` → `analysis/media/`
- `data/` → `analysis/data/`

### Project Configuration

- **Dockerfile** - Complete computational environment
- **Makefile** - Build automation
- **renv.lock** - Exact R package versions
- **.Rprofile** - R session configuration
- **DESCRIPTION** - Project metadata
- **NAMESPACE** - R package namespace

## Directory Structure

```
template_post/
│
├── index.qmd              (symlink → analysis/paper/index.qmd)
├── figures/               (symlink → analysis/figures/)
├── media/                 (symlink → analysis/media/)
├── data/                  (symlink → analysis/data/)
│
├── analysis/
│   ├── paper/
│   │   ├── index.qmd      (blog post - actual file)
│   │   ├── figures/       (symlink for editing)
│   │   ├── media/         (symlink for editing)
│   │   └── data/          (symlink for editing)
│   │
│   ├── scripts/
│   │   ├── 01_prepare_data.R
│   │   ├── 02_fit_models.R
│   │   └── 03_generate_figures.R
│   │
│   ├── figures/           (R-generated plots)
│   ├── media/
│   │   ├── images/        (hero, photos)
│   │   ├── audio/         (podcasts, narration)
│   │   └── video/         (demos, walkthroughs)
│   │
│   └── data/
│       ├── raw_data/      (original data, read-only)
│       └── derived_data/  (processed data, models)
│
├── Dockerfile             (computational environment)
├── Makefile               (build targets)
├── .Rprofile              (R configuration)
├── renv.lock              (package versions)
├── DESCRIPTION            (project metadata)
├── NAMESPACE              (R namespace)
├── .gitignore             (version control)
│
└── docs/                  (zzcollab documentation)
```

## How to Use This As a Template

### 1. Copy and Customize

```bash
cp -r posts/template_post posts/your_new_post
cd posts/your_new_post
```

### 2. Edit the Blog Post

Open `analysis/paper/index.qmd` and:

- Update YAML front matter (title, author, date, categories)
- Replace placeholder content with your post
- Use paths like `figures/`, `media/images/`, `data/` via symlinks
- Add your hero image to `analysis/media/images/`

### 3. Create Analysis Scripts

Modify the numbered scripts in `analysis/scripts/`:

- **01_prepare_data.R** - Load and clean your data
- **02_fit_models.R** - Fit models or perform analysis
- **03_generate_figures.R** - Create visualizations

Each script should be independently runnable.

### 4. Develop Interactively

```bash
# Enter Docker container for interactive development
make docker-zsh

# Inside container:
Rscript analysis/scripts/01_prepare_data.R
Rscript analysis/scripts/02_fit_models.R
Rscript analysis/scripts/03_generate_figures.R

# Install packages as needed (auto-snapshots to renv.lock on exit)
R
> install.packages("package_name")
> q()  # Must use q() to trigger auto-snapshot

exit  # Leave container
```

### 5. Render the Blog Post

```bash
# Full pipeline: analysis + render
make docker-post-render

# Or render just the blog post (assumes scripts already run)
quarto render index.qmd
```

### 6. Verify and Commit

```bash
# View rendered post
open index.html

# Commit to git
git add .
git commit -m "Add [topic] blog post: reproducible compendium

Structure:
- analysis/paper/index.qmd: Blog post content
- analysis/scripts/: 3-step analysis pipeline
- analysis/figures/: R-generated plots
- analysis/media/: Hero images and assets

To reproduce:
  make docker-build && make docker-post-render"
```

## Key Conventions

### Paths in Your Blog Post

Since the file is at `analysis/paper/index.qmd`, use simple paths via symlinks:

```markdown
# Hero image
![Descriptive text](media/images/hero.jpg){.img-fluid}

# Generated figure
![Caption](figures/eda-overview.png){.img-fluid}

# Load data in code chunks
data <- read_csv("data/derived_data/clean.csv")

# Load model results
model <- readRDS("data/derived_data/model.rds")
```

### Script Output Paths

In `analysis/scripts/`, use paths relative to project root:

```r
# Write derived data
write_csv(clean_data, "analysis/data/derived_data/clean_data.csv")

# Save figures
ggsave("analysis/figures/plot.png", p1, width = 8, height = 5)

# Save model objects
saveRDS(model, "analysis/data/derived_data/model.rds")
```

## Makefile Targets

```bash
make docker-build          # Build Docker image (one-time)
make docker-zsh            # Enter container for development
make post-analysis         # Run analysis scripts
make post-render           # Render blog post (requires Quarto)
make docker-post-render    # Run pipeline + render in container
make docker-post-preview   # Preview with Quarto server
make docker-sh             # Container shell (for debugging)
```

## Requirements

- **Docker** - For reproducible computational environment
- **Make** - For build automation
- **Git** - For version control
- **~2GB disk space** - For Docker image
- **~1 hour** - First-time Docker build

## Reproducibility

All analysis is fully reproducible:

```bash
# Reproduce the entire analysis
make docker-build
make docker-post-render

# Or step-by-step
docker run --rm -v "$(pwd):/project" -w /project <image> Rscript analysis/scripts/01_prepare_data.R
docker run --rm -v "$(pwd):/project" -w /project <image> Rscript analysis/scripts/02_fit_models.R
docker run --rm -v "$(pwd):/project" -w /project <image> Rscript analysis/scripts/03_generate_figures.R
```

Every figure in the rendered post is generated by code in `analysis/scripts/`.

## Integration with Parent Blog

This post is designed to integrate seamlessly with Quarto blogs:

```yaml
# In parent _quarto.yml
listing:
  contents: posts/*/index.qmd  # Finds this symlink
  include:
    document-type: "blog"
```

To render all posts:

```bash
# Individual rendering (full reproducibility)
cd posts/template_post && make docker-post-render
cd posts/another_post && make docker-post-render
cd ../.. && quarto render

# Or batch script (see docs/batch_render.sh)
```

## YAML Front Matter Reference

```yaml
---
title: "Your Blog Post Title"
subtitle: "Optional subtitle"
author: "Your Name"
date: "2025-12-08"
categories: [Category1, Category2]
description: "Brief description for blog listing"
image: "media/images/hero.jpg"
document-type: "blog"
draft: false
execute:
  echo: true
  warning: false
  message: false
format:
  html:
    code-fold: false
    code-tools: false
  pdf:
    fontsize: 11pt
---
```

## Example: Palmer Penguins

This template includes example analysis using the Palmer Penguins dataset:

- **Data**: `data/derived_data/penguins_clean.csv` (generated)
- **Model**: Simple linear regression of body mass vs flipper length
- **Figures**: EDA overview and model diagnostics
- **Post**: Demonstrates all key features

Run the example:

```bash
make docker-build
make docker-post-render
open index.html
```

## Troubleshooting

### Docker Build Fails

```bash
# Check Docker is running
docker ps

# Build with verbose output
docker build -f Dockerfile -t template-post:latest .

# Clean and rebuild
docker system prune -a
make docker-build
```

### Symlinks Not Working

```bash
# Verify symlinks exist
ls -l index.qmd figures media data

# Check target paths
readlink index.qmd
# Should output: analysis/paper/index.qmd

# Recreate if broken
rm index.qmd
ln -s analysis/paper/index.qmd index.qmd
```

### Packages Not Persisting

When you exit the container with `q()`, packages are auto-snapshotted to `renv.lock`. Verify:

```bash
git diff renv.lock
# Should show newly installed packages
```

### Quarto Not Found in Container

Ensure the `ubuntu_standard_publishing` profile was used (includes Quarto).

## For More Information

- **Setup Guide**: See `ZZCOLLAB_BLOG_SETUP.md` for detailed instructions
- **ZZCOLLAB Docs**: Run `zzcollab help quickstart`
- **Quarto Docs**: https://quarto.org/docs/websites/website-blog.html
- **Reproducible Research**: https://research-compendium.science/

## Using This Template for Future Posts

### For New Blog Authors: Copy This Template

```bash
# From the blog root directory
cp -r posts/template_post posts/your_new_post
cd posts/your_new_post

# Initialize as a new ZZCOLLAB project (if needed)
zzcollab -r ubuntu_standard_publishing --force
```

### Follow These Steps

1. **Read the guides**:
   - `README.md` (this file) - Overview and quick reference
   - `ZZCOLLAB_BLOG_SETUP.md` - Comprehensive step-by-step guide
   - `ARCHITECTURE_REVIEW.md` - Design decisions explained

2. **Customize the blog post**:
   - Edit `analysis/paper/index.qmd`
   - Follow `<!-- TEMPLATE INSTRUCTION: ... -->` comments throughout
   - Replace `[placeholders]` with your content
   - Update YAML front matter (title, author, date, categories, image)

3. **Prepare your analysis**:
   - Create/modify scripts in `analysis/scripts/`:
     - `01_prepare_data.R` - Load and clean your data
     - `02_fit_models.R` - Fit models or analyze data
     - `03_generate_figures.R` - Generate visualizations
   - Create utility functions in `R/plotting_utils.R` (or load from template)

4. **Add media assets**:
   - Place hero image in `analysis/media/images/`
   - Add 2-3 "ambiance" images for visual rhythm
   - Document sources in `analysis/media/images/README.md`

5. **Test the entire pipeline**:
   ```bash
   make docker-build
   make docker-post-render
   open index.html
   ```

6. **Run tests**:
   ```bash
   # Unit tests for utilities
   Rscript tests/testthat/test-plotting_utils.R

   # Integration tests for analysis pipeline
   Rscript tests/integration/test-analysis-pipeline.R
   ```

7. **Verify reproducibility**:
   - Can readers clone and reproduce your analysis?
   - Are all figures generated by scripts (not committed)?
   - Are all data prepared by pipeline (not hand-curated)?

8. **Commit and publish**:
   ```bash
   git add .
   git commit -m "Add [topic] blog post: reproducible compendium"
   ```

### Best Practices Checklist

- ☐ **Separation of concerns**: Analysis code in `analysis/scripts/`, narrative in `index.qmd`
- ☐ **No inline computation**: Load results from CSVs, not re-fitting models
- ☐ **Pre-generated figures**: Load from `analysis/figures/`, not creating inline
- ☐ **Visual rhythm**: Hero image + 2-3 ambiance images throughout
- ☐ **Comprehensive comments**: `<!-- TEMPLATE INSTRUCTION -->` guides for author
- ☐ **Result tables**: Show key statistics in tables (not just prose)
- ☐ **Author guidance**: Detailed comments in `.qmd` file explaining each section
- ☐ **Tests**: Unit tests for utilities, integration tests for pipeline
- ☐ **Documentation**: README.md explains structure and reproduction

### Key Differences from Traditional Blog Posts

| Aspect | Traditional | ZZCOLLAB Template |
|--------|-------------|-------------------|
| Analysis code | Inline in .qmd | In `analysis/scripts/` (separate) |
| Figures | Generated inline | Pre-generated, loaded via `include_graphics()` |
| Data | Loaded inline or hard-coded | Prepared by pipeline, loaded from CSV |
| Reproducibility | Reader must adapt code | Reader runs `make docker-post-render` |
| Utilities | Copied/modified per post | In `R/`, reused across posts |
| Testing | Manual | Automated test suite |
| Visual design | Often minimal images | Hero + 2-3 ambiance images |

## Questions?

This template aims to make blog posts as reproducible as academic papers. If you encounter issues:

1. Check `ZZCOLLAB_BLOG_SETUP.md` for detailed guidance
2. Review symlink structure: `ls -la` at root and in `analysis/paper/`
3. Test Docker separately: `make docker-sh`
4. Consult ZZCOLLAB docs: `zzcollab help config`

---

**Template Created**: 2025-12-08
**Last Updated**: 2025-12-08
**Profile**: ZZCOLLAB ubuntu_standard_publishing
**License**: CC BY 4.0
