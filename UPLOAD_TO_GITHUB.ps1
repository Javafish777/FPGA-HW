$ErrorActionPreference = 'Stop'
$repoUrl = 'https://github.com/Javafish777/FPGA-HW.git'
$sourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentDir = Split-Path -Parent $sourceRoot
$cloneDir = Join-Path $parentDir 'FPGA-HW-GitHub'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed or is not available in PATH. Install Git for Windows first.'
}
if (Test-Path $cloneDir) {
    throw "Destination already exists: $cloneDir`nRename or remove that folder, then run this script again."
}

git clone $repoUrl $cloneDir
if ($LASTEXITCODE -ne 0) { throw 'git clone failed. Check network access and GitHub sign-in.' }

Get-ChildItem -LiteralPath $sourceRoot -Force | Where-Object { $_.Name -ne 'UPLOAD_TO_GITHUB.ps1' } | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $cloneDir -Recurse -Force
}
Copy-Item -LiteralPath (Join-Path $sourceRoot 'UPLOAD_TO_GITHUB.ps1') -Destination $cloneDir -Force

Push-Location $cloneDir
try {
    git add -A
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    git commit -m 'Organize recovered FPGA homework sources (HW2 and HW3)'
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed. Check your Git user.name and user.email settings.' }
    git push origin HEAD:main
    if ($LASTEXITCODE -ne 0) { throw 'git push failed. Confirm that your GitHub account has write access to Javafish777/FPGA-HW.' }
    Write-Host "Upload complete: $repoUrl" -ForegroundColor Green
}
finally {
    Pop-Location
}
