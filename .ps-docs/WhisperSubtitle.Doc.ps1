# Document WhisperSubtitle module with PSDocs

document 'Module' {
    Title 'WhisperSubtitle PowerShell Module'
    
    # Get module information
    $manifest = Test-ModuleManifest ./WhisperSubtitle.psd1 -ErrorAction SilentlyContinue
    
    Section 'Overview' {
        'Professional subtitle generation module using OpenAI Whisper with advanced features for video processing, multiple output formats, and batch operations.'
        
        if ($manifest) {
            "Version: $($manifest.Version)"
            "Author: $($manifest.Author)"
            "PowerShell: $($manifest.PowerShellVersion)+"
        }
    }
    
    Section 'Installation' {
        'From PowerShell Gallery:'
        '```powershell'
        'Install-Module -Name WhisperSubtitle -Scope CurrentUser'
        '```'
        
        'From Source:'
        '```powershell'
        'git clone https://github.com/kjanat/WhisperSubtitle.git'
        'Import-Module .\WhisperSubtitle\WhisperSubtitle.psd1'
        '```'
    }
    
    Section 'Functions' {
        Import-Module ./WhisperSubtitle.psd1 -Force -ErrorAction SilentlyContinue
        $functions = Get-Command -Module WhisperSubtitle -CommandType Function -ErrorAction SilentlyContinue
        
        if ($functions) {
            foreach ($function in $functions) {
                Section $function.Name {
                    $help = Get-Help $function.Name -ErrorAction SilentlyContinue
                    
                    if ($help.Synopsis) {
                        $help.Synopsis
                    }
                    
                    if ($help.Description) {
                        'Description:'
                        $help.Description[0].Text
                    }
                }
            }
        } else {
            'Module functions could not be loaded.'
        }
    }
    
    Section 'Configuration' {
        'The module supports configuration through Get-WhisperSubtitleConfig and Set-WhisperSubtitleConfig cmdlets.'
        
        'Default configuration includes:'
        '- Base location for Whisper files'
        '- Temporary file path'
        '- Subtitle Edit executable path'
        '- Supported file extensions'
        '- CPU thread settings'
    }
    
    Section 'Requirements' {
        '- PowerShell 7.0 or higher'
        '- FFmpeg (for video processing)'
        '- OpenAI Whisper (legacy main.exe or modern whisper CLI)'
        '- Subtitle Edit (optional, for subtitle optimization)'
    }
}