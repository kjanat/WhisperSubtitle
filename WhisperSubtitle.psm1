#requires -Version 7

<#
.SYNOPSIS
    WhisperSubtitle PowerShell Module - Professional subtitle generation using Whisper AI
.DESCRIPTION
    This module provides advanced subtitle generation capabilities for video files using OpenAI's Whisper.
    Supports batch processing, multiple output formats, and both legacy and modern Whisper implementations.
.AUTHOR
    Enhanced WhisperSubtitle Module
.VERSION
    0.1.0
#>

using namespace System.IO
using namespace System.Collections.Generic

#region Module Configuration
# Load private configuration functions
. (Join-Path $PSScriptRoot 'Private\Get-ModuleConfig.ps1')
. (Join-Path $PSScriptRoot 'Private\Set-ModuleConfig.ps1')

# Load module configuration
$script:ModuleConfig = Get-ModuleConfig

# Set default values if not present in configuration
if (-not $script:ModuleConfig.BaseLocation) {
    $script:ModuleConfig.BaseLocation = Join-Path $PSScriptRoot 'WhisperFiles'
}
if (-not $script:ModuleConfig.TempPath) {
    $script:ModuleConfig.TempPath = Join-Path $script:ModuleConfig.BaseLocation 'temp'
}
if (-not $script:ModuleConfig.SubtitleEditPath) {
    $script:ModuleConfig.SubtitleEditPath = 'C:\Program Files\Subtitle Edit\SubtitleEdit.exe'
}
if (-not $script:ModuleConfig.LogicalProcessorCount) {
    $script:ModuleConfig.LogicalProcessorCount = [System.Environment]::ProcessorCount ?? 4
}
if (-not $script:ModuleConfig.SupportedExtensions) {
    $script:ModuleConfig.SupportedExtensions = @('.aac', '.avi', '.flac', '.m4a', '.mka', '.mkv', '.mov', '.mp2', '.mp3', '.mp4', '.ogg', '.wav', '.wmv', '.weba', '.webm', '.webma')
}
if (-not $script:ModuleConfig.SubtitleFormats) {
    $script:ModuleConfig.SubtitleFormats = @{
		'txt'  = 'Plaintext'
		'vtt'  = 'WebVTT'
		'srt'  = 'SubRip'
		'json' = 'JSON'
		'lrc'  = 'LRCLyrics'
	}
}
#endregion

#region Helper Functions

#region Helper Functions
function Write-ModuleLog {
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory)]
		[string]$Message,

		[ValidateSet('Info', 'Warning', 'Error', 'Debug', 'Verbose')]
		[string]$Level = 'Info',

		[string]$Category = 'General',

		[System.Exception]$Exception = $null
	)

	$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
	$logMessage = "[$timestamp] [$Level] [$Category] $Message"

	switch ($Level) {
		'Error' {
			if ($Exception) {
				Write-Error -Message $logMessage -Exception $Exception
			} else {
				Write-Error -Message $logMessage
			}
		}
		'Warning' { Write-Warning $logMessage }
		'Debug' { Write-Debug $logMessage }
		'Verbose' { Write-Verbose $logMessage }
		default { Write-Information $logMessage -InformationAction Continue }
	}
}

