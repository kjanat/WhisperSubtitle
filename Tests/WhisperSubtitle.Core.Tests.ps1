Describe "ConvertTo-Subtitle" {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot) '..'
        Import-Module (Join-Path $modulePath 'WhisperSubtitle.psm1') -Force

        # Mock external commands
        Mock 'ffmpeg' { param($args) Write-Output "ffmpeg mock output" } -ModuleName WhisperSubtitle
        Mock 'ffprobe' { param($args) Write-Output '{ "format": { "duration": "10.0", "size": "1000", "bit_rate": "100" }, "streams": [ { "codec_type": "audio" } ] }' } -ModuleName WhisperSubtitle
        Mock 'whisper' { param($args) Write-Output "whisper mock output" } -ModuleName WhisperSubtitle
        Mock 'main.exe' { param($args) Write-Output "main.exe mock output" } -ModuleName WhisperSubtitle
        Mock 'Test-ModulePrerequisites' {} -ModuleName WhisperSubtitle
        Mock 'Get-FileHash' { param($LiteralPath, $Algorithm) return [PSCustomObject]@{Hash = "mockhash"} } -ModuleName WhisperSubtitle
        Mock 'Move-Item' {} -ModuleName WhisperSubtitle
        Mock 'Remove-Item' {} -ModuleName WhisperSubtitle
        Mock 'Test-Path' { param($Path) return $true } -ModuleName WhisperSubtitle
        Mock 'Start-Process' { param($FilePath, $ArgumentList, $NoNewWindow, $PassThru, $Wait, $RedirectStandardOutput) return [PSCustomObject]@{ExitCode = 0} } -ModuleName WhisperSubtitle
    }

    AfterAll {
        # Clean up mocks
        Remove-Mock -ModuleName WhisperSubtitle
    }

    It "should process a single video file successfully" {
        $testFile = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "testvideo.mp4" -ItemType File -Force
        $result = ConvertTo-Subtitle -InputPath $testFile.FullName -Language "en" -Model "tiny" -Format "srt" -PassThru
        $result | Should Not BeNullOrEmpty()
        $result.Success | Should Be $true
        Remove-Item $testFile -Force
    }

    It "should process a single video file and output processed files at the end when PassThru is false" {
        $testFile = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "testvideo_no_passthru.mp4" -ItemType File -Force
        $result = ConvertTo-Subtitle -InputPath $testFile.FullName -Language "en" -Model "tiny" -Format "srt"
        $result | Should Not BeNullOrEmpty()
        $result.Count | Should Be 1 # Expecting a list of processed files
        $result[0].Success | Should Be $true
        Remove-Item $testFile -Force
    }

    It "should throw an error for unsupported file extensions" {
        Mock 'Get-InputFiles' { param($InputPath) throw "Unsupported file extension: .txt" } -ModuleName WhisperSubtitle -Verifiable
        {
            ConvertTo-Subtitle -InputPath "C:\test.txt" -Language "en" -Model "tiny" -Format "srt"
        } | Should Throw -ExceptionType 'System.Exception' -Message "Unsupported file extension: .txt"
        Assert-MockCalled Get-InputFiles -Times 1 -ParameterFilter @{ InputPath = "C:\test.txt" }
    }

    It "should handle New-AudioFromVideo failure gracefully" {
        $testFile = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "testvideo_audio_fail.mp4" -ItemType File -Force
        Mock 'New-AudioFromVideo' { param($VideoFile, $OutputPath) throw "Audio conversion failed: FFmpeg error" } -ModuleName WhisperSubtitle -Verifiable

        $result = ConvertTo-Subtitle -InputPath $testFile.FullName -Language "en" -Model "tiny" -Format "srt" -PassThru

        $result | Should Not BeNullOrEmpty()
        $result.Success | Should Be $false
        $result.Error | Should Contain "Audio conversion failed: FFmpeg error"
        Assert-MockCalled New-AudioFromVideo -Times 1 -ParameterFilter @{ VideoFile = $testFile }
        Remove-Item $testFile -Force
    }

    It "should handle Invoke-WhisperTranscription failure gracefully" {
        $testFile = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "testvideo_whisper_fail.mp4" -ItemType File -Force
        Mock 'Invoke-WhisperTranscription' { param($AudioPath, $Language, $Model, $Format, $Threads, $Processors, $WhisperImplementation, $Translate) throw "Whisper transcription failed: Model not found" } -ModuleName WhisperSubtitle -Verifiable

        $result = ConvertTo-Subtitle -InputPath $testFile.FullName -Language "en" -Model "tiny" -Format "srt" -PassThru

        $result | Should Not BeNullOrEmpty()
        $result.Success | Should Be $false
        $result.Error | Should Contain "Whisper transcription failed: Model not found"
        Assert-MockCalled Invoke-WhisperTranscription -Times 1 -ParameterFilter @{ Language = "en"; Model = "tiny"; Format = "srt" }
        Remove-Item $testFile -Force
    }

    It "should handle Optimize-SubtitleFile failure gracefully" {
        $testFile = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "testvideo_optimize_fail.mp4" -ItemType File -Force
        Mock 'Optimize-SubtitleFile' { param($SubtitlePath, $Format) throw "Subtitle optimization failed: Subtitle Edit error" } -ModuleName WhisperSubtitle -Verifiable

        $result = ConvertTo-Subtitle -InputPath $testFile.FullName -Language "en" -Model "tiny" -Format "srt" -PassThru

        $result | Should Not BeNullOrEmpty()
        $result.Success | Should Be $false
        $result.Error | Should Contain "Subtitle optimization failed: Subtitle Edit error"
        Assert-MockCalled Optimize-SubtitleFile -Times 1 -ParameterFilter @{ Format = "srt" }
        Remove-Item $testFile -Force
    }
}

