param([Parameter(Mandatory)][string]$Version)
$ErrorActionPreference = 'Stop'
$appRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../source_v3'))
$package = Get-Content -LiteralPath (Join-Path $appRoot 'package.json') -Raw | ConvertFrom-Json
if ($Version -ne $package.version) { throw 'Requested installer version does not match package.json' }
$tool = Join-Path $env:AdvancedInstallerRoot 'bin/x86/AdvancedInstaller.com'
if (-not (Test-Path -LiteralPath $tool)) { throw 'Advanced Installer was not deployed' }
$installerDir = Join-Path $appRoot 'out/Installer'
$projectPath = Join-Path $installerDir 'EDHM-UI-V3.ci.aip'
$appDirectory = Join-Path $appRoot 'out/EDHM-UI-V3-win32-x64'
$outputDirectory = Join-Path $appRoot 'out/release'
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

# Work on a copy next to the original so its relative resource paths still resolve.
[xml]$project = Get-Content -LiteralPath (Join-Path $installerDir 'EDHM-UI-V3.aip') -Raw
# This fork test has no signing certificate. Never use the author's workstation certificate path.
foreach ($row in @($project.SelectNodes('//COMPONENT[@cid="caphyon.advinst.msicomp.DigCertStoreComponent"]/ROW'))) {
  $row.ParentNode.RemoveChild($row) | Out-Null
}
foreach ($row in $project.SelectNodes('//ROW[@DigSign]')) { $row.SetAttribute('DigSign', 'false') }
$project.Save($projectPath)

function Invoke-Installer([string[]]$Arguments) {
  & $tool @Arguments
  if ($LASTEXITCODE -ne 0) { throw "Advanced Installer failed with exit code $LASTEXITCODE" }
}

# Remove obsolete file entries (old bundle names and Vite hashes) from the CI copy.
# The following sync adds this build's actual files while retaining existing file IDs,
# shortcut targets, upgrade identity, install location and installer UI.
$directories = @{}
foreach ($row in $project.SelectNodes('//COMPONENT[@cid="caphyon.advinst.msicomp.MsiDirsComponent"]/ROW')) {
  $directories[$row.Directory] = $row
}
$components = @{}
foreach ($row in $project.SelectNodes('//COMPONENT[@cid="caphyon.advinst.msicomp.MsiCompsComponent"]/ROW')) {
  $components[$row.Component] = $row
}
function Get-TargetFolder([string]$Id) {
  if ($Id -eq 'APPDIR') { return 'APPDIR' }
  $directory = $directories[$Id]
  if (-not $directory) { throw "Unknown installer directory: $Id" }
  $name = ($directory.DefaultDir -split '\|')[-1]
  return (Get-TargetFolder $directory.Directory_Parent) + '\' + $name
}
foreach ($row in @($project.SelectNodes('//COMPONENT[@cid="caphyon.advinst.msicomp.MsiFilesComponent"]/ROW'))) {
  $source = [System.IO.Path]::GetFullPath((Join-Path $installerDir $row.SourcePath))
  if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    $folder = Get-TargetFolder $components[$row.Component_].Directory_
    $name = ($row.FileName -split '\|')[-1]
    Invoke-Installer @('/edit', $projectPath, '/DelFile', "$folder\$name")
  }
}
Invoke-Installer @('/edit', $projectPath, '/SetVersion', $Version)
Invoke-Installer @('/edit', $projectPath, '/NewSync', 'APPDIR', $appDirectory, '-existingfiles', 'keep')
Invoke-Installer @('/edit', $projectPath, '/SetOutputLocation', '-buildname', 'DefaultBuild', '-path', $outputDirectory)
Invoke-Installer @('/rebuild', $projectPath, '-buildslist', 'DefaultBuild')
$output = Join-Path $outputDirectory 'edhm-ui-v3-windows-x64.exe'
if (-not (Test-Path -LiteralPath $output -PathType Leaf)) { throw 'Expected upstream-named Windows installer was not produced' }
Write-Output "Built $output for app version $Version"
