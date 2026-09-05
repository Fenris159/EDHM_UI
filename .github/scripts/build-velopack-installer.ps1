param(
    [Parameter(Mandatory)][string]$Version,
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z][A-Za-z0-9.-]{2,79}$')][string]$PackageId,
    [string]$Vpk = 'vpk'
)
$ErrorActionPreference = 'Stop'
$appRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../source_v3'))
$package = Get-Content -LiteralPath (Join-Path $appRoot 'package.json') -Raw | ConvertFrom-Json
if ($Version -ne $package.version) { throw 'Installer version must match package.json' }
$toolHelp = (& $Vpk --help | Out-String)
$toolVersion = [regex]::Match($toolHelp, 'Velopack CLI (\d+\.\d+\.\d+)').Groups[1].Value
if ($LASTEXITCODE -ne 0 -or $toolVersion -ne $package.dependencies.velopack) {
    throw "vpk must match the pinned Velopack SDK version: $($package.dependencies.velopack)"
}
$appDirectory = Join-Path $appRoot 'out/EDHM-UI-V3-win32-x64'
$outputDirectory = Join-Path $appRoot 'out/release/velopack'
$notes = Join-Path $appRoot 'out/release/notes/release-notes.md'
foreach ($file in @('EDHM-UI-V3.exe', 'resources/app.asar', 'resources/settings_window/settings.html',
    'resources/app.asar.unpacked/node_modules/velopack/lib/native/velopack_nodeffi_win_x64_msvc.node')) {
    if (-not (Test-Path -LiteralPath (Join-Path $appDirectory $file) -PathType Leaf)) { throw "Missing packaged file: $file" }
}
if (-not (Test-Path -LiteralPath $notes -PathType Leaf)) { throw 'Generate the matching EDHM release notes first' }
if ((Test-Path -LiteralPath $outputDirectory) -and (Get-ChildItem -LiteralPath $outputDirectory)) {
    throw 'Velopack output directory must be empty; use a clean build to prevent stale packages'
}
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
& $Vpk pack --packId $PackageId --packVersion $Version --packDir $appDirectory `
    --mainExe 'EDHM-UI-V3.exe' --packTitle $package.productName --packAuthors $package.author.name `
    --runtime win-x64 --outputDir $outputDirectory --releaseNotes $notes `
    --icon (Join-Path $appRoot 'src/images/Icon_v3_a0.ico') --noPortable --delta None `
    --shortcuts 'Desktop,StartMenuRoot' --yes --skip-updates
if ($LASTEXITCODE -ne 0) { throw "Velopack packaging failed: $LASTEXITCODE" }
$installers = @(Get-ChildItem -LiteralPath $outputDirectory -Filter '*-Setup.exe')
$packages = @(Get-ChildItem -LiteralPath $outputDirectory -Filter '*-full.nupkg')
if ($installers.Count -ne 1 -or $packages.Count -ne 1) { throw 'Expected one Velopack setup and one full package' }
Copy-Item -LiteralPath $installers[0].FullName -Destination (Join-Path $appRoot 'out/release/edhm-ui-v3-windows-x64.exe')
@{ packageId = $PackageId; appVersion = $Version; sdkVersion = $toolVersion; packageFile = $packages[0].Name } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outputDirectory 'build-info.json') -Encoding utf8
