---
name: "wechat-daily-report"
description: "Generate WeChat group daily report image. Invoke when user wants to create a daily report from WeChat chat history. Automatically guides through export and report generation."
---

# WeChat Daily Report Generator

This skill combines WeFlow API export and daily report generation to create beautiful WeChat group daily report images.

## Workflow

```
Step 0: Create output directory for this report
   ↓
Step 1: Export chat history via WeFlow API
   ↓
Step 2: Analyze chat records
   ↓
Step 3: AI generates content based on chat analysis
   ↓
Step 4: Generate daily report image
```

---

## Prerequisites

1. **WeFlow Application**: Must be installed and running
2. **API Service**: Must be enabled in WeFlow Settings → API Service → Start Service
3. **Default Port**: `5031`
4. **Python Environment**: With playwright installed (`pip install playwright && playwright install chromium`)

---

## Important: Path Variables

This skill uses the following path variables. **AI Agent should replace these with actual paths before executing commands:**

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `<PROJECT_ROOT>` | Root directory of the project | `D:\code\opensource\WeFlow` |
| `<OUTPUT_DIR>` | Output directory for this report session | `<PROJECT_ROOT>\.trae\skills\wechat-daily-report\outputs\report_20260306_191500` |
| `<WEFLOW_EXPORT_SCRIPT>` | Path to WeFlow export script | `<PROJECT_ROOT>\.trae\skills\weflow-api-export\scripts\weflow-export.ps1` |
| `<ANALYZE_SCRIPT>` | Path to chat analysis script | `<PROJECT_ROOT>\.trae\skills\wechat-daily-report-skill\scripts\analyze_chat.py` |
| `<GENERATE_SCRIPT>` | Path to report generation script | `<PROJECT_ROOT>\.trae\skills\wechat-daily-report-skill\scripts\generate_report.py` |
| `<AI_PROMPT_FILE>` | Path to AI prompt reference | `<PROJECT_ROOT>\.trae\skills\wechat-daily-report-skill\references\ai_prompt.md` |
| `<GROUP_NAME>` | Target WeChat group name | `技术交流群` |

---

## Step-by-Step Guide

### Step 0: Create Output Directory

**IMPORTANT**: Create a unique directory for each report session to organize all generated files.

```powershell
# Generate timestamp-based directory name
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "<PROJECT_ROOT>\.trae\skills\wechat-daily-report\outputs\report_$timestamp"
New-Item -ItemType Directory -Path $outputDir -Force
```

All subsequent files will be saved to this `<OUTPUT_DIR>`.

---

### Step 1: Export Chat History

First, use the WeFlow API to export chat history.

**Check API Health:**
```powershell
powershell -ExecutionPolicy Bypass -File "<WEFLOW_EXPORT_SCRIPT>" -Action health
```

**Search for Target Session:**
```powershell
powershell -ExecutionPolicy Bypass -File "<WEFLOW_EXPORT_SCRIPT>" -Action sessions -Keyword "<GROUP_NAME>"
```

**Export Chat History (ChatLab format required):**
```powershell
powershell -ExecutionPolicy Bypass -File "<WEFLOW_EXPORT_SCRIPT>" -Keyword "<GROUP_NAME>" -Limit 500 -ChatLab -OutputDir "<OUTPUT_DIR>"
```

> The `-ChatLab` flag is required to export in the correct JSON format for analysis.
>
> The exported file will be saved as `<OUTPUT_DIR>\chat_export_<timestamp>.json`

---

### Step 2: Analyze Chat Records

Run the analysis script on the exported JSON file:

```bash
python "<ANALYZE_SCRIPT>" "<OUTPUT_DIR>\chat_export_<timestamp>.json" --output-stats "<OUTPUT_DIR>\stats.json" --output-text "<OUTPUT_DIR>\simplified_chat.txt"
```

**Outputs:**
- `<OUTPUT_DIR>\stats.json` - Statistics (top talkers, night owls, word cloud, etc.)
- `<OUTPUT_DIR>\simplified_chat.txt` - Compressed chat text for AI analysis

---

### Step 3: AI Generate Content

Based on `simplified_chat.txt` and `stats.json`, generate AI content following the format in the AI prompt reference file.

Read the prompt template:
```
<AI_PROMPT_FILE>
```

Save the generated content as `<OUTPUT_DIR>\ai_content.json` with the following structure:

