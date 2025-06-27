function Get-WhisperSubtitleConfig {
    [CmdletBinding()]
    param()

    . (Join-Path $PSScriptRoot '..\Private\Get-ModuleConfig.ps1')
    Get-ModuleConfig
}