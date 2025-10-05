# 🧭 **Overview — WP Deployment Suite**

## **Purpose**

The **WP Deployment Suite** is a lightweight DevOps toolkit for WordPress developers and system administrators.

It automates **database** and **content** synchronisation between development and production environments — helping teams deploy confidently while maintaining backup safety and change visibility.

Originally built for **Health Academy**, it’s now a **generic and configurable** open-source solution for any WordPress setup.

---

## **Key Features**

| Category | Description |
| --- | --- |
| 🔄 **Database Synchronisation** | Automates both **push (Dev → Live)** and **pull (Live → Dev)** database syncs, with table-level exclusions. |
| 📦 **Content Syncing** | Uses `rsync` to copy `wp-content` between environments while preserving file permissions. |
| 💾 **Automatic Backups** | Creates timestamped SQL and archive backups before every operation. |
| 🧠 **Change Tracking** | Includes a `track_db_changes.php` utility to log daily activity via `wp_stream` and optional webhook alerts. |
| ⚙️ **Central Configuration** | All credentials, paths, and options are stored in a single `wp-deployment.conf` file. |
| 🧱 **Safe by Design** | Built-in validation, error handling, and automatic rollback capability. |
| 🕒 **Automation-Ready** | Easily integrated with cron jobs, CI/CD pipelines, or Jenkins workflows. |

---

## **Included Components**

| Folder | Description |
| --- | --- |
| `config/` | Contains example and user configuration files. |
| `scripts/` | Core shell and PHP scripts for deployment automation. |
| `docs/` | Markdown documentation, setup guides, and troubleshooting references. |
| `logs/` | Default location for script output and historical logs. |

---

## **Included Scripts**

| Script | Direction | Purpose |
| --- | --- | --- |
| **`pull_live_to_dev.sh`** | Live → Dev | Pulls a production database into a dev environment for testing. |
| **`push_dev_to_live.sh`** | Dev → Live | Pushes filtered dev data and `wp-content` to production. |
| **`sync-edu-db.sh`** | Live → Dev | Example variant for complex or multi-site setups (e.g., LMS). |
| **`sync-online-db.sh`** | Live → Dev | Example variant for secondary domains or staging sites. |
| **`track_db_changes.php`** | Monitor | Logs all admin/editor user changes and sends summaries to Google Chat. |

---

## **Configuration Overview**

Configuration is handled through a single file:

```
config/wp-deployment.conf
```

Example:

```bash
# --------------------------------------------------------------------
#  Database Credentials — Primary Site (Live ↔ Dev)
# --------------------------------------------------------------------
LIVE_DB_USER="live_db_user"
LIVE_DB_PASS="live_db_password"
LIVE_DB_NAME="live_database"
LIVE_DB_HOST="localhost"

DEV_DB_USER="dev_db_user"
DEV_DB_PASS="dev_db_password"
DEV_DB_NAME="dev_database"
DEV_DB_HOST="localhost"

# --------------------------------------------------------------------
#  Database Credentials — Optional Secondary Site (Online)
# --------------------------------------------------------------------
# Uncomment and edit if you have a second WordPress site (e.g., a subdomain)
# ONLINE_LIVE_DB_USER="online_live_user"
# ONLINE_LIVE_DB_PASS="online_live_password"
# ONLINE_LIVE_DB_NAME="online_live_database"
# ONLINE_LIVE_DB_HOST="localhost"
# ONLINE_DEV_DB_USER="online_dev_user"
# ONLINE_DEV_DB_PASS="online_dev_password"
# ONLINE_DEV_DB_NAME="online_dev_database"
# ONLINE_DEV_DB_HOST="localhost"

# --------------------------------------------------------------------
#  WordPress Paths
# --------------------------------------------------------------------
# Full absolute paths to your WordPress installations
WP_PATH="/var/www/html"              # Production WordPress root
DEV_PATH="/var/www/html/dev"         # Development/staging site
LIVE_PATH="/var/www/html/live"       # (Optional) Explicit live directory

# --------------------------------------------------------------------
#  Backup Directories
# --------------------------------------------------------------------
BACKUP_ROOT="$HOME/backups/wp-deployment"
DEV_BACKUP_DIR="$BACKUP_ROOT/dev_db_backups"
LIVE_BACKUP_DIR="$BACKUP_ROOT/live_db_backups"
WP_CONTENT_BACKUP_DIR="$BACKUP_ROOT/wp_content_backups"

# --------------------------------------------------------------------
#  General Settings
# --------------------------------------------------------------------
MAX_BACKUPS=3
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")

# --------------------------------------------------------------------
#  Optional Site URL Overrides (for post-import adjustments)
# --------------------------------------------------------------------
# Used by sync and pull scripts to automatically correct URLs
DEV_SITE_URL="https://dev.example.com"
ONLINE_DEV_SITE_URL="https://dev.example-online.com"

# --------------------------------------------------------------------
#  WordPress Table Prefix
# --------------------------------------------------------------------
WP_PREFIX="wp_"  # Adjust if your installation uses a custom prefix
```

Each script automatically loads this configuration and validates its presence before running.

---

## **Recommended Folder Layout**

```
wp-deployment-suite/
│
├── config/
│   └── wp-deployment.conf
│
├── scripts/
│   ├── pull_live_to_dev.sh
│   ├── push_dev_to_live.sh
│   ├── sync-edu-db.sh
│   ├── sync-online-db.sh
│   └── track_db_changes.php
│
├── docs/
│   ├── overview.md
│   ├── setup.md
│   ├── usage-guide.md
│   ├── troubleshooting.md
│   └── changelog.md
│
├── logs/
│   └── .gitkeep
│
├── LICENSE
└── README.md

```

---

## **Compatibility**

✅ **Supported Environments**

- Linux (Debian, Ubuntu, CentOS)
- WordPress Single or Multisite
- MySQL / MariaDB
- WP-CLI (optional)
- Google Chat Webhooks (optional)

✅ **Tested Hosting Platforms**

- Hostinger (Shared + Cloud)
- cPanel-based servers
- Local Dev (WSL / Docker / Ubuntu)

---

## **Security Best Practices**

- Never commit real credentials — only `wp-deployment.conf.example`.
- Restrict config access:
    
    ```bash
    chmod 600 config/wp-deployment.conf
    ```
    
- Store webhooks and passwords using environment variables for production use.
- Always test changes in **Dev** before pushing to **Live**.

---

## **Author & Credits**

**Created by:** [Jonathan Keefe](https://keefecodes.com/)
**Project:** WP Deployment Suite
**License:** MIT License