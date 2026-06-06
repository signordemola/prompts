# Linux Mint XFCE — Developer Command Reference
> Adedamola | HP EliteBook 840 G3 | Linux Mint 22.3 XFCE | Updated: 2026

---

## System Update & Maintenance

```bash
# Full system update
sudo apt update && sudo apt upgrade -y

# Check what can be upgraded
sudo apt list --upgradable

# Clean up unused packages and cache
sudo apt autoremove -y && sudo apt autoclean -y

# Remove a specific package completely
sudo apt purge packagename -y

# Clean old system logs (older than 7 days)
sudo journalctl --vacuum-time=7d

# Check journal disk usage
journalctl --disk-usage

# Check boot speed and what's slowing it
systemd-analyze blame

# Check what actually blocks boot
systemd-analyze critical-chain

# Take a Timeshift snapshot
sudo timeshift --create --comments "description here"

# List Timeshift snapshots
sudo timeshift --list

# Restore a snapshot
sudo timeshift --restore

# Clear recent file history (privacy)
cat /dev/null > ~/.local/share/recently-used.xbel
```

---

## Process Management

```bash
# Kill process by name
pkill -f "process name"

# Kill all Node processes
pkill -f node

# Kill dev server by name
pkill -f "next dev"
pkill -f "vite"
pkill -f "uvicorn"
pkill -f "fastapi"

# Kill process running on a specific port
fuser -k 3000/tcp
fuser -k 8000/tcp
fuser -k 8080/tcp

# Check what is running on a port
ss -tulnp | grep 3000

# Find a process ID
ps aux | grep processname

# Kill by process ID
kill -9 PID

# List all running processes
ps aux

# Check all open ports
ss -tulnp
```

---

## System Monitoring

```bash
# Beautiful live system monitor (CPU, RAM, Network, Processes)
btop

# RAM usage summary
free -h

# Disk space usage
df -h

# Folder size
du -sh ~/Documents
du -sh ~/projects

# Find 5 largest directories on your system
du -h ~ | sort -hr | head -n 5

# Live network usage per application
sudo nethogs

# Data usage — daily
vnstat -d

# Data usage — monthly
vnstat -m

# SSD health check
sudo smartctl -a /dev/sda

# CPU information
cat /proc/cpuinfo

# Memory information
cat /proc/meminfo

# System uptime
uptime

# Current date and time
date

# Who is logged in
whoami

# Kernel information
uname -a
```

---

## File Management

```bash
# List files with full details (uses eza)
eza -la

# List with tree view
eza -la --tree

# List with tree — 2 levels deep
eza -la --tree --level=2

# View file with syntax highlighting (uses bat)
bat filename

# View plain file
cat filename

# Find a file by name
find ~ -name "filename"

# Find a file by extension
find ~ -name "*.env"

# Search text inside files (uses ripgrep — fast)
rg "search term" ~/projects

# Search text inside files — case insensitive
rg -i "search term" ~/projects

# Copy file
cp source destination

# Copy folder recursively
cp -r sourcefolder destination

# Move or rename file
mv source destination

# Delete file
rm filename

# Delete folder and contents
rm -rf foldername

# Create folder
mkdir foldername

# Create nested folders
mkdir -p projects/2026/myapp

# Create empty file
touch filename.txt

# Show current directory
pwd

# Go home
cd ~

# Go back one level
cd ..

# Jump to folder (zoxide — learns your habits)
z projectname

# Extract tar.gz
tar -xzf filename.tar.gz

# Extract tar.xz
tar -xJf filename.tar.xz

# Extract zip
unzip filename.zip

# Compress folder to tar.gz
tar -czf archive.tar.gz foldername
```

---

## Navigation Shortcuts (Terminal)

```bash
Ctrl+L          # Clear screen
Ctrl+C          # Cancel/kill running command
Ctrl+Z          # Suspend process to background
Ctrl+R          # Search command history
Ctrl+A          # Jump to beginning of line
Ctrl+E          # Jump to end of line
Ctrl+W          # Delete word before cursor
Ctrl+D          # Exit terminal session
Up Arrow        # Previous command
Tab             # Autocomplete command or path
!!              # Repeat last command
sudo !!         # Repeat last command with sudo
```

