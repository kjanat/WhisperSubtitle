# Document WhisperSubtitle module with PSDocs

document 'Module' {
    Title 'WhisperSubtitle PowerShell Module'
    
    # Get module information safely
    $manifest = $null
    try {
        $manifest = Test-ModuleManifest ./WhisperSubtitle.psd1 -ErrorAction Stop
    } catch {
        "Failed to load manifest: $($_.Exception.Message)"
        return
    }
    
    Section 'Overview' {
        $manifest.Description
        
        ""
        "**Version:** $($manifest.Version)"
        "**Author:** $($manifest.Author)"
        "**PowerShell:** $($manifest.PowerShellVersion)+"
        ""
    }
    
    Section 'Installation' {
        "## From PowerShell Gallery"
        "```powershell"
        "Install-Module -Name WhisperSubtitle -Scope CurrentUser"
        "```"
        ""
        "## From Source"
        "```powershell"
        "git clone https://github.com/kjanat/WhisperSubtitle.git"
        "Import-Module .\WhisperSubtitle\WhisperSubtitle.psd1"
        "```"
    }
    
    Section 'Functions' {
        # Try to import module and get functions
        try {
            Import-Module ./WhisperSubtitle.psd1 -Force -ErrorAction Stop
            $functions = Get-Command -Module WhisperSubtitle -CommandType Function -ErrorAction Stop
            
            foreach ($function in $functions) {
                Section $function.Name {
                    try {
                        $help = Get-Help $function.Name -Full -ErrorAction SilentlyContinue
                        
                        if ($help.Synopsis) {
                            $help.Synopsis
                            ""
                        }
                        
                        if ($help.Description) {
                            "**Description:**"
                            $help.Description.Text
                            ""
                        }
                        
                        if ($help.Parameters.Parameter) {
                            "**Parameters:**"
                            foreach ($param in $help.Parameters.Parameter) {
                                "- **$($param.Name)**: $($param.Type.Name)"
                                if ($param.Description.Text) {
                                    "  $($param.Description.Text)"
                                }
                            }
                            ""
                        }
                        
                        if ($help.Examples.Example) {
                            "**Examples:**"
                            foreach ($example in $help.Examples.Example) {
                                if ($example.Code) {
                                    "```powershell"
                                    $example.Code
                                    "```"
                                    if ($example.Remarks.Text) {
                                        $example.Remarks.Text
                                    }
                                    ""
                                }
                            }
                        }
                    } catch {
                        "Error retrieving help for $($function.Name): $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            "Unable to load module functions: $($_.Exception.Message)"
        }
    }
    
    Section 'Configuration' {
        "The module supports configuration through Get-WhisperSubtitleConfig and Set-WhisperSubtitleConfig cmdlets."
        ""
        "**Default configuration includes:**"
        "- Base location for Whisper files"
        "- Temporary file path"  
        "- Subtitle Edit executable path"
        "- Supported file extensions"
        "- CPU thread settings"
    }
    
    Section 'Requirements' {
        "- PowerShell 7.0 or higher"
        "- FFmpeg (for video processing)"
        "- OpenAI Whisper (legacy main.exe or modern whisper CLI)"
        "- Subtitle Edit (optional, for subtitle optimization)"
    }
}