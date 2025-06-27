function Set-WhisperSubtitleConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseLocation,

        [Parameter()]
        [string]$TempPath,

        [Parameter()]
        [string]$SubtitleEditPath
    )

    . (Join-Path $PSScriptRoot '..\Private\Get-ModuleConfig.ps1')
    . (Join-Path $PSScriptRoot '..\Private\Set-ModuleConfig.ps1')

    $currentConfig = Get-ModuleConfig

    $newConfig = $currentConfig.Clone()
    if ($PSBoundParameters.ContainsKey('BaseLocation')) {
        $newConfig.BaseLocation = $BaseLocation
    }
    if ($PSBoundParameters.ContainsKey('TempPath')) {
        $newConfig.TempPath = $TempPath
    }
    if ($PSBoundParameters.ContainsKey('SubtitleEditPath')) {
        $newConfig.SubtitleEditPath = $SubtitleEditPath
    }

    Set-ModuleConfig -Config $newConfig
}