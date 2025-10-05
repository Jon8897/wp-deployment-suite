#!/bin/bash
# --------------------------------------------------------------------
#  WP Deployment Suite - Pull Live → Dev
#  Safely syncs the LIVE database down to the DEV environment.
#  Designed for single-site or multisite WordPress environments.
#  © Jonathan Keefe | keefecodes.com
# --------------------------------------------------------------------

# --- Load Configuration ---
CONFIG_FILE="/path/to/config/wp-deployment.conf"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file not found: $CONFIG_FILE"
  echo "Please create it from config-example/wp-deployment.conf.example"
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

# --- Ensure backup directory exists ---
BACKUP_DIR="${BACKUP_ROOT}/live_to_dev"
mkdir -p "$BACKUP_DIR"

# --- Timestamped file names ---
LIVE_DUMP_FILE="${BACKUP_DIR}/live_filtered_backup_${TIMESTAMP}.sql"
LIVE_BACKUP_FILE="${BACKUP_DIR}/live_full_backup_${TIMESTAMP}.sql"
DEV_BACKUP_FILE="${BACKUP_DIR}/dev_pre_pull_backup_${TIMESTAMP}.sql"

# --- Tables to ignore from LIVE dump (non-essential or system-level) ---
WP_PREFIX="${WP_PREFIX:-wp_}"  # allows flexible table prefixes
IGNORED_TABLES=(
  "${WP_PREFIX}blogs"
  "${WP_PREFIX}blog_versions"
  "${WP_PREFIX}site"
  "${WP_PREFIX}sitemeta"
  "${WP_PREFIX}options"
  "${WP_PREFIX}secondary_options"
)

# --- Helper function for error handling ---
handle_error() {
  echo "❌ $1"
  exit 1
}

# --------------------------------------------------------------------
# STEP 0: Backup full LIVE DB (safety first)
# --------------------------------------------------------------------
echo "📦 Backing up full LIVE database → $LIVE_BACKUP_FILE"
mysqldump -u "$LIVE_DB_USER" -p"$LIVE_DB_PASS" --host="$LIVE_DB_HOST" "$LIVE_DB_NAME" > "$LIVE_BACKUP_FILE" \
  || handle_error "Failed to backup LIVE database."
echo "✅ LIVE DB backup complete."

# --------------------------------------------------------------------
# STEP 1: Backup current DEV DB
# --------------------------------------------------------------------
echo "📦 Backing up current DEV database → $DEV_BACKUP_FILE"
mysqldump -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" "$DEV_DB_NAME" > "$DEV_BACKUP_FILE" \
  || handle_error "Failed to backup DEV database."
echo "✅ DEV DB backup complete."

# --------------------------------------------------------------------
# STEP 2: Dump LIVE excluding ignored tables
# --------------------------------------------------------------------
echo "📦 Creating filtered LIVE DB dump → $LIVE_DUMP_FILE"

IGNORE_ARGS=""
for table in "${IGNORED_TABLES[@]}"; do
  IGNORE_ARGS+=" --ignore-table=${LIVE_DB_NAME}.${table}"
done

mysqldump -u "$LIVE_DB_USER" -p"$LIVE_DB_PASS" --host="$LIVE_DB_HOST" $IGNORE_ARGS "$LIVE_DB_NAME" > "$LIVE_DUMP_FILE" \
  || handle_error "Failed to dump filtered LIVE database."
echo "✅ Filtered LIVE dump created."

# --------------------------------------------------------------------
# STEP 3: Import filtered LIVE dump into DEV
# --------------------------------------------------------------------
echo "🚀 Importing LIVE dump into DEV database..."
mysql -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" "$DEV_DB_NAME" < "$LIVE_DUMP_FILE" \
  || handle_error "Failed to import LIVE dump into DEV."

# --------------------------------------------------------------------
# STEP 4: Post-import URL update (optional)
# --------------------------------------------------------------------
if [ -n "$DEV_SITE_URL" ]; then
  echo "🔧 Updating DEV site URLs to: $DEV_SITE_URL"
  mysql -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" "$DEV_DB_NAME" -e "
  UPDATE ${WP_PREFIX}options
  SET option_value = '${DEV_SITE_URL}'
  WHERE option_name IN ('siteurl', 'home');
  " || echo "⚠️ URL update failed or not applicable."
fi

# --------------------------------------------------------------------
# Final Output
# --------------------------------------------------------------------
echo ""
echo "✅ DEV is now synced with LIVE."
echo "🗂 LIVE dump used:        $LIVE_DUMP_FILE"
echo "📦 LIVE full backup:     $LIVE_BACKUP_FILE"
echo "📦 DEV pre-pull backup:  $DEV_BACKUP_FILE"
echo "🌐 DEV Site URL:         ${DEV_SITE_URL:-not updated}"
echo "🕒 Completed at:         $(date)"
echo "✅ All done."
exit 0