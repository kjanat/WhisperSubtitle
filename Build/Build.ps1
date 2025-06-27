#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build script for WhisperSubtitle PowerShell module
.DESCRIPTION
    Performs version synchronization, validation, and module preparation tasks
.PARAMETER SyncVersions
    Synchronize version numbers between .psm1 and .psd1 files
.PARAMETER RunTests
    Execute Pester tests after build
.PARAMETER Validate
    Run validation checks only
#>

[CmdletBinding()]
param(
    [switch]$SyncVersions,
    [switch]$RunTests,
    [switch]$Validate
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# Build configuration
$ModuleRoot = Split-Path $PSScriptRoot -Parent
$ModuleName = 'WhisperSubtitle'
$ManifestPath = Join-Path $ModuleRoot "$ModuleName.psd1"
$ModulePath = Join-Path $ModuleRoot "$ModuleName.psm1"

Write-Host "=' WhisperSubtitle Build Script" -ForegroundColor Cyan
Write-Host "Module Root: $ModuleRoot" -ForegroundColor Gray

function Get-ModuleVersion {
    param([string]$FilePath, [string]$FileType)
    
    switch ($FileType) {
        'psd1' {
            $content = Get-Content $FilePath -Raw
            if ($content -match "ModuleVersion\s*=\s*'([^']+)'") {
                return $Matches[1]
            }
        }
        'psm1' {
            $content = Get-Content $FilePath -Raw
            if ($content -match "\.VERSION\s+([0-9]+\.[0-9]+\.[0-9]+)") {
                return $Matches[1]
            }
        }
    }
    throw "Could not extract version from $FileType file"
}

function Set-ModuleVersion {
    param([string]$FilePath, [string]$FileType, [string]$Version)
    
    $content = Get-Content $FilePath -Raw
    
    switch ($FileType) {
        'psd1' {
            $content = $content -replace "ModuleVersion\s*=\s*'[^']+'", "ModuleVersion        = '$Version'"
        }
        'psm1' {
            $content = $content -replace "(\.VERSION\s+)[0-9]+\.[0-9]+\.[0-9]+", "`${1}$Version"
        }
    }
    
    Set-Content -Path $FilePath -Value $content -NoNewline
    Write-Host " Updated $FileType version to $Version" -ForegroundColor Green
}

function Test-VersionConsistency {
    try {
        $psd1Version = Get-ModuleVersion -FilePath $ManifestPath -FileType 'psd1'
        $psm1Version = Get-ModuleVersion -FilePath $ModulePath -FileType 'psm1'
        
        Write-Host "=Ë Version Check:" -ForegroundColor Yellow
        Write-Host "  Manifest (.psd1): $psd1Version" -ForegroundColor Gray
        Write-Host "  Module (.psm1):   $psm1Version" -ForegroundColor Gray
        
        if ($psd1Version -eq $psm1Version) {
            Write-Host " Version consistency check passed" -ForegroundColor Green
            return $true
        } else {
            Write-Host "L Version mismatch detected" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "L Version check failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Sync-ModuleVersions {
    try {
        $psd1Version = Get-ModuleVersion -FilePath $ManifestPath -FileType 'psd1'
        $psm1Version = Get-ModuleVersion -FilePath $ModulePath -FileType 'psm1'
        
        # Use the higher version number
        $targetVersion = if ([version]$psd1Version -gt [version]$psm1Version) { $psd1Version } else { $psm1Version }
        
        Write-Host "= Synchronizing versions to: $targetVersion" -ForegroundColor Yellow
        
        Set-ModuleVersion -FilePath $ManifestPath -FileType 'psd1' -Version $targetVersion
        Set-ModuleVersion -FilePath $ModulePath -FileType 'psm1' -Version $targetVersion
        
        Write-Host " Version synchronization completed" -ForegroundColor Green
    } catch {
        Write-Host "L Version sync failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Test-ModuleSyntax {
    Write-Host "= Testing PowerShell syntax..." -ForegroundColor Yellow
    
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ModulePath -Raw), [ref]$null)
        $null = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
        Write-Host " Syntax validation passed" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "L Syntax validation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Invoke-ModuleTests {
    Write-Host ">ê Running Pester tests..." -ForegroundColor Yellow
    
    $TestPath = Join-Path $ModuleRoot 'Tests'
    if (-not (Test-Path $TestPath)) {
        Write-Host "  No tests directory found" -ForegroundColor Yellow
        return $true
    }
    
    try {
        $result = Invoke-Pester -Path $TestPath -PassThru -Quiet
        if ($result.FailedCount -eq 0) {
            Write-Host " All tests passed ($($result.PassedCount) passed)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "L $($result.FailedCount) tests failed" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "L Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main build logic
try {
    if ($Validate) {
        Write-Host "= Running validation checks only..." -ForegroundColor Cyan
        $versionCheck = Test-VersionConsistency
        $syntaxCheck = Test-ModuleSyntax
        
        if ($versionCheck -and $syntaxCheck) {
            Write-Host " All validation checks passed" -ForegroundColor Green
            exit 0
        } else {
            Write-Host "L Validation failed" -ForegroundColor Red
            exit 1
        }
    }
    
    if ($SyncVersions) {
        Sync-ModuleVersions
    } else {
        if (-not (Test-VersionConsistency)) {
            Write-Host "=¡ Use -SyncVersions to automatically fix version mismatch" -ForegroundColor Yellow
            exit 1
        }
    }
    
    if (-not (Test-ModuleSyntax)) {
        exit 1
    }
    
    if ($RunTests) {
        if (-not (Invoke-ModuleTests)) {
            exit 1
        }
    }
    
    Write-Host "<‰ Build completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "=¥ Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}