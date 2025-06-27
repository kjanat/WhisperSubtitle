BeforeAll {
    $moduleRoot = (Get-Item -Path $PSScriptRoot).Directory.Parent.FullName
    Import-Module (Join-Path $moduleRoot 'WhisperSubtitle.psm1') -Force
}

Describe "Placeholder" {
    It "should be a placeholder test" {
        $true | Should -Be $true
    }
}