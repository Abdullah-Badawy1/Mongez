# Mongez on Windows — Porting & Setup Guide

This guide is what you do **if you need to move the whole project onto a
Windows machine and run it end-to-end**: backend (Django REST API in
Docker), web dashboard (React + Vite), and the Flutter mobile app.

The codebase has no Linux-only code — everything runs through Docker
Desktop (the container itself stays Linux). The only adjustments are
**toolchain**, **path/line-ending hygiene**, and **launcher script**.

---

## 1. TL;DR — the minimum you need installed

| Tool | Why | Where |
|---|---|---|
| **Windows 10/11** with WSL2 enabled | Docker Desktop's backend | `wsl --install` in an admin PowerShell |
| **Docker Desktop for Windows** | Runs the backend container | <https://www.docker.com/products/docker-desktop> |
| **Git for Windows** | Clones the repo, ships Git Bash | <https://git-scm.com/download/win> |
| **Python 3.11+** | Optional — used by `start.ps1` to mint a SECRET_KEY | <https://www.python.org/downloads/windows/> (tick *Add to PATH*) |
| **Node.js 18+** | Builds and serves the React dashboard | <https://nodejs.org> (LTS) |
| **Flutter SDK (Windows)** | Mobile app | <https://docs.flutter.dev/get-started/install/windows> |
| **PowerShell 5.1+** | Runs `start.ps1` | Built into Windows |

Optional but recommended:

* **Windows Terminal** — better terminal than the old `cmd.exe`/PowerShell console.
* **VS Code** with the *Docker*, *Python*, *Dart*, *Flutter*, and *ESLint* extensions.

---

## 2. Step-by-step setup

### 2.1 Enable WSL2 and install Docker Desktop

```powershell
# In an elevated (admin) PowerShell:
wsl --install
# reboot when asked, then verify
wsl --status      # should report 'Default Version: 2'
```

Install **Docker Desktop**, open it, and confirm:

* Settings → General → **Use the WSL 2 based engine** ✓
* Settings → Resources → WSL Integration → enable the distro you use (Ubuntu is fine).

Test:

```powershell
docker version
docker compose version
```

### 2.2 Clone the repo

Pick a path **without spaces and not too deep** (Docker volume mounts on
Windows are happier with short paths):

```powershell
mkdir C:\src
cd    C:\src
git clone https://github.com/Abdullah-Badawy1/Mongez.git
cd Mongez
```

### 2.3 Configure environment

```powershell
Copy-Item .env.example .env
# Open .env in any editor and at minimum set:
#   DJANGO_SECRET_KEY=<a real 50-char secret>
#   DJANGO_DEBUG=false
#   DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
```

The launcher (`start.ps1`) generates a `DJANGO_SECRET_KEY` for you on
first run if Python is on PATH.

### 2.4 Launch with the PowerShell script

The repository ships `start.ps1`, a one-shot launcher that mirrors the
Linux `start.sh`:

```powershell
# Backend only:
./start.ps1

# Full local stack (backend + dashboard + mobile + test accounts):
./start.ps1 -All

# Common combinations:
./start.ps1 -Seed -Dashboard          # backend + dashboard, seeded
./start.ps1 -Rebuild -Seed -Dashboard # rebuild image, seed, run dashboard
./start.ps1 -Stop                     # stop backend + dashboard
./start.ps1 -Down                     # stop and DELETE database/uploads
./start.ps1 -Status                   # show docker compose ps
./start.ps1 -FollowLogs               # tail backend logs
```

First-run permissions — Windows blocks unsigned scripts by default:

```powershell
# In the SAME PowerShell session (no admin needed):
Set-ExecutionPolicy -Scope Process Bypass
./start.ps1
```

If you want it persistent for the current user (one time, no admin):

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

## 3. What lands where after `start.ps1 -All`

| Surface | URL / how to reach it |
|---|---|
| Django REST API   | <http://localhost:8000/api/> |
| Health check      | <http://localhost:8000/api/health/> |
| Dashboard (Vite dev server) — landing + admin console | <http://localhost:5173/> |
| Mobile (`flutter run`) | A device window or the device picker prompt |

Test accounts (only with `-Seed`):

| Role   | Username | Password         |
|--------|----------|------------------|
| client | client1  | ClientPass123    |
| worker | worker1  | WorkerPass123    |
| admin  | admin1   | AdminPass123     |

---

## 4. Windows-specific gotchas (and the fixes)

### 4.1 Line endings — `entrypoint.sh` must stay LF

The Docker container runs Linux, and `entrypoint.sh` is the first thing
it executes. If Git converts it to CRLF on checkout, the container errors
with `bad interpreter` or `command not found: $'\r'`.

The repo's `.gitattributes` will prevent this if it exists. To be safe:

```powershell
git config --global core.autocrlf input
# already-checked-out file? force LF:
git checkout-index --force -- entrypoint.sh
# or in WSL/Git Bash:
dos2unix entrypoint.sh
```

### 4.2 Drive letters in volume paths

Docker Desktop translates `C:\src\Mongez` automatically in
`docker-compose.yml` mounts (the named volumes `sqlite_data` and
`media_data` keep everything inside Docker's managed area, so this
mostly doesn't matter). If you change the compose file to a bind mount
to a host folder, use Unix-style paths:

```yaml
volumes:
  - /c/src/Mongez/data:/app/data       # Docker Desktop accepts this
  # or
  - ./data:/app/data                   # relative — safest
```

### 4.3 Ports already in use

Windows often has process-level reservations. If `docker compose up`
fails with `Ports are not available`:

```powershell
# Find what holds :8000 or :5173:
netstat -ano | findstr :8000
netstat -ano | findstr :5173
# kill it (replace 12345 with the PID from the last column):
Stop-Process -Id 12345 -Force
```

### 4.4 Antivirus / Windows Defender slowing builds

If `docker compose build` or `npm install` is glacial, add exclusions:

* `C:\src\Mongez`
* `%USERPROFILE%\.docker`
* The WSL distro's filesystem root (`\\wsl$\Ubuntu`)

Defender → Virus & threat protection → Manage settings → Exclusions.

### 4.5 Long paths

Some node_modules paths exceed Windows' default 260-char limit.

```powershell
# Once, admin PowerShell:
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
  -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
git config --system core.longpaths true
```

### 4.6 npm scripts vs zsh/bash dev hooks

The Linux `start.sh` uses bash features. Don't try to run it from
PowerShell — use **`start.ps1`** (or run `start.sh` inside Git Bash /
WSL2 if you prefer).

### 4.7 Flutter SDK PATH

After installing Flutter, add it to PATH:

```powershell
# System → Advanced → Environment Variables → Path → add:
C:\src\flutter\bin
```

Verify:

```powershell
flutter --version
flutter doctor      # follow whatever it asks (Android Studio, etc.)
```

For Windows desktop targets:

```powershell
flutter config --enable-windows-desktop
flutter devices     # 'Windows' should appear
```

### 4.8 Mobile networking from the host

| Target | `ApiConstants.baseUrl` |
|---|---|
| Windows desktop, browser | `http://127.0.0.1:8000/api/` |
| Android emulator (AVD)   | `http://10.0.2.2:8000/api/` |
| Physical Android on Wi-Fi | `http://<your-LAN-IP>:8000/api/` |
| iOS — needs a Mac        | n/a |

If you use the LAN IP, also add it to `DJANGO_ALLOWED_HOSTS` in `.env`.

---

## 5. Running each piece manually (no script)

Sometimes you just want to run one surface. Mapping of `start.ps1` → manual commands:

### Backend only

```powershell
docker compose up -d --build web
docker compose logs -f web
docker compose down            # stop
docker compose down -v         # stop + wipe (DESTRUCTIVE)
```

### Dashboard only

```powershell
cd front
Copy-Item .env.example .env    # first time
npm install
npm run dev                    # http://localhost:5173
# build a deploy bundle:
npm run build                  # outputs to front\dist
# preview that bundle:
npm run preview
```

### Mobile only

```powershell
cd mobile
flutter pub get
flutter run -d windows         # Windows desktop
flutter run -d chrome          # web preview
flutter run                    # asks for the device
flutter build apk --release    # release APK in build\app\outputs\flutter-apk
flutter build windows          # MSIX/EXE in build\windows\runner\Release
```

### Seed test accounts

```powershell
docker compose exec web python manage.py shell
```

Paste the same accounts block from `start.ps1`'s `-Seed` block, or just
re-run `./start.ps1 -Seed`.

---

## 6. Deploying from Windows

| Surface | How |
|---|---|
| Backend container | `docker compose -f docker-compose.yml -f docker-compose.override.yml build` → push the resulting image to a registry, deploy on any Linux host. |
| Dashboard         | `cd front; npm run build` → `firebase deploy --only hosting` (the repo ships `firebase.json`). Or zip `front\dist` and serve from any static host (S3, Nginx, GitHub Pages, etc.). |
| Mobile (Android)  | `flutter build apk --release` or `flutter build appbundle` → publish to Google Play. |
| Mobile (Windows desktop) | `flutter build windows` → ship the contents of `build\windows\runner\Release`. |
| Mobile (iOS)      | Not possible on Windows — requires macOS + Xcode. |

---

## 7. Quick reference — Linux/macOS → Windows command map

| Linux/macOS | Windows PowerShell |
|---|---|
| `./start.sh`                    | `./start.ps1` |
| `./start.sh --all`              | `./start.ps1 -All` |
| `./start.sh --seed --dashboard` | `./start.ps1 -Seed -Dashboard` |
| `./start.sh --stop`             | `./start.ps1 -Stop` |
| `./start.sh --down`             | `./start.ps1 -Down` |
| `cp .env.example .env`          | `Copy-Item .env.example .env` |
| `tail -f .dashboard.log`        | `Get-Content -Wait .dashboard.log` |
| `kill 12345`                    | `Stop-Process -Id 12345 -Force` |
| `chmod +x start.sh`             | not needed |
| `nano .env`                     | `notepad .env` |

---

## 8. Troubleshooting one-liners

| Symptom | What to try |
|---|---|
| `cannot connect to the Docker daemon` | Start Docker Desktop, wait for the green light, retry. |
| `Ports are not available: bind: address already in use` | `netstat -ano \| findstr :8000` → `Stop-Process -Id <pid> -Force`. |
| `entrypoint.sh: not found` inside container | Fix CRLF endings (§4.1). |
| `Set-ExecutionPolicy` error running `start.ps1` | `Set-ExecutionPolicy -Scope Process Bypass` then re-run. |
| `npm install` hangs forever | Add Defender exclusion for the repo and `node_modules`. |
| `flutter doctor` complains about Android licenses | `flutter doctor --android-licenses`. |
| Dashboard loads but `/api` requests 404 | Backend isn't up — `./start.ps1 -Status`. |
| `kex_exchange_identification` when `git clone` | Use HTTPS clone URL instead of SSH, or import your SSH key into Pageant. |

---

## 9. Where the data lives on Windows

| What | Where |
|---|---|
| SQLite database  | Docker named volume `mongez_sqlite_data` — managed by Docker, **not** under your repo |
| Uploaded media   | Docker named volume `mongez_media_data` |
| Dashboard build  | `front\dist\` (regenerated each `npm run build`) |
| Mobile builds    | `mobile\build\` (regenerated each `flutter build …`) |
| `.env`           | `Mongez\.env`     (do **not** commit) |
| `front\.env`     | `Mongez\front\.env` (do **not** commit) |

Inspect Docker volumes:

```powershell
docker volume ls | findstr mongez
docker volume inspect mongez_sqlite_data
```

Backups (one-liner, dumps the SQLite file out of the volume):

```powershell
docker compose exec web cp /app/data/db.sqlite3 /app/media/backup-db.sqlite3
docker compose cp web:/app/media/backup-db.sqlite3 .\backup-db.sqlite3
```

---

## 10. Reading list for deeper changes

* [`README.md`](README.md) — the cross-platform quick start.
* [`all.md`](all.md) — comprehensive architecture reference for every component.
* [`docs/ARCHITECTURE.puml`](docs/ARCHITECTURE.puml) — UML source for system context, components, domain model, sequence flows.
* [`INSTALL.md`](INSTALL.md) — step-by-step generic install (mostly Linux but ports cleanly).
* [`CONTRIBUTING.md`](CONTRIBUTING.md) — branch policy, code style, PR rules.
