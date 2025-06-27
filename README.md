# WhisperSubtitle PowerShell Module

Professional subtitle generation using OpenAI Whisper.

## Quick Start

```powershell
Import-Module WhisperSubtitle
gci *.mp4 | ConvertTo-Subtitle -Language nl -Format srt
```

### Prerequisites

- [**FFmpeg**][FFmpeg Download]: Required for video processing.
- [**Whisper**][Whisper Setup]: OpenAI Whisper model for transcription.
- [**Python**][Python Downloads]: Required for running Whisper.
- [**Pytorch**][PyTorch Get Started]: Required for Whisper model execution.
- [**Subtitle Edit**][Subtitle Edit Latest Release] (optional): For advanced subtitle editing.
- [**CUDA**][CUDA Toolkit] (optional): For GPU acceleration.

## Directory Structure

```text
$env:USERNAME/Documents/PowerShell/Modules/WhisperSubtitle/
├── .git/                          # Git repository
├── .gitignore                     # Git ignore file
├── README.md                      # Project documentation
├── CHANGELOG.md                   # Version history
├── WhisperSubtitle.psd1           # Module manifest
├── WhisperSubtitle.psm1           # Main module file
├── Tests/                         # Pester tests (optional)
│   ├── WhisperSubtitle.Tests.ps1
│   └── TestData/
├── Examples/                      # Usage examples
│   └── Basic-Usage.ps1
├── Docs/                          # Additional documentation
│   ├── API-Reference.md
│   └── Configuration.md
└── Build/                         # Build scripts (optional)
    └── Build.ps1
```

## Setup Commands

### 1. Find PowerShell Module Path

```powershell
# Check where PowerShell looks for modules
$env:PSModulePath -split [System.IO.Path]::PathSeparator | Sort-Object -Unique

# Most common user module path
$UserModulePath = "$env:USERPROFILE\Documents\PowerShell\Modules"
```

### 2. Create Module Directory

```powershell
# Create the module directory
$ModulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\WhisperSubtitle"
New-Item -Path $ModulePath -ItemType Directory -Force

# Navigate to the directory
Set-Location $ModulePath
```

## Features

- Pipeline support
- Multiple output formats
- Batch processing
- Improved error handling and logging
- Enhanced progress reporting
- Automatic optimization

## Requirements

- PowerShell 7+
- FFmpeg
- Whisper
- Subtitle Edit (optional)

## Feature Matrix

| Feature / Dependency | FFmpeg | Whisper (Modern) | Whisper (Legacy) | Subtitle Edit | Python | PyTorch | CUDA (GPU) |
| :------------------- | :----: | :--------------: | :--------------: | :-----------: | :----: | :-----: | :--------: |
| **Video to Audio Extraction** | ✅ | ➖ | ➖ | ➖ | ➖ | ➖ | ➖ |
| **Transcription (Modern)** | ➖ | ✅ | ➖ | ➖ | ✅ | ✅ | ⚡ |
| **Transcription (Legacy)** | ➖ | ➖ | ✅ | ➖ | ➖ | ➖ | ➖ |
| **Subtitle Optimization** | ➖ | ➖ | ➖ | ✅ | ➖ | ➖ | ➖ |
| **Batch Processing** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚡ |
| **Translation** | ➖ | ✅ | ✅ | ➖ | ✅ | ✅ | ⚡ |

**Legend:**
- ✅: Required
- ⚡: Optional, for GPU acceleration
- ➖: Not directly required by this feature, but may be a prerequisite for other features or the Whisper implementation itself.

## Configuration

The module's behavior can be configured using the `Set-WhisperSubtitleConfig` cmdlet. This allows you to customize paths for external tools and temporary files.

### Get Current Configuration

```powershell
Get-WhisperSubtitleConfig
```

### Set Configuration

```powershell
Set-WhisperSubtitleConfig -BaseLocation "D:\WhisperData" -SubtitleEditPath "C:\Program Files\Custom Subtitle Edit\SubtitleEdit.exe"
```

**Available Parameters for `Set-WhisperSubtitleConfig`:**

