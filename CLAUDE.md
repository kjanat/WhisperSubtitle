# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Overview

WhisperSubtitle is a professional PowerShell module for generating subtitles from video files using OpenAI's Whisper AI. The module provides pipeline support, batch processing, and multiple output formats with automatic optimization.

## Development Commands

### Module Testing

```powershell
# Import module for testing
Import-Module .\WhisperSubtitle.psm1 -Force

# Run Pester tests (if available)
Invoke-Pester .\Tests\WhisperSubtitle.Tests.ps1

# Test module functionality
Get-WhisperModuleInfo
ConvertTo-Subtitle -InputPath "test.mp4" -WhatIf
```

### Module Building

The Build.ps1 script is currently empty - development uses direct module import for testing.

### Module Installation

```powershell
# Install to user module path
$ModulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\WhisperSubtitle"
Copy-Item -Path . -Destination $ModulePath -Recurse -Force

# Import and verify
Import-Module WhisperSubtitle -Force
Get-Command -Module WhisperSubtitle
```

## Architecture

### Core Components

**WhisperSubtitle.psm1** - Main module file containing:

- `ConvertTo-Subtitle` - Primary function for video-to-subtitle conversion
- `Get-WhisperModuleInfo` - Module configuration and status information
- Helper functions for video processing, audio extraction, and Whisper transcription

**WhisperSubtitle.psd1** - Module manifest defining:

- Module metadata and dependencies
- Exported functions: `ConvertTo-Subtitle`, `Get-WhisperModuleInfo`
- Alias: `whisperSub` → `ConvertTo-Subtitle`

### Processing Pipeline

1. **Input Validation** - Supports files, directories, and pipeline input
2. **Audio Extraction** - Uses FFmpeg to extract 16kHz mono audio from video
3. **Transcription** - Supports both legacy (main.exe) and modern (whisper CLI) implementations
4. **Optimization** - Optional integration with Subtitle Edit for subtitle enhancement
5. **Output Generation** - Supports txt, vtt, srt, json, and lrc formats

### Configuration

**Base Location**: `A:\Whisper` - Contains Whisper executables and models
**Temp Path**: `A:\Whisper\temp` - Temporary files during processing
**Supported Extensions**: .aac, .avi, .flac, .m4a, .mka, .mkv, .mov, .mp2, .mp3, .mp4, .ogg, .wav, .wmv, .weba, .webm, .webma

### Dependencies

**Required**:

- FFmpeg (video/audio processing)
- Whisper (modern CLI or legacy main.exe)
- PowerShell 7+

**Optional**:

- Subtitle Edit (C:\Program Files\Subtitle Edit\SubtitleEdit.exe) - for subtitle optimization

## Key Functions

### ConvertTo-Subtitle

Primary processing function with parameters:

- `InputPath` - Video file(s) or directory (pipeline-supported)
- `Language` - Target language (default: 'nl', supports 'auto' and 80+ languages)
- `Model` - Whisper model size (tiny, base, small, medium, large, turbo)
- `Format` - Output format (txt, vtt, srt, json)
- `UseOldWhisper` - Switch to legacy implementation
- `Translate` - Translate to English
- `Threads` - Processing threads (auto-calculated based on CPU cores)

### Processing Flow

1. Prerequisites validation (Test-ModulePrerequisites)
2. File discovery and validation (Get-InputFiles)
3. Per-file processing (ConvertSingleFile):
   - Video info extraction (Get-VideoInformation)
   - Audio extraction (New-AudioFromVideo)
   - Whisper transcription (Invoke-WhisperTranscription)
   - Subtitle optimization (Optimize-SubtitleFile)
   - Cleanup and result generation

## Module Patterns

- **Error Handling**: Comprehensive try-catch blocks with structured logging
- **Logging**: Custom Write-ModuleLog function with levels (Info, Warning, Error, Debug, Verbose)
- **Progress Tracking**: Window title updates showing current file and duration
- **Pipeline Support**: Accepts input from Get-ChildItem and other cmdlets
- **Parameter Validation**: Extensive ValidateSet attributes for languages, models, and formats
- **Cleanup**: Automatic temporary file removal on success or failure
