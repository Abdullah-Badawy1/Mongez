<#
.SYNOPSIS
    Mongez — one-shot launcher for the whole platform on Windows.

.DESCRIPTION
    Windows PowerShell equivalent of start.sh.

    Runs:
      * Backend    — Django REST API in Docker Desktop (always)
      * Dashboard  — React + Vite dev server           (-Dashboard, background job)
      * Mobile     — `flutter run` against the backend (-Mobile, foreground)

    Requires:
      * Docker Desktop for Windows with WSL2 backend
      * PowerShell 5.1+ (built-in) or PowerShell 7+
      * Node.js 18+    (for -Dashboard)
      * Flutter SDK    (for -Mobile)
      * Python 3       (optional — used to mint a fresh DJANGO_SECRET_KEY)

.PARAMETER Rebuild
    Force a clean Docker image rebuild.

.PARAMETER Seed
    Create test accounts (client1 / worker1 / admin1).

.PARAMETER Dashboard
    Start the React dashboard dev server (front/) on http://localhost:5173.

.PARAMETER Mobile
    Run `flutter run` for the mobile app after the backend is healthy.

.PARAMETER All
    Shorthand for -Seed -Dashboard -Mobile.

.PARAMETER FollowLogs
    Stream backend logs (`docker compose logs -f web`) after start.

.PARAMETER Stop
    Stop backend and dashboard. Volumes preserved.

.PARAMETER Down
    Stop and wipe Docker volumes. DESTROYS database and uploaded files.

.PARAMETER Status
    Show container + health status and exit.

.EXAMPLE
    ./start.ps1

.EXAMPLE
    ./start.ps1 -Rebuild -Seed -Dashboard -FollowLogs

.EXAMPLE
    ./start.ps1 -All

.EXAMPLE
    ./start.ps1 -Stop
#>

[CmdletBinding()]
param(
    [switch]$Rebuild,
    [switch]$Seed,
    [switch]$Dashboard,
    [switch]$Mobile,
    [switch]$All,
    [switch]$FollowLogs,
    [switch]$Stop,
    [switch]$Down,
    [switch]$Status
)

$ErrorActionPreference = 'Stop'

# ── Paths ────────────────────────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $ScriptDir

$EnvFile             = ".env"
$EnvExample          = ".env.example"
$ComposeService      = "web"
$ContainerName       = "mongez-backend"
$HealthUrl           = "http://localhost:8000/api/health/"
$WorkersUrl          = "http://localhost:8000/api/workers/"

$DashboardDir        = "front"
$DashboardEnvFile    = Join-Path $DashboardDir ".env"
$DashboardEnvExample = Join-Path $DashboardDir ".env.example"
$DashboardPidFile    = ".dashboard.pid"
$DashboardLogFile    = ".dashboard.log"
$DashboardUrl        = "http://localhost:5173/"

# ── Coalesce -All into individual flags ─────────────────────────────────────
if ($All) { $Seed = $true; $Dashboard = $true; $Mobile = $true }

# ── Output helpers (ANSI when available, plain otherwise) ───────────────────
$Esc = [char]27
function Write-Step  { param([string]$Msg) Write-Host "${Esc}[1;36m→${Esc}[0m $Msg" }
function Write-Ok    { param([string]$Msg) Write-Host "${Esc}[1;32m✓${Esc}[0m $Msg" }
function Write-Warn  { param([string]$Msg) Write-Host "${Esc}[1;33m!${Esc}[0m $Msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$Msg) Write-Host "${Esc}[1;31m✗${Esc}[0m $Msg" -ForegroundColor Red }
function Die         { param([string]$Msg) Write-Fail $Msg; exit 1 }

# ── Prereqs ──────────────────────────────────────────────────────────────────
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Die "Docker Desktop is not installed or not on PATH. See WINDOWS.md."
}
& docker compose version *> $null
if ($LASTEXITCODE -ne 0) {
    Die "docker compose plugin not available. Update Docker Desktop."
}

# ── Helpers ──────────────────────────────────────────────────────────────────
function Stop-Dashboard {
    if (Test-Path $DashboardPidFile) {
        $pidValue = Get-Content $DashboardPidFile -Raw -ErrorAction SilentlyContinue
        if ($pidValue) {
            $procId = [int]$pidValue.Trim()
            $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Step "Stopping dashboard dev server (pid=$procId)..."
                # Kill the npm/node tree (vite + esbuild child).
                Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.Parent.Id -eq $procId } |
                    ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
                Write-Ok "Dashboard stopped."
            }
        }
        Remove-Item $DashboardPidFile -Force -ErrorAction SilentlyContinue
    }
}

