---
name: "weflow-api-export"
description: "Export WeChat chat history via WeFlow HTTP API. Invoke when user needs to export WeChat messages, contacts, or sessions programmatically."
---

# WeFlow HTTP API Export Guide

This skill provides instructions for exporting WeChat chat history using WeFlow's HTTP API. WeFlow is a local WeChat chat viewer, analyzer, and exporter tool.

## Prerequisites

1. **WeFlow Application**: Must be installed and running
2. **API Service**: Must be enabled in Settings → API Service → Start Service
3. **Default Port**: `5031`
4. **Base URL**: `http://127.0.0.1:5031`

---

## Quick Start (PowerShell Script)

> **Recommended**: Use the provided PowerShell script for stable execution.

### Script Location

The PowerShell script is located at:
```
{SKILL_DIR}/scripts/weflow-export.ps1
```

> **Important**: Replace `{SKILL_DIR}` with the absolute path to this skill's directory. 
> 
> For AI Agents: The skill directory is the directory containing this SKILL.md file.

### Basic Usage

```powershell
# Check API health
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Action health

# Search sessions
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Action sessions -Keyword "群名"

# Export chat history (auto-creates timestamped output directory)
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Keyword "群名" -Limit 50 -ChatLab

# Export to specific base directory (will create subdirectory with timestamp)
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Keyword "群名" -Limit 100 -ChatLab -OutputDir "D:\exports"
```

---

## Script Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Action` | string | export | Action: health, sessions, contacts, export |
| `-Keyword` | string | - | Search keyword for session/contact |
| `-Talker` | string | - | Direct talker ID (skip search) |
| `-Limit` | int | 100 | Number of messages (1-10000) |
| `-Offset` | int | 0 | Pagination offset |
| `-StartDate` | string | - | Start date (YYYYMMDD) |
| `-EndDate` | string | - | End date (YYYYMMDD) |
| `-MessageKeyword` | string | - | Keyword filter for messages |
| `-OutputDir` | string | . | Base output directory (subdirectory with timestamp will be created) |
| `-OutputFile` | string | auto | Output filename (default: chat_export.json) |
| `-ChatLab` | switch | - | Export in ChatLab format |
| `-Media` | switch | - | Export media files |
| `-Image` | switch | - | Export images (requires -Media) |
| `-Voice` | switch | - | Export voice (requires -Media) |
| `-Video` | switch | - | Export video (requires -Media) |
| `-Emoji` | switch | - | Export emoji (requires -Media) |

> **Output Directory Behavior**: When exporting, the script automatically creates a unique subdirectory named `weflow_export_YYYYMMDD_HHmmss` under the specified `-OutputDir`. This ensures each export is isolated in its own folder.

---

## Common Use Cases

### 1. Check API Health

```powershell
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Action health
```

### 2. Search Sessions

```powershell
# Search by keyword
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Action sessions -Keyword "工作群"

# List all sessions
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Action sessions -Limit 50
```

### 3. Export Chat History

> **Note**: Each export creates a unique output directory with timestamp (format: `weflow_export_YYYYMMDD_HHmmss`).

```powershell
# Export by keyword search
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Keyword "xxx交流群" -Limit 50 -ChatLab

# Export by talker ID
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Talker "wxid_xxx" -Limit 100 -ChatLab

# Export with date range
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Talker "wxid_xxx" -StartDate 20260101 -EndDate 20260205 -Limit 1000 -ChatLab

# Export with media files
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Talker "wxid_xxx" -Limit 100 -ChatLab -Media -Image -Voice

# Filter messages by keyword
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Talker "wxid_xxx" -MessageKeyword "项目" -Limit 50 -ChatLab
```

### 4. Export Contacts

```powershell
# List all contacts
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Action contacts -Limit 100

# Search contacts
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Action contacts -Keyword "张三"
```

---

## Response Format

### ChatLab Format (Recommended)

