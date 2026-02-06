#!/bin/bash

################################################################################
# Git Repository Mirror to Remote Host Script
#
# This script mirrors all local git repositories to a remote git hosting
# service (GitLab, Bitbucket, Codeberg, etc.). It adds mirror remotes and
# pushes all branches and tags.
#
# Usage:
#   ./mirror-to-remote.sh <host> <username> [projects_dir]
#
# Examples:
#   ./mirror-to-remote.sh gitlab.com myusername
#   ./mirror-to-remote.sh bitbucket.org myusername ~/Projects
#   ./mirror-to-remote.sh codeberg.org myusername
#
# Supported hosts:
#   - gitlab.com
#   - bitbucket.org
#   - codeberg.org
#   - Or any custom git host
#
# Note: You must create the repositories on the remote host first, or have
#       appropriate permissions for automatic creation.
################################################################################

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <host> <username> [projects_dir]"
    echo ""
    echo "Examples:"
    echo "  $0 gitlab.com myusername"
    echo "  $0 bitbucket.org myusername ~/Projects"
    echo "  $0 codeberg.org myusername"
    echo ""
    exit 1
fi

# Configuration
MIRROR_HOST="$1"
MIRROR_USER="$2"
PROJECTS_DIR="${3:-$HOME/Projects}"
REMOTE_NAME="mirror"

# Statistics
TOTAL_REPOS=0
SUCCESS_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

# Print header
echo "================================================"
echo "  Git Repository Mirror to Remote Host"
echo "================================================"
echo ""
print_info "Mirror host: $MIRROR_HOST"
print_info "Mirror user: $MIRROR_USER"
print_info "Projects directory: $PROJECTS_DIR"
print_info "Remote name: $REMOTE_NAME"
echo ""

# Check if projects directory exists
if [ ! -d "$PROJECTS_DIR" ]; then
    print_error "Projects directory does not exist: $PROJECTS_DIR"
    exit 1
fi

# Check SSH connection (optional but recommended)
print_info "Checking SSH connection to $MIRROR_HOST..."
if ssh -T git@$MIRROR_HOST 2>&1 | grep -q "successfully authenticated\|Welcome"; then
    print_success "SSH connection verified"
else
    print_warning "Could not verify SSH connection. You may need to set up SSH keys."
    print_warning "Continue anyway? (y/n)"
    read -r response
    if [ "$response" != "y" ]; then
        exit 1
    fi
fi

echo ""
print_info "Searching for git repositories..."
echo ""

# Find all git repositories
while IFS= read -r git_dir; do
    # Get the repository directory
    repo_dir=$(dirname "$git_dir")
    repo_name=$(basename "$repo_dir")
    
    # Skip if this is a bare repository
    if [ -f "$repo_dir/HEAD" ] && [ ! -f "$repo_dir/index" ]; then
        continue
    fi
    
    TOTAL_REPOS=$((TOTAL_REPOS + 1))
    
    echo "----------------------------------------"
    print_info "Repository: $repo_name"
    print_info "Location: $repo_dir"
    
    # Change to repository directory
    cd "$repo_dir" || continue
    
    # Check if repository has uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_warning "Repository has uncommitted changes. Commit them before mirroring."
    fi
    
    # Construct mirror URL
    mirror_url="git@$MIRROR_HOST:$MIRROR_USER/$repo_name.git"
    print_info "Mirror URL: $mirror_url"
    
    # Check if mirror remote already exists
    if git remote | grep -q "^$REMOTE_NAME$"; then
        print_info "Remote '$REMOTE_NAME' already exists"
        
        # Check if URL matches
        current_url=$(git config --get remote.$REMOTE_NAME.url)
        if [ "$current_url" != "$mirror_url" ]; then
            print_warning "Remote URL differs. Updating..."
            git remote set-url $REMOTE_NAME "$mirror_url"
            print_success "Remote URL updated"
        fi
    else
        # Add mirror remote
        print_info "Adding mirror remote..."
        if git remote add $REMOTE_NAME "$mirror_url"; then
            print_success "Mirror remote added"
        else
            print_error "Failed to add mirror remote"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            echo ""
            continue
        fi
    fi
    
    # Push to mirror
    print_info "Pushing to mirror..."
    
    # Try to push with --mirror first
    if git push $REMOTE_NAME --mirror 2>&1 | tee /tmp/mirror_output.txt; then
        print_success "Repository mirrored successfully"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        # Check if the error is about non-existent repository
        if grep -q "does not appear to be a git repository\|Could not read from remote repository\|Repository not found" /tmp/mirror_output.txt; then
            print_warning "Remote repository does not exist yet"
            print_warning "Please create '$repo_name' on $MIRROR_HOST first"
            print_warning "Visit: https://$MIRROR_HOST/$MIRROR_USER/$repo_name"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        else
            print_error "Failed to push to mirror"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    fi
    
    # Clean up temp file
    rm -f /tmp/mirror_output.txt
    
    echo ""
done < <(find "$PROJECTS_DIR" -type d -name ".git" 2>/dev/null)

# Print summary
echo "================================================"
echo "  Mirror Summary"
echo "================================================"
print_info "Total repositories found: $TOTAL_REPOS"
print_success "Successfully mirrored: $SUCCESS_COUNT"
if [ $SKIPPED_COUNT -gt 0 ]; then
    print_warning "Skipped (repo not created): $SKIPPED_COUNT"
fi
if [ $FAILED_COUNT -gt 0 ]; then
    print_error "Failed: $FAILED_COUNT"
fi
echo ""

# Provide helpful next steps
if [ $SKIPPED_COUNT -gt 0 ]; then
    echo "================================================"
    echo "  Next Steps"
    echo "================================================"
    print_info "For skipped repositories:"
    echo "  1. Create the repositories on https://$MIRROR_HOST"
    echo "  2. Run this script again to push them"
    echo ""
    print_info "Or use the ${MIRROR_HOST} API to create repos automatically"
    echo ""
fi

echo "================================================"

# Exit with appropriate code
if [ $FAILED_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi
