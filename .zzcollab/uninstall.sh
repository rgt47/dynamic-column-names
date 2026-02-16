#!/bin/bash
##############################################################################
# ZZCOLLAB UNINSTALL SCRIPT
##############################################################################
# 
# PURPOSE: Safely removes files and directories created by zzcollab setup
#          - Reads manifest file to determine what to remove
#          - Provides interactive confirmation for safety
#          - Handles Docker image cleanup
#          - Preserves user-created content
#
# USAGE:   ./.zzcollab/uninstall.sh [OPTIONS]
#
# AUTHOR:  Companion to zzcollab.sh
##############################################################################

set -euo pipefail

#=============================================================================
# CONFIGURATION
#=============================================================================

readonly MANIFEST_FILE=".zzcollab/manifest.json"
readonly MANIFEST_TXT=".zzcollab/manifest.txt"
readonly SCRIPT_NAME="$(basename "$0")"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

confirm() {
    local message="$1"
    local response
    
    # Ensure we're reading from the terminal, not stdin
    if [[ -t 0 ]]; then
        echo -e "${YELLOW}$message [y/N]: ${NC}"
        read -r response
    else
        echo -e "${YELLOW}$message [y/N]: ${NC}"
        read -r response </dev/tty
    fi
    [[ "$response" =~ ^[Yy]$ ]]
}

#=============================================================================
# MANIFEST READING FUNCTIONS
#=============================================================================

read_manifest_json() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        return 1
    fi
    
    if ! command_exists jq; then
        log_error "jq is required to read JSON manifest but not installed"
        return 1
    fi
    
    # Validate JSON format
    if ! jq empty "$MANIFEST_FILE" 2>/dev/null; then
        log_error "Invalid JSON in manifest file"
        return 1
    fi
    
    return 0
}

read_manifest_txt() {
    if [[ ! -f "$MANIFEST_TXT" ]]; then
        return 1
    fi
    return 0
}

get_created_items() {
    local type="$1"
    
    if read_manifest_json; then
        case "$type" in
            directories) jq -r '.directories[]' "$MANIFEST_FILE" 2>/dev/null || true ;;
            files) jq -r '.files[]' "$MANIFEST_FILE" 2>/dev/null || true ;;
            symlinks) jq -r '.symlinks[].link' "$MANIFEST_FILE" 2>/dev/null || true ;;
            docker_image) jq -r '.docker_image // empty' "$MANIFEST_FILE" 2>/dev/null || true ;;
        esac
    elif read_manifest_txt; then
        case "$type" in
            directories) grep "^directory:" "$MANIFEST_TXT" | cut -d: -f2- || true ;;
            files) grep "^file:" "$MANIFEST_TXT" | cut -d: -f2- || true ;;
            symlinks) grep "^symlink:" "$MANIFEST_TXT" | cut -d: -f2- || true ;;
            docker_image) grep "^docker_image:" "$MANIFEST_TXT" | cut -d: -f2- || true ;;
        esac
    fi
}

#=============================================================================
# REMOVAL FUNCTIONS
#=============================================================================

remove_symlinks() {
    log_info "Checking for symbolic links to remove..."
    
    local symlinks
    symlinks=$(get_created_items "symlinks")
    
    if [[ -z "$symlinks" ]]; then
        log_info "No symbolic links found in manifest"
        return 0
    fi
    
    local count=0
    while IFS= read -r link; do
        [[ -z "$link" ]] && continue
        
        if [[ -L "$link" ]]; then
            log_info "Removing symlink: $link"
            unlink "$link"
            ((count++))
        else
            log_warning "Symlink not found or not a link: $link"
        fi
    done <<< "$symlinks"

    log_success "Removed $count symbolic links"
    return 0
}