function Test-ModulePrerequisites {
	[CmdletBinding()]
	param()

	$errors = [List[string]]::new()

	# Test base location
	if (-not (Test-Path $script:ModuleConfig.BaseLocation)) {
		$errors.Add("Base location not found: $($script:ModuleConfig.BaseLocation)")
	}

	# Test temp directory
	if (-not (Test-Path $script:ModuleConfig.TempPath)) {
		try {
			New-Item -Path $script:ModuleConfig.TempPath -ItemType Directory -Force | Out-Null
			Write-ModuleLog "Created temp directory: $($script:ModuleConfig.TempPath)" -Level Verbose
		} catch {
			$errors.Add("Cannot create temp directory: $($script:ModuleConfig.TempPath)")
		}
	}

	# Test external dependencies
	$dependencies = @(
		@{ Name = 'ffmpeg'; Command = 'ffmpeg -version' }
		@{ Name = 'whisper'; Command = 'whisper --help' }
	)

	foreach ($dep in $dependencies) {
		try {
			$null = Invoke-Expression $dep.Command 2>$null
			Write-ModuleLog "$($dep.Name) found" -Level Verbose -Category 'Prerequisites'
		} catch {
			$errors.Add("Required dependency not found: $($dep.Name)")
		}
	}

	if ($errors.Count -gt 0) {
		Write-ModuleLog "Prerequisites check failed." -Level Error -Category 'Prerequisites' -Exception ([System.Exception]::new(($errors -join "`n")))
		throw "Prerequisites check failed.`n$($errors -join "`n")"
	}

	Write-ModuleLog 'All prerequisites validated successfully' -Level Info -Category 'Prerequisites'
}

function Get-VideoInformation {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[FileInfo]$File
	)

	try {
		$ffprobeArgs = @(
			'-v', 'quiet'
			'-print_format', 'json'
			'-show_format'
			'-show_streams'
			$File.FullName
		)

		$result = & ffprobe @ffprobeArgs | ConvertFrom-Json

		return @{
			Duration = [TimeSpan]::FromSeconds([double]$result.format.duration)
			Size     = [long]$result.format.size
			Bitrate  = [int]$result.format.bit_rate
			HasAudio = ($result.streams | Where-Object codec_type -EQ 'audio').Count -gt 0
		}
	} catch {
		Write-ModuleLog "Failed to get video information for: $($File.Name)" -Level Warning -Category $PSCmdlet.MyInvocation.InvocationName -Exception $_.Exception
		return @{
			Duration = [TimeSpan]::Zero
			Size     = $File.Length
			Bitrate  = 0
			HasAudio = $true # Assume true for processing
		}
	}
}

function New-AudioFromVideo {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[FileInfo]$VideoFile,

		[Parameter(Mandatory)]
		[string]$OutputPath
	)

	Write-ModuleLog "Converting video to audio: $($VideoFile.Name)" -Level Info -Category $PSCmdlet.MyInvocation.InvocationName

	$ffmpegArgs = @(
		'-hwaccel', 'auto'
		'-y'
		'-nostdin'
		'-loglevel', 'error'
		'-i', $VideoFile.FullName
		'-ar', '16000'
		'-c:a', 'pcm_s16le'
		'-ac', '1'
		$OutputPath
	)

	try {
		$process = Start-Process -FilePath 'ffmpeg' -ArgumentList $ffmpegArgs -NoNewWindow -PassThru -Wait

		if ($process.ExitCode -ne 0) {
			throw "FFmpeg failed with exit code: $($process.ExitCode)"
		}

		if (-not (Test-Path $OutputPath)) {
			throw "Audio file was not created: $OutputPath"
		}

		Write-ModuleLog 'Audio conversion completed successfully' -Level Verbose -Category $PSCmdlet.MyInvocation.InvocationName
	} catch {
		Write-ModuleLog "Audio conversion failed: $($_.Exception.Message)" -Level Error -Category $PSCmdlet.MyInvocation.InvocationName -Exception $_.Exception
		throw
	}
}

function Invoke-WhisperTranscription {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string]$AudioPath,

		[Parameter(Mandatory)]
		[string]$Language,

		[Parameter(Mandatory)]
		[string]$Model,

		[Parameter(Mandatory)]
		[string]$Format,

		[Parameter(Mandatory)]
		[int]$Threads,

		[Parameter(Mandatory)]
		[int]$Processors,

		[Parameter(Mandatory)]
		[string]$WhisperImplementation,

		[switch]$Translate
	)

	Write-ModuleLog 'Starting Whisper transcription' -Level Info -Category $PSCmdlet.MyInvocation.InvocationName

	$isVerbose = $PSCmdlet.MyInvocation.BoundParameters['Verbose'] -or $VerbosePreference -eq 'Continue'

			if ($WhisperImplementation -eq 'Legacy') {
		Invoke-LegacyWhisper -AudioPath $AudioPath -Language $Language -Model $Model -Format $Format -Threads $Threads -Processors $Processors -WhisperImplementation $WhisperImplementation -Translate:$Translate -Verbose:$isVerbose
	} else {
		Invoke-ModernWhisper -AudioPath $AudioPath -Language $Language -Model $Model -Format $Format -Threads $Threads -Processors $Processors -WhisperImplementation $WhisperImplementation -Translate:$Translate -Verbose:$isVerbose
	}
}

function Invoke-LegacyWhisper {
	[CmdletBinding()]
	param(
		[string]$AudioPath,
		[string]$Language,
		[string]$Model,
		[string]$Format,
		[int]$Threads,
		[int]$Processors,
		[switch]$Translate
	)
	$executablePath = Join-Path $script:ModuleConfig.BaseLocation 'main.exe'
	$modelPath = Join-Path $script:ModuleConfig.BaseLocation 'models\large.bin'
	if (-not (Test-Path $executablePath)) {
		Write-ModuleLog "Legacy Whisper executable not found: $executablePath" -Level Error -Category $PSCmdlet.MyInvocation.InvocationName -Exception ([System.IO.FileNotFoundException]::new("Legacy Whisper executable not found: $executablePath"))
		throw "Legacy Whisper executable not found: $executablePath"
	}
	$arguments = @(
		"--output-$Format"
		'--model', $modelPath
		'--diarize'
		'--processors', $Processors
		'--threads', $Threads
		'--file', $AudioPath
	)
	if ($Translate) { $arguments += '--translate' }
	Write-ModuleLog "Executing legacy Whisper: $executablePath" -Level Debug -Category $PSCmdlet.MyInvocation.InvocationName
	try {
		$process = Start-Process -FilePath $executablePath -ArgumentList $arguments -NoNewWindow -PassThru -Wait

		if ($process.ExitCode -ne 0) {
			throw "Legacy Whisper failed with exit code: $($process.ExitCode)"
		}
	} catch {
		Write-ModuleLog "Legacy Whisper execution failed: $($_.Exception.Message)" -Level Error -Category $PSCmdlet.MyInvocation.InvocationName -Exception $_.Exception
		throw
	}
}

function Invoke-ModernWhisper {
	[CmdletBinding()]
	param(
		[string]$AudioPath,
		[string]$Language,
		[string]$Model,
		[string]$Format,
		[int]$Threads,
		[int]$Processors,
		[string]$WhisperImplementation,
		[switch]$Translate
	)
	$arguments = @(
		'--output_format', $Format
		'--model', $Model
		'--threads', $Threads
		'--processors', $Processors
		'--task', ($Translate ? 'translate' : 'transcribe')
		'--output_dir', $script:ModuleConfig.TempPath
		$AudioPath
	)
	if ($Language -ne 'auto') {
		$arguments += '--language', $Language
	}
	Write-ModuleLog 'Executing modern Whisper' -Level Debug -Category $PSCmdlet.MyInvocation.InvocationName
	try {
		$process = Start-Process -FilePath 'whisper' -ArgumentList $arguments -NoNewWindow -PassThru -Wait

		if ($process.ExitCode -ne 0) {
			throw "Modern Whisper failed with exit code: $($process.ExitCode)"
		}
	} catch {
		Write-ModuleLog "Modern Whisper execution failed: $($_.Exception.Message)" -Level Error -Category $PSCmdlet.MyInvocation.InvocationName -Exception $_.Exception
		throw
	}
}

function Optimize-SubtitleFile {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string]$SubtitlePath,

		[Parameter(Mandatory)]
		[string]$Format
	)

	$subtitleEditPath = $script:ModuleConfig.SubtitleEditPath

	if (-not (Test-Path $subtitleEditPath)) {
		Write-ModuleLog 'Subtitle Edit not found, skipping optimization' -Level Warning -Category $PSCmdlet.MyInvocation.InvocationName
		return
	}

	Write-ModuleLog "Optimizing subtitle file: $(Split-Path $SubtitlePath -Leaf)" -Level Info -Category $PSCmdlet.MyInvocation.InvocationName

	$formatMapping = $script:ModuleConfig.SubtitleFormats[$Format]

	$arguments = @(
		"/convert `"$SubtitlePath`""
		$formatMapping
		'/encoding:utf-8'
		'/overwrite'
		'/MergeSameTimeCodes'
		'/MergeSameTexts'
		'/MergeShortLines'
		'/BalanceLines'
	)

	try {
		$process = Start-Process -FilePath $subtitleEditPath -ArgumentList $arguments -NoNewWindow -PassThru -Wait -RedirectStandardOutput 'NUL'

		if ($process.ExitCode -eq 0) {
			Write-ModuleLog 'Subtitle optimization completed' -Level Verbose -Category $PSCmdlet.MyInvocation.InvocationName
		} else {
			Write-ModuleLog "Subtitle optimization failed with exit code: $($process.ExitCode)" -Level Warning -Category $PSCmdlet.MyInvocation.InvocationName
		}
	} catch {
		Write-ModuleLog "Subtitle optimization error: $($_.Exception.Message)" -Level Warning -Category $PSCmdlet.MyInvocation.InvocationName -Exception $_.Exception
	}
}

