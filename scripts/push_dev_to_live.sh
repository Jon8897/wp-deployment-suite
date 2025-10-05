#!/bin/bash
# --------------------------------------------------------------------
#  WP Deployment Suite - Push Dev → Live
#  Safely syncs the DEV database and wp-content to the LIVE WordPress environment.
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

# --- Helper function for error handling ---
handle_error() {
  echo "❌ $1"
  exit 1
}

# --- Prepare backup directories ---
mkdir -p "$DEV_BACKUP_DIR" "$LIVE_BACKUP_DIR" "$WP_CONTENT_BACKUP_DIR"

DEV_DUMP_FILE="${DEV_BACKUP_DIR}/dev_filtered_backup_${TIMESTAMP}.sql"
LIVE_BACKUP_FILE="${LIVE_BACKUP_DIR}/live_pre_push_backup_${TIMESTAMP}.sql"
WP_CONTENT_BACKUP_FILE="${WP_CONTENT_BACKUP_DIR}/live_wp_content_backup_${TIMESTAMP}.tar.gz"

# --- Table prefixes (for multi-site setups) ---
WP_PREFIX="wp_"
SECONDARY_PREFIX="wp_2_"

# --- Tables to exclude completely from base dump ---
IGNORED_TABLES=(
  "${WP_PREFIX}users"
  "${WP_PREFIX}usermeta"
  "${WP_PREFIX}blogs"
  "${WP_PREFIX}blog_versions"
  "${WP_PREFIX}site"
  "${WP_PREFIX}sitemeta"
  "${WP_PREFIX}registration_log"
  "${WP_PREFIX}options"
  "${WP_PREFIX}postmeta"
  "${WP_PREFIX}posts"
  "${SECONDARY_PREFIX}options"
)

# --------------------------------------------------------------------
# STEP 0: Backup current LIVE DB
# --------------------------------------------------------------------
echo "📦 Backing up LIVE database → $LIVE_BACKUP_FILE"
mysqldump -u "$LIVE_DB_USER" -p"$LIVE_DB_PASS" --host="$LIVE_DB_HOST" "$LIVE_DB_NAME" > "$LIVE_BACKUP_FILE" \
  || handle_error "Failed to backup LIVE database."
echo "✅ LIVE DB backup complete."

# --------------------------------------------------------------------
# STEP 1: Dump filtered DEV DB (base minus ignored tables)
# --------------------------------------------------------------------
echo "📦 Dumping filtered DEV DB → $DEV_DUMP_FILE"
IGNORE_ARGS=""
for table in "${IGNORED_TABLES[@]}"; do
  IGNORE_ARGS+=" --ignore-table=${DEV_DB_NAME}.${table}"
done
IGNORE_ARGS+=" --ignore-table=${DEV_DB_NAME}.${SECONDARY_PREFIX}posts"
IGNORE_ARGS+=" --ignore-table=${DEV_DB_NAME}.${SECONDARY_PREFIX}postmeta"

mysqldump -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" $IGNORE_ARGS "$DEV_DB_NAME" > "$DEV_DUMP_FILE" \
  || handle_error "Failed to dump base DEV database."

# --------------------------------------------------------------------
# STEP 1D–1K: Append filtered post/postmeta data by type
# --------------------------------------------------------------------

echo "📄 Appending ${WP_PREFIX}posts (pages, posts, courses, lessons, topics, modules)..."
mysqldump -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" \
  --skip-add-drop-table --no-create-info --replace "$DEV_DB_NAME" "${WP_PREFIX}posts" \
  --where="post_type IN ('page','post','sfwd-courses','sfwd-lessons','sfwd-topic','custom_module')" >> "$DEV_DUMP_FILE"