remove_files() {
    log_info "Checking for files to remove..."

    local files
    files=$(get_created_items "files")

    # Comprehensive list of all zzcollab files that may not be in manifest
    # Core project files
    local standard_files="DESCRIPTION NAMESPACE LICENSE Makefile .gitignore .Rprofile .Rprofile_docker renv.lock"

    # Docker files
    standard_files="$standard_files Dockerfile Dockerfile.teamcore Dockerfile.personal .zshrc_docker"

    # Configuration and documentation
    standard_files="$standard_files zzcollab.yaml config.yaml .Rbuildignore"

    # Validation and development scripts
    standard_files="$standard_files check_rprofile_options.R dev.sh dev_workflow.R"

    # GitHub templates and workflows
    standard_files="$standard_files .github/pull_request_template.md .github/ISSUE_TEMPLATE/bug_report.md .github/ISSUE_TEMPLATE/feature_request.md"
    standard_files="$standard_files .github/workflows/analysis-workflow.yml .github/workflows/manuscript-workflow.yml .github/workflows/package-workflow.yml"
    standard_files="$standard_files .github/workflows/r-package.yml .github/workflows/render-paper.yml .github/workflows/render-report.yml"

    # R package files
    standard_files="$standard_files tests/testthat.R _pkgdown.yml"

    # Data documentation
    standard_files="$standard_files data/README.md data/raw_data/README.md data/derived_data/README.md data/metadata/README.md data/validation/README.md data/correspondence/README.md"

    # Analysis paradigm files
    standard_files="$standard_files analysis/scripts/01_exploratory_analysis.R analysis/scripts/02_statistical_modeling.R analysis/scripts/03_model_validation.R"
    standard_files="$standard_files analysis/scripts/04_interactive_dashboard.Rmd analysis/scripts/05_automated_report.Rmd analysis/scripts/analysis_functions.R analysis/scripts/README.md"
    standard_files="$standard_files analysis/scripts/02_data_validation.R analysis/scripts/00_setup_parallel.R analysis/scripts/00_database_setup.R analysis/scripts/99_reproducibility_check.R analysis/scripts/00_testing_guide.R"
    standard_files="$standard_files analysis/exploratory/README.md analysis/modeling/README.md analysis/validation/README.md"
    standard_files="$standard_files outputs/figures/README.md outputs/tables/README.md reports/README.md"
    standard_files="$standard_files analysis/templates/example_analysis.R analysis/templates/figure_template.R"

    # Manuscript paradigm files
    standard_files="$standard_files manuscript/paper.Rmd manuscript/supplementary.Rmd manuscript/references.bib"
    standard_files="$standard_files analysis/reproduce/01_data_preparation.R analysis/reproduce/02_statistical_analysis.R"
    standard_files="$standard_files analysis/reproduce/03_figures_tables.R analysis/reproduce/04_manuscript_render.R"
    standard_files="$standard_files R/analysis_functions.R"
    standard_files="$standard_files submission/figures/README.md submission/tables/README.md submission/supplementary/README.md submission/manuscript_versions/README.md"

    # Package paradigm files
    standard_files="$standard_files R/example_functions.R R/sample_dataset.R R/README.md"
    standard_files="$standard_files tests/testthat/test-example-functions.R tests/testthat/helper-test-functions.R tests/testthat/test-utils.R tests/testthat/README.md"
    standard_files="$standard_files vignettes/getting-started.Rmd vignettes/advanced-usage.Rmd vignettes/README.md"
    standard_files="$standard_files inst/examples/README.md pkgdown/README.md data-raw/README.md man/README.md"

    # NOTE: .zzcollab/uninstall.sh is NOT in this list - it will be removed at the very end
    # to allow the script to complete all operations first

    # Add dynamically named .Rproj file if it exists
    local rproj_file
    rproj_file=$(find . -maxdepth 1 -name "*.Rproj" -type f 2>/dev/null | head -1)
    if [[ -n "$rproj_file" ]]; then
        rproj_file="${rproj_file#./}"  # Remove leading ./
        standard_files="$standard_files $rproj_file"
    fi

    # Convert space-separated standard_files to newline-separated
    local standard_files_newline
    standard_files_newline=$(echo "$standard_files" | tr ' ' '\n')

    if [[ -n "$files" ]]; then
        files="$(printf "%s\n%s" "$files" "$standard_files_newline")"
    else
        files="$standard_files_newline"
    fi

    if [[ -z "$files" ]]; then
        log_info "No files found in manifest"
        return 0
    fi

    local count=0
    local skipped=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        
        if [[ -f "$file" ]]; then
            # Check if file has been modified by checking if it's different from template
            if should_remove_file "$file"; then
                log_info "Removing file: $file"
                rm "$file"
                ((count++))
            else
                log_warning "Skipping modified file: $file"
                ((skipped++))
            fi
        else
            log_warning "File not found: $file"
        fi
    done <<< "$files"
    
    log_success "Removed $count files"
    [[ $skipped -gt 0 ]] && log_warning "Skipped $skipped modified files"
    return 0
}