Describe "Get-VideoInformation" {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot) '..'
        Import-Module (Join-Path $modulePath 'WhisperSubtitle.psm1') -Force
    }

    It "should return correct video information" {
        $testFile = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "dummy.mp4" -ItemType File -Force
        Mock 'ffprobe' {
            param($args)
            Write-Output '{ "format": { "duration": "123.45", "size": "500000", "bit_rate": "128000" }, "streams": [ { "codec_type": "audio" }, { "codec_type": "video" } ] }'
        } -ModuleName WhisperSubtitle -Verifiable

        $videoInfo = Get-VideoInformation -File $testFile

        $videoInfo.Duration.TotalSeconds | Should Be 123.45
        $videoInfo.Size | Should Be 500000
        $videoInfo.Bitrate | Should Be 128000
        $videoInfo.HasAudio | Should Be $true

        Assert-MockCalled ffprobe -Times 1 -ParameterFilter @{ args = @('-v', 'quiet', '-print_format', 'json', '-show_format', '-show_streams', $testFile.FullName) }
        Remove-Item $testFile -Force
    }

    It "should handle ffprobe failure gracefully" {
        $testFile = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "dummy_fail.mp4" -ItemType File -Force
        Mock 'ffprobe' { param($args) throw "ffprobe failed" } -ModuleName WhisperSubtitle -Verifiable

        $videoInfo = Get-VideoInformation -File $testFile

        $videoInfo.Duration.TotalSeconds | Should Be 0
        $videoInfo.Size | Should Be $testFile.Length
        $videoInfo.Bitrate | Should Be 0
        $videoInfo.HasAudio | Should Be $true # Assumed true for processing

        Assert-MockCalled ffprobe -Times 1 -ParameterFilter @{ args = @('-v', 'quiet', '-print_format', 'json', '-show_format', '-show_streams', $testFile.FullName) }
        Remove-Item $testFile -Force
    }
}

