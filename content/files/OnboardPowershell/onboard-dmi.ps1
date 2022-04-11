#Requires -RunAsAdministrator
# Suppress error messages
$InformationPreference="SilentlyContinue"
# Suppress progress bar with Invoke-WebRequest. This improves performance DRASTICALLY
$ProgressPreference="SilentlyContinue"
# Temporary folder to download files
$temp="$env:temp\OnboardTemp"
# Current working directory of the script
$cwd = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

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

# Create a full backup of all registry hives
function _BackupRegistryHives{
    $outputDirectory="C:\Windows\System32\config\OnboardRegBackupDMI"
    if (!(Test-Path "$outputDirectory")){
        New-Item -Path "$outputDirectory" -ItemType Directory
    }
    Write-Host "Exporting HKEY_CLASSES_ROOT to $outputDirectory\hkcr.reg"
    reg export HKCR "$outputDirectory\hkcr.reg" /y
    Write-Host "Exporting HKEY_LOCAL_MACHINE to $outputDirectory\hklm.reg"
    reg export HKLM "$outputDirectory\hklm.reg" /y
    Write-Host "Exporting HKEY_USERS to $outputDirectory\hku.reg"
    reg export HKU "$outputDirectory\hku.reg" /y
}

# Function to set HKCU registry keys for all users
#https://adamtheautomator.com/active-setup-registry/
#https://github.com/Adam-the-Automator/Scripts/blob/main/Set-RegistryValueForAllUsers.ps1
function Set-RegistryValueForAllUsers {
    <#
    .SYNOPSIS
        This function uses Active Setup to create a "seeder" key which creates or modifies a user-based registry value
        for all users on a computer. If the key path doesn't exist to the value, it will automatically create the key and add the value.
    .EXAMPLE
        PS> Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'Setting'; 'Type' = 'String'; 'Value' = 'someval'; 'Path' = 'SOFTWARE\Microsoft\Windows\Something'}
        This example would modify the string registry value 'Type' in the path 'SOFTWARE\Microsoft\Windows\Something' to 'someval'
        for every user registry hive.
    .PARAMETER RegistryInstance
        A hash table containing key names of 'Name' designating the registry value name, 'Type' to designate the type
        of registry value which can be 'String,Binary,Dword,ExpandString or MultiString', 'Value' which is the value itself of the
        registry value and 'Path' designating the parent registry key the registry value is in.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable[]]$RegistryInstance
    )
    try {
        New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS | Out-Null

        ## Change the registry values for the currently logged on user. Each logged on user SID is under HKEY_USERS
        $LoggedOnSids = $(Get-ChildItem HKU: | Where-Object { $_.Name -match 'S-\d-\d+-(\d+-){1,14}\d+$' } | foreach-object { $_.Name })
        Write-Verbose "Found $($LoggedOnSids.Count) logged on user SIDs"
        foreach ($sid in $LoggedOnSids) {
            Write-Verbose -Message "Loading the user registry hive for the logged on SID $sid"
            foreach ($instance in $RegistryInstance) {
                ## Create the key path if it doesn't exist
                if (!(Test-Path "HKU:\$sid\$($instance.Path)")) {
                    New-Item -Path "HKU:\$sid\$($instance.Path | Split-Path -Parent)" -Name ($instance.Path | Split-Path -Leaf) -Force | Out-Null
                }
                ## Create (or modify) the value specified in the param
                Set-ItemProperty -Path "HKU:\$sid\$($instance.Path)" -Name $instance.Name -Value $instance.Value -Type $instance.Type -Force
            }
        }

        ## Create the Active Setup registry key so that the reg add cmd will get ran for each user
        ## logging into the machine.
        ## http://www.itninja.com/blog/view/an-active-setup-primer
        Write-Verbose "Setting Active Setup registry value to apply to all other users"
        foreach ($instance in $RegistryInstance) {
            ## Generate a unique value (usually a GUID) to use for Active Setup
            $Guid = [guid]::NewGuid().Guid
            $ActiveSetupRegParentPath = 'HKLM:\Software\Microsoft\Active Setup\Installed Components'
            ## Create the GUID registry key under the Active Setup key
            New-Item -Path $ActiveSetupRegParentPath -Name $Guid -Force | Out-Null
            $ActiveSetupRegPath = "HKLM:\Software\Microsoft\Active Setup\Installed Components\$Guid"
            Write-Verbose "Using registry path '$ActiveSetupRegPath'"

            ## Convert the registry value type to one that reg.exe can understand.  This will be the
            ## type of value that's created for the value we want to set for all users
            switch ($instance.Type) {
                'String' {
                    $RegValueType = 'REG_SZ'
                }
                'Dword' {
                    $RegValueType = 'REG_DWORD'
                }
                'Binary' {
                    $RegValueType = 'REG_BINARY'
                }
                'ExpandString' {
                    $RegValueType = 'REG_EXPAND_SZ'
                }
                'MultiString' {
                    $RegValueType = 'REG_MULTI_SZ'
                }
                default {
                    throw "Registry type '$($instance.Type)' not recognized"
                }
            }

            ## Build the registry value to use for Active Setup which is the command to create the registry value in all user hives
            $ActiveSetupValue = "reg add `"{0}`" /v {1} /t {2} /d {3} /f" -f "HKCU\$($instance.Path)", $instance.Name, $RegValueType, $instance.Value
            Write-Verbose -Message "Active setup value is '$ActiveSetupValue'"
            ## Create the necessary Active Setup registry values
            Set-ItemProperty -Path $ActiveSetupRegPath -Name '(Default)' -Value 'Active Setup Test' -Force
            Set-ItemProperty -Path $ActiveSetupRegPath -Name 'Version' -Value '1' -Force
            Set-ItemProperty -Path $ActiveSetupRegPath -Name 'StubPath' -Value $ActiveSetupValue -Force
        }
    }
    catch {
        Write-Warning -Message $_.Exception.Message
    }
}

function _SetExecutionPolicy{
    Set-ExecutionPolicy RemoteSigned
}

# Using the Win32_OperatingSystem WMI object to
# forcefully logout all users portably.
function _LogoutAllUsers{
    $a = get-wmiobject win32_operatingsystem
    $a.win32shutdown(4)
    Start-Sleep 10
}

# Clears any local group policy changes
function _ClearGpedit{
    Remove-Item -Recurse -Force "$env:WinDir\System32\GroupPolicyUsers"
    Remove-Item -Recurse -Force "$env:WinDir\System32\GroupPolicy"
    gpupdate /force
}

# Sets the gpedit entries we would typically change in the gpedit.msc
# It uses LGPO.exe to import the GPOs from an already exported backup
# It also sets some local user registry keys for some further configuration
function _Gpedit{
    # Install Gpedit if it's not already
    if ((Test-Path "C:\Windows\System32\gpedit.msc") -eq $false){
        Write-Host "Installing Gpedit.msc"
        $packages=(Get-ChildItem "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum",
            "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum").name
        foreach ($package in $packages){
            dism /online /norestart /add-package:"$env:SystemRoot\servicing\Packages\$package"
        }
    } else {
        Write-Host "Gpedit.msc is already installed."
    }
    # Extract the zip file of our group policy backup
    Expand-Archive -Path $cwd\GroupPolicySettings.zip -DestinationPath $cwd
    # Restore from the group policy backup
    Start-Process "$cwd\lgpo.exe" -ArgumentList "/g $cwd\GroupPolicySettings"
    # Hide Cortona button from the taskbar
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'ShowCortanaButton'; 'Type' = 'DWORD'; 'Value' = '0'; 'Path' = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'}
    # Hide the Task View button from the taskbar
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'ShowTaskViewButton'; 'Type' = 'DWORD'; 'Value' = '0'; 'Path' = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'}
    # Hide the People button from the taskbar
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'HidePeopleBar'; 'Type' = 'DWORD'; 'Value' = '1'; 'Path' = 'Software\Policies\Microsoft\Windows\Explorer'}
    # Only show windows when Alt-Tabbing
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'MultiTaskingAltTabFilter'; 'Type' = 'DWORD'; 'Value' = '3'; 'Path' = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'}
    # Show file extensions in Explorer
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'HideFileExt'; 'Type' = 'DWORD'; 'Value' = '0'; 'Path' = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'}
    # Open file explorer in the "This PC" folder instead of "Quick Access"
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'LaunchTo'; 'Type' = 'DWORD'; 'Value' = '1'; 'Path' = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'}
    # Disables the beeping sound when changing volume or when a windows error occurs
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = '(Default)'; 'Type' = 'STRING'; 'Value' = '.None'; 'Path' = 'AppEvents\Schemes'}
    # Set the ControlPanel icon size to small
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'AllItemsIconView'; 'Type' = 'DWORD'; 'Value' = '1'; 'Path' = 'Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel'}
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'StartupPage'; 'Type' = 'DWORD'; 'Value' = '1'; 'Path' = 'Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel'}
}

# Unpins apps such as Mail, Store, and the Dell Optimizer
function _UnpinAppsFromTaskbar{
    try {
        $appname = "Microsoft Store"
        ((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{$_.Name -eq $appname}).Verbs() | ?{$_.Name.replace('&','') -match 'Unpin from taskbar'} | %{$_.DoIt(); $exec = $true}
    } catch{"Failed to remove Microsoft Store from taskbar"}

    try {
        $appname = "Mail"
        ((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{$_.Name -eq $appname}).Verbs() | ?{$_.Name.replace('&','') -match 'Unpin from taskbar'} | %{$_.DoIt(); $exec = $true}
    } catch{"Failed to remove the Mail App from taskbar"}

    try {
        $appname = "Dell Optimizer"
        ((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{$_.Name -eq $appname}).Verbs() | ?{$_.Name.replace('&','') -match 'Unpin from taskbar'} | %{$_.DoIt(); $exec = $true}
    } catch{"Failed to remove the Dell Optimizer from the taskbar"}
}

# Removes all the app groups from the Windows start menu
# It does this for every user on the system
# https://superuser.com/questions/1068382/how-to-remove-all-the-tiles-in-the-windows-10-start-menu
function _UnpinAppFromStartMenu{
$START_MENU_LAYOUT = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
    <LayoutOptions StartTileGroupCellWidth="6" />
    <DefaultLayoutOverride>
        <StartLayoutCollection>
            <defaultlayout:StartLayout GroupCellWidth="6" />
        </StartLayoutCollection>
    </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@

    $layoutFile="C:\Windows\StartMenuLayout.xml"

    #Delete layout file if it already exists
    If(Test-Path $layoutFile){
        Remove-Item $layoutFile
    }

    #Creates the blank layout file
    $START_MENU_LAYOUT | Out-File $layoutFile -Encoding ASCII

    #Assign the start layout and force it to apply with "LockedStartLayout" at both the machine and user level
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'StartLayoutFile'; 'Type' = 'STRING'; 'Value' = "$layoutFile"; 'Path' = '\SOFTWARE\Policies\Microsoft\Windows\Explorer'}
    Set-RegistryValueForAllUsers -RegistryInstance @{'Name' = 'LockedStartLayout'; 'Type' = 'DWORD'; 'Value' = '0'; 'Path' = '\SOFTWARE\Policies\Microsoft\Windows\Explorer'}

    # Uncomment the next line to make clean start menu default for all new users
    Import-StartLayout -LayoutPath $layoutFile -MountPath $SystemDrive\
}

function _EnableNetworkDiscovery{
    Get-NetFirewallRule -DisplayGroup 'Network Discovery'|
        Set-NetFirewallRule -Profile 'Private, Domain' -Enabled true -PassThru |
        Select-Object Name,DisplayName,Enabled,Profile |
        Format-Table -a
}

# Removes OneDrive from the autostart list
function _DisableOneDriveAutostart{
    $users = (Get-ChildItem -path c:\users).name
    foreach($user in $users){
        reg load "hku\$user" "C:\Users\$user\NTUSER.DAT"
        reg delete "hkey_users\$user\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\" /v OneDrive /f
        reg unload "hku\$user"
    }
}

# Disables the automatic setup of printers
function _DisableAutomaticPrinterSetup{
    # https://www.reddit.com/r/Intune/comments/l6ilgk/disable_turn_on_automatic_setup_of_network/
    # Setting the connection to private
    $obj = Get-NetConnectionProfile | Select-Object -Property InterfaceIndex
    Set-NetConnectionProfile -InterfaceIndex $obj.InterfaceIndex -NetworkCategory Private
    # Disable automatic setup of network devices
    New-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private" -Name "AutoSetup" -Value 0 
    Restart-Service spooler
}

# Disables UAC - NOT USED. GROUP POLICY HANDLES IT.
function _DisableUserAccessControl{
    New-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -PropertyType DWord -Value 0 -Force
}

# Disables any powersaving modes for the NIC
# Only enables IPv4, QoS packet scheduler, and File and Printer sharing
function _ConfigureNic{
    # Only enabling IPv4, Client for Microsoft Networks, and File and Printer Sharing
    Disable-NetAdapterBinding -Name "*" -ComponentID "*" -ErrorAction SilentlyContinue
    Enable-NetAdapterBinding -Name "*" -ComponentID "ms_tcpip" -ErrorAction SilentlyContinue
    Enable-NetAdapterBinding -Name "*" -ComponentID "ms_msclient" -ErrorAction SilentlyContinue
    Enable-NetAdapterBinding -Name "*" -ComponentID "ms_server" -ErrorAction SilentlyContinue

    # Disables the powersaving settings for all the NICs
    Set-NetAdapterAdvancedProperty -Name "*" -DisplayName "Large Send Offload V2 (IPv4)" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name "*" -DisplayName "Energy Efficient Ethernet" -DisplayValue "Off" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name "*" -DisplayName "Ultra Low Power Mode" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name "*" -DisplayName "Idle Power Saving" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name "*" -DisplayName "Green Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue

    $adapters = Get-NetAdapter | Get-NetAdapterPowerManagement
    foreach ($adapter in $adapters){
        $adapter.AllowComputerToTurnOffDevice = 'Disabled'
        $adapter.SelectiveSuspend = 'Disabled'
        $adapter | Set-NetAdapterPowerManagement -ErrorAction SilentlyContinue
    }
}

# Enables system restore and sets the disk usage to 5%
function _ConfigureRestorePoint{
    # Enable the system restore feature
    Enable-ComputerRestore -Drive "C:\"
    # Set the system restore disk usage to 5%
    vssadmin resize shadowstorage /on=C: /for=C: /maxsize=5%
}

# Enables high performance mode and configures the power profile
function _ConfigurePowerSettings{
    # Set profile to high performance. This UID doesn't seem to change
    powercfg.exe -SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    # Turn off display after 60 minutes on charger. 20 minutes on battery.
    powercfg.exe -Change -monitor-timeout-ac 60
    powercfg.exe -Change -monitor-timeout-dc 20
    # Turn off hard disk never on charger. 30 minutes on battery
    powercfg.exe -Change -disk-timeout-ac 0
    powercfg.exe -Change -disk-timeout-dc 20
    # Suspend computer never on charger. 20 minutes on battery
    powercfg.exe -Change -standby-timeout-ac 0
    powercfg.exe -Change -standby-timeout-dc 20
    # Hibernate computer never on charger. 60 minutes on battery
    powercfg.exe -Change -hibernate-timeout-ac 0
    powercfg.exe -Change -hibernate-timeout-dc 60
    # Disable USB Selective Suspend. The registry change only works with WinXP
    # This is the equivlent to right clicking the USB hub in Device Manager and disabling the powersaving mode there
    $devicesUSB = Get-PnpDevice | where {$_.InstanceId -like "*USB\ROOT*"}  | 
        ForEach-Object -Process {
        Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi 
        }
    foreach ($device in $devicesUSB){
        Set-CimInstance -Namespace root\wmi -Query "SELECT * FROM MSPower_DeviceEnable WHERE InstanceName LIKE '%$($device.PNPDeviceID)%'" -Property @{Enable=$False} -PassThru
    }
}

# Sets the timezone to PST and syncs the time
function _ConfigureTimeSync{
    # Setting the timezone to PST
    Set-Timezone -Id "Pacific Standard Time"
    # Starting and enabling the w32time service to run on startup
    Set-Service -Name w32time -StartupType Automatic
    Start-Service w32time
    # Set the NTP server list and sync the time
    w32tm.exe /config /syncfromflags:manual /manualpeerlist:time.windows.com,time.nist.gov,time.nist-nw.gov,time.nist-a.gov,time.nist-b.gov,0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org /update /reliable:yes
    w32tm.exe /resync
}

function _StopAdobeProcess{
    # Kill the Adobe process
    $ids=(Get-Process -Name acro*).id
    foreach ($id in $ids){
        Stop-Process -Force $id 2>&1 | Out-Null
        Wait-Process -Id $id 2>&1 | Out-Null
    }
}

function _WindowsFeatureUpdate{
    # These folders can cause Windows Updates to fail
    Remove-Item 'C:\$Windows.~WS' -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item 'C:\$Windows.~BT' -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item 'C:\$GetCurrent' -Recurse -Force -ErrorAction SilentlyContinue

    # https://social.technet.microsoft.com/Forums/windows/en-US/51104081-4ed7-4fdd-8b12-5d1f5be532ae/windows-10-feature-update-via-cmd-powershell-or-gpo
    # Exit if not running Windows 10
    $WINVER=(get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
    if ( $WINVER -notlike "Windows 10*"){
    Write-Host "This script only works with Windows 10. Current OSVersion: $WINVER"
    Exit 1
    }

    # Store the Win10 downloader in the temp directory
    Write-Host "Storing Win10Upgrade in C:\Windows\Temp"
    $dir = $temp

    # Downloading the file
    Write-Host "Creating WebClient object to download the file"
    $webClient = New-Object System.Net.WebClient
    $url = 'https://go.microsoft.com/fwlink/?LinkID=799445'
    $file = "$($dir)\Win10Upgrade.exe"

    Write-Host "Downloading File"
    $webClient.DownloadFile($url,$file)

    # Executing the file
    Write-Host "Starting upgrade"
    Start-Process -FilePath $file -ArgumentList '/quietinstall /skipeula /auto upgrade /copylogs $dir' -Wait
    Write-Host "The Windows update assistant is running in the background. This will take a while to complete"
}

# Fetch the uninstall string for adobe
function _UninstallAdobe{
    # Fetch the uninstall string for Adobe and grab the product id of it
    $progs=Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty
    # Uninstalling it silently
    try{
        (($progs | Where {$_.displayname -match "Adobe Acrobat.*DC"}).uninstallstring) -match "{.*.}" | Out-Null
        Start-Process "msiexec.exe" -ArgumentList "/X $($matches[0]) /qn" -Wait
    } catch {
        "Couldn't find Adobe Acrobat Reader. Installing it."
    }
}

function _InstallAdobe{
    Write-Host "Downloading Adobe"
    Invoke-WebRequest -Uri 'https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2200120085/AcroRdrDC2200120085_en_US.exe' -OutFile "$temp\adobereader.exe" -UseBasicParsing
    Write-Host "Extracting Adobe"
    Start-Process "$cwd\7za.exe" -ArgumentList "x $temp\adobereader.exe -o$temp\AdobeReaderExtracted -aoa" -Wait

    # Parsing the DC release notes page to view the adobe patch for the current year and month.
    # It'll be the first link available.
    Write-Host "Locating the latest Adobe patch file for this month"
    $base="https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/"
    $link=(Invoke-WebRequest -Uri "https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html" -UseBasicParsing).links.href | Select-String "continuous/dccontinuous" | Select -First 1
    $link = $base+$link

    Write-Host "Downloading the latest Adobe patch file."
    # After finding the patch notes for the month, let's parse out the URL for the latest patch file
    $patchlink=(Invoke-WebRequest -Uri "$link" -UseBasicParsing).links.href | Select-String "pub/adobe/reader/win/AcrobatDC/" | Select -First 1
    # Get the filename from the url and download it
    $filename=([uri]"$patchlink").Segments[-1]
    # Download the patch.msp
    Invoke-WebRequest -Uri "$patchlink" -OutFile "$filename" -UseBasicParsing

# Create a new setup.ini file and have it point to the latest patch file
$Setup_INI_Content = @"
[Startup]
RequireMSI=3.0

[Product]
PATCH=$filename
msi=AcroRead.msi
"@

    Write-Host "Creating a new setup.ini for the Adobe installer. This will install the latest patch"
    $Setup_INI_Content | Set-Content "$temp\AdobeReaderExtracted\setup.ini"
    Write-Host "Starting the installation"
    Start-Process "$temp\AdobeReaderExtracted\setup.exe" -ArgumentList "/sAll" -Wait
}

function _AdobeSettings{
    Write-Host "Disabling the update task, update services, and update registry keys"
    # Prevent autoupdates (not necessary with the enterprise edition)
    Disable-ScheduledTask -TaskName "Adobe Acrobat Update Task"
    Stop-Service -Name "Adobe Acrobat Update Service"
    Set-Service -Name "AdobeARMservice" -StartupType Disabled
    # Disables and locks down the update button
    New-Item "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC" -ErrorAction SilentlyContinue
    New-Item "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -ErrorAction SilentlyContinue
    New-ItemProperty "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "Mode" -Value 0 -PropertyType DWORD -Force
    New-ItemProperty "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bUpdater" -Value 0 -PropertyType DWORD -Force
    New-ItemProperty "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bProtectedModeValue" -Value 0 -PropertyType DWORD -Force
    # This *should* disable enhanced security mode
    New-ItemProperty "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bEnhancedSecurityStandalone" -Value 0 -PropertyType DWORD -Force
    New-ItemProperty "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bEnhancedSecurityInBrowser" -Value 0 -PropertyType DWORD -Force
}

function _RemoveSpecificDesktopIcons{
    Remove-Item -Force -Path "C:\Users\*\Desktop\Microsoft Edge.lnk"
    Remove-Item -Force -Path "C:\Users\*\Desktop\Acrobat Reader DC.lnk"
}

_LogoutAllUsers
_CreateTempDirectory
_BackupRegistryHives
_Gpedit
_ConfigureNic
_ConfigurePowerSettings
_ConfigureRestorePoint
_DisableOneDriveAutostart
_DisableAutomaticPrinterSetup
_EnableNetworkDiscovery
_UnpinAppsFromTaskbar
_UnpinAppFromStartMenu
_RemoveSpecificDesktopIcons
_WindowsFeatureUpdate
if ($env:InstallAdobe -eq $true){
    _StopAdobeProcess
    _UninstallAdobe
    _InstallAdobe
    _AdobeSettings
}