function Get-WhisperOptimalCpuSettings {
	<#
    .SYNOPSIS
        Calculates optimal --threads and --processors settings for whisper.cpp.
    .DESCRIPTION
        Based on the number of logical CPU cores, this function returns optimal values
        for threads and processors to avoid CPU overload and maximize performance.
    .OUTPUTS
        [PSCustomObject] with Threads and Processors properties.
    .EXAMPLE
        Get-WhisperOptimalCpuSettings
        Threads   Processors
        -------   ----------
        8         2
    #>
	$logicalCores = [System.Environment]::ProcessorCount
	$maxThreads = [Math]::Min(12, $logicalCores)
	$processors = 1
	$threads = [Math]::Floor($logicalCores / $processors)
	if ($threads -gt $maxThreads) {
		$threads = $maxThreads
		$processors = [Math]::Floor($logicalCores / $threads)
	}
	[PSCustomObject]@{
		Threads    = $threads
		Processors = $processors
	}
}
#endregion

#region Main Functions
function ConvertTo-Subtitle {
	<#
    .SYNOPSIS
        Converts video files to subtitle files using Whisper AI

    .DESCRIPTION
        This function processes video files and generates subtitles using OpenAI's Whisper.
        Supports multiple languages, models, and output formats with advanced optimization.

    .PARAMETER InputPath
        The video file(s) or directory containing video files to process

    .PARAMETER Language
        The language of the subtitle content (default: 'nl')

    .PARAMETER Model
        The Whisper model to use for transcription (default: 'turbo')

    .PARAMETER Format
        The output subtitle format (default: 'srt')

    .PARAMETER WhisperImplementation
        Specify which Whisper implementation to use: 'Modern' (default) or 'Legacy'

    .PARAMETER Translate
        Translate the subtitles to English

    .PARAMETER Threads
        Number of processing threads to use

    .PARAMETER PassThru
        Return processed file information

    .EXAMPLE
        ConvertTo-Subtitle -InputPath "C:\Videos\movie.mp4" -Language "en" -Format "srt"

        Generates English SRT subtitles for a single video file

    .EXAMPLE
        Get-ChildItem "C:\Videos" -Filter "*.mp4" | ConvertTo-Subtitle -Language "nl" -Model "large"

        Processes all MP4 files in a directory using the large model for Dutch subtitles
    #>

	[CmdletBinding(SupportsPaging, SupportsShouldProcess)]
	param(
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('i', 'FullName', 'Path')]
		[object]$InputPath,

		[Parameter()]
		[ValidateSet('en', 'nl', 'af', 'am', 'ar', 'as', 'az', 'ba', 'be', 'bg', 'bn', 'bo', 'br', 'bs', 'ca', 'cs', 'cy', 'da', 'de', 'el', 'es', 'et', 'eu', 'fa', 'fi', 'fo', 'fr', 'gl', 'gu', 'ha', 'haw', 'he', 'hi', 'hr', 'ht', 'hu', 'hy', 'id', 'is', 'it', 'ja', 'jw', 'ka', 'kk', 'km', 'kn', 'ko', 'la', 'lb', 'ln', 'lo', 'lt', 'lv', 'mg', 'mi', 'mk', 'ml', 'mn', 'mr', 'ms', 'mt', 'my', 'ne', 'nn', 'no', 'oc', 'pa', 'pl', 'ps', 'pt', 'ro', 'ru', 'sa', 'sd', 'si', 'sk', 'sl', 'sn', 'so', 'sq', 'sr', 'su', 'sv', 'sw', 'ta', 'te', 'tg', 'th', 'tk', 'tl', 'tr', 'tt', 'uk', 'ur', 'uz', 'vi', 'yi', 'yo', 'yue', 'zh', 'auto')]
		[Alias('l')]
		[string]$Language = 'nl',

		[Parameter()]
		[ValidateSet('tiny', 'tiny.en', 'base', 'base.en', 'small', 'small.en', 'medium', 'medium.en', 'large', 'turbo')]
		[Alias('m')]
		[string]$Model = 'turbo',

		[Parameter()]
		[ValidateSet('txt', 'vtt', 'srt', 'json')]
		[Alias('f')]
		[string]$Format = 'srt',

		[Parameter()]
		[ValidateSet('Modern', 'Legacy')]
		[string]$WhisperImplementation = 'Modern',

		[Parameter()]
		[switch]$Translate,

		[Parameter()]
		[ValidateRange(1, [int]::MaxValue)]
		[int]$Threads,

		[Parameter()]
		[switch]$PassThru
	)

							begin {
		Write-ModuleLog 'Starting subtitle conversion process' -Level Info

		try {
			Test-ModulePrerequisites
		} catch {
			Write-ModuleLog "Prerequisites validation failed: $($_.Exception.Message)" -Level Error -Category $PSCmdlet.MyInvocation.InvocationName -Exception $_.Exception
			throw
		}

		$cpuSettings = Get-WhisperOptimalCpuSettings
		if (-not $PSBoundParameters.ContainsKey('Threads')) {
			$Threads = $cpuSettings.Threads
		}
		$Processors = $cpuSettings.Processors
		$processedFiles = [List[object]]::new()
		$originalWindowTitle = $Host.UI.RawUI.WindowTitle
		$startTime = Get-Date

		Write-ModuleLog "Process started at: $startTime" -Level Verbose
	}

		process {
		try {
			$files = Get-InputFiles -InputPath $InputPath
			$fileCount = $files.Count
			$currentFileIndex = 0

			foreach ($file in $files) {
				$currentFileIndex++
				Write-Progress -Activity "Generating Subtitles" -Status "Processing $($file.Name)" -CurrentOperation "File $currentFileIndex of $fileCount" -PercentComplete (($currentFileIndex / $fileCount) * 100)

				if ($PSCmdlet.ShouldProcess($file.FullName, 'Generate subtitles')) {
					$result = ConvertSingleFile -File $file -Language $Language -Model $Model -Format $Format -Threads $Threads -Processors $Processors -UseOldWhisper:$UseOldWhisper -Translate:$Translate
					$processedFiles.Add($result)

					if ($PassThru) {
						Write-Output $result
					}
				}
			}
		} catch {
			Write-ModuleLog "Processing error: $($_.Exception.Message)" -Level Error
			throw
		}
	}

		end {
		$elapsedTime = (Get-Date) - $startTime
		

		Write-ModuleLog 'Subtitle conversion completed' -Level Info
		Write-ModuleLog "Total files processed: $($processedFiles.Count)" -Level Info
		Write-ModuleLog "Total time elapsed: $($elapsedTime.ToString('hh\:mm\:ss'))" -Level Info

		if (-not $PassThru) {
			Write-Output $processedFiles
		}
	}
}