Describe "New-AudioFromVideo" {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot) '..'
        Import-Module (Join-Path $modulePath 'WhisperSubtitle.psm1') -Force
    }

    It "should convert video to audio successfully" {
        $testVideoFile = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "video_to_audio.mp4" -ItemType File -Force
        $outputPath = Join-Path (Split-Path $PSScriptRoot) "temp_audio.wav"

        Mock 'Start-Process' {
            param($FilePath, $ArgumentList, $NoNewWindow, $PassThru, $Wait)
            return [PSCustomObject]@{ ExitCode = 0 }
        } -ModuleName WhisperSubtitle -Verifiable
        Mock 'Test-Path' { param($Path) return $true } -ModuleName WhisperSubtitle

        New-AudioFromVideo -VideoFile $testVideoFile -OutputPath $outputPath

        Assert-MockCalled Start-Process -Times 1 -ParameterFilter @{ FilePath = 'ffmpeg'; ArgumentList = @('-hwaccel', 'auto', '-y', '-nostdin', '-loglevel', 'error', '-i', $testVideoFile.FullName, '-ar', '16000', '-c:a', 'pcm_s16le', '-ac', '1', $outputPath) }
        Remove-Item $testVideoFile -Force
    }

    It "should throw an error if ffmpeg fails" {
        $testVideoFile = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "video_to_audio_fail.mp4" -ItemType File -Force
        $outputPath = Join-Path (Split-Path $PSScriptRoot) "temp_audio_fail.wav"

        Mock 'Start-Process' {
            param($FilePath, $ArgumentList, $NoNewWindow, $PassThru, $Wait)
            return [PSCustomObject]@{ ExitCode = 1 }
        } -ModuleName WhisperSubtitle -Verifiable

        {
            New-AudioFromVideo -VideoFile $testVideoFile -OutputPath $outputPath
        } | Should Throw -ExceptionType 'System.Management.Automation.RuntimeException' -Message "FFmpeg failed with exit code: 1"

        Assert-MockCalled Start-Process -Times 1 -ParameterFilter @{ FilePath = 'ffmpeg' }
        Remove-Item $testVideoFile -Force
    }

    It "should throw an error if audio file is not created" {
        $testVideoFile = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "video_to_audio_not_created.mp4" -ItemType File -Force
        $outputPath = Join-Path (Split-Path $PSScriptRoot) "temp_audio_not_created.wav"

        Mock 'Start-Process' {
            param($FilePath, $ArgumentList, $NoNewWindow, $PassThru, $Wait)
            return [PSCustomObject]@{ ExitCode = 0 }
        } -ModuleName WhisperSubtitle -Verifiable
        Mock 'Test-Path' { param($Path) return $false } -ModuleName WhisperSubtitle

        {
            New-AudioFromVideo -VideoFile $testVideoFile -OutputPath $outputPath
        } | Should Throw -ExceptionType 'System.Management.Automation.RuntimeException' -Message "Audio file was not created: $outputPath"

        Assert-MockCalled Start-Process -Times 1 -ParameterFilter @{ FilePath = 'ffmpeg' }
        Remove-Item $testVideoFile -Force
    }
}

Describe "Invoke-WhisperTranscription" {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot) '..'
        Import-Module (Join-Path $modulePath 'WhisperSubtitle.psm1') -Force
    }

    It "should call Invoke-LegacyWhisper when WhisperImplementation is Legacy" {
        Mock 'Invoke-LegacyWhisper' {} -ModuleName WhisperSubtitle -Verifiable
        Invoke-WhisperTranscription -AudioPath "audio.wav" -Language "en" -Model "tiny" -Format "srt" -Threads 1 -Processors 1 -WhisperImplementation "Legacy" -Translate:$false
        Assert-MockCalled Invoke-LegacyWhisper -Times 1 -ParameterFilter @{ AudioPath = "audio.wav"; Language = "en"; Model = "tiny"; Format = "srt"; Threads = 1; Processors = 1; Translate = $false }
    }

    It "should call Invoke-ModernWhisper when WhisperImplementation is Modern" {
        Mock 'Invoke-ModernWhisper' {} -ModuleName WhisperSubtitle -Verifiable
        Invoke-WhisperTranscription -AudioPath "audio.wav" -Language "en" -Model "tiny" -Format "srt" -Threads 1 -Processors 1 -WhisperImplementation "Modern" -Translate:$false
        Assert-MockCalled Invoke-ModernWhisper -Times 1 -ParameterFilter @{ AudioPath = "audio.wav"; Language = "en"; Model = "tiny"; Format = "srt"; Threads = 1; Processors = 1; Translate = $false }
    }
}

