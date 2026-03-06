<#
.SYNOPSIS
    WeFlow API Export Script - Export WeChat chat history via HTTP API

.DESCRIPTION
    This script exports WeChat chat history using WeFlow's HTTP API.
    It can search for sessions by keyword and export messages in ChatLab format.
    Each export creates a unique timestamped directory for output files.

.PARAMETER Action
    Action to perform: health, sessions, contacts, export (default: export)

.PARAMETER Keyword
    Search keyword for session/contact search

.PARAMETER Talker
    Direct talker ID (skip search if provided)

.PARAMETER Limit
    Number of messages to export (default: 100, max: 10000)

.PARAMETER Offset
    Pagination offset (default: 0)

.PARAMETER StartDate
    Start date filter (format: YYYYMMDD)

.PARAMETER EndDate
    End date filter (format: YYYYMMDD)

.PARAMETER MessageKeyword
    Keyword filter for messages

.PARAMETER OutputDir
    Base output directory - a timestamped subdirectory will be created (default: current directory)

.PARAMETER OutputFile
    Output filename (default: chat_export.json)

.PARAMETER ChatLab
    Export in ChatLab format

.PARAMETER Media
    Export media files

.PARAMETER Image
    Export images (requires -Media)

.PARAMETER Voice
    Export voice messages (requires -Media)

.PARAMETER Video
    Export videos (requires -Media)

.PARAMETER Emoji
    Export emojis (requires -Media)

.EXAMPLE
    .\weflow-export.ps1 -Action health
    Check API health status

.EXAMPLE
    .\weflow-export.ps1 -Action sessions -Keyword "工作群"
    Search sessions containing "工作群"

.EXAMPLE
    .\weflow-export.ps1 -Keyword "岛城股市交流群" -Limit 50 -ChatLab
    Export 50 messages - creates weflow_export_YYYYMMDD_HHmmss/chat_export.json

.EXAMPLE
    .\weflow-export.ps1 -Talker "wxid_xxx" -Limit 100 -ChatLab -Media -Image -Voice
    Export messages with images and voice files

.EXAMPLE
    .\weflow-export.ps1 -Talker "wxid_xxx" -StartDate 20260101 -EndDate 20260205 -Limit 1000 -OutputDir "D:\exports"
    Export messages within date range to D:\exports\weflow_export_YYYYMMDD_HHmmss\
#>

param(
    [ValidateSet("health", "sessions", "contacts", "export")]
    [string]$Action = "export",
    
    [string]$Keyword = "",
    [string]$Talker = "",
    [int]$Limit = 100,
    [int]$Offset = 0,
    [string]$StartDate = "",
    [string]$EndDate = "",
    [string]$MessageKeyword = "",
    [string]$OutputDir = ".",
    [string]$OutputFile = "",
    [switch]$ChatLab,
    [switch]$Media,
    [switch]$Image,
    [switch]$Voice,
    [switch]$Video,
    [switch]$Emoji
)

$ErrorActionPreference = "Stop"
$BaseUrl = "http://127.0.0.1:5031"

function New-ExportDirectory {
    param([string]$BaseDir)
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $exportDirName = "weflow_export_$timestamp"
    $fullPath = Join-Path $BaseDir $exportDirName
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
    return $fullPath
}

function Write-JsonOutput {
    param($Data, $FilePath)
    if ($FilePath) {
        $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $FilePath -Encoding utf8
        Write-Host "Output saved to: $FilePath"
    } else {
        $Data | ConvertTo-Json -Depth 10
    }
}

function Invoke-ApiRequest {
    param([string]$Uri)
    try {
        return Invoke-RestMethod -Uri $Uri
    } catch {
        Write-Error "API request failed: $_"
        exit 1
    }
}

switch ($Action) {
    "health" {
        $result = Invoke-ApiRequest "$BaseUrl/health"
        if ($result.status -eq "ok") {
            Write-Host "API is healthy"
        } else {
            Write-Error "API health check failed"
            exit 1
        }
    }
    
    "sessions" {
        $uri = "$BaseUrl/api/v1/sessions?limit=$Limit"
        if ($Keyword) {
            $encodedKeyword = [uri]::EscapeDataString($Keyword)
            $uri = "$BaseUrl/api/v1/sessions?keyword=$encodedKeyword&limit=$Limit"
        }
        $result = Invoke-ApiRequest $uri
        Write-Host "Found $($result.count) sessions"
        if ($OutputFile) {
            Write-JsonOutput $result $OutputFile
        } else {
            Write-JsonOutput $result
        }
    }
    
    "contacts" {
        $uri = "$BaseUrl/api/v1/contacts?limit=$Limit"
        if ($Keyword) {
            $encodedKeyword = [uri]::EscapeDataString($Keyword)
            $uri = "$BaseUrl/api/v1/contacts?keyword=$encodedKeyword&limit=$Limit"
        }
        $result = Invoke-ApiRequest $uri
        Write-Host "Found $($result.count) contacts"
        if ($OutputFile) {
            Write-JsonOutput $result $OutputFile
        } else {
            Write-JsonOutput $result
        }
    }
    
    "export" {
        $health = Invoke-ApiRequest "$BaseUrl/health"
        if ($health.status -ne "ok") {
            Write-Error "API health check failed"
            exit 1
        }
        
        if (-not $Talker -and $Keyword) {
            $encodedKeyword = [uri]::EscapeDataString($Keyword)
            $searchUri = "$BaseUrl/api/v1/sessions?keyword=$encodedKeyword&limit=10"
            $sessions = Invoke-ApiRequest $searchUri
            if ($sessions.count -eq 0) {
                Write-Error "No session found with keyword: $Keyword"
                exit 1
            }
            $Talker = $sessions.sessions[0].username
            $sessionName = $sessions.sessions[0].displayName
            Write-Host "Found session: $sessionName ($Talker)"
        }
        
        if (-not $Talker) {
            Write-Error "Talker ID is required. Use -Talker or -Keyword to specify."
            exit 1
        }
        
        $encodedTalker = [uri]::EscapeDataString($Talker)
        $uri = "$BaseUrl/api/v1/messages?talker=$encodedTalker&limit=$Limit&offset=$Offset"
        
        if ($ChatLab) { $uri += "&chatlab=1" }
        if ($Media) { $uri += "&media=1" }
        if ($Image) { $uri += "&image=1" }
        if ($Voice) { $uri += "&voice=1" }
        if ($Video) { $uri += "&video=1" }
        if ($Emoji) { $uri += "&emoji=1" }
        if ($StartDate) { $uri += "&start=$StartDate" }
        if ($EndDate) { $uri += "&end=$EndDate" }
        if ($MessageKeyword) {
            $encodedMsgKeyword = [uri]::EscapeDataString($MessageKeyword)
            $uri += "&keyword=$encodedMsgKeyword"
        }
        
        $result = Invoke-ApiRequest $uri
        
        $exportDir = New-ExportDirectory $OutputDir
        Write-Host "Export directory: $exportDir"
        
        if (-not $OutputFile) {
            $OutputFile = "chat_export.json"
        }
        
        $OutputFile = Join-Path $exportDir $OutputFile
        
        Write-JsonOutput $result $OutputFile
        
        $msgCount = $result.messages.Count
        Write-Host "Export completed!"
        Write-Host "  - Messages: $msgCount"
        Write-Host "  - Output: $OutputFile"
        
        if ($result.media) {
            Write-Host "  - Media path: $($result.media.exportPath)"
            Write-Host "  - Media count: $($result.media.count)"
        }
    }
}