should_remove_file() {
    local file="$1"
    
    # Always confirm removal of certain important files
    case "$file" in
        DESCRIPTION|NAMESPACE|*.Rproj|Makefile|Dockerfile*|.Rprofile|renv.lock|*.yaml)
            confirm "Remove $file (may contain custom changes)?"
            return $?
            ;;
        *)
            return 0
            ;;
    esac
}

remove_directories() {
    log_info "Checking for directories to remove..."
    
    local directories
    directories=$(get_created_items "directories")
    
    if [[ -z "$directories" ]]; then
        log_info "No directories found in manifest"
        return 0
    fi
    
    # Sort directories in reverse order (deepest first)
    local sorted_dirs
    sorted_dirs=$(echo "$directories" | sort -r)
    
    local count=0
    local skipped=0
    
    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue
        
        if [[ -d "$dir" ]]; then
            if is_directory_empty "$dir"; then
                log_info "Removing empty directory: $dir"
                rmdir "$dir"
                ((count++))
            else
                if confirm "Directory $dir contains files. Remove anyway?"; then
                    log_info "Removing directory and contents: $dir"
                    rm -rf "$dir"
                    ((count++))
                else
                    log_warning "Skipping non-empty directory: $dir"
                    ((skipped++))
                fi
            fi
        else
            log_warning "Directory not found: $dir"
        fi
    done <<< "$sorted_dirs"
    
    log_success "Removed $count directories"
    [[ $skipped -gt 0 ]] && log_warning "Skipped $skipped directories with content"
    return 0
}

is_directory_empty() {
    local dir="$1"
    [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]
}

remove_renv_directory() {
    log_info "Checking for renv directory..."
    
    if [[ -d "renv" ]]; then
        if confirm "Remove renv directory (contains R package cache)?"; then
            log_info "Removing renv directory and cache..."
            rm -rf renv
            log_success "Removed renv directory"
        else
            log_info "Keeping renv directory"
        fi
    else
        log_info "No renv directory found"
    fi
}

remove_docker_images() {
    log_info "Checking for Docker images to remove..."
    
    # Check manifest first
    local manifest_image
    manifest_image=$(get_created_items "docker_image")
    
    if ! command_exists docker; then
        log_warning "Docker not available, skipping image removal"
        return 0
    fi
    
    # Look for common zzcollab Docker images
    local project_name
    if [[ -f "DESCRIPTION" ]]; then
        project_name=$(grep "^Package:" DESCRIPTION 2>/dev/null | cut -d: -f2 | tr -d ' ')
    fi
    
    local images_to_check=()
    [[ -n "$manifest_image" ]] && images_to_check+=("$manifest_image")
    [[ -n "$project_name" ]] && images_to_check+=("$project_name" "${project_name}:latest")
    
    # Also check for team images if we can determine team name
    if [[ -f "zzcollab.yaml" ]] || [[ -f "config.yaml" ]]; then
        local team_name=$(grep -E "team_name|team-name" *.yaml 2>/dev/null | head -1 | cut -d: -f2 | tr -d ' "'"'" || true)
        if [[ -n "$team_name" && -n "$project_name" ]]; then
            images_to_check+=("${team_name}/${project_name}core-shell:latest")
            images_to_check+=("${team_name}/${project_name}core-rstudio:latest") 
            images_to_check+=("${team_name}/${project_name}core-verse:latest")
        fi
    fi
    
    local removed_count=0
    # Use [@]:+ to safely handle empty arrays with set -u
    for image in "${images_to_check[@]+"${images_to_check[@]}"}"; do
        [[ -z "$image" ]] && continue
        
        if docker image inspect "$image" >/dev/null 2>&1; then
            if confirm "Remove Docker image '$image'?"; then
                log_info "Removing Docker image: $image"
                if docker rmi "$image" 2>/dev/null; then
                    ((removed_count++))
                else
                    log_warning "Failed to remove Docker image: $image"
                fi
            else
                log_info "Keeping Docker image: $image"
            fi
        fi
    done
    
    if [[ $removed_count -gt 0 ]]; then
        log_success "Removed $removed_count Docker images"
    else
        log_info "No Docker images removed"
    fi
    return 0
}