function Wait-DashboardReady {
    for ($i = 0; $i -lt 60; $i++) {
        if (Test-Path $DashboardLogFile) {
            $log = Get-Content $DashboardLogFile -Raw -ErrorAction SilentlyContinue
            if ($log -and $log.Contains("Local:")) { return $true }
        }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

# ── Lifecycle shortcuts that exit early ─────────────────────────────────────
if ($Status) {
    docker compose ps
    exit 0
}

if ($Stop) {
    Write-Step "Stopping stack (volumes preserved)..."
    Stop-Dashboard
    docker compose down
    Write-Ok "Stopped."
    exit 0
}

if ($Down) {
    Write-Warn "This will DELETE the database and uploaded files."
    $ans = Read-Host "Type 'yes' to confirm"
    if ($ans -ne "yes") { Write-Warn "Aborted."; exit 1 }
    Stop-Dashboard
    docker compose down -v
    Write-Ok "Stopped and wiped."
    exit 0
}

# ── .env bootstrap ───────────────────────────────────────────────────────────
if (-not (Test-Path $EnvFile)) {
    if (Test-Path $EnvExample) {
        Write-Step "Creating $EnvFile from $EnvExample..."
        Copy-Item $EnvExample $EnvFile

        # Mint a real SECRET_KEY if Python is around.
        $py = Get-Command python -ErrorAction SilentlyContinue
        if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
        if ($py) {
            $key = & $py.Source -c "import secrets; print(secrets.token_urlsafe(50))"
            (Get-Content $EnvFile) `
                -replace '^DJANGO_SECRET_KEY=.*', "DJANGO_SECRET_KEY=$key" |
                Set-Content $EnvFile
            Write-Ok "Generated a fresh DJANGO_SECRET_KEY in $EnvFile"
        }
        else {
            Write-Warn "python not found — edit DJANGO_SECRET_KEY in $EnvFile manually."
        }
    }
    else {
        Die "Neither $EnvFile nor $EnvExample found."
    }
}

# ── Build (only if image missing, or -Rebuild) ──────────────────────────────
& docker image inspect mongez-backend:latest *> $null
$imagePresent = ($LASTEXITCODE -eq 0)

if ($Rebuild -or -not $imagePresent) {
    Write-Step "Building image (mongez-backend:latest)..."
    if ($Rebuild) {
        docker compose build --no-cache $ComposeService
    } else {
        docker compose build $ComposeService
    }
    if ($LASTEXITCODE -ne 0) { Die "Docker build failed." }
    Write-Ok "Image built."
}
else {
    Write-Ok "Image already present — skipping build (use -Rebuild to force)."
}

# ── Start ────────────────────────────────────────────────────────────────────
Write-Step "Starting container..."
docker compose up -d $ComposeService | Out-Null
Write-Ok "Container started."

# ── Wait for healthcheck ─────────────────────────────────────────────────────
Write-Step "Waiting for healthcheck to go green..."
$deadline = (Get-Date).AddSeconds(90)
$last = ""
while ($true) {
    $status = "missing"
    try {
        $status = (docker inspect --format='{{.State.Health.Status}}' $ContainerName 2>$null).Trim()
    } catch {}

    if ($status -ne $last) {
        Write-Host ("  [{0}] health={1}" -f (Get-Date -Format HH:mm:ss), $status)
        $last = $status
    }
    if ($status -eq "healthy") { Write-Ok "Healthy."; break }
    if ($status -eq "unhealthy") {
        Write-Fail "Container is unhealthy. Last 50 log lines:"
        docker compose logs --tail=50 $ComposeService
        exit 1
    }
    if ((Get-Date) -ge $deadline) {
        Write-Fail "Timed out waiting for healthy status. Recent logs:"
        docker compose logs --tail=50 $ComposeService
        exit 1
    }
    Start-Sleep -Seconds 2
}

# ── Confirm API reachable from host ──────────────────────────────────────────
try {
    Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 5 | Out-Null
    Write-Ok "API responding at $HealthUrl"
} catch {
    Write-Warn "Container is healthy but $HealthUrl is unreachable. Check port mapping."
}

# ── Optional: seed test accounts ─────────────────────────────────────────────
if ($Seed) {
    Write-Step "Seeding test accounts (client1 / worker1 / admin1)..."
    $seedScript = @'
from apps.users.models import User
accounts = [
    {"username":"client1","phone":"01000000001","email":"client1@mongez.local","password":"ClientPass123","role":User.Role.CLIENT,"name_ar":"عميل تجريبي"},
    {"username":"worker1","phone":"01000000002","email":"worker1@mongez.local","password":"WorkerPass123","role":User.Role.WORKER,"name_ar":"عامل تجريبي"},
    {"username":"admin1", "phone":"01000000003","email":"admin1@mongez.local", "password":"AdminPass123", "role":User.Role.ADMIN, "name_ar":"مشرف تجريبي"},
]
for a in accounts:
    u,created = User.objects.get_or_create(username=a["username"],
        defaults={"phone":a["phone"],"email":a["email"],"role":a["role"],"name_ar":a["name_ar"]})
    u.phone=a["phone"]; u.email=a["email"]; u.role=a["role"]; u.name_ar=a["name_ar"]
    u.set_password(a["password"])
    if a["role"]==User.Role.ADMIN: u.is_staff=True; u.is_superuser=True
    u.save()
    print(("created" if created else "updated") + ": " + u.username + " (role=" + u.role + ")")
'@
    $seedScript | docker compose exec -T $ComposeService python manage.py shell
    Write-Ok "Seed complete."
}

# ── Optional: launch dashboard (Vite dev server) ─────────────────────────────
$DashboardRunning = $false
if ($Dashboard) {
    if (-not (Test-Path $DashboardDir)) {
        Write-Warn "$DashboardDir not found — skipping -Dashboard."
    }
    elseif (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Warn "npm not on PATH — install Node 18+ then re-run with -Dashboard."
    }
    else {
        if (-not (Test-Path $DashboardEnvFile) -and (Test-Path $DashboardEnvExample)) {
            Write-Step "Creating $DashboardEnvFile from $DashboardEnvExample..."
            Copy-Item $DashboardEnvExample $DashboardEnvFile
        }

        $reusing = $false
        if (Test-Path $DashboardPidFile) {
            $oldPid = (Get-Content $DashboardPidFile -Raw).Trim()
            if ($oldPid -and (Get-Process -Id ([int]$oldPid) -ErrorAction SilentlyContinue)) {
                Write-Ok "Dashboard already running (pid=$oldPid) — skipping launch."
                $reusing = $true
                $DashboardRunning = $true
            }
        }

        if (-not $reusing) {
            Write-Step "Installing dashboard dependencies (idempotent)..."
            Push-Location $DashboardDir
            try { npm install --no-audit --no-fund --silent }
            finally { Pop-Location }

            Write-Step "Starting dashboard dev server (Vite) in background → $DashboardLogFile"
            # Out-File first to truncate, then the process appends.
            "" | Out-File $DashboardLogFile -Encoding utf8

            $args = @(
                "-NoLogo", "-NoProfile",
                "-Command",
                "Set-Location '$ScriptDir\$DashboardDir'; " +
                "npm run dev *>> '$ScriptDir\$DashboardLogFile'"
            )
            $proc = Start-Process powershell -ArgumentList $args -PassThru -WindowStyle Hidden
            $proc.Id | Out-File $DashboardPidFile -Encoding ascii

            if (Wait-DashboardReady) {
                try {
                    Invoke-WebRequest -Uri $DashboardUrl -UseBasicParsing -TimeoutSec 5 | Out-Null
                    Write-Ok "Dashboard responding at $DashboardUrl"
                    $DashboardRunning = $true
                } catch {
                    Write-Warn "Dashboard didn't answer. Tail ${DashboardLogFile} for details."
                }
            } else {
                Write-Warn "Vite didn't print 'Local:' in time. Tail ${DashboardLogFile} for details."
            }
        }
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "${Esc}[1;36m================ Mongez is up ================${Esc}[0m"
Write-Host "  API:       $HealthUrl" -ForegroundColor Green
Write-Host "  Workers:   $WorkersUrl" -ForegroundColor Green
if ($DashboardRunning) {
    Write-Host "  Dashboard: $DashboardUrl" -ForegroundColor Green
}
if ($Seed) {
    Write-Host ""
    Write-Host "  Test accounts:"
    Write-Host "    client : client1 / ClientPass123" -ForegroundColor Green
    Write-Host "    worker : worker1 / WorkerPass123" -ForegroundColor Green
    Write-Host "    admin  : admin1  / AdminPass123"  -ForegroundColor Green
}
Write-Host "${Esc}[1;36m===============================================${Esc}[0m"
Write-Host "Notes:" -ForegroundColor DarkGray
Write-Host "  • Stop:          ./start.ps1 -Stop      (stops backend + dashboard)"
Write-Host "  • Wipe data:     ./start.ps1 -Down"
Write-Host "  • Rebuild:       ./start.ps1 -Rebuild"
Write-Host "  • Backend logs:  docker compose logs -f web"
if ($DashboardRunning) {
    Write-Host "  • Dashboard logs: Get-Content -Wait $DashboardLogFile"
}
Write-Host "  • Android emu:   change mobile baseUrl to http://10.0.2.2:8000/api/"
Write-Host ""

# ── Optional: launch mobile ──────────────────────────────────────────────────
if ($Mobile) {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Warn "flutter not on PATH — skipping -Mobile. See WINDOWS.md."
    }
    elseif (-not (Test-Path "mobile")) {
        Write-Warn "mobile/ directory not found — skipping -Mobile."
    }
    else {
        Write-Step "Fetching Flutter packages..."
        Push-Location "mobile"
        try {
            flutter pub get
            Write-Step "Launching mobile app (flutter run)..."
            flutter run
        } finally { Pop-Location }
    }
}

# ── Optional: follow logs ────────────────────────────────────────────────────
if ($FollowLogs) {
    Write-Step "Following backend logs (Ctrl+C to detach — container keeps running)..."
    docker compose logs -f $ComposeService
}