---

## Network & VPN

```bash
# Check internet connection
ping google.com

# Check your IP address
ip addr show

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check all network connections
nmcli connection show

# Check active connections only
nmcli connection show --active

# Connect VPN by name
nmcli connection up "VPN name"

# Disconnect VPN
nmcli connection down "VPN name"

# Check open ports
ss -tulnp

# Download a file
wget https://example.com/file.deb

# Download and save with specific name
curl -o filename.deb https://example.com/file.deb

# Follow redirects when downloading
curl -L -o filename.tar.gz https://example.com/file
```

---

## PostgreSQL

```bash
# Start PostgreSQL
sudo systemctl start postgresql

# Stop PostgreSQL
sudo systemctl stop postgresql

# Restart PostgreSQL
sudo systemctl restart postgresql

# Check PostgreSQL status
sudo systemctl status postgresql

# Connect to your database
psql -U adedamola -d demola-studio -h localhost

# Connect as postgres superuser
sudo -u postgres psql

# Connect to specific database as superuser
sudo -u postgres psql -d databasename
```

### Inside psql

```sql
-- List all databases
\l

-- List all tables in current database
\dt

-- Switch to a database
\c databasename

-- Describe a table
\d tablename

-- Create a database
CREATE DATABASE "dbname" OWNER adedamola;

-- Drop a database
DROP DATABASE "dbname";

-- Create a user
CREATE USER username WITH PASSWORD 'password';

-- Give superuser rights
ALTER USER adedamola SUPERUSER;

-- Change password
ALTER USER adedamola WITH PASSWORD 'newpassword';

-- Exit psql
\q
```

---

## Git

```bash
# Clone a repository
git clone https://github.com/username/repo.git

# Clone into current folder
git clone https://github.com/username/repo.git .

# Check status
git status

# Stage all changes
git add .

# Stage specific file
git add filename

# Commit with message
git commit -m "your message"

# Push to remote
git push

# Pull latest changes
git pull

# Check all branches
git branch -a

# Switch to branch
git checkout branchname

# Create and switch to new branch
git checkout -b newbranch

# Merge branch into current
git merge branchname

# View compact log
git log --oneline

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Stash changes
git stash

# Apply stash
git stash pop

# Check remote URLs
git remote -v

# Set global username
git config --global user.name "Your Name"

# Set global email
git config --global user.email "you@email.com"
```

---

## Node / pnpm / nvm

```bash
# Install dependencies
pnpm install

# Run dev server
pnpm dev

# Build project
pnpm build

# Run scripts
pnpm run scriptname

# Add a package
pnpm add packagename

# Add dev dependency
pnpm add -D packagename

# Remove a package
pnpm remove packagename

# Install global package
npm install -g packagename

# Check Node version
node -v

# Check npm version
npm -v

# Check pnpm version
pnpm -v

# List installed nvm versions
nvm list

# Install specific Node version
nvm install 20

# Switch Node version
nvm use 20

# Set default Node version
nvm alias default 20

# Update npm
npm install -g npm@latest
```

---

## Python / FastAPI / pyenv

```bash
# Check Python version
python --version

# List installed Python versions (pyenv)
pyenv versions

# Install a Python version
pyenv install 3.13

# Set global Python version
pyenv global 3.13

# Create virtual environment
python -m venv venv

# Activate virtual environment
source venv/bin/activate

# Deactivate virtual environment
deactivate

# Install a package (inside venv)
pip install packagename

# Install from requirements file
pip install -r requirements.txt

# Save current packages to requirements
pip freeze > requirements.txt

# List installed packages
pip list

# Run FastAPI dev server
uvicorn main:app --reload

# Run FastAPI on specific port
uvicorn main:app --reload --port 8000

# Run FastAPI with host
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

## Services (systemctl)

```bash
# Start a service
sudo systemctl start servicename

# Stop a service
sudo systemctl stop servicename

# Restart a service
sudo systemctl restart servicename

# Enable service on boot
sudo systemctl enable servicename

# Disable service on boot
sudo systemctl disable servicename

