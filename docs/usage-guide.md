# 🚀 **Usage Guide — WP Deployment Suite**

This guide explains how to **run**, **customise**, and **automate** your WordPress deployment workflows using the WP Deployment Suite.

Whether you’re syncing from **Live → Dev** for testing or **Dev → Live** for release, each script is modular, predictable, and safe.

---

## ⚙️ **1. Quick Start Commands**

| Action | Direction | Script | Description |
| --- | --- | --- | --- |
| 🡓 **Pull Live → Dev** | Live → Dev | `pull_live_to_dev.sh` | Copies your production database into your development site. |
| 🡑 **Push Dev → Live** | Dev → Live | `push_dev_to_live.sh` | Pushes filtered content and posts from Dev into Live safely. |
| 🡒 **Sync EDU DB** | Live → Dev | `sync-edu-db.sh` | Variant for multi-site or LMS-based setups (example). |
| 🡒 **Sync Online DB** | Live → Dev | `sync-online-db.sh` | Variant for secondary domains or staging sites. |
| 🕵️ **Track DB Changes** | Monitoring | `track_db_changes.php` | Logs admin/editor user activity via `wp_stream` and alerts via webhook. |

---

## 🧭 **2. Pulling Live → Dev**

**Script:** `scripts/pull_live_to_dev.sh`

### **Purpose**

To create a development copy of your production database while preserving dev-specific settings.

### **How It Works**

1. Backs up full Live & Dev databases.
2. Dumps Live DB excluding network tables and `wp_options`.
3. Imports the filtered dump into Dev.
4. Logs results in `~/backups/wp-deployment/live_to_dev/`.

### **Example Run**

```bash
bash scripts/pull_live_to_dev.sh
```

### **Output**

```
📦 Backing up full LIVE database → live_full_backup_2025-10-04_15-45.sql
✅ Filtered LIVE dump created.
🚀 Importing LIVE dump into DEV...
✅ DEV is now synced with LIVE.
```

### **Pro Tip**

If your Dev site uses a different domain, include an automatic URL patch in your config:

```bash
DEV_SITE_URL="https://dev.example.com"
```

Then append to the end of the script:

```bash
mysql -u "$DEV_DB_USER" -p"$DEV_DB_PASS" "$DEV_DB_NAME" -e "
UPDATE wp_options SET option_value='$DEV_SITE_URL' WHERE option_name IN ('siteurl','home');
"
```

---

## 🧱 **3. Pushing Dev → Live**

**Script:** `scripts/push_dev_to_live.sh`

### **Purpose**

To safely promote approved content and changes from Dev to Live, without overwriting sensitive or user data.

### **How It Works**

1. Backs up the full Live database.
2. Dumps Dev DB excluding user and configuration tables.
3. Appends only approved post types (pages, lessons, topics, modules).
4. Imports into Live.
5. Syncs `/wp-content/` between environments.
6. Flushes caches, permalinks, and optional PHP opcache.

### **Example Run**

```bash
bash scripts/push_dev_to_live.sh
```

### **Output**

```
📦 Backing up LIVE database → live_pre_push_backup_2025-10-04.sql
📄 Dumping filtered DEV DB...
🗂 Syncing wp-content from DEV → LIVE...
🧽 Flushing caches/transients/rewrites...
✅ Live DB updated successfully from DEV.
```

### **Safety Features**

- Automatically keeps the last 3 backups (editable via `MAX_BACKUPS`).
- Runs database and content backups before every import.
- Optionally integrates `wp-cli` for cache flushes.

### **Partial Deploy Example**

Push only specific post types:

```bash
bash scripts/push_dev_to_live.sh --posts "page,post,custom_type"
```

(Requires small modification to parse CLI arguments — documented in `troubleshooting.md`.)

---

## 🧩 **4. Syncing Specific Sites (Examples)**

These are optional variants demonstrating **multi-site or multi-domain** usage.

### **`sync-edu-db.sh`**

Use for large LMS environments where Live and Dev need regular DB refreshes.

```bash
bash scripts/sync-edu-db.sh
```

This script:

- Ignores user tables and sensitive data.
- Rewrites URLs automatically to your Dev LMS.

### **`sync-online-db.sh`**

Used for alternate production sites (e.g., marketing domain).

```bash
bash scripts/sync-online-db.sh
```

Automatically replaces Live URLs like:

```
https://www.example.com → https://dev.example.co.uk
```

---

## 🕵️ **5. Tracking Database Changes**

**Script:** `scripts/track_db_changes.php`

### **Purpose**

Monitors recent user changes (from `wp_stream`) and sends summaries via Google Chat or other webhook integrations.

### **Setup**

Add your webhook to `wp-deployment.conf`:

```bash
GOOGLE_CHAT_WEBHOOK="https://chat.googleapis.com/v1/spaces/XXXX/messages?key=XXXXX"
```

Run manually:

```bash
php scripts/track_db_changes.php
```

Automate daily:

```bash
crontab -e
# Run every morning at 8am
0 8 * * * /usr/bin/php /path/to/wp-deployment-suite/scripts/track_db_changes.php >> /path/to/wp-deployment-suite/logs/changes.log 2>&1
```

---

## 🧠 **6. Recommended Workflow**

### **Daily**

- Pull Live → Dev before starting work.
- Test and validate changes locally.

### **Weekly or Release Day**

- Push Dev → Live after QA sign-off.
- Verify front-end and LMS integrity.
- Review change logs (`logs/` folder).

### **Monthly**

- Clean backups (`~/backups/wp-deployment`).
- Review Google Chat logs for abnormal activity.

---

## ⚙️ **7. Automation & Integration**

### **Cron Example (Server Automation)**

```bash
# Sync Dev to Live every Friday at 18:00
0 18 * * 5 bash /var/www/wp-deployment-suite/scripts/push_dev_to_live.sh >> /var/www/wp-deployment-suite/logs/deploy.log 2>&1
```

### **Jenkins Example**

```bash
pipeline {
  stages {
    stage('Deploy to Live') {
      steps {
        sh 'bash scripts/push_dev_to_live.sh'
      }
    }
  }
}
```

### **GitHub Actions Example**

```yaml
name: Deploy to Production
on:
  workflow_dispatch:
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash scripts/push_dev_to_live.sh
```

---

## 🧼 **8. Maintenance Tips**

- 🧾 Check `/logs/` folder regularly for errors or slow syncs.
- 💾 Review `.sql` and `.tar.gz` backups before deleting.
- 🔐 Keep your `config/wp-deployment.conf` outside version control.
- ⚠️ Always test on a staging environment before running on production.

---

## 👤 **Credits**

**Author:** [Jonathan Keefe](https://keefecodes.com/)
**Project:** WP Deployment Suite
**License:** MIT
