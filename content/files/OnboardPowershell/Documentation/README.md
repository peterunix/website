# Script Usage
Here's how to run the prep script

~~~ powershell
$env:InstallAdobe=$true
./onboard-dmi.ps1
~~~

To change what group policy settings are applied, configure group policy on your computer and make a backup of it.

~~~ powershell
lgpo.exe /b C:\windows\temp /n backup
~~~

Rename the group policy backup folder "GroupPolicySettings".
Create a zip file of that folder and place it in the same folder as the script.
Alternativley create the zip file and upload it to the datto component.

# Function details
## _CreateTempDirectory/_RemoveTempDirectory
All downloaded files are placed in $env:temp\OnboardTemp.
This folder is created and deleted during and after the script completes

## _LogoutAllUsers
Uses the WIN32_OperatingSystem WMI object to log all users off of there computer.
This is better than using logoff.exe and quser.exe since those two programs aren't available in the home edition of Windows.

## _BackupRegistryHives
The script changes some system settings through the registry.
A full backup of HKCR, HKLM, and HKU is made to C:\Windows\System32\config\OnboardRegBackupDMI

## Set-RegistryValueForAllUsers
Creates registry keys for all users on the system.
Users that aren't logged in will have their registry keys set when they first login

## _ClearGpedit
Resets all local group policy changes.
There are two registry.pol files in C:\Windows\System32\GroupPolicy.
One registry.pol is for Computer Configurations and the other for User Configurations.
I don't use this in the script, but it exists

## _Gpedit
This uses the LGPO from the "Microsoft Security Compliance Toolkit 1.0" to import a preconfigured group policy backup.
https://www.microsoft.com/en-us/download/details.aspx?id=55319.
If group policy isn't already installed, it installs it. This is primarly used for the home editions of powershell.
LGPO.exe can be used to export and rebuild the registry.pol files.
I found this to be better than registry edits since the changes are reflected in gpedit.msc.

~~~ powershell
lgpo.exe /b C:\windows\temp /n backup

lgpo.exe /g 'C:\windows\temp\{E9C20D51-140D-4A13-9707-F53FE5945D97}'
~~~

## _UnpinAppsFromTaskbar
Lists all the installed applications uses the Shell.Application class and calls a method to unpin or pin the applications.
It's used to remove the MS Store, Mail, and other unwanted apps from the taskbar.
This doesn't work when running the script as another user (i.e a Datto RMM component)

## _UnpinAppFromStartMenu
A blank XML template file is imported to remove all the tiles from the start menu.
This change is applied to the current user and any newly created users.
https://superuser.com/questions/1068382/how-to-remove-all-the-tiles-in-the-windows-10-start-menu
This also doesn't work when ran from another user. Still troubleshooting this.

## _EnableNetworkDiscovery
Enables a preconfigured firewall rule for Network Discovery for Private and Domain networks

## _DisableOneDriveAutostart
All users must be logged out first.
This mounts the %userprofile% NTUSER.dat file and removes the registry key for starting onedrive on boot

## _DisableAutomaticPrinterSetup
This unticks the box for automatic printer setup.
This option -- regardless of how its disabled -- will always re-enable itself after updates

## _ConfigureNic
Disables all the powersaving properties on all NICs.
Only enables IPv4, Client for Microsoft Networks, and File and Printer sharing

## _ConfigureRestorePoint
Enables the computer restore point feature.
Sets the restore disk usage to 5%

## _ConfigurePowerSettings
This enables the default high-performance powerplan and changes the monitor and sleep timeouts when on battery and when connected to mains
This also unchecks powersaving from the host USB controller

## _ConfigureTimeSync
Sets the timezone to PST and enables the W32Time service.
Commands to set the NTP servers are commented out