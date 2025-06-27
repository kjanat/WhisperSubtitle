#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install development dependencies for WhisperSubtitle module
.DESCRIPTION
    Installs PowerShell modules and checks for external dependencies required for development
#>

Write-Host "WhisperSubtitle Development Dependencies Installer" -ForegroundColor Green

# Check if PowerShell Gallery is trusted
$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if ($psGallery.InstallationPolicy -ne 'Trusted') {
    Write-Host "Setting PowerShell Gallery as trusted repository..." -ForegroundColor Yellow
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

# Install required modules
$requiredModules = @(
    @{ Name = 'Pester'; MinimumVersion = '5.0.0' },
    @{ Name = 'PSScriptAnalyzer'; MinimumVersion = '1.20.0' }
)

foreach ($module in $requiredModules) {
    Write-Host "Installing $($module.Name)..." -ForegroundColor Yellow
    
    $installed = Get-Module -Name $module.Name -ListAvailable | 
                 Where-Object { $_.Version -ge [version]$module.MinimumVersion } | 
                 Select-Object -First 1
    
    if ($installed) {
        Write-Host "✓ $($module.Name) v$($installed.Version) already installed" -ForegroundColor Green
    } else {
        Install-Module -Name $module.Name -MinimumVersion $module.MinimumVersion -Scope CurrentUser -Force
        Write-Host "✓ $($module.Name) installed successfully" -ForegroundColor Green
    }
}

# Verify external dependencies
Write-Host "`nChecking external dependencies..." -ForegroundColor Yellow

$dependencies = @{
    'ffmpeg' = 'FFmpeg (required for video processing)'
    'ffprobe' = 'FFprobe (required for video information)'
}

foreach ($dep in $dependencies.GetEnumerator()) {
    try {
        $null = Get-Command $dep.Key -ErrorAction Stop
        Write-Host "✓ $($dep.Value) found" -ForegroundColor Green
    } catch {
        Write-Host "⚠ $($dep.Value) not found in PATH" -ForegroundColor Yellow
        Write-Host "  Please install FFmpeg manually: https://ffmpeg.org/download.html" -ForegroundColor Gray
    }
}

Write-Host "`nDevelopment environment setup complete!" -ForegroundColor Green
