# 🧩 **troubleshooting.md**

## 🧠 Overview

This guide helps diagnose and resolve the most common issues you might encounter when using the **WP Deployment Suite**.

Each section includes the likely cause, quick fixes, and relevant commands.

---

## ⚠️ 1. “❌ Config file not found”

**Symptom:**

> ❌ Config file not found: /path/to/config/wp-deployment.conf
> 

**Cause:**

The suite cannot locate the configuration file.

**Fix:**

1. Ensure you’ve created a valid `wp-deployment.conf` inside your `/config` directory.
2. The path in each script should match your environment:
    
    ```bash
    CONFIG_FILE="/home/<user>/config/wp-deployment.conf"
    ```
    
3. To test:
    
    ```bash
    cat /home/<user>/config/wp-deployment.conf
    ```
    

---

## 🔑 2. “Access denied for user 'X'@'localhost'”

**Symptom:**

> MySQL login fails when running any script.
> 

**Cause:**

Database credentials in the config file are incorrect or user permissions are restricted.

**Fix:**

1. Verify credentials in `wp-deployment.conf`.
2. Test MySQL access manually:
    
    ```bash
    mysql -u <user> -p<password> <database>
    ```
    
3. If access works manually but not via script, ensure there are no hidden spaces or special characters in your `.conf` file.

---

## 🗂 3. “Failed to dump / import database”

**Symptom:**

> Script exits at mysqldump or mysql import step.
> 

**Causes:**

- Database too large or missing privileges
- Incorrect table names in ignored list

**Fix:**

1. Increase memory and timeout limits:
    
    ```bash
    ulimit -n 4096
    ```
    
2. Check if the listed `IGNORED_TABLES` actually exist in your database.
3. Run the `mysqldump` command manually with the same parameters to debug output.

---

## 📁 4. “rsync: permission denied”

**Symptom:**

> rsync fails when syncing wp-content folders.
> 

**Cause:**

File or directory permissions mismatch between environments.

**Fix:**

1. Ensure both source and target directories are writable by your user.
    
    ```bash
    chmod -R 755 wp-content
    chown -R <user>:<group> wp-content
    ```
    
2. If you’re on shared hosting, test with the `-dry-run` flag:
    
    ```bash
    rsync -avz --dry-run /path/dev/wp-content/ /path/live/wp-content/
    ```
    

---

## 🧱 5. “WP-CLI not found”

**Symptom:**

> ℹ️ WP-CLI not found; skipping cache flushes.
> 

**Cause:**

WP-CLI is not installed or not in `$PATH`.

**Fix:**

1. Install globally:
    
    ```bash
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
    ```
    
2. Verify:
    
    ```bash
    wp --info
    ```
    

---

## 🧹 6. Old backups not cleaning up

**Symptom:**

> Backups accumulate despite the MAX_BACKUPS limit.
> 

**Cause:**

`head` and `xargs` cleanup logic may fail on older shells.

**Fix:**

1. Replace cleanup section with:
    
    ```bash
    find "$BACKUP_DIR" -type f -mtime +7 -delete
    ```
    
2. Or verify the `$MAX_BACKUPS` variable is set correctly in your config.

---

## 🧩 7. “No changes found in track_db_changes.php”

**Symptom:**

> The tracker runs but finds no updates.
> 

**Cause:**

- The `wp_stream` plugin isn’t installed or has no data.
- The tracked roles don’t exist.

**Fix:**

1. Confirm the plugin table exists:
    
    ```bash
    SHOW TABLES LIKE '%stream%';
    ```
    
2. Adjust `$allowedRoles` in the script (e.g., add `author`, `contributor`).
3. Extend the time window:
    
    ```php
    $sinceDate = date('Y-m-d H:i:s', strtotime('-72 hours'));
    ```
    

---

## 🔍 Debug Tips

- Add `set -x` at the top of any `.sh` script to trace execution.
- Log output to a file:
    
    ```bash
    ./push_dev_to_live.sh | tee debug.log
    ```
    
- Use MySQL’s `-verbose` flag for detailed dump/import logs.

---

## 💡 Pro Tip

Before every deployment, run:

```bash
mysqldump -u $DEV_DB_USER -p"$DEV_DB_PASS" $DEV_DB_NAME > ~/backup/pre-deploy.sql
```

If something breaks, you can restore instantly:

```bash
mysql -u $DEV_DB_USER -p"$DEV_DB_PASS" $DEV_DB_NAME < ~/backup/pre-deploy.sql
```