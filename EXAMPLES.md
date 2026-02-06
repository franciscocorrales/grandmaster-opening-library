# Quick Start Examples

This file provides quick copy-paste examples for using the backup scripts.

## Scenario 1: Daily Local Backups

```bash
# Make scripts executable (one-time setup)
chmod +x backup-repos.sh mirror-to-remote.sh

# Run backup manually
./backup-repos.sh ~/Projects ~/backup/git-repositories

# Schedule daily backups at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * $HOME/backup-repos.sh ~/Projects ~/backup/git-repositories >> $HOME/backup.log 2>&1") | crontab -

# Check if cron job is scheduled
crontab -l
```

## Scenario 2: Backup with Default Locations

```bash
# Uses defaults: ~/Projects and ~/backup/git-repositories
./backup-repos.sh
```

## Scenario 3: Mirror to GitLab

```bash
# First, create repositories on GitLab: https://gitlab.com/
# Then run:
./mirror-to-remote.sh gitlab.com your-gitlab-username ~/Projects
```

## Scenario 4: Mirror to Multiple Hosts

```bash
# Mirror to GitLab
./mirror-to-remote.sh gitlab.com your-username ~/Projects

# Mirror to Codeberg (privacy-focused, open source friendly)
./mirror-to-remote.sh codeberg.org your-username ~/Projects

# Mirror to Bitbucket
./mirror-to-remote.sh bitbucket.org your-username ~/Projects
```

## Scenario 5: Sync to Mega.nz After Local Backup

```bash
# Install MEGAcmd if not already installed
# Debian/Ubuntu: sudo apt install megacmd

# Login to MEGA
mega-login your-email@example.com

# Create one-time sync
mega-put ~/backup/git-repositories /Backups/git-repositories

# Or setup automatic sync
mega-sync ~/backup/git-repositories /Backups/git-repositories
```

## Scenario 6: Complete Backup Solution

```bash
# Step 1: Create local mirrors daily
./backup-repos.sh ~/Projects ~/backup/git-repositories

# Step 2: Sync to cloud (Mega.nz)
mega-sync ~/backup/git-repositories /Backups/git-repositories

# Step 3: Mirror to GitLab weekly
./mirror-to-remote.sh gitlab.com your-username ~/Projects

# Automate with cron:
crontab -e

# Add these lines:
# Daily local backup at 2 AM
0 2 * * * $HOME/backup-repos.sh ~/Projects ~/backup/git-repositories >> $HOME/backup.log 2>&1

# Weekly GitLab mirror on Sunday at 3 AM
0 3 * * 0 $HOME/mirror-to-remote.sh gitlab.com your-username ~/Projects >> $HOME/mirror.log 2>&1
```

## Scenario 7: Your Specific Use Case

Based on your question, here's the recommended setup:

```bash
# 1. Run initial backup
cd ~/Projects/grandmaster-opening-library
./backup-repos.sh ~/Projects ~/backup/git-repositories

# 2. Setup MEGA sync (you already have MEGA client)
mega-login your-email@example.com
mega-sync ~/backup/git-repositories /Backups/git-repositories

# 3. Setup daily automated backups
(crontab -l 2>/dev/null; echo "0 2 * * * $HOME/Projects/grandmaster-opening-library/backup-repos.sh ~/Projects ~/backup/git-repositories >> $HOME/backup.log 2>&1") | crontab -

# 4. Optional: Mirror to GitLab for redundancy
# Create account on gitlab.com first, then:
./mirror-to-remote.sh gitlab.com your-gitlab-username ~/Projects
```

This gives you:
- ✅ Local backups (fast restore)
- ✅ Cloud sync via Mega.nz (off-site protection)
- ✅ All branches and git history preserved
- ✅ node_modules and other .gitignore files automatically excluded
- ✅ Optional mirror on another host (GitLab) for maximum redundancy

## Testing Your Backup

```bash
# Test restoring from a backup
cd /tmp
git clone ~/backup/git-repositories/grandmaster-opening-library.git test-restore
cd test-restore
git branch -a  # Should show all branches
git log --oneline | head  # Should show history
ls -la  # Should show all your files
```

## Checking Backup Status

```bash
# View backup log
tail -f ~/backup-repos.log

# Check MEGA sync status
mega-sync

# List backed up repositories
ls -la ~/backup/git-repositories/
```

## Restoring from Backup

### Restore from local mirror:
```bash
git clone ~/backup/git-repositories/your-repo.git ~/restored-repos/your-repo
```

### Restore from MEGA:
```bash
mega-get /Backups/git-repositories/your-repo.git ~/restored-repos/your-repo.git
git clone ~/restored-repos/your-repo.git ~/restored-repos/your-repo
```

### Restore from mirror host:
```bash
git clone git@gitlab.com:your-username/your-repo.git ~/restored-repos/your-repo
```