# Check service status
sudo systemctl status servicename

# List all running services
systemctl list-units --type=service --state=running

# Disable and stop in one command
sudo systemctl disable --now servicename
```

---

## Tmux

```bash
# Start new tmux session
tmux

# Start named session
tmux new -s sessionname

# Attach to last session
tmux attach

# Attach to named session
tmux attach -t sessionname

# List all sessions
tmux ls

# Kill a session
tmux kill-session -t sessionname
```

### Inside Tmux (Ctrl+B is the prefix)

```
Ctrl+B %        # Split pane vertically
Ctrl+B "        # Split pane horizontally
Ctrl+B arrows   # Move between panes
Ctrl+B x        # Close current pane
Ctrl+B c        # New window
Ctrl+B n        # Next window
Ctrl+B p        # Previous window
Ctrl+B ,        # Rename current window
Ctrl+B d        # Detach session (leave running)
Ctrl+B [        # Scroll mode (q to exit)
```

---

## Permissions & Security

```bash
# Make file executable
chmod +x filename

# Secure file — owner only read/write
chmod 600 filename

# Full permissions for owner only
chmod 700 foldername

# Change file owner
sudo chown username filename

# Change folder owner recursively
sudo chown -R username foldername

# Run command as root
sudo command

# Edit a system file
sudo nano /path/to/file

# Check firewall status
sudo ufw status

# Enable firewall
sudo ufw enable

# Allow a port
sudo ufw allow 3000

# Deny a port
sudo ufw deny 3000
```

---

## XFCE Desktop Specific

```bash
# Open application finder
xfrun4

# Refresh panel
xfce4-panel -r

# Restart XFCE desktop without rebooting
xfce4-session-logout --logout

# Take a screenshot
flameshot gui

# Open file manager
thunar

# Open settings manager
xfce4-settings-manager

# Adjust brightness (hardware)
echo 500 | sudo tee /sys/class/backlight/intel_backlight/brightness

# Check max brightness value
cat /sys/class/backlight/intel_backlight/max_brightness

# Start redshift manually
redshift -l 6.5:3.3 -t 5500:3500 -b 0.9:0.6 &

# Stop redshift
pkill redshift
```

---

## Privacy & Cleanup

```bash
# Clear bash/zsh history
history -c && history -w

# Clear recent files history
cat /dev/null > ~/.local/share/recently-used.xbel

# Clear thumbnail cache
rm -rf ~/.cache/thumbnails/*

# Clear apt cache
sudo apt autoclean -y

# Remove unused packages
sudo apt autoremove -y

# Clear trash
rm -rf ~/.local/share/Trash/*

# Full monthly cleanup — run all at once
sudo apt autoremove -y && sudo apt autoclean -y && sudo journalctl --vacuum-time=7d && rm -rf ~/.cache/thumbnails/*
```

---

## Useful One-Liners

```bash
# Find all .env files in projects
find ~/projects -name ".env"

# Count lines in a file
wc -l filename

# Check history for a command you ran before
history | grep "apt install"

# Count executables on system
ls /usr/bin | wc -l

# Watch a command run every 2 seconds
watch -n 2 free -h

# Run command in background
command &

# Run multiple commands
command1 && command2

# Show last 50 lines of a log file
tail -n 50 /var/log/syslog

# Follow a log file live
tail -f /var/log/syslog

# Show calendar
cal

# Repeat last sudo command
sudo !!
```

---

## Monthly Maintenance Checklist

```bash
# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Clean up
sudo apt autoremove -y && sudo apt autoclean -y

# 3. Clean logs
sudo journalctl --vacuum-time=7d

# 4. Check boot speed
systemd-analyze blame

# 5. Check data usage
vnstat -m

# 6. Check SSD health
sudo smartctl -a /dev/sda

# 7. Take Timeshift snapshot
sudo timeshift --create --comments "monthly - $(date +%Y-%m)"

# 8. Clear thumbnails and trash
rm -rf ~/.cache/thumbnails/* ~/.local/share/Trash/*
```

---

*Linux Mint 22.3 XFCE | Reference updated April 2026*
