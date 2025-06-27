# Basic Usage Examples for WhisperSubtitle Module

#region Example 1: Basic Subtitle Generation
Write-Host "`n--- Example 1: Basic Subtitle Generation ---"
Write-Host "This example demonstrates generating English SRT subtitles for a single video file."

# Create a dummy video file for demonstration
$dummyVideoPath = Join-Path $PSScriptRoot "dummy_video.mp4"
Set-Content -Path $dummyVideoPath -Value "This is a dummy video file content."

Try {
    ConvertTo-Subtitle -InputPath $dummyVideoPath -Language "en" -Model "tiny" -Format "srt" -PassThru
    Write-Host "Successfully generated subtitles for $($dummyVideoPath)"
} Catch {
    Write-Warning "Failed to generate subtitles for $($dummyVideoPath): $($_.Exception.Message)"
} Finally {
    Remove-Item $dummyVideoPath -ErrorAction SilentlyContinue
    Remove-Item "$dummyVideoPath.en.srt" -ErrorAction SilentlyContinue
}
#endregion

#region Example 2: Batch Processing
Write-Host "`n--- Example 2: Batch Processing ---"
Write-Host "This example processes multiple video files in a directory."

# Create dummy video files for demonstration
$dummyDir = Join-Path $PSScriptRoot "BatchVideos"
New-Item -ItemType Directory -Path $dummyDir -Force | Out-Null

$dummyVideo1 = Join-Path $dummyDir "video1.mp4"
$dummyVideo2 = Join-Path $dummyDir "video2.mp4"
Set-Content -Path $dummyVideo1 -Value "Dummy content for video 1."
Set-Content -Path $dummyVideo2 -Value "Dummy content for video 2."

Try {
    Get-ChildItem -Path $dummyDir -Filter "*.mp4" | ConvertTo-Subtitle -Language "nl" -Model "base" -Format "vtt"
    Write-Host "Successfully processed videos in $($dummyDir)"
} Catch {
    Write-Warning "Failed to process videos in $($dummyDir): $($_.Exception.Message)"
} Finally {
    Remove-Item $dummyDir -Recurse -Force -ErrorAction SilentlyContinue
}
#endregion

#region Example 3: Translation to English
Write-Host "`n--- Example 3: Translation to English ---"
Write-Host "This example generates subtitles and translates them to English."

$dummyForeignVideoPath = Join-Path $PSScriptRoot "foreign_video.mp4"
Set-Content -Path $dummyForeignVideoPath -Value "This is a dummy foreign video content."

Try {
    ConvertTo-Subtitle -InputPath $dummyForeignVideoPath -Language "fr" -Model "small" -Format "srt" -Translate -PassThru
    Write-Host "Successfully generated and translated subtitles for $($dummyForeignVideoPath)"
} Catch {
    Write-Warning "Failed to generate and translate subtitles for $($dummyForeignVideoPath): $($_.Exception.Message)"
} Finally {
    Remove-Item $dummyForeignVideoPath -ErrorAction SilentlyContinue
    Remove-Item "$dummyForeignVideoPath.en.srt" -ErrorAction SilentlyContinue
}
#endregion

#region Example 4: Handling Errors (Unsupported File Type)
Write-Host "`n--- Example 4: Handling Errors (Unsupported File Type) ---"
Write-Host "This example demonstrates how the module handles unsupported file types."

$unsupportedFilePath = Join-Path $PSScriptRoot "document.txt"
Set-Content -Path $unsupportedFilePath -Value "This is a dummy text document."

Try {
    ConvertTo-Subtitle -InputPath $unsupportedFilePath -Language "en" -Format "srt"
} Catch {
    Write-Error "Caught expected error for unsupported file: $($_.Exception.Message)"
} Finally {
    Remove-Item $unsupportedFilePath -ErrorAction SilentlyContinue
}
#endregion

#region Example 5: Using Legacy Whisper Implementation
Write-Host "`n--- Example 5: Using Legacy Whisper Implementation ---"
Write-Host "This example forces the use of the legacy Whisper implementation."

$dummyLegacyVideoPath = Join-Path $PSScriptRoot "legacy_video.mp4"
Set-Content -Path $dummyLegacyVideoPath -Value "Dummy content for legacy whisper."

Try {
    ConvertTo-Subtitle -InputPath $dummyLegacyVideoPath -Language "en" -Model "large" -Format "srt" -WhisperImplementation "Legacy" -PassThru
    Write-Host "Successfully generated subtitles using Legacy Whisper for $($dummyLegacyVideoPath)"
} Catch {
    Write-Warning "Failed to generate subtitles using Legacy Whisper for $($dummyLegacyVideoPath): $($_.Exception.Message)"
} Finally {
    Remove-Item $dummyLegacyVideoPath -ErrorAction SilentlyContinue
    Remove-Item "$dummyLegacyVideoPath.en.srt" -ErrorAction SilentlyContinue
}
#endregion
