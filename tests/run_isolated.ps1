param(
    [string]$Godot = 'C:\Zekrui\Godot_v4.7.2-stable_win64_console.exe',
    [string[]]$Tests = @('test_npc_persistence.gd', 'test_npc_identity.gd', 'test_local_chat.gd', 'test_gameplay_mechanics.gd', 'test_ui_presentation.gd', 'test_mobile_ui.gd', 'test_title_screen.gd')
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$testRoot = Join-Path $projectRoot '.godot/qwen-test-project'
New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
# Shared source/assets, separate application name and user:// save location.
foreach ($folder in @('assets', 'Characters', 'data', 'scenes', 'scripts', 'shaders', 'tests', 'ui')) {
    $source = Join-Path $projectRoot $folder
    if (-not (Test-Path -LiteralPath $source)) { continue }
    $target = Join-Path $testRoot $folder
    if (-not (Test-Path -LiteralPath $target)) {
        New-Item -ItemType Junction -Path $target -Target $source | Out-Null
    }
}
$config = Get-Content -LiteralPath (Join-Path $projectRoot 'project.godot') -Raw
$config = $config.Replace('config/name="Snake Oil Salesman"', 'config/name="Snake Oil Salesman Integration Tests"')
[IO.File]::WriteAllText((Join-Path $testRoot 'project.godot'), $config)
Copy-Item -LiteralPath (Join-Path $projectRoot 'icon.svg') -Destination $testRoot -Force
New-Item -ItemType Directory -Force -Path (Join-Path $testRoot '.godot/ui_review') | Out-Null
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$testUserData = Join-Path $projectRoot '.godot/qwen-test-userdata'
New-Item -ItemType Directory -Force -Path $testUserData | Out-Null
try {
    # Godot's Windows OS adapter reads these process environment variables.
    # Keep test saves, editor settings and caches entirely inside the workspace.
    $env:APPDATA = $testUserData
    $env:LOCALAPPDATA = $testUserData
    $ErrorActionPreference = 'Continue' # Native stderr is logged; exit codes govern tests.
    $importLog = Join-Path $projectRoot '.godot/qwen-test-import.log'
    & $Godot --headless --path $testRoot --log-file $importLog --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Test project import failed' }
    if (Select-String -LiteralPath $importLog -Pattern 'SCRIPT ERROR|Parse Error|Compilation failed' -Quiet) {
        throw 'Test project import reported a script error'
    }
    foreach ($test in $Tests) {
        $testLog = Join-Path $projectRoot ".godot/$test.log"
        & $Godot --headless --path $testRoot --log-file $testLog --script "tests/$test"
        $testExitCode = $LASTEXITCODE
        if (Select-String -LiteralPath $testLog -Pattern 'SCRIPT ERROR|Parse Error|Compilation failed' -Quiet) {
            throw "$test reported a script error"
        }
        if ($test -eq 'test_llm_connection.gd' -and $testExitCode -eq 2 -and
            (Select-String -LiteralPath $testLog -Pattern '^SKIPPED:' -Quiet)) {
            Write-Output 'Live inference SKIPPED; this is not a passing inference test.'
            continue
        }
        if ($testExitCode -ne 0) { throw "$test exited with $testExitCode" }
        if ($test -eq 'test_npc_persistence.gd') {
            # Save -> actual Quit -> a fresh Godot process -> actual Continue.
            foreach ($phase in @('write-process-fixture', 'read-process-fixture')) {
                $phaseLog = Join-Path $projectRoot ".godot/$test.$phase.log"
                & $Godot --headless --path $testRoot --log-file $phaseLog --script "tests/$test" -- "--$phase"
                $phaseExitCode = $LASTEXITCODE
                if ($phaseExitCode -ne 0 -or (Select-String -LiteralPath $phaseLog -Pattern 'SCRIPT ERROR|Parse Error|Compilation failed' -Quiet)) {
                    throw "$test $phase failed (exit $phaseExitCode)"
                }
            }
        }
    }
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