```json
{
  "chatlab": {
    "version": "0.0.2",
    "exportedAt": 1738713600000,
    "generator": "WeFlow"
  },
  "meta": {
    "name": "Session Name",
    "platform": "wechat",
    "type": "group",
    "groupId": "xxx@chatroom"
  },
  "members": [...],
  "messages": [
    {
      "sender": "wxid_xxx",
      "accountName": "Username",
      "timestamp": 1738713600000,
      "type": 0,
      "content": "Message content"
    }
  ]
}
```

### Original Format

```json
{
  "success": true,
  "talker": "wxid_xxx",
  "count": 50,
  "hasMore": true,
  "messages": [...]
}
```

---

## ChatLab Message Types

| Type | Description |
|------|-------------|
| 0 | TEXT |
| 1 | IMAGE |
| 2 | VOICE |
| 3 | VIDEO |
| 4 | FILE |
| 5 | EMOJI |
| 7 | LINK |
| 8 | LOCATION |
| 20 | RED_PACKET |
| 21 | TRANSFER |
| 23 | CALL |
| 80 | SYSTEM |
| 81 | RECALL |
| 99 | OTHER |

---

## Media Export

Default media export path: `%USERPROFILE%\Documents\WeFlow\api-media`

When using `-Media` flag, media files are exported to this directory and paths are included in the response.

---

## Workflow for AI Agents

### Step 1: Determine Skill Directory

The skill directory is the absolute path containing this SKILL.md file. Use this path to construct the script path:
```
{SKILL_DIR}/scripts/weflow-export.ps1
```

### Step 2: Check API Status

```powershell
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Action health
```

Expected output: `API is healthy`

### Step 3: Find Target Session

```powershell
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Action sessions -Keyword "目标群名"
```

Extract `username` from response as the talker ID.

### Step 4: Export Messages

```powershell
powershell -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/weflow-export.ps1" -Talker "{username}" -Limit 100 -ChatLab
```

> **Output**: A unique directory will be created automatically (e.g., `weflow_export_20260306_143052/`) containing the exported JSON file.

### Step 5: Verify Output

Check the output file path printed in the console. The output structure will be:
```
{OutputDir}/weflow_export_YYYYMMDD_HHmmss/
├── chat_export.json
└── (media files if -Media was used)
```

---

## Important Notes

1. API only listens on `127.0.0.1` (localhost)
2. Database connection must be established first in WeFlow app
3. Date format: `YYYYMMDD` (e.g., 20260205)
4. WeFlow must be running in the background for API to work
5. Use `-ExecutionPolicy Bypass` when running PowerShell scripts
6. Output files use UTF-8 encoding to preserve Chinese characters

---

## API Reference (Direct HTTP Calls)

If you need to make direct HTTP calls, here are the endpoints:

### Health Check
```
GET http://127.0.0.1:5031/health
```

### Get Sessions
```
GET http://127.0.0.1:5031/api/v1/sessions?keyword=xxx&limit=100
```

### Get Contacts
```
GET http://127.0.0.1:5031/api/v1/contacts?keyword=xxx&limit=100
```

### Export Messages
```
GET http://127.0.0.1:5031/api/v1/messages?talker=xxx&limit=100&chatlab=1
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `talker` | string | ✅ | Session ID (wxid or group ID) |
| `limit` | number | ❌ | Number of messages (default: 100) |
| `offset` | number | ❌ | Pagination offset (default: 0) |
| `start` | string | ❌ | Start date (YYYYMMDD) |
| `end` | string | ❌ | End date (YYYYMMDD) |
| `keyword` | string | ❌ | Message keyword filter |
| `chatlab` | string | ❌ | Set to `1` for ChatLab format |
| `media` | string | ❌ | Set to `1` to export media |
| `image` | string | ❌ | Export images (1/0) |
| `voice` | string | ❌ | Export voice (1/0) |
| `video` | string | ❌ | Export video (1/0) |
| `emoji` | string | ❌ | Export emoji (1/0) |