# --- MAIN postmeta ---
echo "📄 Appending ${WP_PREFIX}postmeta for MAIN posts..."
POST_IDS=$(mysql -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" -Nse "use $DEV_DB_NAME; SELECT ID FROM ${WP_PREFIX}posts WHERE post_type IN ('page','post','sfwd-courses','sfwd-lessons','sfwd-topic','custom_module');")
INCLUDED_POST_IDS=$(echo "$POST_IDS" | tr '\n' ',' | sed 's/,$//')

if [[ -n "$INCLUDED_POST_IDS" ]]; then
  mysqldump -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" \
    --skip-add-drop-table --no-create-info --replace "$DEV_DB_NAME" "${WP_PREFIX}postmeta" \
    --where="post_id IN (${INCLUDED_POST_IDS})" >> "$DEV_DUMP_FILE"
else
  echo "⚠️ No posts found on MAIN; skipping postmeta."
fi

# --- Term relationships for MAIN ---
if [[ -n "$INCLUDED_POST_IDS" ]]; then
  echo "📄 Appending ${WP_PREFIX}term_relationships..."
  mysqldump -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" \
    --skip-add-drop-table --no-create-info --replace "$DEV_DB_NAME" "${WP_PREFIX}term_relationships" \
    --where="object_id IN (${INCLUDED_POST_IDS})" >> "$DEV_DUMP_FILE"
fi

# --- Secondary site/blog data (multi-site safe) ---
declare -A SECONDARY_TYPES=(
  ["sfwd-courses"]="COURSE_IDS_2"
  ["sfwd-lessons"]="LESSON_IDS_2"
  ["sfwd-topic"]="TOPIC_IDS_2"
  ["custom_module"]="MODULE_IDS_2"
)

for post_type in "${!SECONDARY_TYPES[@]}"; do
  echo "📄 Appending ${SECONDARY_PREFIX}posts (${post_type})..."
  mysqldump -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" \
    --skip-add-drop-table --no-create-info --replace "$DEV_DB_NAME" "${SECONDARY_PREFIX}posts" \
    --where="post_type = '${post_type}'" >> "$DEV_DUMP_FILE"

  IDS=$(mysql -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" -Nse "use $DEV_DB_NAME; SELECT ID FROM ${SECONDARY_PREFIX}posts WHERE post_type = '${post_type}';")
  INCLUDED_IDS=$(echo "$IDS" | tr '\n' ',' | sed 's/,$//')

  if [[ -n "$INCLUDED_IDS" ]]; then
    echo "📄 Appending ${SECONDARY_PREFIX}postmeta (${post_type})..."
    mysqldump -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" \
      --skip-add-drop-table --no-create-info --replace "$DEV_DB_NAME" "${SECONDARY_PREFIX}postmeta" \
      --where="post_id IN (${INCLUDED_IDS})" >> "$DEV_DUMP_FILE"
  fi
done

# --- Term relationships for combined SECONDARY posts ---
COMBINED_IDS_2=$(mysql -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" -Nse "use $DEV_DB_NAME; SELECT ID FROM ${SECONDARY_PREFIX}posts WHERE post_type IN ('sfwd-courses','sfwd-lessons','sfwd-topic','custom_module');" | tr '\n' ',' | sed 's/,$//')
if [[ -n "$COMBINED_IDS_2" ]]; then
  echo "📄 Appending ${SECONDARY_PREFIX}term_relationships..."
  mysqldump -u "$DEV_DB_USER" -p"$DEV_DB_PASS" --host="$DEV_DB_HOST" \
    --skip-add-drop-table --no-create-info --replace "$DEV_DB_NAME" "${SECONDARY_PREFIX}term_relationships" \
    --where="object_id IN (${COMBINED_IDS_2})" >> "$DEV_DUMP_FILE"
fi

# --------------------------------------------------------------------
# STEP 2: Import DEV dump into LIVE
# --------------------------------------------------------------------
echo "🚀 Importing DEV dump into LIVE..."
mysql -u "$LIVE_DB_USER" -p"$LIVE_DB_PASS" --host="$LIVE_DB_HOST" "$LIVE_DB_NAME" < "$DEV_DUMP_FILE" \
  || handle_error "Failed to import DEV dump into LIVE."
echo "✅ Live DB updated successfully."

# --------------------------------------------------------------------
# STEP 3: Backup and Sync wp-content
# --------------------------------------------------------------------
WP_CONTENT_SRC="$WP_PATH/wp-content"
echo "📦 Backing up LIVE wp-content → $WP_CONTENT_BACKUP_FILE"
tar --warning=no-file-changed --ignore-failed-read \
    --exclude='cache' \
    --exclude='wflogs' \
    --exclude='upgrade' \
    --exclude='temporary' \
    -czf "$WP_CONTENT_BACKUP_FILE" -C "$WP_CONTENT_SRC" . \
  || {
    echo "⚠️ tar backup failed, falling back to rsync snapshot..."
    SNAPSHOT_DIR="$WP_CONTENT_BACKUP_DIR/wp-content-snapshot_${TIMESTAMP}"
    mkdir -p "$SNAPSHOT_DIR"
    rsync -a --delete \
      --exclude='cache' --exclude='wflogs' --exclude='upgrade' --exclude='temporary' \
      "$WP_CONTENT_SRC"/ "$SNAPSHOT_DIR"/ || handle_error "Snapshot failed too."
    echo "✅ Snapshot created at $SNAPSHOT_DIR"
  }

# --- Sync wp-content from DEV to LIVE ---
echo "🗂 Syncing wp-content from DEV → LIVE..."
rsync -avz --delete \
  "$DEV_PATH/wp-content/" "$WP_CONTENT_SRC"/ || handle_error "wp-content sync failed."
echo "✅ wp-content sync complete."

# --------------------------------------------------------------------
# STEP 3.2: Post-import cache maintenance
# --------------------------------------------------------------------
echo "🧽 Flushing caches/transients/rewrites..."
if command -v wp >/dev/null 2>&1; then
  wp --path="$WP_PATH" cache flush || true
  wp --path="$WP_PATH" transient delete --all || true
  wp --path="$WP_PATH" site list --field=url | xargs -I % sh -c 'wp --path="'"$WP_PATH"'" --url=% rewrite flush --hard || true'
  rm -rf "$WP_PATH/wp-content/cache/"* 2>/dev/null || true
else
  echo "ℹ️ WP-CLI not found; skipping cache flushes."
fi

# --- Optional PHP opcache reset ---
if [ -f "$WP_PATH/opcache-reset.php" ]; then
  echo "⚙️ Triggering PHP opcache reset..."
  curl -s "https://example.com/opcache-reset.php" >/dev/null 2>&1 || true
fi

# --------------------------------------------------------------------
# STEP 4: Housekeeping - retain last $MAX_BACKUPS
# --------------------------------------------------------------------
echo "🧹 Cleaning up old backups..."
for dir in "$WP_CONTENT_BACKUP_DIR" "$DEV_BACKUP_DIR" "$LIVE_BACKUP_DIR"; do
  cd "$dir" || continue
  ls -1tr | head -n -"$MAX_BACKUPS" | xargs -d '\n' rm -f -- 2>/dev/null || true
done

# --------------------------------------------------------------------
# FINAL MESSAGE
# --------------------------------------------------------------------
echo "✅ Live DB updated successfully from DEV."
echo "🗂 Dump file used: $DEV_DUMP_FILE"
echo "📦 Live DB backup: $LIVE_BACKUP_FILE"
echo "Source: $DEV_PATH/wp-content/"
echo "Target: $WP_CONTENT_SRC/"
echo "🕒 Completed at: $(date)"
echo "✅ All done."
exit 0