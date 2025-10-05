#!/usr/bin/env php
<?php
// --------------------------------------------------------------------
//  WP Deployment Suite - Track DB Changes (Live + Dev)
//  Logs all wp_stream entries made by admin/editor/group_leader users 
//  within the last 24 hours and sends a summary to Google Chat.
//  © Jonathan Keefe | keefecodes.com
// --------------------------------------------------------------------

// Display errors for debugging (optional)
ini_set('display_errors', 1);
error_reporting(E_ALL);

// --------------------------------------------------------------------
// STEP 0: Load Configuration
// --------------------------------------------------------------------
$configFile = __DIR__ . '/../config/wp-deployment.conf';

if (!file_exists($configFile)) {
    fwrite(STDERR, "❌ Config file not found: {$configFile}\n");
    exit(1);
}

// Parse INI-style config into PHP array
$config = parse_ini_file($configFile);
if (!$config) {
    fwrite(STDERR, "❌ Failed to parse config file.\n");
    exit(1);
}

// Optional Google Chat webhook (leave blank to disable)
$webhookUrl = $config['GOOGLE_CHAT_WEBHOOK'] ?? null;
if (!$webhookUrl) {
    echo "⚠️ No webhook defined (GOOGLE_CHAT_WEBHOOK missing in config). Notifications disabled.\n";
}

// --------------------------------------------------------------------
// STEP 1: General Setup
// --------------------------------------------------------------------
$sinceDate = date('Y-m-d H:i:s', strtotime('-24 hours'));
$timestampLabel = date('Y-m-d_H-i-s');

$logDir = __DIR__ . '/../logs/';
if (!is_dir($logDir)) mkdir($logDir, 0755, true);

echo "📅 Tracking changes since: {$sinceDate}\n";

// Roles to monitor (adjust if needed)
$allowedRoles = ['administrator', 'editor', 'group_leader', '0'];

// --------------------------------------------------------------------
// STEP 2: Databases to Track
// --------------------------------------------------------------------
$databases = [
    [
        'label'  => 'live',
        'host'   => $config['LIVE_DB_HOST'] ?? 'localhost',
        'db'     => $config['LIVE_DB_NAME'] ?? '',
        'user'   => $config['LIVE_DB_USER'] ?? '',
        'pass'   => $config['LIVE_DB_PASS'] ?? '',
        'prefix' => $config['LIVE_DB_PREFIX'] ?? 'wp_',
    ],
    [
        'label'  => 'dev',
        'host'   => $config['DEV_DB_HOST'] ?? 'localhost',
        'db'     => $config['DEV_DB_NAME'] ?? '',
        'user'   => $config['DEV_DB_USER'] ?? '',
        'pass'   => $config['DEV_DB_PASS'] ?? '',
        'prefix' => $config['DEV_DB_PREFIX'] ?? 'wp_',
    ],
];

// --------------------------------------------------------------------
// STEP 3: Process Each Database
// --------------------------------------------------------------------
foreach ($databases as $db) {
    echo "\n🔍 Connecting to {$db['label']} database...\n";

    $mysqli = @new mysqli($db['host'], $db['user'], $db['pass'], $db['db']);
    if ($mysqli->connect_error) {
        echo "❌ Connection failed: {$mysqli->connect_error}\n";
        continue;
    }

    $prefix = $db['prefix'];
    $label  = $db['label'];

    // ----------------------------------------------------------------
    // STEP 3A: Get Users with Allowed Roles
    // ----------------------------------------------------------------
    $roleQuery = $mysqli->query("SELECT user_id, meta_value FROM {$prefix}usermeta WHERE meta_key LIKE '%_capabilities'");
    if (!$roleQuery) {
        echo "⚠️ Could not query usermeta table for {$label}.\n";
        $mysqli->close();
        continue;
    }

    $validUsers = [];
    while ($row = $roleQuery->fetch_assoc()) {
        $roles = maybe_unserialize($row['meta_value']);
        if (is_array($roles)) {
            foreach ($roles as $role => $hasRole) {
                if (in_array($role, $allowedRoles, true)) {
                    $validUsers[] = (int)$row['user_id'];
                    break;
                }
            }
        }
    }

    if (empty($validUsers)) {
        echo "⚠️ No matching users in {$label}, skipping...\n";
        $mysqli->close();
        continue;
    }

    $userList = implode(',', $validUsers);
    echo "✅ Tracking users in {$label}: [{$userList}]\n";

    // ----------------------------------------------------------------
    // STEP 3B: Retrieve Stream Entries
    // ----------------------------------------------------------------
    $streamTable = "{$prefix}stream";
    $query = "
        SELECT created, user_id, summary, action, context
        FROM {$streamTable}
        WHERE user_id IN ({$userList})
        AND created >= '{$sinceDate}'
        ORDER BY created ASC
    ";

    $result = $mysqli->query($query);
    if (!$result || $result->num_rows === 0) {
        echo "⚠️ No changes found in {$label} since {$sinceDate}\n";
        $mysqli->close();
        continue;
    }

    // ----------------------------------------------------------------
    // STEP 3C: Log Results
    // ----------------------------------------------------------------
    $logFileCsv  = "{$logDir}stream-changes-{$label}-{$timestampLabel}.csv";
    $logFileJson = str_replace('.csv', '.json', $logFileCsv);

    $fp = fopen($logFileCsv, 'w');
    fputcsv($fp, ['created', 'user_id', 'summary', 'action', 'context']);

    $jsonData = [];
    while ($row = $result->fetch_assoc()) {
        fputcsv($fp, [$row['created'], $row['user_id'], $row['summary'], $row['action'], $row['context']]);
        $jsonData[] = $row;
    }

    fclose($fp);
    file_put_contents($logFileJson, json_encode($jsonData, JSON_PRETTY_PRINT));

    echo "✅ {$result->num_rows} log(s) saved → {$logFileCsv}\n";

    // ----------------------------------------------------------------
    // STEP 3D: Send Alert to Google Chat
    // ----------------------------------------------------------------
    if ($webhookUrl) {
        sendGoogleChatAlert($webhookUrl, $label, $result->num_rows, basename($logFileCsv));
    }

    $mysqli->close();
}

// --------------------------------------------------------------------
// STEP 4: Final Summary
// --------------------------------------------------------------------
echo "\n✅ Change tracking completed successfully.\n";
echo "🕒 Completed at: " . date('Y-m-d H:i:s') . "\n";
exit(0);

// --------------------------------------------------------------------
// Helper Functions
// --------------------------------------------------------------------
function maybe_unserialize($data) {
    if (!is_string($data)) return $data;
    if (is_serialized($data)) return @unserialize($data);
    return $data;
}

function is_serialized($data) {
    return @unserialize($data) !== false || $data === 'b:0;';
}

function sendGoogleChatAlert($webhookUrl, $label, $count, $logFile) {
    $payload = [
        'text' => "📣 *{$label}* WordPress changes detected:\n"
                . "• Entries: *{$count}*\n"
                . "• Log file: `{$logFile}`\n"
                . "• Time: " . date('Y-m-d H:i'),
    ];

    $ch = curl_init($webhookUrl);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_RETURNTRANSFER => true,
    ]);
    curl_exec($ch);
    curl_close($ch);
}