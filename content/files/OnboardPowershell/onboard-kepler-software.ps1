param(
    [switch]$KeplerGeneric,
    [switch]$KeplerDevelopment
)

# Suppress error messages
$InformationPreference="SilentlyContinue"
# Suppress progress bar with Invoke-WebRequest. This improves performance DRASTICALLY
$ProgressPreference="SilentlyContinue"
# Temporary folder to download files
$temp="$env:temp\OnboardTemp"
# Current working directory of the script
$cwd = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Temporary folder where executable files will be downloaded to
function _CreateTempDirectory{
    if (Test-Path "$temp"){
        Remove-Item -Recurse "$temp"
        New-Item -Path "$temp" -ItemType Directory
    } else {
        New-Item -Path "$temp" -ItemType Directory
    }
}

function _RemoveTempDirectory{
    if (Test-Path "$temp"){
        Remove-Item -Recurse "$temp"
    }
}

# Using the dotnet webclient object to download files
# Invoke-WebRequest would randomly freeze until you pressed a key
function _Download{
    Param(
        [Parameter(Mandatory=$true)] [string]$Uri,
        [Parameter(Mandatory=$true)] [string]$OutFile
    )

    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($Uri, $OutFile)
}

# Downloads the enterprise version of Adobe
function _InstallAdobe{
    Write-Host "Downloading Adobe Reader Enterprise (32bit)"
    _Download -Uri 'https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2101120039/AcroRdrDC2101120039_en_US.exe' -OutFile "$temp\adobereader.exe"
    Start-Process "7za.exe" -ArgumentList "x $temp\adobereader.exe -o$temp\AdobeReaderExtracted -aoa" -Wait
    Write-Host "Running the Adobe Installer"
    Start-Process "$temp\AdobeReaderExtracted\AcroRead.msi" -ArgumentList "/qn" -Wait
}

function _InstallChrome{
    Write-Host "Downloading Google Chrome"
    _Download -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile "$temp\chrome_installer.exe"
    Write-Host "Running the Chrome installer"
    Start-Process "$temp\chrome_installer" -ArgumentList "/silent /install" -Wait
}
function _InstallDrive{
    Write-Host "Downloading Google Drive"
    _Download -Uri "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe" -OutFile "$temp\GoogleDriveSetup.exe"
    Write-Host "Running the Drive installer"
    Start-Process "$temp\GoogleDriveSetup.exe" -ArgumentList "--silent --gsuite_shortcuts=false"
}

function _InstallSlack{
    Write-Host "Downloading Slack"
    _Download -Uri "https://slack.com/ssb/download-win64-msi-legacy" -OutFile "$temp\slackwin64.msi"
    Write-Host "Running the Slack Deployment Installer"
    Start-Process "$temp\slackwin64.msi" -Wait
    Write-Host "Installing Slack"
    Start-Process "C:\Program Files\Slack Deployment\slack.exe"
    Start-Sleep -Seconds 15
    Stop-Process -ProcessName "slack" -Force -Confirm:$false
}

function _InstallZoom{
    Write-Host "Downloading Zoom"
    _Download -Uri "https://zoom.us/client/latest/ZoomInstallerFull.msi" -OutFile "$temp\zoom.msi"
    Write-Host "Installing Zoom"
    Start-Process "msiexec.exe" -ArgumentList "/i $temp\zoom.msi /qn" -Wait
}

function _InstallAnaconda{
    Write-Host "Downloading Anaconda"
    $url=(Invoke-WebRequest -Uri "https://www.anaconda.com/products/individual" -UseBasicParsing).links.href | select-string "https://repo.anaconda.com/archive/.*Windows-x86_64.exe" | select-object -First 1
    _Download -Uri "$url" -Outfile "$temp\anaconda.exe"
    Write-Host "Installing Anaconda"
    Start-Process "$temp\anaconda.exe" -ArgumentList "/InstallationType=JustMe /RegisterPython=0 /S /D=%UserProfile%\Miniconda3" -Wait
}

function _InstallGit{
    Write-Host "Downloading Git"
    $url=(Invoke-WebRequest -Uri "https://git-scm.com/download/win" -UseBasicParsing).links.href | select-string "https://github.com/git-for-windows/git/releases/download/v2.35.1.windows.2/Git-.*-bit.exe" | select-object -First 1
    _Download -Uri "$url" -Outfile "$temp\git.exe"
    Write-Host "Installing Git"
    Start-Process "$temp\git.exe" -ArgumentList "/VERYSILENT /NORESTART" -Wait
}

function _InstallSublime{
    Write-Host "Downloading Sublime"
    $url=(Invoke-WebRequest -Uri "https://www.sublimetext.com/3" -UseBasicParsing).links.href | select-string "https://download.sublimetext.com/Sublime.*.x64 Setup.exe" | Out-String | foreach {$_.replace(" ","%20")}
    _Download -Uri "$url" -Outfile "$temp\sublime.exe"
    Write-Host "Installing Sublime"
    Start-Process "$temp\sublime.exe" -ArgumentList "/VERYSILENT" -Wait
}

function _InstallPycharm{
    Write-Host "Downloading Pycharm"
    # Hardcoded url for pycharm. I don't want to scrap a JS page.
    $url="https://download.jetbrains.com/python/pycharm-community-2021.3.2.exe"
    _Download -Uri "$url" -Outfile "$temp\pycharm.exe"
    Write-Host "Installing Pycharm"
    Start-Process "$temp\pycharm.exe" -ArgumentList "/S" -Wait
}

function _InstallKlayout{
    Write-Host "Downloading Klayout"
    $url=(Invoke-WebRequest -Uri "https://www.klayout.de/build.html" -UseBasicParsing).links.href | select-string "https://www.klayout.org/downloads/Windows/klayout-.*.-win64-install.exe" | select-object -First 1
    _Download -Uri "$url" -Outfile "$temp\klayout.exe"
    Write-Host "Installing Klayout"
    Start-Process "$temp\klayout.exe" -ArgumentList "/VERYSILENT /NORESTART" -Wait
}

_CreateTempDirectory
if ($KeplerGeneric){
    #_InstallAdobe
    _InstallChrome
    _InstallDrive
    _InstallSlack
    _InstallZoom
}

if ($KeplerDevelopment){
    _InstallAnaconda
    _InstallGit
    _InstallSublime
    _InstallPycharm
    _InstallKlayout
}