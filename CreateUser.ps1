#------------------------------------------------#
#Project: CreateUser.ps1#
#Author: Cedric Menzi#
#Date: 20.04.2021#
#Function: Creating a user with standard settings#
#------------------------------------------------#

#Setting the Excecution Police
Set-ExecutionPolicy -ExecutionPolicy Unrestricted

#Filling the Array "$LocalGroups" with all the Local Groups and Output it as a list
function getLocalGroups {
    [array]$global:LocalGroups = Get-LocalGroup
    Write-Host "+++++++++++++++++++++++= Local Groups, type number to select =+++++++++++++++++++++++"
    for ($i = 0; $i -lt $LocalGroups.Count; $i++) {
        Write-Host $i  ": "  $LocalGroups[$i]
    }
    Write-Host "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

#Reads in all the needed Arguments
function readArguments {
    [string]$global:configurationUsername = Read-Host "User which runs this script:"
    [string]$global:UserName = Read-Host "Username"
    [string]$global:fullName = Read-Host "Full name"
    [string]$global:UserDescription = Read-Host "Description"
    [securestring]$global:Password = Read-Host "Passwort" -AsSecureString
    [string]$global:userChangePassword = Read-Host "Should the user be able to change his password? [y/n]"
    getLocalGroups
    [string]$global:selectedGroups = Read-Host "Groups (Type Space to seperate)"
}

#Create the User with the provieded Settings
function createUser {
    if ($userChangePassword -eq "y") {
        New-LocalUser -AccountNeverExpires -PasswordNeverExpires -Name $UserName -FullName $fullName -Description $UserDescription -Password $Password | Out-Null
    } elseif ($userChangePassword -eq "n") {
        New-LocalUser -AccountNeverExpires -PasswordNeverExpires -Name $UserName -FullName $fullName -Description $UserDescription -Password $Password -UserMayNotChangePassword | Out-Null 
    }
}

#Set the Groups for the user
function setGroups {
    $selectedGroupsSize = $selectedGroups.Count
    $selectedGroupsArray = $selectedGroups.Split(" ")
    if ($selectedGroupsSite -le 1) {
        Add-LocalGroupMember -Group $LocalGroups[$selectedGroupsArray[0]] -Member $UserName
        Write-Host "Added User $userName to " $LocalGroups[$selectedGroupsArray[0]] "..."
    } else {
        for ($i = 0; $i -le $selectedGroupsSize; $i++) {
            Add-LocalGroupMember -Group $LocalGroups[$selectedGroupsArray[$i]] -Member $UserName
            Write-Host "Added User $userName to " $LocalGroups[$selectedGroupsArray[$i]] "..."
        }
    }
}

function getUserSID {
    [string]$global:userSID = (New-Object System.Security.Principal.NTAccount($UserName)).Translate([System.Security.Principal.SecurityIdentifier]).Value 
}


#Downloading needed files
function downloadFiles {
    #Creates Folder for Download, checks if already created
    if (Test-Path -Path "C:\CreateUser") {
        Write-Host "Download Folder already exists"
    } else {
        New-Item -Name "CreateUser" -Path "C:" -ItemType "directory" | Out-Null
        New-Item -Name "dl" -Path "C:\CreateUser" -ItemType "directory" | Out-Null 
    }

    #Downloads standard wallpaper
    $WebClient = New-Object System.Net.WebClient
    $WebClient.downloadFile("https://i.imgur.com/57Onk4E.jpg", "C:\CreateUser\dl\wallpaper.jpg")

    # Copies the "ConfigureUser.ps1" script
    Copy-Item -Path "C:\Users\$configurationUsername\Desktop\ConfigureUser.ps1" -Destination "C:\CreateUser" -Force
    
}
# Creates the scheduled task - starts at login
function createScheduledTask {
    [string]$TaskArgs = "-noprofile -command &{ Start-Process powershell.exe -ArgumentList '-noprofile -file C:\CreateUser\ConfigureUser.ps1' -verb RunAs}"
    $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $TaskArgs
    $TaskPrincipal = New-ScheduledTaskPrincipal -UserId $UserName -LogonType ServiceAccount -RunLevel Highest
    $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
    $Task = New-ScheduledTask -Action $TaskAction -Principal $TaskPrincipal -Trigger $TaskTrigger 
    Register-ScheduledTask -Force -InputObject $Task -TaskName "ConfigureUser" | Out-Null
}

# Creates the SID File for Configuration Purposes
function createConfigFile {
    New-Item -Name "config" -Path "C:\CreateUser" -ItemType "directory" | Out-Null
    $SIDFile = $global:userSID | Out-File -FilePath "C:\CreateUser\config\SID.txt"
}

# Gives the created User Admin rights, to execute the 2nd Script
function setAdminRights {
    if ([CultureInfo]::InstalledUICulture.Name -eq "de-DE") {
        Add-LocalGroupMember -Group "Administratoren" -Member $userSID
    } else {
        Add-LocalGroupMember -Group "Administrators" -Member $userSID
    }
}

# Reboots Windows
function endCreation {
    $read = Read-Host "Do you want to restart the PC? The Configuration Script will be started automatically. [y/n]"
    if ($read -eq "y") {
        Restart-Computer -Force 
    } else {
        Write-Host "Restart aborted...."
    }
    
}

#--------Excecution--------#
getLocalGroups
readArguments
createUser
setGroups
getUserSID
downloadFiles
createScheduledTask
createConfigFile
setAdminRights
endCreation
#--------------------------#
