 
 <#
.SYNOPSIS
Script to push a file to a group of workstations in a list

.DESCRIPTION
pull HWIDs from PCs for intune provisioning

.PARAMETER File
input file name that holds list of PCs to pull from

.PARAMETER room
input room from which you want to pull hwids from [ex. s-a213]

 
#>

 param (

 [Parameter(Mandatory=$false)][string]$File,
 [Parameter(Mandatory=$false)][string]$room

 )


 if ( $File ){

 $computers = get-content $File 
 }

 elseif ( $room ){
 $computers = @()
 $getad = (([adsisearcher]"(&(objectCategory=Computer)(name=$room))").findall()).properties
 $computers += $getad.cn 
 }

 else { 
 Write-Host "Please define a room or a text file to use as input" 
 exit 1
 }

mkdir .\hwid -ErrorAction Ignore

Invoke-Command -ComputerName $computers {

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -Type Directory -Path "C:\Users\Public\ID" -ErrorAction Ignore
Set-Location -Path "C:\Users\Public\ID"
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"

try{ 
    Set-ExecutionPolicy AllSigned -Scope LocalMachine
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force -ErrorAction Ignore
}
catch {
    
}

Install-Script -Name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile "$env:COMPUTERNAME.csv"
}



foreach ($computer in $computers){


Copy-Item -Path \\$computer\c$\Users\Public\ID\$computer.csv -Destination ".\hwid\$computer.csv"


}

