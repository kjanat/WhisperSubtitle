function Set-ModuleConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Hashtable]$Config
    )

    $configPath = Join-Path (Split-Path $PSScriptRoot) 'ModuleConfig.json'

    try {
        $Config | ConvertTo-Json -Depth 100 | Set-Content $configPath -Force
        Write-Verbose "Module configuration saved to '$configPath'."
    } catch {
        Write-Error "Failed to save module configuration to '$configPath': $($_.Exception.Message)"
    }
}