Describe "Invoke-LegacyWhisper" {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot) '..'
        Import-Module (Join-Path $modulePath 'WhisperSubtitle.psm1') -Force
        $script:ModuleConfig.BaseLocation = Join-Path $PSScriptRoot "TestData" # Set a mock base location
    }

    It "should execute legacy Whisper successfully" {
        Mock 'Start-Process' {
            param($FilePath, $ArgumentList, $NoNewWindow, $PassThru, $Wait)
            return [PSCustomObject]@{ ExitCode = 0 }
        } -ModuleName WhisperSubtitle -Verifiable
        Mock 'Test-Path' { param($Path) return $true } -ModuleName WhisperSubtitle # Mock main.exe exists

        Invoke-LegacyWhisper -AudioPath "audio.wav" -Language "en" -Model "large" -Format "srt" -Threads 1 -Processors 1 -Translate:$false

        Assert-MockCalled Start-Process -Times 1 -ParameterFilter @{ FilePath = (Join-Path $PSScriptRoot "TestData" "main.exe"); ArgumentList = @("--output-srt", "--model", (Join-Path $PSScriptRoot "TestData" "models\large.bin"), "--diarize", "--processors", 1, "--threads", 1, "--file", "audio.wav") }
    }

    It "should throw an error if legacy Whisper executable not found" {
        Mock 'Test-Path' { param($Path) return $false } -ModuleName WhisperSubtitle # Mock main.exe does not exist

        {
            Invoke-LegacyWhisper -AudioPath "audio.wav" -Language "en" -Model "large" -Format "srt" -Threads 1 -Processors 1 -Translate:$false
        } | Should Throw -ExceptionType 'System.IO.FileNotFoundException' -Message "Legacy Whisper executable not found: "
    }

    It "should throw an error if legacy Whisper fails" {
        Mock 'Start-Process' {
            param($FilePath, $ArgumentList, $NoNewWindow, $PassThru, $Wait)
            return [PSCustomObject]@{ ExitCode = 1 }
        } -ModuleName WhisperSubtitle -Verifiable
        Mock 'Test-Path' { param($Path) return $true } -ModuleName WhisperSubtitle # Mock main.exe exists

        {
            Invoke-LegacyWhisper -AudioPath "audio.wav" -Language "en" -Model "large" -Format "srt" -Threads 1 -Processors 1 -Translate:$false
        } | Should Throw -ExceptionType 'System.Management.Automation.RuntimeException' -Message "Legacy Whisper failed with exit code: 1"
    }
}

Describe "Invoke-ModernWhisper" {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot) '..'
        Import-Module (Join-Path $modulePath 'WhisperSubtitle.psm1') -Force
        $script:ModuleConfig.TempPath = Join-Path $PSScriptRoot "TestData" # Set a mock temp path
    }

    It "should execute modern Whisper successfully" {
        Mock 'Start-Process' {
            param($FilePath, $ArgumentList, $NoNewWindow, $PassThru, $Wait)
            return [PSCustomObject]@{ ExitCode = 0 }
        } -ModuleName WhisperSubtitle -Verifiable

        Invoke-ModernWhisper -AudioPath "audio.wav" -Language "en" -Model "tiny" -Format "srt" -Threads 1 -Processors 1 -Translate:$false

        Assert-MockCalled Start-Process -Times 1 -ParameterFilter @{ FilePath = 'whisper'; ArgumentList = @('-output_format', 'srt', '-model', 'tiny', '-threads', 1, '-processors', 1, '-task', 'transcribe', '-output_dir', (Join-Path $PSScriptRoot "TestData"), 'audio.wav', '-language', 'en') }
    }

    It "should throw an error if modern Whisper fails" {
        Mock 'Start-Process' {
            param($FilePath, $ArgumentList, $NoNewWindow, $PassThru, $Wait)
            return [PSCustomObject]@{ ExitCode = 1 }
        } -ModuleName WhisperSubtitle -Verifiable

        {
            Invoke-ModernWhisper -AudioPath "audio.wav" -Language "en" -Model "tiny" -Format "srt" -Threads 1 -Processors 1 -Translate:$false
        } | Should Throw -ExceptionType 'System.Management.Automation.RuntimeException' -Message "Modern Whisper failed with exit code: 1"
    }
}