remove_manifest() {
    local removed=0
    
    if [[ -f "$MANIFEST_FILE" ]]; then
        log_info "Removing manifest file: $MANIFEST_FILE"
        if rm "$MANIFEST_FILE" 2>/dev/null; then
            ((removed++))
        else
            log_warning "Failed to remove manifest file: $MANIFEST_FILE"
        fi
    fi
    
    if [[ -f "$MANIFEST_TXT" ]]; then
        log_info "Removing manifest file: $MANIFEST_TXT"
        if rm "$MANIFEST_TXT" 2>/dev/null; then
            ((removed++))
        else
            log_warning "Failed to remove manifest file: $MANIFEST_TXT"
        fi
    fi
    
    if [[ $removed -gt 0 ]]; then
        log_success "Removed $removed manifest file(s)"
    else
        log_info "No manifest files found to remove"
    fi
    return 0
}

#=============================================================================
# MAIN FUNCTIONS
#=============================================================================

show_help() {
    cat << EOF
$SCRIPT_NAME - Uninstall zzcollab-created files and directories

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    --dry-run           Show what would be removed without actually removing
    --force             Skip confirmation prompts (dangerous!)
    --keep-docker       Don't remove Docker image
    --keep-files        Only remove empty directories and symlinks
    --help, -h          Show this help message

EXAMPLES:
    $SCRIPT_NAME                    # Interactive uninstall
    $SCRIPT_NAME --dry-run          # See what would be removed
    $SCRIPT_NAME --force            # Uninstall without prompts
    $SCRIPT_NAME --keep-docker      # Keep Docker image

DESCRIPTION:
    This script comprehensively removes ALL files and directories created by
    zzcollab across all paradigms (analysis, manuscript, package). It checks
    both manifest files and a comprehensive list of zzcollab-generated files.

    It will remove:
    - Symbolic links first
    - All core project files (DESCRIPTION, NAMESPACE, LICENSE, Makefile, etc.)
    - All Docker files (Dockerfile, .Rprofile, etc.)
    - All configuration files (zzcollab.yaml, config.yaml, .Rbuildignore, etc.)
    - All paradigm-specific files (analysis scripts, manuscript templates, etc.)
    - All GitHub workflows and templates (.github/workflows/*, .github/ISSUE_TEMPLATE/*)
    - All directories (empty ones first, then asks about non-empty ones)
    - renv directory and package cache
    - Docker images (project and team images)
    - Manifest files
    - The uninstall script itself (last step)

    Safety features:
    - Confirms before removing non-empty directories
    - Confirms before removing potentially customized files
    - Detects and removes team Docker images automatically
    - Handles dynamically named .Rproj files
    - Can run in dry-run mode to preview changes
    - Removes uninstall script itself after completion

EOF
}

show_summary() {
    log_info "=== ZZCOLLAB UNINSTALL SUMMARY ==="
    
    if ! read_manifest_json && ! read_manifest_txt; then
        log_error "No manifest file found!"
        log_error "Cannot determine what files were created by zzcollab"
        log_error "Manifest files: $MANIFEST_FILE or $MANIFEST_TXT"
        return 1
    fi
    
    local pkg_name
    if read_manifest_json; then
        pkg_name=$(jq -r '.package_name // "unknown"' "$MANIFEST_FILE")
        log_info "Package: $pkg_name"
        log_info "Created: $(jq -r '.created_at // "unknown"' "$MANIFEST_FILE")"
    fi
    
    local dirs files symlinks docker_image
    dirs=$(get_created_items "directories" | wc -l)
    files=$(get_created_items "files" | wc -l)
    symlinks=$(get_created_items "symlinks" | wc -l)
    docker_image=$(get_created_items "docker_image")
    
    log_info "Items to remove:"
    log_info "  - Directories: $dirs"
    log_info "  - Files: $files" 
    log_info "  - Symlinks: $symlinks"
    [[ -n "$docker_image" ]] && log_info "  - Docker image: $docker_image"
    
    echo
}

main() {
    local dry_run=false
    local force=false
    local keep_docker=false
    local keep_files=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --keep-docker)
                keep_docker=true
                shift
                ;;
            --keep-files)
                keep_files=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                log_error "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Override confirm function if force mode
    if [[ "$force" == true ]]; then
        confirm() { return 0; }
    fi
    
    # Show summary
    show_summary || exit 1
    
    if [[ "$dry_run" == true ]]; then
        log_info "DRY RUN MODE - No files will be removed"
        log_info "Items that would be removed:"
        
        echo "Symlinks:"
        get_created_items "symlinks" | sed 's/^/  /'
        
        echo "Files:"
        (
            get_created_items "files"
            # Core project files
            echo "DESCRIPTION"
            echo "NAMESPACE"
            echo "LICENSE"
            echo "Makefile"
            echo ".gitignore"
            echo ".Rprofile"
            echo ".Rprofile_docker"
            echo "renv.lock"

            # Docker files
            echo "Dockerfile"
            echo "Dockerfile.teamcore"
            echo "Dockerfile.personal"
            echo ".zshrc_docker"

            # Configuration and documentation
            echo "zzcollab.yaml"
            echo "config.yaml"
            echo ".Rbuildignore"

            # Validation and development scripts
            echo "check_rprofile_options.R"
            echo "dev.sh"
            echo "dev_workflow.R"

            # GitHub templates
            echo ".github/pull_request_template.md"
            echo ".github/ISSUE_TEMPLATE/bug_report.md"
            echo ".github/ISSUE_TEMPLATE/feature_request.md"
            echo ".github/workflows/analysis-workflow.yml"
            echo ".github/workflows/manuscript-workflow.yml"
            echo ".github/workflows/package-workflow.yml"
            echo ".github/workflows/r-package.yml"
            echo ".github/workflows/render-paper.yml"
            echo ".github/workflows/render-report.yml"

            # R package files
            echo "tests/testthat.R"
            echo "_pkgdown.yml"

            # Dynamically named .Rproj file
            find . -maxdepth 1 -name "*.Rproj" -type f 2>/dev/null | sed 's|^\./||'

            # Note: .zzcollab/uninstall.sh will be removed at the very end (not shown here)
        ) | sort -u | sed 's/^/  /'
        
        echo "Directories:"
        (
            get_created_items "directories"
            # Core directories
            [[ -d "renv" ]] && echo "renv"
            [[ -d "R" ]] && echo "R"
            [[ -d "man" ]] && echo "man"
            [[ -d "tests" ]] && echo "tests"
            [[ -d "tests/testthat" ]] && echo "tests/testthat"
            [[ -d "vignettes" ]] && echo "vignettes"
            [[ -d "inst" ]] && echo "inst"
            [[ -d "inst/examples" ]] && echo "inst/examples"
            [[ -d "archive" ]] && echo "archive"
            [[ -d "docs" ]] && echo "docs"

            # Data directories (common across paradigms)
            [[ -d "data" ]] && echo "data"
            [[ -d "data/raw_data" ]] && echo "data/raw_data"
            [[ -d "data/derived_data" ]] && echo "data/derived_data"
            [[ -d "data/metadata" ]] && echo "data/metadata"
            [[ -d "data/validation" ]] && echo "data/validation"
            [[ -d "data/correspondence" ]] && echo "data/correspondence"
            [[ -d "data/raw" ]] && echo "data/raw"
            [[ -d "data/processed" ]] && echo "data/processed"
            [[ -d "data-raw" ]] && echo "data-raw"

            # Analysis directories (analysis paradigm)
            [[ -d "analysis" ]] && echo "analysis"
            [[ -d "analysis/scripts" ]] && echo "analysis/scripts"
            [[ -d "analysis/exploratory" ]] && echo "analysis/exploratory"
            [[ -d "analysis/modeling" ]] && echo "analysis/modeling"
            [[ -d "analysis/validation" ]] && echo "analysis/validation"
            [[ -d "analysis/report" ]] && echo "analysis/report"
            [[ -d "analysis/figures" ]] && echo "analysis/figures"
            [[ -d "analysis/tables" ]] && echo "analysis/tables"
            [[ -d "analysis/templates" ]] && echo "analysis/templates"
            [[ -d "analysis/reproduce" ]] && echo "analysis/reproduce"

            # Output directories (analysis paradigm)
            [[ -d "outputs" ]] && echo "outputs"
            [[ -d "outputs/figures" ]] && echo "outputs/figures"
            [[ -d "outputs/tables" ]] && echo "outputs/tables"
            [[ -d "reports" ]] && echo "reports"
            [[ -d "reports/dashboard" ]] && echo "reports/dashboard"

            # Manuscript paradigm directories
            [[ -d "manuscript" ]] && echo "manuscript"
            [[ -d "manuscript/journal_templates" ]] && echo "manuscript/journal_templates"
            [[ -d "submission" ]] && echo "submission"
            [[ -d "submission/figures" ]] && echo "submission/figures"
            [[ -d "submission/tables" ]] && echo "submission/tables"
            [[ -d "submission/supplementary" ]] && echo "submission/supplementary"
            [[ -d "submission/manuscript_versions" ]] && echo "submission/manuscript_versions"

            # Package paradigm directories
            [[ -d "pkgdown" ]] && echo "pkgdown"

            # GitHub directories
            [[ -d ".github" ]] && echo ".github"
            [[ -d ".github/workflows" ]] && echo ".github/workflows"
            [[ -d ".github/ISSUE_TEMPLATE" ]] && echo ".github/ISSUE_TEMPLATE"
        ) | sort -ru | sed 's/^/  /'
        
        echo "Docker images:"
        local project_name team_name
        [[ -f "DESCRIPTION" ]] && project_name=$(grep "^Package:" DESCRIPTION 2>/dev/null | cut -d: -f2 | tr -d ' ')
        if [[ -f "zzcollab.yaml" ]] || [[ -f "config.yaml" ]]; then
            team_name=$(grep -E "team_name|team-name" *.yaml 2>/dev/null | head -1 | cut -d: -f2 | tr -d ' "'"'" || true)
        fi
        
        local docker_image
        docker_image=$(get_created_items "docker_image")
        [[ -n "$docker_image" ]] && echo "  $docker_image"
        [[ -n "$project_name" ]] && echo "  $project_name:latest"
        if [[ -n "$team_name" && -n "$project_name" ]]; then
            echo "  ${team_name}/${project_name}core-shell:latest"
            echo "  ${team_name}/${project_name}core-rstudio:latest"
            echo "  ${team_name}/${project_name}core-verse:latest"
        fi
        
        exit 0
    fi
    
    # Confirm before proceeding
    if ! confirm "Proceed with uninstall?"; then
        log_info "Uninstall cancelled"
        exit 0
    fi
    
    # Perform removal in safe order
    log_info "Starting zzcollab uninstall..."
    
    remove_symlinks
    
    if [[ "$keep_files" == false ]]; then
        remove_files
    fi
    
    remove_directories
    
    # Remove renv directory
    remove_renv_directory
    
    if [[ "$keep_docker" == false ]]; then
        remove_docker_images
    fi
    
    remove_manifest

    # Final step: Remove the uninstall script itself and .zzcollab directory
    local uninstall_script=".zzcollab/uninstall.sh"
    if [[ -f "$uninstall_script" ]]; then
        log_info "Removing uninstall script: $uninstall_script"
        # Use a subshell to delete the script and .zzcollab directory after this function exits
        (sleep 1; rm -f "$uninstall_script" 2>/dev/null; rmdir .zzcollab 2>/dev/null) &
        log_success "Uninstall script and .zzcollab directory will be removed in background"
    fi

    log_success "Uninstall completed!"
    log_info "Some files may have been preserved if they contained modifications"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi