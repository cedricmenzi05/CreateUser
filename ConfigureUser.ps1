#------------------------------------------------#
#Project: ConfigureUser.ps1#
#Author: Cedric Menzi#
#Date: 23.04.2021#
#Function: Configure an already created user#
#------------------------------------------------#

Set-ExecutionPolicy -ExecutionPolicy Unrestricted
# Creates the PSDrive for the "HKEY_USERS" Registry Key
function createPSDrive {
    New-PSDrive -Name "HKU" -PSProvider "Registry" -Root "HKEY_USERS" -Scope script
}

# Determines the SID of the user which has to be configured
function setSID {
    $global:userSID = Get-Content -Path "C:\CreateUser\config\SID.txt"
}

# Configures the User's Design settings (e.g. Wallpaper, Dark-or Brightmode)
function configureDesign {
    Set-ItemProperty -Path "HKU:\$userSID\Control Panel\Desktop" -Name "WallPaper" -Value "C:\CreateUser\dl\wallpaper.jpg"
}

# Removes the PSDrive for the "HKEY_USERS" Registry Key
function removePSDrive {
    Remove-PSDrive -Name "HKU"
}

# Removes the "SID.txt"-File to avoid errors when creating multiple users
function removeConfigFile {
    Remove-Item -Path "C:\CreateUser\config\SID.txt" -Force
}

# Gives the created User Admin rights, to execute the 2nd Script
function removeAdminRights {
    if ([CultureInfo]::InstalledUICulture.Name -eq "de-DE") {
        Remove-LocalGroupMember -Group "Administratoren" -Member $userSID
    } else {
        Remove-LocalGroupMember -Group "Administrators" -Member $userSID
    }
}

function endConfiguration {
    $read = Read-Host "Do you want to restart the PC? The Configuration Script will be started automatically. [y/n]"
    if ($read -eq "y") {
        Restart-Computer -Force 
    } else {
        Write-Host "Restart aborted...."
    }
}

#--------Excecution--------#
createPSDrive
setSID
configureDesign
removePSDrive
removeConfigFile
removeAdminRights
endConfiguration
#--------------------------#