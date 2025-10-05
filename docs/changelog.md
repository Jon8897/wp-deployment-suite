# 🧾 **Changelog**

> All notable changes to this project will be documented in this file.
> 
> 
> This project follows Semantic Versioning and the Keep a Changelog format.
> 

---

## [v1.0.0] – *2025-10-05*

### 🚀 **Initial Public Release**

This version marks the first stable and fully documented release of **WP Deployment Suite**, a modular WordPress DevOps toolkit that safely automates **database and content deployments** between development and live environments.

---

### ✨ **Added**

- **Core Deployment Scripts (`/scripts/`)**
    - `pull_live_to_dev.sh` — safely syncs LIVE → DEV with pre/post backup
    - `push_dev_to_live.sh` — deploys DEV → LIVE with advanced filtering logic
    - `sync-edu-db.sh` — example: multisite/staging environment sync
    - `sync-online-db.sh` — example: secondary domain environment sync
    - `track_db_changes.php` — optional DB audit tracker with Google Chat webhook alerts
- **Central Configuration System (`/config/`)**
    - Added unified `wp-deployment.conf` for global environment variables
    - Added example file: `config-example/wp-deployment.conf.example`
    - Covers credentials, paths, backup directories, timestamps, and retention policies
- **Documentation Suite (`/docs/`)**
    - `overview.md` — high-level overview of the project
    - `setup.md` — detailed installation & environment setup
    - `usage-guide.md` — safe usage, common flows, and CLI examples
    - `changelog.md` — version tracking and feature log
- **Repository Structure**
    - Logical folder structure (`scripts/`, `config/`, `docs/`, `logs/`)
    - `.gitignore` to exclude sensitive credentials, dumps, and temp files
    - `.gitkeep` to persist `/logs/` directory in Git

---

### ⚙️ **Improved**

- Unified script headers for consistency and readability.
- Added a shared `handle_error()` function for reliable error control.
- Timestamp-based backups with automatic cleanup of older archives.
- Enhanced `rsync` exclusion filters for cache and temp directories.
- Introduced emoji-based CLI status icons for clear visual feedback (📦, 🚀, 🧹, ✅, ⚠️).

---

### 🧠 **Highlights**

- 100% environment-agnostic — no hard-coded credentials or URLs.
- Compatible with shared hosting or CI/CD environments.
- Optional Google Chat webhook notifications for team visibility.
- Built for **safety**, **clarity**, and **repeatable WordPress deployment workflows**.

---

### 🔮 **Planned for v1.1.0**

- 🧩 GitHub Actions workflow for automatic deployment.
- 🔔 Slack & Discord webhook support.
- 🪶 Incremental table-aware sync for large WordPress databases.
- 🧰 MySQL connectivity check and rollback verification.
- 🪄 PowerShell and Python equivalents for cross-platform use.

---

**Maintainer:** [Jonathan Keefe](https://keefecodes.com/)
**GitHub:** [github.com/jon8897/wp-deployment-suite](https://github.com/jon8897/wp-deployment-suite)
**License:** MIT