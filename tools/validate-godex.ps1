param(
    [string]$GodotPath = "E:/Program Files/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64_console.exe",
    [switch]$SkipGodot
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Assert-PathExists([string]$Path) {
    if (-not (Test-Path $Path)) {
        throw "Missing required path: $Path"
    }
}

function Assert-NoTrackedSecretSettings([string]$RepoRoot) {
    $trackedFiles = & git -C $RepoRoot ls-files
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to list tracked files for local settings leak validation"
    }

    $blockedExactPaths = @(
        "settings.json",
        "godex/settings.json",
        "userdata/godex/settings.json",
        "user/godex/settings.json",
        "addons/godex/settings.json",
        "addons/godex/settings.local.json",
        "docs/references/settings.json"
    )
    $blockedSuffixes = @(".local.json", ".secrets.json", ".secret.json")

    foreach ($file in $trackedFiles) {
        $normalized = ($file -replace "\\", "/").ToLowerInvariant()
        if ($blockedExactPaths -contains $normalized) {
            throw "Tracked personal Godex settings file is not allowed: $file"
        }
        foreach ($suffix in $blockedSuffixes) {
            if ($normalized.EndsWith($suffix)) {
                throw "Tracked local or secret settings file is not allowed: $file"
            }
        }
    }

    $textExtensions = @(".cfg", ".gd", ".json", ".md", ".ps1", ".toml", ".tres", ".tscn", ".txt", ".yaml", ".yml")
    $secretPatterns = @(
        @{ Name = "raw OpenAI-style API key"; Pattern = 'sk-[A-Za-z0-9]{20,}' },
        @{ Name = "raw bearer token"; Pattern = 'Authorization:\s*Bearer\s+(?!\*\*\*\*|\[redacted\]|<redacted>|redacted|REDACTED)[A-Za-z0-9._-]{24,}' },
        @{ Name = "inline JSON API key"; Pattern = '"api(?:_?key|Key)"\s*:\s*"(?!\s*"|\{env:|OPENAI_|YUREN_|AZURE_|GODEX_TEST_|<|\[redacted\]|redacted|REDACTED)[^"]{24,}"' }
    )

    foreach ($file in $trackedFiles) {
        $extension = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
        if ($textExtensions -notcontains $extension) {
            continue
        }

        $path = Join-Path $RepoRoot $file
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        $content = Get-Content -LiteralPath $path -Encoding UTF8 -Raw
        foreach ($entry in $secretPatterns) {
            if ($content -match $entry.Pattern) {
                throw "Potential secret leak in tracked file '$file': $($entry.Name)"
            }
        }
    }
}

Assert-PathExists "project.godot"
Assert-PathExists "addons/godex/plugin.cfg"
Assert-PathExists "addons/godex/plugin.gd"
Assert-PathExists "addons/godex/ui/godex_main.tscn"
Assert-PathExists "addons/godex/core/agent_service.gd"
Assert-NoTrackedSecretSettings $repo

$pluginCfg = Get-Content -Encoding UTF8 "addons/godex/plugin.cfg" -Raw
if ($pluginCfg -notmatch 'name="Godex"') {
    throw "plugin.cfg must name the plugin Godex"
}
if ($pluginCfg -notmatch 'script="plugin.gd"') {
    throw "plugin.cfg must point to plugin.gd"
}

$plugin = Get-Content -Encoding UTF8 "addons/godex/plugin.gd" -Raw
if ($plugin -notmatch "_has_main_screen") {
    throw "plugin.gd must expose a Godot editor main screen"
}
if ($plugin -notmatch 'return "Godex"') {
    throw "plugin.gd must return the Godex main screen name"
}
if ($plugin -notmatch 'godex_dock_controller\.gd' -or $plugin -notmatch 'CACHE_MODE_IGNORE') {
    throw "plugin.gd must cache-bust both the main scene and controller script for editor reload validation"
}

