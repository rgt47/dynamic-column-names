# Debugging the CI Workflow

*2026-04-26 11:41 PDT*

This document describes how to reproduce and diagnose failures of the
`Render Blog Post (Simple)` workflow defined in
`.github/workflows/blog-render.yml`. It is written for post 43
(`dynamic-column-names`) but the patterns generalise to any post repo
in the qblog system.

## Current state of CI for post 43

The most recent failing run (24943789947, 2026-04-26) failed during
**Docker image build**, not at the workflow's later renv or Quarto
steps. The triggering commit (c6b24f8) modified only the
`categories:` YAML field in `analysis/report/index.qmd`, a one-line
change unrelated to packages or build configuration. The prior commit
on identical Dockerfile and `renv.lock` succeeded on 2026-04-22. The
failure is therefore environmental drift, not a regression in repo
content.

The proximate error from the build log:

```
[stage-0  7/10] RUN Rscript -e "renv::restore(prompt=FALSE)"
...
Error: failed to install 'S7', 'ggplot2'
Warning message:
curl does not appear to be installed; downloads will fail.
```

Two observations:

1. The `renv::restore` that failed is in the **Dockerfile** at line
   82, not the workflow's step 4. The workflow restores again at
   runtime, but the build never gets that far.

2. The `curl does not appear to be installed` line is plausibly a red
   herring (renv emits it when its download check fails for any
   reason). The substantive failure is the source install of `S7`
   0.2.1-1 and `ggplot2` 4.0.1 from Posit Package Manager. PPM is
   pinned in the Dockerfile to
   `https://packagemanager.posit.co/cran/__linux__/noble/latest`,
   where `latest` is a moving snapshot. Between 2026-04-22 and
   2026-04-26, binary availability for one of those package versions
   on Ubuntu Noble shifted, forcing a source build that the image
   lacks the toolchain for.

Likely fixes, in order of preference:

- Pin PPM to a specific dated snapshot (replace `latest` with
  `2026-04-22` or similar) so the build is reproducible across time.
- Add `curl` to the apt install list (lines 44 to 63 of the
  Dockerfile), which silences the warning and may resolve the
  download failure if `curl` was in fact missing.
- Regenerate `renv.lock` against the current PPM snapshot so the
  pinned versions match what is presently downloadable as binaries.

## How the workflow maps to local commands

The workflow has nine steps; only steps 3, 4, 5, and 6 do
substantive work. The rest (checkout, buildx setup, artifact upload,
summaries) have no local equivalent. Run these from the post root
(`posts/43-dynamic-column-names/dynamic-column-names`).

### Step 3: build the Docker image

```bash
# Direct equivalent
docker build -t blog-env .

# Makefile shortcut (uses tag = package name)
make docker-build

# Force a clean rebuild (no layer cache)
make docker-rebuild
```

If the build fails, this is where roughly 80 percent of CI failures
in this repo originate. The Dockerfile bakes in `renv::restore` at
build time, so any package resolution problem surfaces here.

### Step 4: restore renv against the workspace mount

The CI runs renv a second time against the live mount (the one in
the image is from the `renv.lock` at build time; this catches
mid-flight lockfile changes). Direct equivalent:

```bash
docker run --rm \
  -v "$(pwd):/home/analyst/project" \
  -w /home/analyst/project --user root blog-env \
  bash -c 'chown -R analyst:analyst /home/analyst/project && \
           mkdir -p /home/analyst/project/renv && \
           chown -R analyst:analyst /home/analyst/project/renv && \
           su - analyst -c "cd /home/analyst/project && \
             Rscript -e \"options(warn=1); \
                          renv::restore(prompt=FALSE)\""'
```

The `chown -R` rewrites host file ownership to the container's
analyst UID. On CI this is harmless; on macOS and Dropbox it is
mostly cosmetic but can confuse Dropbox sync. To avoid it locally,
substitute `--user "$(id -u):$(id -g)"` and drop the `chown`.

### Step 5: render the Quarto post

```bash
# Direct equivalent
docker run --rm \
  -v "$(pwd):/home/analyst/project" \
  -w /home/analyst/project --user root blog-env \
  bash -c 'chown -R analyst:analyst /home/analyst/project && \
           su - analyst -c "cd /home/analyst/project && \
             quarto render analysis/report/index.qmd --to html"'

# Makefile shortcut
make docker-render-qmd
```

### Step 6: verify the rendered HTML

```bash
ls -l analysis/report/index.html

# CI fails the run if size is below 1000 bytes
stat -f%z analysis/report/index.html  # macOS
stat -c%s analysis/report/index.html  # Linux
```

## Best general-purpose debugging mode

For most failures, the fastest diagnostic loop is an interactive
shell inside the container, not replaying CI commands one by one:

```bash
make r            # drops into the container as analyst
# inside the container:
Rscript -e 'renv::status()'
Rscript -e 'renv::restore(prompt=FALSE)'
quarto render analysis/report/index.qmd --to html
```

Interactive runs let you see live tracebacks, re-render after a fix
without rebuilding the image, and inspect intermediate state
(`.quarto/`, `_freeze/`, `analysis/report/index_files/`). This
flavour does not catch failures that depend on a cold mount; for
that, replay step 4 once after you believe you have a fix.