- **`BaseLocation`**: Specifies the base directory for Whisper models and temporary files. Defaults to `WhisperFiles` within the module directory.
- **`TempPath`**: Specifies the directory for temporary audio and subtitle files. Defaults to a `temp` subdirectory within `BaseLocation`.
- **`SubtitleEditPath`**: Specifies the full path to the `SubtitleEdit.exe` executable. This is optional, and if not set, subtitle optimization will be skipped.

Changes made with `Set-WhisperSubtitleConfig` are persistent across PowerShell sessions.

## `ConvertTo-Subtitle` Parameters

- **`InputPath`**: The video file(s) or directory containing video files to process.
- **`Language`**: The language of the subtitle content (default: `'nl'`).
- **`Model`**: The Whisper model to use for transcription (default: `'turbo'`).
- **`Format`**: The output subtitle format (default: `'srt'`).

- **`Translate`**: Translate the subtitles to English.
- **`Threads`**: Number of processing threads to use.
- **`PassThru`**: Return processed file information.

## Installation Methods

### Method 1: Manual Installation (Recommended)

```powershell
# 1. Download/create the module files
# 2. Place in: $env:USERPROFILE\Documents\PowerShell\Modules\WhisperSubtitle\
# 3. Import-Module WhisperSubtitle
```

### Method 2: Install from Git

```powershell
# Clone to modules directory
Set-Location "$env:USERPROFILE\Documents\PowerShell\Modules"
git clone https://github.com/kjanat/WhisperSubtitle.git
Import-Module WhisperSubtitle
```

### Method 3: Symlink (Development)

```powershell
# If you want to develop in a different location
$DevPath = "C:\Dev\WhisperSubtitle"
$ModulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\WhisperSubtitle"

# Create symlink (requires admin rights)
New-Item -ItemType SymbolicLink -Path $ModulePath -Target $DevPath
```

## Verification

### Check Module Installation

```powershell
# List available modules
Get-Module -ListAvailable WhisperSubtitle

# Import and test
Import-Module WhisperSubtitle -Force
Get-Command -Module WhisperSubtitle

# Check module info
Get-WhisperModuleInfo
```

### Test Basic Functionality

```powershell
# Test with WhatIf
ConvertTo-Subtitle -InputPath "C:\test.mp4" -WhatIf

# Get help
Get-Help ConvertTo-Subtitle -Examples
```

## PowerShell Profile Integration

### Add to Profile (Optional)

```powershell
# Edit your PowerShell profile, look for the profile path
if (!(Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force
}; echo "PowerShell profile path: $PROFILE"

# Add this line to auto-import the module
Import-Module WhisperSubtitle

# Or with alias
Import-Module WhisperSubtitle
Set-Alias ws ConvertTo-Subtitle
```

## Development Workflow

### Local Development

```powershell
# Work in your development directory
Set-Location "C:\Dev\WhisperSubtitle"

# Test changes
Import-Module .\WhisperSubtitle.psm1 -Force

# Commit changes
git add .
git commit -m "Feature: Added new functionality"
git push origin main
```

### Version Management

```powershell
# Update version in manifest
$manifest = ".\WhisperSubtitle.psd1"
(Get-Content $manifest) -replace "ModuleVersion = '0.1.0'", "ModuleVersion = '2.1.0'" | Set-Content $manifest

# Tag release
git tag -a "v2.1.0" -m "Release version 2.1.0"
git push origin --tags
```

## Module Path Priority

PowerShell searches for modules in this order:

1. `$env:USERPROFILE\Documents\PowerShell\Modules` (User modules)
2. `$env:ProgramFiles\PowerShell\Modules` (System modules)
3. `$PSHOME\Modules` (Built-in modules)

Your module in the user directory will take priority!

[PyTorch Get Started]: https://pytorch.org/get-started/
[Python Downloads]: https://www.python.org/downloads/
[Whisper Setup]: https://github.com/openai/whisper?tab=readme-ov-file#setup
[FFmpeg Download]: https://ffmpeg.org/download.html
[Subtitle Edit Latest Release]: https://github.com/SubtitleEdit/subtitleedit/releases/latest
[CUDA Toolkit]: https://developer.nvidia.com/cuda-downloads