function Get-InputFiles {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[object]$InputPath
	)

	$currentPath = switch ($InputPath.GetType().Name) {
		'FileInfo' { $InputPath.FullName }
		'DirectoryInfo' { $InputPath.FullName }
		'String' { $InputPath }
		default {
			if ($InputPath.FullName) { $InputPath.FullName }
			else { $InputPath.ToString() }
		}
	}

	if ([File]::Exists($currentPath)) {
		$fileInfo = Get-Item -LiteralPath $currentPath
		if ($script:ModuleConfig.SupportedExtensions -contains $fileInfo.Extension.ToLower()) {
			return @($fileInfo)
		} else {
			throw "Unsupported file extension: $($fileInfo.Extension)"
		}
	} elseif ([Directory]::Exists($currentPath)) {
		$files = Get-ChildItem -Path $currentPath -File -Recurse |
			Where-Object { $script:ModuleConfig.SupportedExtensions -contains $_.Extension.ToLower() }

		if ($files.Count -eq 0) {
			throw "No supported video files found in directory: $currentPath"
		}

		return $files
	} else {
		# Handle wildcard patterns
		try {
			$files = Get-ChildItem -Path $currentPath -File |
				Where-Object { $script:ModuleConfig.SupportedExtensions -contains $_.Extension.ToLower() }

			if ($files.Count -eq 0) {
				throw "No matching files found: $currentPath"
			}

			return $files
		} catch {
			throw "Invalid path or pattern: $currentPath"
		}
	}
}