Describe "Optimize-SubtitleFile" {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot) '..'
        Import-Module (Join-Path $modulePath 'WhisperSubtitle.psm1') -Force
        $script:ModuleConfig.SubtitleEditPath = "C:\Program Files\Subtitle Edit\SubtitleEdit.exe" # Set a mock path
    }

    It "should optimize subtitle file successfully" {
        $testSubtitlePath = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "test.srt" -ItemType File -Force
        Mock 'Start-Process' {
            param($FilePath, $ArgumentList, $NoNewWindow, $PassThru, $Wait, $RedirectStandardOutput)
            return [PSCustomObject]@{ ExitCode = 0 }
        } -ModuleName WhisperSubtitle -Verifiable
        Mock 'Test-Path' { param($Path) return $true } -ModuleName WhisperSubtitle # Mock SubtitleEdit.exe exists

        Optimize-SubtitleFile -SubtitlePath $testSubtitlePath.FullName -Format "srt"

        Assert-MockCalled Start-Process -Times 1 -ParameterFilter @{ FilePath = $script:ModuleConfig.SubtitleEditPath; ArgumentList = @("/convert `"$($testSubtitlePath.FullName)`"", "SubRip", "/encoding:utf-8", "/overwrite", "/MergeSameTimeCodes", "/MergeSameTexts", "/MergeShortLines", "/BalanceLines") }
        Remove-Item $testSubtitlePath -Force
    }

    It "should skip optimization if Subtitle Edit is not found" {
        $testSubtitlePath = New-Item -Path (Join-Path $PSScriptRoot "TestData") -Name "test_no_se.srt" -ItemType File -Force
        Mock 'Test-Path' { param($Path) return $false } -ModuleName WhisperSubtitle # Mock SubtitleEdit.exe does not exist
        Mock 'Write-ModuleLog' {} -ModuleName WhisperSubtitle -Verifiable

        Optimize-SubtitleFile -SubtitlePath $testSubtitlePath.FullName -Format "srt"

        Assert-MockCalled Write-ModuleLog -Times 1 -ParameterFilter @{ Message = 'Subtitle Edit not found, skipping optimization'; Level = 'Warning' }
        Remove-Item $testSubtitlePath -Force
    }
}

Describe "Get-WhisperOptimalCpuSettings" {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot) '..'
        Import-Module (Join-Path $modulePath 'WhisperSubtitle.psm1') -Force
    }

    It "should return optimal CPU settings" {
        # Mock ProcessorCount for consistent testing
        [System.Environment]::ProcessorCount = 8
        $settings = Get-WhisperOptimalCpuSettings
        $settings.Threads | Should Be 8
        $settings.Processors | Should Be 1

        [System.Environment]::ProcessorCount = 16
        $settings = Get-WhisperOptimalCpuSettings
        $settings.Threads | Should Be 12
        $settings.Processors | Should Be 1

        [System.Environment]::ProcessorCount = 2
        $settings = Get-WhisperOptimalCpuSettings
        $settings.Threads | Should Be 2
        $settings.Processors | Should Be 1
    }
}