## Diagnostic recipes for specific symptoms

### `renv::restore` fails to install one or more packages

1. Identify whether the failure is binary-only or includes source
   compilation. A line containing `installing *binary* package` is
   a binary install; `installing *source* package` is source.
2. If source: confirm that the build toolchain inside the image has
   the right system libs. Common gaps: `libcurl4-openssl-dev`
   (already present here), `libssl-dev`, `libxml2-dev`,
   `libfontconfig1-dev`, `libpng-dev`. `apt list --installed
   2>/dev/null | grep -E 'libcurl|libssl'` inside the container.
3. Confirm the package and version are available on PPM Noble:

   ```bash
   curl -sI https://packagemanager.posit.co/cran/__linux__/\
   noble/latest/src/contrib/S7_0.2.1-1.tar.gz
   ```

   A 200 indicates source is available; 404 means renv must look
   elsewhere or fail.
4. If PPM has rotated and the pinned version is gone, regenerate
   the lockfile from a fresh `renv::install` and commit.

### Build succeeds but Quarto render fails

Common causes, in approximate frequency order:

- **YAML front matter syntax error.** Validate with
  `quarto inspect analysis/report/index.qmd` inside the container.
- **Missing image referenced from the qmd.** All `media/images/`
  paths must resolve from the `analysis/report/` working directory.
  `find analysis/report -name '*.png' -o -name '*.jpg'` enumerates
  what the renderer can see.
- **R code chunk error.** Re-run individual chunks interactively
  via `make r` and `Rscript -e "rmarkdown::render(...)"`, or set
  `error: true` on the offending chunk while bisecting.
- **Stale `_freeze/`.** Quarto caches chunk results in
  `analysis/report/_freeze/`. If a chunk's environment changed but
  the cache did not, results may be inconsistent.
  `rm -rf analysis/report/_freeze .quarto` and re-render.
- **Non-ASCII in YAML.** Em dashes, smart quotes, and zero-width
  spaces from copy-paste can break the YAML parser silently. Run
  `LC_ALL=C grep -nP '[^\x00-\x7F]' analysis/report/index.qmd` to
  list every non-ASCII character with line numbers.

### Render succeeds but verification step fails (HTML smaller than
### 1000 bytes)

Quarto can produce a near-empty HTML when it errors late but does
not propagate a non-zero exit code (rare, but it has happened with
some chunk-engine combinations). Inspect the rendered file
directly:

```bash
wc -c analysis/report/index.html
head -50 analysis/report/index.html
```

If the body is empty, look in `analysis/report/index_files/` and
`.quarto/` for partial logs.

### CI passes locally but fails on GitHub (or vice versa)

- **Architecture mismatch.** The Makefile pins
  `--platform linux/amd64` for Apple Silicon parity with the GHA
  ubuntu-latest runners. If you ran `docker build` directly without
  this flag on an arm64 host, the local image is arm64 and the CI
  image is amd64. Some R binary packages are only available for
  one. Always reproduce CI failures with `--platform linux/amd64`.
- **Cache pollution.** Local Docker has layer caches; the CI
  builder is fresh. A package that was cached locally may fail to
  download fresh on CI. `make docker-rebuild` forces parity.
- **Mount path differences.** CI mounts at
  `/home/analyst/project`; the Makefile uses the same path. If you
  run with a different `-v` mapping, working-directory-relative
  Quarto paths can resolve differently.

### `gh run` commands for triage

```bash
# List recent runs and their conclusions
gh run list --limit 10

# Read the failed steps of a specific run (substitute run id)
gh run view 24943789947 --log-failed | tail -120

# Re-run a workflow against the same commit (useful to test if the
# failure is deterministic or transient)
gh run rerun 24943789947

# Watch a triggered run until it finishes
gh run watch
```

## Reproducibility hygiene worth adopting

Three habits cut down on the class of failure currently affecting
post 43:

1. **Pin PPM to a dated snapshot, not `latest`.** Replace
   `https://packagemanager.posit.co/cran/__linux__/noble/latest`
   with a specific date (for example
   `.../noble/2026-04-22`). Bump the date deliberately when you
   want newer binaries.
2. **Run a periodic uncached build.** Add a weekly
   `workflow_dispatch` or scheduled run that builds the image with
   `--no-cache`. This catches PPM rotation and CRAN drift early
   instead of at random commit time.
3. **Keep the Dockerfile-side `renv::restore` and the workflow-side
   `renv::restore` consistent.** They restore the same lockfile
   against potentially different repos overrides. If you change the
   repos, change both.

## When `act` is worth the setup

`act` (`brew install act`) runs the workflow YAML locally using
`nektos/act`. It is heavier than the manual replay above and is
only worth reaching for when the failure looks like it is in the
GitHub Actions harness itself: action versions, runner image
defaults, env var injection, secret resolution. For an R or Quarto
failure, manual replay is faster and clearer.

---
*Rendered on 2026-04-26 at 11:41 PDT.*<br>
*Source: ~/prj/qblog/posts/43-dynamic-column-names/dynamic-column-names/CI_DEBUGGING.md*
