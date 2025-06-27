function Get-ModuleConfig {
    [CmdletBinding()]
    param()

    $configPath = Join-Path (Split-Path $PSScriptRoot) 'ModuleConfig.json'

    if (Test-Path $configPath) {
        try {
            return (Get-Content $configPath | ConvertFrom-Json)
        } catch {
            Write-Warning "Failed to read module configuration from '$configPath': $($_.Exception.Message)"
            return @{}
        }
    } else {
        return @{}
    }
}