```json
{
  "topics": [...],
  "resources": [...],
  "important_messages": [...],
  "dialogues": [...],
  "qas": [...],
  "talker_profiles": [...]
}
```

---

### Step 4: Generate Report Image

Generate the final PNG report:

```bash
python "<GENERATE_SCRIPT>" --stats "<OUTPUT_DIR>\stats.json" --ai-content "<OUTPUT_DIR>\ai_content.json" --output "<OUTPUT_DIR>\report.png" --clean-temp
```

> Output resolution: iPhone 14 Pro Max (430x932 @3x)
>
> Using `--clean-temp` will remove intermediate files (stats.json, ai_content.json, simplified_chat.txt, temp HTML) after generation.

---

## Output Directory Structure

After completing all steps, the output directory will contain:

```
<OUTPUT_DIR>/
├── chat_export_<timestamp>.json    # Raw exported chat history
├── stats.json                       # Chat statistics (if --clean-temp not used)
├── simplified_chat.txt              # Compressed chat text (if --clean-temp not used)
├── ai_content.json                  # AI generated content (if --clean-temp not used)
└── report.png                       # Final report image ✅
```

---

## Quick Reference (with example paths)

| Step | Command |
|------|---------|
| Create Dir | `$ts=Get-Date -Format "yyyyMMdd_HHmmss"; $dir="<PROJECT_ROOT>\.trae\skills\wechat-daily-report\outputs\report_$ts"; New-Item -ItemType Directory -Path $dir -Force` |
| Health Check | `powershell -ExecutionPolicy Bypass -File "<WEFLOW_EXPORT_SCRIPT>" -Action health` |
| Search Sessions | `powershell -ExecutionPolicy Bypass -File "<WEFLOW_EXPORT_SCRIPT>" -Action sessions -Keyword "<GROUP_NAME>"` |
| Export Chat | `powershell -ExecutionPolicy Bypass -File "<WEFLOW_EXPORT_SCRIPT>" -Keyword "<GROUP_NAME>" -Limit 500 -ChatLab -OutputDir "<OUTPUT_DIR>"` |
| Analyze | `python "<ANALYZE_SCRIPT>" "<OUTPUT_DIR>\chat_export.json" --output-stats "<OUTPUT_DIR>\stats.json" --output-text "<OUTPUT_DIR>\simplified_chat.txt"` |
| Generate | `python "<GENERATE_SCRIPT>" --stats "<OUTPUT_DIR>\stats.json" --ai-content "<OUTPUT_DIR>\ai_content.json" --output "<OUTPUT_DIR>\report.png" --clean-temp` |

---

## Notes

- Ensure WeFlow API is running before export
- Use `-ChatLab` flag for correct JSON format
- Each report session gets its own timestamped directory
- Large chat exports may take time
- The final output is a PNG image optimized for mobile viewing

---

## Troubleshooting

### Image appears empty or too small

If the generated PNG is very small (e.g., < 100KB), it may indicate:
1. **Missing AI content** - Ensure `ai_content.json` is properly generated with all required fields
2. **Template rendering issue** - Check the HTML file first before converting to image

**Recommended workflow:**
```bash
# Step 1: Generate WITHOUT --clean-temp first
python "<GENERATE_SCRIPT>" --stats "<OUTPUT_DIR>\stats.json" --ai-content "<OUTPUT_DIR>\ai_content.json" --output "<OUTPUT_DIR>\report.png"

# Step 2: Verify the HTML and PNG are correct
# Open report.html in browser to check content

# Step 3: If everything looks good, manually clean up temp files
# Or re-run with --clean-temp
```

### Common issues

| Issue | Solution |
|-------|----------|
| API connection failed | Ensure WeFlow API service is running on port 5031 |
| Playwright not found | Run `pip install playwright && playwright install chromium` |
| Empty image content | Check ai_content.json has all required fields (topics, resources, dialogues, qas, talker_profiles) |
| Image too small | Generate without `--clean-temp` first, verify HTML content |

---

## Best Practices

1. **Don't use `--clean-temp` initially** - Keep intermediate files for debugging until you confirm the output is correct
2. **Check HTML first** - Open `report.html` in browser to verify content before checking PNG
3. **Validate AI content** - Ensure `ai_content.json` has all required sections with proper structure
4. **Expected image size** - A complete report PNG should be 1-5MB depending on content
