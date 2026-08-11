# Claude Code usage aggregator
# Reads all local transcript files and summarizes token usage + estimated cost
# Run from anywhere: pwsh usage.ps1

$transcriptBase = "$env:USERPROFILE\.claude\projects"

if (-not (Test-Path $transcriptBase)) {
    Write-Host "No transcripts found at $transcriptBase"
    exit 1
}

$files = Get-ChildItem -Path $transcriptBase -Recurse -Filter "*.jsonl" | Sort-Object LastWriteTime

$totalInput = [long]0; $totalOutput = [long]0
$totalCacheCreate = [long]0; $totalCacheRead = [long]0
$byModel = @{}; $byDay = @{}; $byProject = @{}; $sessions = @{}

foreach ($file in $files) {
    $projectDir = $file.Directory.Name
    if ($projectDir -eq "subagents") { $projectDir = $file.Directory.Parent.Name }

    $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        if ($line -notmatch '"usage"') { continue }
        try { $obj = $line | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { continue }
        $u = $obj.message.usage
        if (-not $u) { continue }

        $inp   = [long]($u.input_tokens ?? 0)
        $out   = [long]($u.output_tokens ?? 0)
        $cc    = [long]($u.cache_creation_input_tokens ?? 0)
        $cr    = [long]($u.cache_read_input_tokens ?? 0)
        $model = [string]($obj.message.model ?? "unknown")
        $ts    = [string]($obj.timestamp ?? "")
        $day   = if ($ts.Length -ge 10) { $ts.Substring(0,10) } else { "unknown" }
        $sid   = [string]($obj.session_id ?? $obj.sessionId ?? "unknown")

        $totalInput += $inp; $totalOutput += $out
        $totalCacheCreate += $cc; $totalCacheRead += $cr

        foreach ($key in @($model, $day, $projectDir)) {
            $map = switch ($key) { $model { $byModel } $day { $byDay } $projectDir { $byProject } }
            if (-not $map.ContainsKey($key)) { $map[$key] = @{inp=[long]0;out=[long]0;cc=[long]0;cr=[long]0} }
            $map[$key].inp += $inp; $map[$key].out += $out
            $map[$key].cc  += $cc;  $map[$key].cr  += $cr
        }
        $sessions[$sid] = 1
    }
}

# Pricing per million tokens — Sonnet 4.6 rates
# Adjust if you use a different model primarily
$priceInp = 3.0/1e6; $priceOut = 15.0/1e6; $priceCW = 3.75/1e6; $priceCR = 0.30/1e6
function Cost($inp,$out,$cc,$cr) { $inp*$priceInp + $out*$priceOut + $cc*$priceCW + $cr*$priceCR }

$totalCost = Cost $totalInput $totalOutput $totalCacheCreate $totalCacheRead

Write-Host ""
Write-Host "=== CLAUDE CODE USAGE — ALL TIME ==="
Write-Host "  Sessions:           $($sessions.Count)  ($($files.Count) transcript files)"
Write-Host ("  Input tokens:       {0,15:N0}" -f $totalInput)
Write-Host ("  Output tokens:      {0,15:N0}" -f $totalOutput)
Write-Host ("  Cache write tokens: {0,15:N0}" -f $totalCacheCreate)
Write-Host ("  Cache read tokens:  {0,15:N0}" -f $totalCacheRead)
Write-Host ("  Est. cost:          `${0:F2}" -f $totalCost)

Write-Host ""
Write-Host "=== BY MODEL ==="
$byModel.GetEnumerator() | Where-Object { $_.Key -ne "<synthetic>" } |
    Sort-Object { $_.Value.out } -Descending | ForEach-Object {
    $c = Cost $_.Value.inp $_.Value.out $_.Value.cc $_.Value.cr
    "  {0,-40}  out={1,10:N0}  est=`${2:F2}" -f $_.Key, $_.Value.out, $c
}

Write-Host ""
Write-Host "=== BY DAY ==="
$byDay.GetEnumerator() | Where-Object { $_.Key -ne "unknown" } | Sort-Object Name | ForEach-Object {
    $c = Cost $_.Value.inp $_.Value.out $_.Value.cc $_.Value.cr
    "  {0}  out={1,8:N0}  cache_r={2,12:N0}  est=`${3:F2}" -f $_.Key, $_.Value.out, $_.Value.cr, $c
}

Write-Host ""
Write-Host "=== BY PROJECT (top 15) ==="
$byProject.GetEnumerator() | Sort-Object { $_.Value.out } -Descending | Select-Object -First 15 | ForEach-Object {
    $c = Cost $_.Value.inp $_.Value.out $_.Value.cc $_.Value.cr
    "  {0,-55}  out={1,9:N0}  est=`${2:F2}" -f $_.Key, $_.Value.out, $c
}

Write-Host ""
