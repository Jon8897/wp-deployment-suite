#!/bin/bash
# --------------------------------------------------------------------
#  WP Deployment Suite - Sync EDU Database (Live → Dev)
#  Copies filtered data from the LIVE WordPress site into the DEV environment.
#  Designed for multisite or single-site WordPress setups.
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

# --- Variables ---
TMP_DUMP="/tmp/live_filtered.sql"
WP_PREFIX="${WP_PREFIX:-wp_}"  # Allow configurable table prefix

# --- Tables to exclude (sensitive or system-level) ---
IGNORE_TABLES=(
  "${WP_PREFIX}users"
  "${WP_PREFIX}usermeta"
  "${WP_PREFIX}site"
  "${WP_PREFIX}blogs"
  "${WP_PREFIX}sitemeta"
  "${WP_PREFIX}1_options"
)

# --- Helper function for error handling ---
handle_error() {
  echo "❌ $1"
  exit 1
}

# --------------------------------------------------------------------
# STEP 0: Start Sync Process
# --------------------------------------------------------------------
echo "📦 Starting EDU database sync (LIVE ➝ DEV)..."
echo "LIVE DB: $LIVE_DB_NAME → DEV DB: $DEV_DB_NAME"
echo "Timestamp: $TIMESTAMP"

# --------------------------------------------------------------------
# STEP 1: Dump filtered LIVE DB
# --------------------------------------------------------------------
echo "📄 Creating filtered LIVE DB dump → $TMP_DUMP"

IGNORE_ARGS=""
for table in "${IGNORE_TABLES[@]}"; do
  IGNORE_ARGS+=" --ignore-table=${LIVE_DB_NAME}.${table}"
done

mysqldump -u "$LIVE_DB_USER" -p"$LIVE_DB_PASS" --host="$LIVE_DB_HOST" \
  $IGNORE_ARGS "$LIVE_DB_NAME" > "$TMP_DUMP" \
  || handle_error "Failed to dump filtered LIVE database."

echo "✅ Filtered LIVE DB dump created successfully."

# --------------------------------------------------------------------
# STEP 2: Import filtered dump into DEV
# --------------------------------------------------------------------
echo "🚀 Importing filtered dump into DEV database..."
mysql -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" "$DEV_DB_NAME" < "$TMP_DUMP" \
  || handle_error "Failed to import dump into DEV DB."

echo "✅ DEV database successfully updated."

# --------------------------------------------------------------------
# STEP 3: Patch site URLs for DEV environment
# --------------------------------------------------------------------
echo "🔧 Updating site URLs for DEV environment..."

# Allow URL substitution via config file variables
DEV_SITE_URL="${DEV_SITE_URL:-https://dev.example.com}"

mysql -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" "$DEV_DB_NAME" -e "
UPDATE ${WP_PREFIX}options 
SET option_value = '${DEV_SITE_URL}' 
WHERE option_name IN ('siteurl', 'home');
" || handle_error "Failed to patch DEV URLs."

echo "✅ Site URLs updated for DEV (${DEV_SITE_URL})."

# --------------------------------------------------------------------
# STEP 4: Cleanup temporary files
# --------------------------------------------------------------------
rm -f "$TMP_DUMP" 2>/dev/null || true
echo "🧹 Temporary files cleaned up."

# --------------------------------------------------------------------
# Final Output
# --------------------------------------------------------------------
echo ""
echo "✅ LIVE ➝ DEV EDU database sync complete."
echo "🗂 LIVE DB: $LIVE_DB_NAME"
echo "🗂 DEV DB:  $DEV_DB_NAME"
echo "🌐 Updated URLs: $DEV_SITE_URL"
echo "🕒 Completed at: $(date)"
echo "✅ All done."
exit 0