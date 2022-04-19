function _Main{
    $ProgressPreference="SilentlyContinue"
    $programs=Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty
    # Add $HOME variable
    [System.Environment]::SetEnvironmentVariable('HOME',"$env:userprofile",[System.EnvironmentVariableTarget]::User)
    # Add Putty to $PATH
    [System.Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\Program Files\PuTTY;C:\Program Files\Emacs\emacs-28.1\bin;$env:localappdata\Programs\MiKTeX\miktex\bin\x64\", [EnvironmentVariableTarget]::Machine)
    _InstallEmacs
    _InstallPutty
    _InstallSSHFS
}


function _InstallEmacs{
    Write-Host "Installing Emacs init.el to $env:HOME\.emacs.d\init.el"
    # Downloading my init.el file
    if (Test-Path -Path "$env:HOME\.emacs.d"){
        Remove-Item -Force -Recurse "$env:HOME\.emacs.d"
    }
    New-Item -Type Directory "$env:HOME\.emacs.d" > $null
    Invoke-WebRequest -UseBasicParsing -Uri "https://unixfandom.com/content/files/Emacs/init.el" -OutFile "$env:HOME\.emacs.d\init.el"

    # Installing emacs if it doesn't exist
    if (-not(Test-Path -Path "C:\Program Files\Emacs")){
        Write-Host "Downloading Emacs28 from GNU.ORG"
        Invoke-WebRequest -UseBasicParsing -Uri "https://ftp.gnu.org/gnu/emacs/windows/emacs-28/emacs-28.1-installer.exe" -OutFile "$env:TEMP\emacs.exe"
        Write-Host "Installing Emacs"
        Start-Process "$env:TEMP\emacs.exe" -ArgumentList "/S" -Wait
        Remove-Item -Force "$env:TEMP\emacs.exe"
        Write-Host "INSTALLED!"
    }

    Write-Host "Installing SauceCodePro Nerd Font"
    Invoke-WebRequest -UseBasicParsing -Uri "https://unixfandom.com/content/files/Fonts/sauce-code-nerd-font-complete.ttf" -OutFile "$env:TEMP\sauce-code.ttf"
    Start-Process "$env:TEMP\sauce-code.ttf" -Wait
    Remove-Item -Force "$env:TEMP\sauce-code.ttf"
    Write-Host "INSTALLED!"

    Write-Host "Installing Terminess Nerd Font"
    Invoke-WebRequest -UseBasicParsing -Uri "https://unixfandom.com/content/files/Fonts/terminess-nerd-font-complete.ttf" -OutFile "$env:TEMP\terminess.ttf"
    Start-Process "$env:TEMP\terminess.ttf" -Wait
    Remove-Item -Force "$env:TEMP\terminess.ttf"
    Write-Host "INSTALLED!"
}

function _InstallPutty{
    Write-Host "Downloading Putty"
    Invoke-WebRequest -UseBasicParsing -Uri "https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.76-installer.msi" -OutFile "$env:TEMP\putty.msi"
    Write-Host "Installing Putty"
    Start-Process "msiexec" -ArgumentList "/i $env:TEMP\putty.msi /qn" -Wait
    Remove-Item -Force "$env:TEMP\putty.msi"
    Write-Host "INSTALLED!"
}

function _InstallSSFS{
    Write-Host "Downloading WinFSP (SSFS Fuse)"
    Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/billziss-gh/winfsp/releases/download/v1.11B2/winfsp-1.11.22103.msi' -OutFile "$env:TEMP\winfsp.msi"
    Write-Host "Installing WinFSP"
    Start-Process "msiexec" -ArgumentList "/i $env:TEMP\winfsp.msi /qn" -Wait
    Remove-Item -Force "$env:TEMP\winfsp.msi"
    Write-Host "INSTALLED!"
    Write-Host "Use \\sshfs\username@hostname to map the drive"
}

_Main
