#!/bin/bash

################################################################################
# GitHub Repository Backup Script
#
# This script creates mirror backups of all git repositories found in a
# specified directory. Mirror backups preserve complete git history, all
# branches, and all tags while excluding working directory files and
# respecting .gitignore patterns.
#
# Usage:
#   ./backup-repos.sh [projects_dir] [backup_dir]
#
# Examples:
#   ./backup-repos.sh                                    # Uses defaults
#   ./backup-repos.sh ~/Projects ~/backup/repos          # Custom paths
#
# Default locations:
#   Projects: $HOME/Projects
#   Backups:  $HOME/backup/git-repositories
################################################################################

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECTS_DIR="${1:-$HOME/Projects}"
BACKUP_DIR="${2:-$HOME/backup/git-repositories}"
LOG_FILE="$HOME/backup-repos.log"

# Statistics
TOTAL_REPOS=0
SUCCESS_COUNT=0
FAILED_COUNT=0
UPDATED_COUNT=0
NEW_COUNT=0

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Print header
echo "=================================="
echo "  Git Repository Backup Script"
echo "=================================="
echo ""
print_info "Projects directory: $PROJECTS_DIR"
print_info "Backup directory: $BACKUP_DIR"
print_info "Log file: $LOG_FILE"
echo ""

# Check if projects directory exists
if [ ! -d "$PROJECTS_DIR" ]; then
    print_error "Projects directory does not exist: $PROJECTS_DIR"
    exit 1
fi

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    print_info "Creating backup directory: $BACKUP_DIR"
    if ! mkdir -p "$BACKUP_DIR"; then
        print_error "Failed to create backup directory"
        exit 1
    fi
fi

# Log start of backup
log_message "=== Backup started ==="
log_message "Projects: $PROJECTS_DIR"
log_message "Backups: $BACKUP_DIR"

# Find all git repositories and create/update mirrors
print_info "Searching for git repositories..."
echo ""

# Use a more reliable method to find git repositories
while IFS= read -r git_dir; do
    # Get the repository directory
    repo_dir=$(dirname "$git_dir")
    repo_name=$(basename "$repo_dir")
    
    # Skip if this is a bare repository
    if [ -f "$repo_dir/HEAD" ] && [ ! -f "$repo_dir/index" ]; then
        print_warning "Skipping bare repository: $repo_name"
        continue
    fi
    
    # Skip backup directory itself
    if [[ "$repo_dir" == "$BACKUP_DIR"* ]]; then
        continue
    fi
    
    TOTAL_REPOS=$((TOTAL_REPOS + 1))
    
    echo "----------------------------------------"
    print_info "Repository: $repo_name"
    print_info "Location: $repo_dir"
    
    # Change to repository directory to get remote info
    cd "$repo_dir" || continue
    
    # Get remote URL if available
    remote_url=$(git config --get remote.origin.url 2>/dev/null)
    if [ -n "$remote_url" ]; then
        print_info "Remote: $remote_url"
    fi
    
    # Create or update mirror
    if [ -d "$BACKUP_DIR/$repo_name.git" ]; then
        # Update existing mirror
        print_info "Updating existing mirror..."
        cd "$BACKUP_DIR/$repo_name.git"
        
        # Update the remote URL in case it changed
        git remote set-url origin "$repo_dir" 2>/dev/null
        
        # Fetch updates
        if git remote update --prune 2>/dev/null; then
            print_success "Mirror updated successfully"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
            log_message "Updated: $repo_name"
        else
            print_error "Failed to update mirror"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            log_message "Failed to update: $repo_name"
        fi
    else
        # Create new mirror
        print_info "Creating new mirror..."
        if git clone --mirror "$repo_dir" "$BACKUP_DIR/$repo_name.git" 2>/dev/null; then
            print_success "Mirror created successfully"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            NEW_COUNT=$((NEW_COUNT + 1))
            log_message "Created: $repo_name"
        else
            print_error "Failed to create mirror"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            log_message "Failed to create: $repo_name"
        fi
    fi
    
    echo ""
done < <(find "$PROJECTS_DIR" -type d -name ".git" 2>/dev/null)

# Print summary
echo "=========================================="
echo "  Backup Summary"
echo "=========================================="
print_info "Total repositories found: $TOTAL_REPOS"
print_success "Successful backups: $SUCCESS_COUNT"
if [ $NEW_COUNT -gt 0 ]; then
    print_info "New mirrors created: $NEW_COUNT"
fi
if [ $UPDATED_COUNT -gt 0 ]; then
    print_info "Mirrors updated: $UPDATED_COUNT"
fi
if [ $FAILED_COUNT -gt 0 ]; then
    print_error "Failed backups: $FAILED_COUNT"
fi
echo ""
print_info "Backups location: $BACKUP_DIR"
print_info "Log file: $LOG_FILE"
echo "=========================================="

# Log completion
log_message "=== Backup completed ==="
log_message "Total: $TOTAL_REPOS | Success: $SUCCESS_COUNT | Failed: $FAILED_COUNT"
log_message ""

# Exit with appropriate code
if [ $FAILED_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi
