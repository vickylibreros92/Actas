# Construye la app y sube todo el proyecto a GitHub (vickylibreros92/Actas).
# El sitio web (Netlify u otro) publica la carpeta web/ de ese repositorio automáticamente.
# Uso: powershell -ExecutionPolicy Bypass -File .\publicar-web.ps1 [-Mensaje "texto"]
param([string]$Mensaje = '')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$remoto = 'https://github.com/vickylibreros92/Actas.git'
$git = "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"; if (-not (Test-Path $git)) { $git = (Get-Command git).Source }
$gh  = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GitHub.cli_*\bin\gh.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
if (-not $gh) { $gh = (Get-Command gh).Source }
$env:GH_PROMPT_DISABLED = '1'
$env:Path = (Split-Path $git) + ';' + $env:Path

& powershell -NoProfile -ExecutionPolicy Bypass -File "$root\build.ps1"
if ($LASTEXITCODE) { throw 'Falló la construcción' }

$owner = (& $gh api user --jq .login).Trim()
$id    = (& $gh api user --jq .id).Trim()
if (-not $owner) { throw 'No hay sesión de GitHub. Ejecute: gh auth login' }
& $gh auth setup-git | Out-Null

Set-Content -Path "$root\web\.nojekyll" -Value '' -Encoding ascii
Push-Location $root
try {
  if (-not (Test-Path "$root\.git")) {
    & $git init -q -b main
    & $git config user.name $owner
    & $git config user.email "$id+$owner@users.noreply.github.com"
    & $git remote add origin $remoto
  }
  & $git add -A
  if (& $git status --porcelain) {
    if (-not $Mensaje) { $Mensaje = 'Actualización ' + (Get-Date -Format 'yyyy-MM-dd HH:mm') }
    & $git commit -q -m $Mensaje -m 'Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>'
    & $git push -q -u origin main
    "Subido a $remoto"
  } else { 'Sin cambios para subir.' }
} finally { Pop-Location }