function ConvertSingleFile {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[FileInfo]$File,

		[string]$Language,
		[string]$Model,
		[string]$Format,
		[int]$Threads,
		[int]$Processors,
		[string]$WhisperImplementation,
		[switch]$Translate
	)
	$fileHash = (Get-FileHash -LiteralPath $File.FullName -Algorithm MD5).Hash
	$audioPath = Join-Path $script:ModuleConfig.TempPath "$fileHash.wav"
	$subtitlePath = Join-Path $script:ModuleConfig.TempPath "$fileHash.$Format"
	try {
		$videoInfo = Get-VideoInformation -File $File
		Write-ModuleLog "Processing: $($File.Name)" -Level Info -Category 'FileProcessing'
		# Step 1: Extract audio
		New-AudioFromVideo -VideoFile $File -OutputPath $audioPath
		# Step 2: Generate subtitles
		Invoke-WhisperTranscription -AudioPath $audioPath -Language $Language -Model $Model -Format $Format -Threads $Threads -Processors $Processors -WhisperImplementation:$WhisperImplementation -Translate:$Translate
		# Step 3: Move and optimize subtitle
		$languageSuffix = $Translate ? 'en' : $Language
		$finalSubtitlePath = Join-Path $File.Directory "$($File.BaseName).$languageSuffix.$Format"
		if (Test-Path $subtitlePath) {
			Move-Item -LiteralPath $subtitlePath -Destination $finalSubtitlePath -Force
			Optimize-SubtitleFile -SubtitlePath $finalSubtitlePath -Format $Format
		} else {
			throw "Subtitle file was not generated: $subtitlePath"
		}
		# Step 4: Cleanup
		if (Test-Path $audioPath) {
			Remove-Item -LiteralPath $audioPath -Force
		}
		Write-ModuleLog "Successfully processed: $($File.Name)" -Level Info -Category 'FileProcessing'
		return [PSCustomObject]@{
			SourceFile   = $File.FullName
			SubtitleFile = $finalSubtitlePath
			Language     = $languageSuffix
			Format       = $Format
			Duration     = $videoInfo.Duration
			ProcessedAt  = Get-Date
			Success      = $true
		}
	} catch {
		Write-ModuleLog "Failed to process $($File.Name): $($_.Exception.Message)" -Level Error -Category 'FileProcessing'
		# Cleanup on failure
		@($audioPath, $subtitlePath) | ForEach-Object {
			if (Test-Path $_) { Remove-Item -LiteralPath $_ -Force -ErrorAction SilentlyContinue }
		}
		return [PSCustomObject]@{
			SourceFile   = $File.FullName
			SubtitleFile = $null
			Language     = $null
			Format       = $Format
			Duration     = [TimeSpan]::Zero
			ProcessedAt  = Get-Date
			Success      = $false
			Error        = $_.Exception.Message
		}
	}
}

