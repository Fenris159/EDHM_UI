# Installation tests must never run against the developer's machine.
$ErrorActionPreference = 'Stop'
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_ENVIRONMENT -ne 'github-hosted' -or -not $env:RUNNER_TEMP) {
    throw 'Run only on a disposable GitHub-hosted Windows runner'
}
$appRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../source_v3'))
$buildInfo = Get-Content (Join-Path $appRoot 'out/release/velopack/build-info.json') -Raw | ConvertFrom-Json
$testRoot = Join-Path $env:RUNNER_TEMP 'Velopack lifecycle Ω'
$installDir = Join-Path $testRoot 'App'
if (Test-Path -LiteralPath $testRoot) { throw 'Expected a fresh test directory' }
New-Item -ItemType Directory -Path $testRoot | Out-Null
function Run-Checked([string]$File, [string]$Arguments) {
    $process = Start-Process -FilePath $File -ArgumentList $Arguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(120000)) { $process.Kill(); throw "Timed out: $File" }
    if ($process.ExitCode -ne 0) { throw "Failed ($($process.ExitCode)): $File $Arguments" }
}
function Check-Payload {
    $source = Join-Path $appRoot 'out/EDHM-UI-V3-win32-x64'
    foreach ($file in Get-ChildItem -LiteralPath $source -Recurse -File) {
        if ($file.Extension -eq '.pdb') { continue }
        $relative = [IO.Path]::GetRelativePath($source, $file.FullName)
        $installed = Join-Path $installDir "current/$relative"
        if (-not (Test-Path -LiteralPath $installed -PathType Leaf)) { throw "Missing installed payload: $relative" }
        if ((Get-FileHash -LiteralPath $installed).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash) {
            throw "Installed payload mismatch: $relative"
        }
    }
}
$installer = Join-Path $appRoot 'out/release/edhm-ui-v3-windows-x64.exe'
Run-Checked $installer "--silent --installto `"$installDir`" --log `"$testRoot/install.log`""
Check-Payload
# Verify the real packaged Electron/native SDK bootstrap exits before app startup.
$stdout = Join-Path $testRoot 'hook.stdout.txt'
$stderr = Join-Path $testRoot 'hook.stderr.txt'
$process = Start-Process -FilePath (Join-Path $installDir 'current/EDHM-UI-V3.exe') `
    -ArgumentList '--veloapp-version' -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
if (-not $process.WaitForExit(30000)) { $process.Kill(); throw 'Velopack bootstrap did not exit before normal app startup' }
if ($process.ExitCode -ne 0 -or (Get-Content -LiteralPath $stdout -Raw).Trim() -ne $buildInfo.sdkVersion) {
    throw "Velopack bootstrap did not return the expected SDK version; see $testRoot"
}
$registration = Get-ItemProperty -LiteralPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($buildInfo.packageId)"
if ($registration.DisplayVersion -ne $buildInfo.appVersion) { throw 'Incorrect registered app version' }
foreach ($folder in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
    $shortcutPath = Join-Path $folder 'EDHM-UI-V3.lnk'
    if (-not (Test-Path -LiteralPath $shortcutPath)) { throw "Missing shortcut: $shortcutPath" }
}
# Full-installer updates remain the app's update mechanism; exercise a repeated install.
Run-Checked $installer "--silent --installto `"$installDir`" --log `"$testRoot/reinstall.log`""
Check-Payload
Run-Checked (Join-Path $installDir 'Update.exe') "uninstall --silent --log `"$testRoot/uninstall.log`""
if (Test-Path -LiteralPath (Join-Path $installDir 'current/EDHM-UI-V3.exe')) { throw 'Uninstall left the application executable' }
if (Test-Path -LiteralPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($buildInfo.packageId)") {
    throw 'Uninstall left the registration'
}
Write-Host 'Velopack payload, startup hook, registration, shortcuts, reinstall, and uninstall checks passed.'