$scene = Get-Content -Encoding UTF8 "addons/godex/ui/godex_main.tscn" -Raw
foreach ($nodeName in @("SidebarPanel", "MainPanel", "ComposerPanel", "RightRail", "ProgressSection", "OutputSection", "SubAgentsSection", "SourcesSection")) {
    if ($scene -notmatch "name=`"$nodeName`"") {
        throw "godex_main.tscn missing node $nodeName"
    }
}

$controller = Get-Content -Encoding UTF8 "addons/godex/ui/godex_dock_controller.gd" -Raw
foreach ($servicePath in @("core/godex_state.gd", "core/agent_service.gd", "core/settings_store.gd", "core/session_store.gd")) {
    if ($controller -notmatch [regex]::Escape($servicePath) -or $controller -notmatch "CACHE_MODE_IGNORE") {
        throw "godex_dock_controller.gd must cache-bust service script loading for editor reload validation"
    }
}
foreach ($transportNeedle in @("_openai_request", "_start_openai_transport", "_on_openai_request_completed", "handle_model_http_result")) {
    if ($controller -notmatch $transportNeedle) {
        throw "godex_dock_controller.gd must wire OpenAI HTTP transport: $transportNeedle"
    }
}

$agent = Get-Content -Encoding UTF8 "addons/godex/core/agent_service.gd" -Raw
foreach ($servicePath in @("core/context_compressor.gd", "core/openai_execution_service.gd", "core/subagent_manager.gd", "core/mcp_client.gd", "core/approval_policy.gd", "core/command_capability.gd")) {
    if ($agent -notmatch [regex]::Escape($servicePath) -or $agent -notmatch "CACHE_MODE_IGNORE") {
        throw "agent_service.gd must cache-bust mutable dependency loading for editor reload validation"
    }
}

if (-not $SkipGodot) {
    if (-not (Test-Path $GodotPath)) {
        throw "Godot executable not found: $GodotPath"
    }
    $logDir = Join-Path $repo ".tmp"
    New-Item -ItemType Directory -Force $logDir | Out-Null
    $logPath = Join-Path $logDir "godot-headless.log"
    $stdoutPath = Join-Path $logDir "godot-headless.stdout.log"
    $stderrPath = Join-Path $logDir "godot-headless.stderr.log"
    if (Test-Path $stdoutPath) { Remove-Item -LiteralPath $stdoutPath -Force }
    if (Test-Path $stderrPath) { Remove-Item -LiteralPath $stderrPath -Force }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/d /c `"`"$GodotPath`" --headless --log-file `"$logPath`" --path `"$repo`" --script `"res://addons/godex/tests/headless_smoke_test.gd`" > `"$stdoutPath`" 2> `"$stderrPath`"`""
    $psi.WorkingDirectory = $repo
    $psi.UseShellExecute = $false
    $process = [System.Diagnostics.Process]::Start($psi)
    if (-not $process.WaitForExit(60000)) {
        try { $process.Kill() } catch {}
        throw "Godot headless smoke test timed out after 60 seconds"
    }
    $exitCode = $process.ExitCode
    $stdout = if (Test-Path $stdoutPath) { Get-Content -Encoding UTF8 $stdoutPath -Raw } else { "" }
    $stderr = if (Test-Path $stderrPath) { Get-Content -Encoding UTF8 $stderrPath -Raw } else { "" }
    if (-not [string]::IsNullOrWhiteSpace($stdout)) { Write-Host $stdout.TrimEnd() }
    if (-not [string]::IsNullOrWhiteSpace($stderr)) { Write-Host $stderr.TrimEnd() }
    $joinedOutput = "$stdout`n$stderr"
    if ($exitCode -ne 0) {
        throw "Godot headless smoke test failed with exit code $exitCode"
    }
    if ($joinedOutput -match "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script") {
        throw "Godot headless smoke test emitted script errors"
    }
}

Write-Host "Godex validation passed."
