# API Reference

## ConvertTo-Subtitle

### Synopsis
Converts video files to subtitle files using Whisper AI

### Description
This function processes video files and generates subtitles using OpenAI's Whisper.
Supports multiple languages, models, and output formats with advanced optimization.

### Parameters
- **-InputPath <Object>**
  The video file(s) or directory containing video files to process.

- **-Language <String>**
  The language of the subtitle content (default: 'nl').
  Valid values: 'en', 'nl', 'af', 'am', 'ar', 'as', 'az', 'ba', 'be', 'bg', 'bn', 'bo', 'br', 'bs', 'ca', 'cs', 'cy', 'da', 'de', 'el', 'es', 'et', 'eu', 'fa', 'fi', 'fo', 'fr', 'gl', 'gu', 'ha', 'haw', 'he', 'hi', 'hr', 'ht', 'hu', 'hy', 'id', 'is', 'it', 'ja', 'jw', 'ka', 'kk', 'km', 'kn', 'ko', 'la', 'lb', 'ln', 'lo', 'lt', 'lv', 'mg', 'mi', 'mk', 'ml', 'mn', 'mr', 'ms', 'mt', 'my', 'ne', 'nn', 'no', 'oc', 'pa', 'pl', 'ps', 'pt', 'ro', 'ru', 'sa', 'sd', 'si', 'sk', 'sl', 'sn', 'so', 'sq', 'sr', 'su', 'sv', 'sw', 'ta', 'te', 'tg', 'th', 'tk', 'tl', 'tr', 'tt', 'uk', 'ur', 'uz', 'vi', 'yi', 'yo', 'yue', 'zh', 'auto'.

- **-Model <String>**
  The Whisper model to use for transcription (default: 'turbo').
  Valid values: 'tiny', 'tiny.en', 'base', 'base.en', 'small', 'small.en', 'medium', 'medium.en', 'large', 'turbo'.

- **-Format <String>**
  The output subtitle format (default: 'srt').
  Valid values: 'txt', 'vtt', 'srt', 'json'.

- **-WhisperImplementation <String>**
  Specify which Whisper implementation to use: 'Modern' (default) or 'Legacy'.

- **-Translate [<SwitchParameter>]**
  Translate the subtitles to English.

- **-Threads <Int32>**
  Number of processing threads to use.

- **-PassThru [<SwitchParameter>]**
  Return processed file information.

### Examples

#### EXAMPLE 1
```powershell
ConvertTo-Subtitle -InputPath "C:\Videos\movie.mp4" -Language "en" -Format "srt"
```
Generates English SRT subtitles for a single video file.

#### EXAMPLE 2
```powershell
Get-ChildItem "C:\Videos" -Filter "*.mp4" | ConvertTo-Subtitle -Language "nl" -Model "large"
```
Processes all MP4 files in a directory using the large model for Dutch subtitles.

## Get-WhisperModuleInfo

### Synopsis
Gets information about the WhisperSubtitle module configuration

### Description
Returns detailed information about the current module configuration,
supported formats, and system capabilities.

## Get-WhisperSubtitleConfig

### Synopsis
Gets the current configuration settings for the WhisperSubtitle module.

### Description
This cmdlet retrieves the current configuration settings that control the behavior
of the WhisperSubtitle module, such as base paths for Whisper models, temporary
file locations, and the path to the Subtitle Edit executable.

### Output
Returns a PSCustomObject containing the current configuration settings.

### Examples

#### EXAMPLE 1
```powershell
Get-WhisperSubtitleConfig
```
Retrieves and displays all current configuration settings.

## Set-WhisperSubtitleConfig

### Synopsis
Sets configuration settings for the WhisperSubtitle module.

### Description
This cmdlet allows you to modify the configuration settings for the WhisperSubtitle
module. Changes made with this cmdlet are persistent across PowerShell sessions.

### Parameters
- **-BaseLocation <String>**
  Specifies the base directory for Whisper models and temporary files.
  Defaults to `WhisperFiles` within the module directory.

- **-TempPath <String>**
  Specifies the directory for temporary audio and subtitle files.
  Defaults to a `temp` subdirectory within `BaseLocation`.

- **-SubtitleEditPath <String>**
  Specifies the full path to the `SubtitleEdit.exe` executable.
  This is optional, and if not set, subtitle optimization will be skipped.

### Examples

#### EXAMPLE 1
```powershell
Set-WhisperSubtitleConfig -BaseLocation "D:\WhisperData" -SubtitleEditPath "C:\Program Files\Custom Subtitle Edit\SubtitleEdit.exe"
```
Sets a custom base location for Whisper data and a specific path for Subtitle Edit.

#### EXAMPLE 2
```powershell
Set-WhisperSubtitleConfig -TempPath "C:\Temp\Whisper"
```
Changes only the temporary file path, leaving other settings as they are.
