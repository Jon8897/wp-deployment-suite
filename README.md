# 🧰 WP Deployment Suite

**Author:** [Jonathan Keefe](https://keefecodes.com)

**License:** MIT

**Version:** 1.0.0

---

## 📦 Overview

The **WP Deployment Suite** is a modular Bash-based toolkit for safely managing WordPress deployments between development and production environments.

It automates **database syncing**, **wp-content updates**, and **backup management**, while maintaining total control over what data is pushed or pulled.

Ideal for **shared hosting**, **staging sites**, or **multisite WordPress** setups where version-controlled deployment pipelines (e.g., GitHub Actions, Jenkins) are not available.

---

## 🚀 Key Features

- 🔄 **Bi-directional Sync** – push or pull database and file changes between Live and Dev.
- 🧩 **Modular Configuration** – one `.conf` file handles credentials, paths, and URLs.
- 🗂 **Backup Safety Net** – auto-generates timestamped SQL backups before every operation.
- 🧱 **Custom Table Exclusions** – exclude user data, site meta, or network-level tables.
- 🧽 **Cache & Rewrite Flush** – uses WP-CLI to automatically clean caches post-deployment.
- 🧹 **Automated Cleanup** – keeps only your last few backups to save space.
- 🔐 **Public-Safe Design** – ready for open-source use, with sensitive data externalised.

---

## 📁 Project Structure

```bash
wp-deployment-suite/
│
├── config/                           # Example + user config templates      
│   └── wp-deployment.conf            # Example template for public users
│
├── scripts/                          # Core executable deployment scripts
│   ├── pull_live_to_dev.sh           # Sync Live → Dev
│   ├── push_dev_to_live.sh           # Sync Dev → Live
│   ├── sync-edu-db.sh                # Example: multisite/staging variant
│   ├── sync-online-db.sh             # Example: secondary site variant
│   └── track_db_changes.php          # (Optional) change tracking utility
│
├── docs/                             # Documentation & usage guides
│   ├── overview.md                   # General project overview
│   ├── setup.md                      # Step-by-step installation & setup
│   ├── usage-guide.md                # Detailed script usage examples
│   ├── troubleshooting.md            # Common issues & fixes
│   └── changelog.md                  # Version history (manual or auto)
│
├── logs/                             # Output & logs from operations
│   └── .gitkeep                      # Ensures folder stays tracked
│
├── LICENSE                           # MIT License file
├── README.md                         # Main documentation
└── .gitignore                        # Ignores credentials, dumps, temp files

```

---

## ⚙️ Setup

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/keefecodes/wp-deployment-suite.git
cd wp-deployment-suite
```

### 2️⃣ Copy and Configure

```bash
mkdir -p ~/config
cp config-example/wp-deployment.conf.example ~/config/wp-deployment.conf
```

Edit your configuration:

```bash
nano ~/config/wp-deployment.conf
```

**Example values:**

```bash
LIVE_DB_USER="live_user"
LIVE_DB_PASS="securepassword"
LIVE_DB_NAME="live_wp"
DEV_DB_USER="dev_user"
DEV_DB_PASS="securepassword"
DEV_DB_NAME="dev_wp"
WP_PATH="/var/www/html"
DEV_PATH="/var/www/html/dev"
BACKUP_ROOT="$HOME/backups/wp-deployment"
```

---

## 🔧 Usage

### 🧲 Pull Live → Dev

Safely overwrite your Dev database with Live content.

```bash
bash scripts/pull_live_to_dev.sh
```

**What it does:**

- Backs up both Live & Dev databases
- Dumps Live DB excluding system tables
- Imports into Dev
- (Optionally) Updates site URLs for Dev

---

### 🚀 Push Dev → Live

Deploy new content, themes, or plugins to production.

```bash
bash scripts/push_dev_to_live.sh
```

**What it does:**

- Backs up Live DB and wp-content
- Dumps filtered Dev DB (excluding user data)
- Imports into Live
- Syncs `/wp-content/`
- Flushes caches & rewrites

---

### 🎓 Sync Secondary Sites

Use these examples if you maintain multiple WordPress properties.

```bash
bash scripts/sync-edu-db.sh
bash scripts/sync-online-db.sh
```

Each script:

- Pulls filtered data from its Live database
- Imports into the corresponding Dev environment
- Updates site URLs

---

## 🧱 Configuration Options

| Variable | Description |
| --- | --- |
| `LIVE_DB_*` | Credentials for your Live database |
| `DEV_DB_*` | Credentials for your Dev database |
| `BACKUP_ROOT` | Path for all generated backups |
| `WP_PATH` | Path to your production WordPress root |
| `DEV_PATH` | Path to your dev/staging site |
| `MAX_BACKUPS` | Number of historical backups to retain |
| `DEV_SITE_URL` | Optional replacement URL after import |
| `WP_PREFIX` | Table prefix (default: `wp_`) |

---

## 🧹 Housekeeping & Backups

All backups are timestamped and stored in:

```
$HOME/backups/wp-deployment/
```

Backups older than `MAX_BACKUPS` are automatically deleted to conserve disk space.

---

## 🧠 Recommended Tools

- **WP-CLI** – for flushing caches and running commands (`wp cache flush`, etc.)
- **rsync** – for efficient wp-content file syncing
- **mysqldump / mysql** – for database operations
- **cron** – for scheduling regular syncs or backups

---

## 🧑‍💻 Example Use Case

| Scenario | Script | Description |
| --- | --- | --- |
| Test plugin updates in a safe sandbox | `pull_live_to_dev.sh` | Copy latest production DB into dev |
| Deploy new LearnDash content | `push_dev_to_live.sh` | Push only course-related posts to Live |
| Refresh staging for QA | `sync-edu-db.sh` | Clone data for QA testing |
| Maintain secondary training site | `sync-online-db.sh` | Keep brand sites in sync |

---

## 🛡️ Security Notes

- Never store credentials directly in Git — use `.conf` files outside repo root.
- Use strong database passwords and secure SSH connections.
- Always verify backups before large sync operations.
- Tested on **Linux environments (CentOS, Ubuntu, AlmaLinux)** with MySQL 5.7+.

---

## 🧭 Future Enhancements

- 🧰 Add rollback command for last backup
- 🕹️ Interactive CLI menu for non-technical users
- 🔄 Optional S3/FTP remote backup upload
- ⚙️ Jenkins/GitHub Actions integration example

---

## 📜 License

This project is released under the **MIT License**.

You’re free to use, modify, and distribute with attribution.

---

## 💬 Author

**Jonathan Keefe** — [keefecodes.com](http://keefecodes.com)
Building automation, infrastructure, and DevOps tools for WordPress and beyond.
Follow along for more open-source deployment and monitoring scripts.