# ⚙️ **Setup Guide — WP Deployment Suite**

## **Overview**

The **WP Deployment Suite** helps you safely synchronise databases and content between WordPress environments — such as **Live → Dev** or **Dev → Live**.

This guide walks you through installation, configuration, and first-run verification.

---

## 🧩 **1. Requirements**

Before you begin, ensure your environment meets these requirements:

| Category | Requirement |
| --- | --- |
| **OS** | Linux (Ubuntu, Debian, CentOS, or compatible) |
| **Database** | MySQL / MariaDB |
| **Shell Tools** | `bash`, `mysqldump`, `mysql`, `tar`, `rsync` |
| **WordPress** | Installed (single or multisite) |
| **Optional Tools** | `wp-cli` (for cache flushes) |
| **Optional Integration** | Google Chat webhook (for change alerts) |

> 💡 Tip: These scripts are designed to work on both shared hosting and full server environments.
> 

---

## 🏗️ **2. Directory Structure**

Clone or download the repository to your preferred server path.

The recommended folder structure is:

```
wp-deployment-suite/
│
├── config/                     # Configuration files
│   └── wp-deployment.conf       # Your live config
│
├── scripts/                    # Deployment scripts
│   ├── pull_live_to_dev.sh
│   ├── push_dev_to_live.sh
│   ├── sync-edu-db.sh
│   ├── sync-online-db.sh
│   └── track_db_changes.php
│
├── docs/                       # Documentation
│   ├── overview.md
│   ├── setup.md
│   ├── usage-guide.md
│   └── changelog.md
│
├── logs/                       # Script output and logs
│   └── .gitkeep
│
└── LICENSE / README.md
```

---

## 🧱 **3. Configuration Setup**

All credentials and paths are stored in a single config file:

```
config/wp-deployment.conf
```

Copy the example template:

```bash
cp config/wp-deployment.conf.example config/wp-deployment.conf
```

Then open it in your editor:

```bash
nano config/wp-deployment.conf
```

Edit the following sections with your details:

```bash
# --- Database Credentials ---
LIVE_DB_USER="live_db_user"
LIVE_DB_PASS="live_db_password"
LIVE_DB_NAME="live_database"
LIVE_DB_HOST="localhost"

DEV_DB_USER="dev_db_user"
DEV_DB_PASS="dev_db_password"
DEV_DB_NAME="dev_database"
DEV_DB_HOST="localhost"

# --- WordPress Paths ---
WP_PATH="/var/www/html"
DEV_PATH="/var/www/html/dev"

# --- Backup Directories ---
BACKUP_ROOT="$HOME/backups/wp-deployment"
MAX_BACKUPS=3
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
```

> 🔐 Security Tip:
> 
> 
> Do **not** commit your real config file to Git.
> 
> Add this to `.gitignore`:
> 
> ```
> config/wp-deployment.conf
> backups/
> *.sql
> ```
> 

---

## 🧰 **4. File Permissions**

Ensure the scripts are executable:

```bash
chmod +x scripts/*.sh
```

For shared hosting or multi-user environments:

```bash
chmod 700 config/wp-deployment.conf
```

---

## 🧪 **5. Test Database Connectivity**

Before syncing, test both database connections manually:

```bash
mysql -u your_live_user -p -h localhost -e "SHOW DATABASES;"
mysql -u your_dev_user -p -h localhost -e "SHOW DATABASES;"
```

If both connect successfully, you’re ready for your first sync.

---

## 🚀 **6. Run Your First Test (Dry Run)**

To verify everything works safely:

### ✅ **Pull Live → Dev**

```bash
bash scripts/pull_live_to_dev.sh
```

This will:

- Back up both Live and Dev databases.
- Dump the Live DB (excluding ignored tables).
- Import into Dev automatically.

### ✅ **Push Dev → Live**

```bash
bash scripts/push_dev_to_live.sh

```

This will:

- Back up the Live database.
- Dump filtered Dev data.
- Sync `wp-content` folders.
- Flush caches and rebuild rewrites.

---

## 📋 **7. Optional Tools**

### 🕵️ **Track Database Changes**

Enable daily WordPress Stream monitoring (if you use the plugin):

```bash
php scripts/track_db_changes.php
```

To automate daily logs:

```bash
crontab -e
# Add:
0 8 * * * /usr/bin/php /path/to/wp-deployment-suite/scripts/track_db_changes.php >> /path/to/wp-deployment-suite/logs/changes.log 2>&1
```

---

## 🧩 **8. Integrate with Cron or CI/CD**

Example cron automation:

```bash
# Sync Dev to Live every Wednesday at 6PM
0 18 * * 3 /path/to/wp-deployment-suite/scripts/push_dev_to_live.sh >> /path/to/wp-deployment-suite/logs/deploy.log 2>&1
```

Example Jenkins/GitHub Action step:

```bash
- name: Deploy to Production
  run: bash scripts/push_dev_to_live.sh
```

---

## 🧼 **9. Backup Management**

Each run keeps up to `$MAX_BACKUPS` copies of your `.sql` and `.tar.gz` archives.

They’re stored under:

```
~/backups/wp-deployment/
```

To view:

```bash
ls -lh ~/backups/wp-deployment/*
```

---

## 🧠 **10. Verify and Maintain**

- Always test `pull_live_to_dev.sh` before `push_dev_to_live.sh`.
- Review logs regularly (`/logs/` folder).
- Periodically update the suite (`git pull`).

---

## 👤 **Credits**

**Author:** [Jonathan Keefe](https://keefecodes.com/)
**License:** MIT