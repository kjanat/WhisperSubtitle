# Document WhisperSubtitle module with PSDocs

document 'Module' {
    Title 'WhisperSubtitle PowerShell Module'
    
    # Import the module
    Import-Module ./WhisperSubtitle.psd1 -Force
    
    # Get module information
    $moduleInfo = Get-Module WhisperSubtitle
    
    Section 'Overview' {
        $moduleInfo.Description
        
        Paragraph {
            'Version: ' + $moduleInfo.Version
            'Author: ' + $moduleInfo.Author
            'PowerShell: ' + $moduleInfo.PowerShellVersion + '+'
        }
    }
    
    Section 'Installation' {
        @'
        ## From PowerShell Gallery
        ```powershell
        Install-Module -Name WhisperSubtitle -Scope CurrentUser
        ```
        
        ## From Source
        ```powershell
        git clone https://github.com/kjanat/WhisperSubtitle.git
        Import-Module .\WhisperSubtitle\WhisperSubtitle.psd1
        ```
'@
    }
    
    Section 'Functions' {
        $functions = Get-Command -Module WhisperSubtitle -CommandType Function
        
        foreach ($function in $functions) {
            $help = Get-Help $function.Name -Full
            
            Section $function.Name {
                $help.Synopsis
                
                if ($help.Description) {
                    Section 'Description' {
                        $help.Description.Text
                    }
                }
                
                if ($help.Parameters.Parameter) {
                    Section 'Parameters' {
                        foreach ($param in $help.Parameters.Parameter) {
                            Section $param.Name {
                                Paragraph {
                                    "Type: $($param.Type.Name)"
                                    if ($param.Required -eq 'true') { 'Required: Yes' } else { 'Required: No' }
                                    if ($param.DefaultValue) { "Default: $($param.DefaultValue)" }
                                }
                                
                                if ($param.Description.Text) {
                                    $param.Description.Text
                                }
                            }
                        }
                    }
                }
                
                if ($help.Examples.Example) {
                    Section 'Examples' {
                        foreach ($example in $help.Examples.Example) {
                            if ($example.Code) {
                                Code powershell $example.Code
                                if ($example.Remarks.Text) {
                                    $example.Remarks.Text
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    Section 'Configuration' {
        @'
        The module supports configuration through `Get-WhisperSubtitleConfig` and `Set-WhisperSubtitleConfig` cmdlets.
        
        Default configuration includes:
        - Base location for Whisper files
        - Temporary file path
        - Subtitle Edit executable path
        - Supported file extensions
        - CPU thread settings
'@
    }
    
    Section 'Requirements' {
        @'
        - PowerShell 7.0 or higher
        - FFmpeg (for video processing)
        - OpenAI Whisper (legacy main.exe or modern whisper CLI)
        - Subtitle Edit (optional, for subtitle optimization)
'@
    }
}

document 'README' {
    Title 'WhisperSubtitle'
    
    # Include existing README content
    $readmeContent = Get-Content -Path './README.md' -Raw
    $readmeContent
}