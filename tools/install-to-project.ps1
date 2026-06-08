param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repo "addons/godex"
$project = Resolve-Path $ProjectPath
$addons = Join-Path $project "addons"
$target = Join-Path $addons "godex"
$uidBackup = Join-Path $env:TEMP "godex_uid_backup"

if (-not (Test-Path (Join-Path $project "project.godot"))) {
    throw "Target is not a Godot project: $project"
}
if (-not (Test-Path $source)) {
    throw "Godex addon source missing: $source"
}

New-Item -ItemType Directory -Force $addons | Out-Null
if (Test-Path $uidBackup) {
    Remove-Item -Recurse -Force $uidBackup
}
if (Test-Path $target) {
    $uidFiles = Get-ChildItem -Path $target -Recurse -Filter "*.uid" -ErrorAction SilentlyContinue
    foreach ($uid in $uidFiles) {
        $relative = $uid.FullName.Substring($target.Length).TrimStart("\", "/")
        $backupPath = Join-Path $uidBackup $relative
        New-Item -ItemType Directory -Force (Split-Path -Parent $backupPath) | Out-Null
        Copy-Item -Force $uid.FullName $backupPath
    }
    Remove-Item -Recurse -Force $target
}
Copy-Item -Recurse -Force $source $target
if (Test-Path $uidBackup) {
    Get-ChildItem -Path $uidBackup -Recurse -Filter "*.uid" | ForEach-Object {
        $relative = $_.FullName.Substring($uidBackup.Length).TrimStart("\", "/")
        $restorePath = Join-Path $target $relative
        New-Item -ItemType Directory -Force (Split-Path -Parent $restorePath) | Out-Null
        Copy-Item -Force $_.FullName $restorePath
    }
    Remove-Item -Recurse -Force $uidBackup
}

Write-Host "Installed Godex to $target"
