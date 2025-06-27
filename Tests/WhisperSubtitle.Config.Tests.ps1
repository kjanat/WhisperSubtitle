Describe "Configuration Cmdlets" {
    BeforeAll {
        # Ensure a clean state for configuration tests
        $modulePath = Join-Path (Split-Path $PSScriptRoot) '..'
        $configFilePath = Join-Path $modulePath 'ModuleConfig.json'
        if (Test-Path $configFilePath) {
            Remove-Item $configFilePath -Force
        }

        # Import the module to make cmdlets available
        Import-Module (Join-Path $modulePath 'WhisperSubtitle.psm1') -Force
    }

    It "should set and get BaseLocation correctly" {
        $testBaseLocation = "C:\TestWhisperBase"
        Set-WhisperSubtitleConfig -BaseLocation $testBaseLocation
        $config = Get-WhisperSubtitleConfig
        $config.BaseLocation | Should Be $testBaseLocation
    }

    It "should set and get TempPath correctly" {
        $testTempPath = "C:\TestWhisperTemp"
        Set-WhisperSubtitleConfig -TempPath $testTempPath
        $config = Get-WhisperSubtitleConfig
        $config.TempPath | Should Be $testTempPath
    }

    It "should set and get SubtitleEditPath correctly" {
        $testSubtitleEditPath = "C:\Program Files\SubtitleEdit\SubtitleEdit.exe"
        Set-WhisperSubtitleConfig -SubtitleEditPath $testSubtitleEditPath
        $config = Get-WhisperSubtitleConfig
        $config.SubtitleEditPath | Should Be $testSubtitleEditPath
    }

    It "should retain existing settings when one is updated" {
        $initialBaseLocation = "C:\InitialBase"
        $newTempPath = "C:\NewTemp"

        Set-WhisperSubtitleConfig -BaseLocation $initialBaseLocation
        Set-WhisperSubtitleConfig -TempPath $newTempPath

        $config = Get-WhisperSubtitleConfig
        $config.BaseLocation | Should Be $initialBaseLocation
        $config.TempPath | Should Be $newTempPath
    }

    It "should return default values if no config file exists" {
        # Remove config file to simulate no existing config
        $modulePath = Join-Path (Split-Path $PSScriptRoot) '..'
        $configFilePath = Join-Path $modulePath 'ModuleConfig.json'
        if (Test-Path $configFilePath) {
            Remove-Item $configFilePath -Force
        }

        # Re-import module to load default config
        Import-Module (Join-Path $modulePath 'WhisperSubtitle.psm1') -Force

        $config = Get-WhisperSubtitleConfig
        $config.BaseLocation | Should Not BeNullOrEmpty()
        $config.TempPath | Should Not BeNullOrEmpty()
        $config.SubtitleEditPath | Should Not BeNullOrEmpty()
    }
}