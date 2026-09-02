param(
    [string]$WslDistro = "",
    [string]$ProjectPathInWsl = "~/Verkonhallinta"
)

$ErrorActionPreference = "Stop"

function Convert-SizeToMiB {
    param([string]$Value)

    if (-not $Value) { return 0.0 }

    $normalized = $Value.Trim()
    if ($normalized -match '^([0-9]*\.?[0-9]+)\s*(KiB|MiB|GiB|KB|MB|GB)$') {
        $num = [double]$Matches[1]
        $unit = $Matches[2]
        switch ($unit) {
            "KiB" { return $num / 1024.0 }
            "MiB" { return $num }
            "GiB" { return $num * 1024.0 }
            "KB"  { return $num / 1024.0 }
            "MB"  { return $num }
            "GB"  { return $num * 1024.0 }
            default { return 0.0 }
        }
    }

    return 0.0
}

function Invoke-Wsl {
    param([string]$Command)

    $wslArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($WslDistro)) {
        $wslArgs += @("-d", $WslDistro)
    }

    $wslArgs += @("-e", "bash", "-lc", $Command)
    return & wsl @wslArgs
}

Write-Output ""
Write-Output "========================================="
Write-Output " Verkonhallinta Memory Report"
Write-Output "========================================="
Write-Output ""

# ----------------------------------------------------
# Windows host memory
# ----------------------------------------------------

$os = Get-CimInstance Win32_OperatingSystem
$totalGiB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeGiB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedGiB = [math]::Round($totalGiB - $freeGiB, 2)
$usedPct = if ($totalGiB -gt 0) { [math]::Round(($usedGiB / $totalGiB) * 100, 1) } else { 0 }

Write-Output "[WINDOWS]"
Write-Output "Total RAM : $totalGiB GiB"
Write-Output "Used RAM  : $usedGiB GiB ($usedPct%)"
Write-Output "Free RAM  : $freeGiB GiB"
Write-Output ""

# ----------------------------------------------------
# WSL memory
# ----------------------------------------------------

$wslFree = Invoke-Wsl "free -m"
$memLine = $wslFree | Where-Object { $_ -match '^Mem:' }

$wslTotalMiB = 0.0
$wslUsedMiB = 0.0
$wslFreeMiB = 0.0

if ($memLine) {
    $parts = ($memLine -split '\s+') | Where-Object { $_ -ne "" }
    if ($parts.Count -ge 4) {
        $wslTotalMiB = [double]$parts[1]
        $wslUsedMiB = [double]$parts[2]
        $wslFreeMiB = [double]$parts[3]
    }
}

$wslTotalGiB = [math]::Round($wslTotalMiB / 1024.0, 2)
$wslUsedGiB = [math]::Round($wslUsedMiB / 1024.0, 2)
$wslFreeGiB = [math]::Round($wslFreeMiB / 1024.0, 2)
$wslUsedPct = if ($wslTotalMiB -gt 0) { [math]::Round(($wslUsedMiB / $wslTotalMiB) * 100, 1) } else { 0 }

Write-Output "[WSL]"
Write-Output "Total RAM : $wslTotalGiB GiB"
Write-Output "Used RAM  : $wslUsedGiB GiB ($wslUsedPct%)"
Write-Output "Free RAM  : $wslFreeGiB GiB"
Write-Output ""

# ----------------------------------------------------
# Docker memory per container (WSL)
# ----------------------------------------------------

$dockerCommand = "docker stats --no-stream --format '{{json .}}'"
if ([string]::IsNullOrWhiteSpace($WslDistro)) {
    $dockerStatsJson = & wsl -e bash -lc $dockerCommand
} else {
    $dockerStatsJson = & wsl -d $WslDistro -e bash -lc $dockerCommand
}

$rows = @()
$dockerTotalMiB = 0.0

foreach ($line in $dockerStatsJson) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }

    $obj = $line | ConvertFrom-Json
    $memRaw = [string]$obj.MemUsage
    $usedPart = ($memRaw -split ' / ')[0].Trim()
    $usedMiB = Convert-SizeToMiB -Value $usedPart

    $dockerTotalMiB += $usedMiB
    $rows += [PSCustomObject]@{
        Name = [string]$obj.Name
        MemUsage = $memRaw
        UsedMiB = [math]::Round($usedMiB, 2)
        Cpu = [string]$obj.CPUPerc
    }
}

$dockerTotalGiB = [math]::Round($dockerTotalMiB / 1024.0, 2)

Write-Output "[DOCKER IN WSL]"
Write-Output "Containers: $($rows.Count)"
Write-Output "Total RAM : $dockerTotalGiB GiB"
Write-Output ""

Write-Output "Top 10 containers by memory:"
$rows |
    Sort-Object UsedMiB -Descending |
    Select-Object -First 10 Name, MemUsage, Cpu |
    Format-Table -AutoSize |
    Out-String |
    Write-Output

# ----------------------------------------------------
# Quick sizing hint
# ----------------------------------------------------

$recommendation = ""
if ($dockerTotalGiB -lt 2) {
    $recommendation = "Nykyinen kuorma on kevyt. 16 GiB host toimii, 32 GiB suositus sujuvuuteen."
} elseif ($dockerTotalGiB -lt 4) {
    $recommendation = "Nykyinen kuorma on keskitaso. 32 GiB host suositeltu."
} else {
    $recommendation = "Nykyinen kuorma on raskas. 32-64 GiB host suositeltu kaytosta riippuen."
}

Write-Output "[ARVIO]"
Write-Output $recommendation
Write-Output ""
Write-Output "Vinkki: aja raportti ennen ja jalkeen labran deployn kuormituspiikkien arviointiin."
