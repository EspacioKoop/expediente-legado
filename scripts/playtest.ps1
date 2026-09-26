param(
    [switch]$Force,
    [switch]$NoRun,
    [string]$InstallDir = "",
    [switch]$Help
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Repo = "EspacioKoop/expediente-legado"
$Channel = "playtest-latest"
$BaseUrl = "https://github.com/$Repo/releases/download/$Channel"
$Asset = "SIGA-98-playtest-windows.zip"
$Checksums = "SIGA-98-playtest-SHA256SUMS.txt"
$Metadata = "SIGA-98-playtest-build.json"

function Show-Usage {
    @"
SIGA-98 - actualizador de playtest para Windows

Uso:
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File Actualizar-SIGA98.ps1
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File Actualizar-SIGA98.ps1 -NoRun
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File Actualizar-SIGA98.ps1 -Force
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File Actualizar-SIGA98.ps1 -InstallDir C:\Ruta

Opciones:
  -Force       Vuelve a descargar aunque el SHA instalado coincida.
  -NoRun       Actualiza sin arrancar el juego.
  -InstallDir  Cambia la carpeta de instalacion.
  -Help        Muestra esta ayuda.

Por defecto instala en:
  %LOCALAPPDATA%\SIGA98\playtest
"@
}

if ($Help) {
    Show-Usage
    exit 0
}

if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $LocalAppData = [Environment]::GetFolderPath("LocalApplicationData")
    if ([string]::IsNullOrWhiteSpace($LocalAppData)) {
        throw "No se pudo resolver LOCALAPPDATA. Usa -InstallDir para elegir una carpeta."
    }
    $InstallDir = Join-Path $LocalAppData "SIGA98\playtest"
}

$InstallDir = [IO.Path]::GetFullPath($InstallDir)
$Executable = Join-Path $InstallDir "SIGA-98.exe"
$LocalMetadata = Join-Path $InstallDir ".playtest-build.json"

# GitHub requiere TLS moderno. Esto mantiene compatibilidad con Windows PowerShell 5.1.
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}
catch {
    # PowerShell 7+ no depende de ServicePointManager para HttpClient.
}

function Download-File {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile
    )

    Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $OutFile
}

function Read-BuildSha {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $Data = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        $Value = [string]$Data.sha
        if ($Value.Length -ge 7) {
            return $Value.Trim()
        }
    }
    catch {
        return ""
    }
    return ""
}

$TempDir = Join-Path ([IO.Path]::GetTempPath()) ("SIGA98-playtest-" + [Guid]::NewGuid().ToString("N"))
$Staging = "$InstallDir.staging.$PID"
$Backup = "$InstallDir.previous.$PID"

try {
    New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

    $RemoteMetadata = Join-Path $TempDir $Metadata
    Write-Host "Consultando la ultima alpha de playtest..."
    try {
        Download-File -Uri "$BaseUrl/$Metadata" -OutFile $RemoteMetadata
    }
    catch {
        throw "Todavia no hay un canal '$Channel' descargable o GitHub no responde. Revisa https://github.com/$Repo/actions"
    }

    $RemoteSha = Read-BuildSha -Path $RemoteMetadata
    if ([string]::IsNullOrWhiteSpace($RemoteSha)) {
        throw "Los metadatos remotos no contienen un SHA valido."
    }

    $LocalSha = ""
    if (Test-Path -LiteralPath $LocalMetadata) {
        $LocalSha = Read-BuildSha -Path $LocalMetadata
    }

    $NeedsUpdate = $Force -or ($LocalSha -ne $RemoteSha) -or -not (Test-Path -LiteralPath $Executable)

    if (-not $NeedsUpdate) {
        Write-Host ("Ya tienes la alpha actual: " + $RemoteSha.Substring(0, [Math]::Min(12, $RemoteSha.Length)))
    }
    else {
        $ZipPath = Join-Path $TempDir $Asset
        $ChecksumsPath = Join-Path $TempDir $Checksums

        Write-Host ("Descargando alpha " + $RemoteSha.Substring(0, [Math]::Min(12, $RemoteSha.Length)) + " para Windows...")
        Download-File -Uri "$BaseUrl/$Asset" -OutFile $ZipPath
        Download-File -Uri "$BaseUrl/$Checksums" -OutFile $ChecksumsPath

        $Expected = ""
        foreach ($Line in Get-Content -LiteralPath $ChecksumsPath -Encoding UTF8) {
            if ($Line -match "^([0-9a-fA-F]{64})\s+\*?SIGA-98-playtest-windows\.zip\s*$") {
                $Expected = $Matches[1].ToLowerInvariant()
                break
            }
        }
        if ([string]::IsNullOrWhiteSpace($Expected)) {
            throw "$Checksums no contiene checksum para $Asset."
        }

        $Actual = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($Actual -ne $Expected) {
            throw "Checksum SHA-256 invalido para $Asset. Esperado: $Expected; obtenido: $Actual"
        }

        $Parent = Split-Path -Parent $InstallDir
        if (-not [string]::IsNullOrWhiteSpace($Parent)) {
            New-Item -ItemType Directory -Force -Path $Parent | Out-Null
        }

        Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $Backup -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force -Path $Staging | Out-Null

        Expand-Archive -LiteralPath $ZipPath -DestinationPath $Staging -Force

        $StagedExecutable = Join-Path $Staging "SIGA-98.exe"
        if (-not (Test-Path -LiteralPath $StagedExecutable)) {
            throw "El paquete descargado no contiene SIGA-98.exe."
        }

        Copy-Item -LiteralPath $RemoteMetadata -Destination (Join-Path $Staging ".playtest-build.json") -Force

        $HadPrevious = Test-Path -LiteralPath $InstallDir
        if ($HadPrevious) {
            Move-Item -LiteralPath $InstallDir -Destination $Backup
        }

        try {
            Move-Item -LiteralPath $Staging -Destination $InstallDir
            if ($HadPrevious -and (Test-Path -LiteralPath $Backup)) {
                Remove-Item -LiteralPath $Backup -Recurse -Force
            }
        }
        catch {
            if (Test-Path -LiteralPath $InstallDir) {
                Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            if ($HadPrevious -and (Test-Path -LiteralPath $Backup)) {
                Move-Item -LiteralPath $Backup -Destination $InstallDir
            }
            throw
        }

        Write-Host ("Alpha instalada y verificada: " + $RemoteSha.Substring(0, [Math]::Min(12, $RemoteSha.Length)))
    }

    if ($NoRun) {
        Write-Host "Lista en: $InstallDir"
        exit 0
    }

    if (-not (Test-Path -LiteralPath $Executable)) {
        throw "Falta el ejecutable esperado: $Executable"
    }

    Write-Host "Arrancando SIGA-98..."
    Start-Process -FilePath $Executable -WorkingDirectory $InstallDir
}
finally {
    Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
}
