# GitHub Repository Backup Guide

## Overview

This guide provides strategies for backing up your GitHub repositories to prevent data loss. Whether you're concerned about account issues, service outages, or simply want to maintain local copies of your work, this guide will help you choose the right backup strategy.

## Why Backup Your Repositories?

- **Account Security**: Protect against account suspension or closure
- **Service Availability**: Guard against service outages or changes
- **Local Control**: Maintain offline access to your code
- **Disaster Recovery**: Ensure business continuity
- **Version History**: Preserve complete git history, branches, and tags

## Backup Strategies Comparison

### 1. Local Mirror Backup (Recommended)

**Pros:**
- Complete git history, branches, and tags preserved
- Fast restore process
- No dependency on external services
- Respects .gitignore (doesn't backup ignored files)
- Free and under your control

**Cons:**
- Requires local storage space
- Manual or scheduled automation needed
- Single point of failure if not synced to cloud

### 2. Cloud Sync (e.g., Mega.nz, Dropbox, Google Drive)

**Pros:**
- Off-site backup
- Easy to set up with existing sync clients
- Automatic synchronization
- Accessible from anywhere

**Cons:**
- Git metadata may sync inefficiently (many small files)
- Potential sync conflicts with .git directory
- Storage costs may apply
- Privacy concerns with proprietary data

### 3. Mirror to Another Git Host (GitLab, Bitbucket, Codeberg)

**Pros:**
- Complete git functionality preserved
- Redundancy across multiple platforms
- Easy to keep in sync with git push
- Professional backup solution
- Free tiers available

**Cons:**
- Requires account on another platform
- Need to maintain access credentials
- Push/pull overhead

## Recommended Solution: Combined Approach

The best strategy combines multiple methods:

1. **Primary**: Local mirror backups (bare repositories)
2. **Secondary**: Mirror to another git host (GitLab, Bitbucket, or Codeberg)
3. **Optional**: Cloud sync of local mirrors for off-site storage

## Implementation Guide

### Method 1: Local Mirror Backup Script

Create a backup script that mirrors all your repositories:

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="$HOME/backup/git-repositories"
PROJECTS_DIR="$HOME/Projects"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Find all git repositories and create mirrors
find "$PROJECTS_DIR" -type d -name ".git" | while read git_dir; do
    # Get the repository directory
    repo_dir=$(dirname "$git_dir")
    repo_name=$(basename "$repo_dir")
    
    echo "Backing up: $repo_name"
    
    # Create or update mirror
    if [ -d "$BACKUP_DIR/$repo_name.git" ]; then
        # Update existing mirror
        cd "$BACKUP_DIR/$repo_name.git"
        git remote update --prune
    else
        # Create new mirror
        git clone --mirror "$repo_dir" "$BACKUP_DIR/$repo_name.git"
    fi
done

echo "Backup complete! Repositories saved to: $BACKUP_DIR"
```

**Usage:**
1. Save this script as `backup-repos.sh`
2. Make it executable: `chmod +x backup-repos.sh`
3. Run it: `./backup-repos.sh`
4. Schedule it with cron for automatic backups

**Why Mirror?**
- `--mirror` creates a bare repository with all refs (branches, tags, remotes)
- Includes complete history and all branches
- Does NOT copy working directory files or .gitignore'd files
- Smaller storage footprint than regular clones

### Method 2: Sync to Cloud (Mega.nz or Similar)

After creating local mirrors, you can sync them to Mega.nz:

```bash
# Install MEGAcmd (if not already installed)
# For Debian/Ubuntu:
# sudo apt install megacmd

# Login to MEGA
mega-login your-email@example.com

# Sync your backup directory to MEGA
mega-sync "$HOME/backup/git-repositories" /Backups/git-repositories

# This creates a two-way sync between local and MEGA
```

**Note:** Syncing git repositories to cloud storage works better with bare mirrors because:
- Fewer files to sync (no working directory)
- No .gitignore conflicts (bare repos don't have working files)
- More efficient storage and sync

### Method 3: Mirror to Another Git Host

For each repository you want to mirror:

```bash
# Navigate to your repository
cd ~/Projects/grandmaster-opening-library

# Add a mirror remote (example: GitLab)
git remote add gitlab git@gitlab.com:yourusername/grandmaster-opening-library.git

# Push everything to the mirror
git push gitlab --mirror

# Or add multiple mirrors
git remote add bitbucket git@bitbucket.org:yourusername/grandmaster-opening-library.git
git push bitbucket --mirror

# To keep mirrors updated, create an alias or script
# Add to your .bashrc or .zshrc:
# alias git-push-all='git push origin --all && git push origin --tags && git push gitlab --all && git push gitlab --tags'
```

**Automation with Git Hooks:**

Create a post-push hook to automatically mirror:

```bash
# In your repository: .git/hooks/post-push
#!/bin/bash
git push gitlab --mirror 2>&1 | logger -t git-mirror
git push bitbucket --mirror 2>&1 | logger -t git-mirror
```

### Method 4: Automated Multi-Repository Mirror Script

For mirroring all repositories to another host:

```bash
#!/bin/bash

# Configuration
PROJECTS_DIR="$HOME/Projects"
MIRROR_HOST="gitlab.com"
MIRROR_USER="yourusername"

# Find all git repositories
find "$PROJECTS_DIR" -type d -name ".git" | while read git_dir; do
    repo_dir=$(dirname "$git_dir")
    repo_name=$(basename "$repo_dir")
    
    echo "Mirroring: $repo_name to $MIRROR_HOST"
    
    cd "$repo_dir"
    
    # Check if mirror remote exists
    if ! git remote | grep -q "mirror"; then
        # Add mirror remote
        git remote add mirror "git@$MIRROR_HOST:$MIRROR_USER/$repo_name.git"
    fi
    
    # Push to mirror (you may need to create repos on the host first)
    git push mirror --mirror 2>/dev/null || echo "  Note: You may need to create $repo_name on $MIRROR_HOST first"
done

echo "Mirror sync complete!"
```

## Best Practices

### 1. Regular Backups
Set up a cron job to run backups automatically:

```bash
# Edit crontab
crontab -e

# Add this line to run backup daily at 2 AM
0 2 * * * /home/yourusername/backup-repos.sh >> /home/yourusername/backup.log 2>&1
```

### 2. Verify Backups
Periodically test restoration:

```bash
# Test restoring from a mirror
git clone /path/to/backup/repository.git test-restore
cd test-restore
git branch -a  # Verify all branches are present
git log  # Verify history is intact
```

### 3. Document Your Remotes
Keep a list of your remote URLs in case you need to recreate:

```bash
# List all remotes for all repos
find ~/Projects -type d -name ".git" -exec sh -c 'echo "{}:" && git -C $(dirname "{}") remote -v' \;
```

### 4. Encryption for Sensitive Repositories
If uploading to cloud storage, consider encryption:

```bash
# Using gpg to encrypt backup archives
tar -czf - ~/backup/git-repositories | gpg --symmetric --cipher-algo AES256 -o git-backup.tar.gz.gpg

# To decrypt and restore:
gpg --decrypt git-backup.tar.gz.gpg | tar -xzf - -C ~/restore/
```

## What Gets Backed Up?

### Included in Git Backups:
- ✅ All commits and history
- ✅ All branches (local and remote tracking)
- ✅ All tags
- ✅ Git configuration
- ✅ Submodules (references)
- ✅ Git hooks (in full clones, not mirrors)
- ✅ Reflog (in full clones, limited in mirrors)

### NOT Included (Automatically Excluded):
- ❌ Files matching .gitignore patterns (node_modules, build artifacts, etc.)
- ❌ Untracked files (files never added to git)
- ❌ Unstaged changes (uncommitted work)
- ❌ Git stashes (in mirrors)

**Important:** Commit your work before backing up to ensure it's included!

## Comparison: Your Question Answered

### Is Mega.nz Sync a Good Way?

**Yes, with caveats:**
- ✅ Good for off-site backup
- ✅ Works well if you sync bare/mirror repositories
- ⚠️ Less efficient with working directories (many small .git objects)
- ⚠️ Potential sync issues during active development
- ⚠️ Limited free storage (may need paid plan for many repos)

**Recommendation:** Use Mega.nz as a *secondary* backup for your local mirrors, not as the primary method.

### Should You Mirror to Another Host?

**Yes, this is highly recommended:**
- ✅ Professional solution
- ✅ Preserves full git functionality
- ✅ Easy to maintain (single push command)
- ✅ Free tiers available (GitLab, Bitbucket, Codeberg)
- ✅ No storage concerns for code repositories
- ✅ Provides public-facing alternative if GitHub is down

**Recommendation:** Set up mirrors on at least one alternative platform (GitLab or Codeberg are excellent free options).

## Recommended Setup for Your Use Case

Based on your requirements, here's the ideal setup:

1. **Daily Local Mirrors** (Script runs via cron)
   - Creates/updates bare mirrors in `~/backup/git-repositories`
   - Fast, complete, respects .gitignore

2. **Sync to Mega.nz** (Using MEGAcmd sync)
   - Syncs your local mirrors to cloud
   - Provides off-site backup
   - Automatic via MEGA sync daemon

3. **Mirror to GitLab** (Optional, recommended)
   - Add GitLab remotes to important repositories
   - Push mirrors weekly or after major changes
   - Provides instant recovery point

4. **Weekly Verification** (Manual check)
   - Test restore from one backup
   - Verify branches and tags
   - Confirm cloud sync is working

## Quick Start for Your Situation

```bash
# 1. Create backup directory
mkdir -p ~/backup/git-repositories

# 2. Create the backup script
cat > ~/backup-repos.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="$HOME/backup/git-repositories"
PROJECTS_DIR="$HOME/Projects"
mkdir -p "$BACKUP_DIR"
find "$PROJECTS_DIR" -type d -name ".git" | while read git_dir; do
    repo_dir=$(dirname "$git_dir")
    repo_name=$(basename "$repo_dir")
    echo "Backing up: $repo_name"
    if [ -d "$BACKUP_DIR/$repo_name.git" ]; then
        cd "$BACKUP_DIR/$repo_name.git"
        git remote update --prune
    else
        git clone --mirror "$repo_dir" "$BACKUP_DIR/$repo_name.git"
    fi
done
echo "Backup complete!"
EOF

# 3. Make it executable
chmod +x ~/backup-repos.sh

# 4. Run initial backup
~/backup-repos.sh

# 5. Setup MEGA sync (if using)
mega-login your-email@example.com
mega-sync ~/backup/git-repositories /Backups/git-repositories

# 6. Schedule daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * $HOME/backup-repos.sh >> $HOME/backup.log 2>&1") | crontab -
```

## Additional Resources

- [Git Documentation - git-clone --mirror](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---mirror)
- [GitHub: Duplicating a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/duplicating-a-repository)
- [MEGAcmd Documentation](https://github.com/meganz/MEGAcmd)
- [GitLab: Repository mirroring](https://docs.gitlab.com/ee/user/project/repository/mirror/)

## Summary

**Your specific concerns addressed:**

| Concern | Solution |
|---------|----------|
| Backup all repositories | Use find command to locate all .git directories and mirror them |
| Track branches and git stuff | Use `git clone --mirror` to preserve all refs |
| Exclude gitignore files (node_modules) | Git mirrors automatically exclude working directory files |
| Mega.nz sync | Good as secondary backup; sync your local mirrors |
| Mirror to another host | Highly recommended; use GitLab or Codeberg |

**Recommended approach:** 
Local mirrors (daily) → Sync to Mega.nz (automatic) + Mirror important repos to GitLab (weekly)

This gives you three layers of protection:
1. Fast local access
2. Off-site cloud backup
3. Alternative git hosting

All while respecting .gitignore and preserving complete git history!