function Get-WhisperModuleInfo {
	<#
    .SYNOPSIS
        Gets information about the WhisperSubtitle module configuration

    .DESCRIPTION
        Returns detailed information about the current module configuration,
        supported formats, and system capabilities
    #>

	[CmdletBinding()]
	param()

	return [PSCustomObject]@{
		ModuleVersion       = '0.1.0'
		BaseLocation        = $script:ModuleConfig.BaseLocation
		TempPath            = $script:ModuleConfig.TempPath
		LogicalProcessors   = $script:ModuleConfig.LogicalProcessorCount
		SupportedExtensions = $script:ModuleConfig.SupportedExtensions
		SupportedFormats    = $script:ModuleConfig.SubtitleFormats.Keys
		Prerequisites       = @{
			FFmpeg       = ($null -ne (Get-Command ffmpeg -ErrorAction SilentlyContinue))
			Whisper      = ($null -ne (Get-Command whisper -ErrorAction SilentlyContinue))
			SubtitleEdit = Test-Path $script:ModuleConfig.SubtitleEditPath
		}
	}
}
#endregion

#region Module Exports
Export-ModuleMember -Function @(
	'ConvertTo-Subtitle'
	'Get-WhisperModuleInfo'
	'Get-WhisperSubtitleConfig'
	'Set-WhisperSubtitleConfig'
)

# Create aliases for backward compatibility
New-Alias -Name 'whisperSub' -Value 'ConvertTo-Subtitle' -Force
Export-ModuleMember -Alias 'whisperSub'
#endregion

#region Module Initialization
Write-ModuleLog 'WhisperSubtitle module loaded successfully' -Level Info
Write-ModuleLog "Use 'Get-WhisperModuleInfo' to view module configuration" -Level Verbose
#endregion
