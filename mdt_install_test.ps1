<#
.SYNOPSIS 
Script to remotely execute application installs via MDT Server on designated PCs. Includes interactive menu to select an application for install. 

.PARAMETER list 
(-l) Input file name that contains list of desired PCs

.PARAMETER room_method 
(-r) Command line switch to prompt user for entire rooms of PCs to remote install apps on

.EXAMPLE 
.\mdt-install.ps1 -r 

Runs the remote install script and prompts the user for room number input for application installs to entire rooms at a time

Use Case: Easier if you know you have to do full room installs beforehand 

.\mdt-intall.ps1 -l <relative or full path to .txt file containing PC list>

Runs the remote install script using a txt file to retrieve target PCs from

Use Case: Useful if you don't have to do entire rooms. Potentially partial rooms, or PCs scattered throughout multiple rooms.



#>




param (

 [Parameter(Mandatory=$false)][string]$list,
 [Parameter(Mandatory=$false)][switch]$room_method
 )

 function Start-Menu {

    $apps = Get-ChildItem -Path C:\Users\jeree\script_test | Select-Object -exp Name 
    $app_length = $apps.Length -1 
    
    While ($true){

    $apps_hashtable = @{}

    for ($x = 0; $x -lt $apps.Length; $x++){
   
       $apps_hashtable.Add("$x", $apps[$x])
   
    }
    Write-Host ""
    Write-Host "################ Application Select #################"
    Write-Host ""
    Write-Host "Options:"
    Write-Host ""
    Write-host "[s] Search for specific application"
    Write-Host "[v] View all applications"
    Write-Host "[q] Quit this Script"
    Write-Host "[0 - $app_length] Choose the number corresponding to your desired application" 
    Write-Host ""
     
    $option = read-host 
    
        if ($option -like "v"){

            $apps_hashtable.GetEnumerator() | Sort-Object  Value |  Format-Table

        }

        elseif ($option -like "s"){

            $search = read-host "Please enter the name of the application you'd like to search"
            $global:result = $apps_hashtable.GetEnumerator() | Where-Object Value -like *$search* | Sort-Object Name | Format-Table  

            if ($null -eq $global:result){

                Write-Host "Error! No applications found with that search. Restarting Menu...."
                Start-Sleep -Seconds 3
                continue 

            }
            
            Write-host "Below are the applications that are similar to your search."
            $global:result  

            $choice = read-host "Select a number to install or press q to restart"
                
                if ($choice -le $apps.length){
                    $global:result = $apps_hashtable.GetEnumerator() | Where-Object Name -eq $choice | Sort-Object Value | select -exp Value
                    Write-host "Are you sure you'd like to install $global:result ?"
                    $confirm =  Read-Host "Press y/n"
                            if ($confirm -like "y"){
                                break
                            }
                            else {
                                Write-host "Returning to beginning of menu..."
                                Start-sleep -Seconds 3 
                                
                            }
                }
                elseif ($choice -like "q"){
                    "Restarting this Menu"
                    Start-Sleep -Seconds 3
                }   
        }

        elseif ($option -eq "q"){
            Write-Host "Exiting this Script"
            exit 1 
        }

        elseif ($option -le $apps.Length){

            $global:result = $apps_hashtable.GetEnumerator() | Where-Object Name -eq $option | select -exp Value 
            Write-host "Are you sure you would like to install $global:result ?"  
            $confirm = read-host "press y/n"
                if ($confirm -eq "y"){
                    break 
                }
                else {
                    "Returning to beginning of menu..."
                    Start-Sleep -Seconds 3
                }
            
        }
        elseif ($choice -gt $apps.Length){

            Write-Host "the value you input is too high, please try again"
            Write-Host "Returning to beginning of menu..."
            Start-sleep -seconds 3 
        }
        
        }

}

function remote-install {

    Invoke-Command -ComputerName $args[0] { # Invokes commands on remote computer given a list of PCs designated by the -ComputerName parameter
    
        Invoke-Expression $using:net_command 
    
        Set-Location "Z:\Applications\$using:result" # Change directory into designated applicaiton folder 
    
        $cmd_file = Get-ChildItem -path "Z:\Applications\$using:result" | Where-Object Name -like "*.cmd" | select -exp Name # Extracts the .cmd file from app directory
        
        Invoke-Expression .\$cmd_file # executes .cmd file on remote computer
    
        }
    
    }

function pc-health { # If PC is able to be pinged, add it to alive_pcs array. If not, display error message to screen

    $check = $args[0]
    If ( Test-Connection -BufferSize 32 -Count 1 -ComputerName $check -Quiet )  
    { 
        $alive_pcs += $check 
    }
    else
    { Write-Host " $check is not available " -ForegroundColor Red
         continue }
         
    }
function get-pclist { # Function to take room number input and output list of PCs

    do { # Loop to keep prompting users for rooms until they press "q" 
        $room = Read-Host "Please enter your room number(s). (i.e openlab or a227). Press q and enter when finished" 
            
            if ($room -notlike "q"){ # Logic to make sure that the letter "q" is not entered into the array
            
            $roomarray += $room # adds user-defined room to room array 
                
            }
        } until ($room -like "q") # if user input is "q", exits the loop and continues to making the PC list 
            
              
    foreach ($room in $roomarray){ # Iterates through room array to change dns formatting and conduct AD search 
            
            
        $length =$room.Length # assigns the length of the room string to a variable
        $room = $room.Insert($length,"-*") # adds a wildcard asterisk at the end of the string to search for all PCs beginning with that DNS
        $room = $room.Insert(0,"s-") # adds correct Stanton Campus dns prefix 

        # Example: Input: openlab Output: s-openlab-*
                
        $getad = (([adsisearcher]"(&(objectCategory=Computer)(name=$room))").findall()).properties # Conducts an AD search based on Computer objects whose name is like room dns
                    
        $pc_list += $getad.cn # Adds all PCs dns names (that start with the room number) to pc_list array 
            
        #Example:
        # $room = s-openlab-*. Output would be s-openlab-01, s-openlab-02.... s-openlab-14, etc. 
        }
    
    }

Start-Menu 

############## Assigning Variables and arrays necessary for function use ######################


$roomarray = @()
$pc_list = @()
$pcs = @()
$alive_pcs = @()
$mdt_server = "\\s-mdt-w10\distribution$"
$drive_letter = "Z:"
$applications_dir = "Applications"

if (($list -eq "") -and ($room_method -eq $false) -or ($list -ne "") -and ($room_method = $true)){ # logic to catch inputs for both or neither of the two parameters for PC lists

    Write-Host "Error! You must choose (only) 1 method of importing PC Names" -BackgroundColor Red 

    exit 1 

}

#Prompting for User Credentials 
$username = read-host "Please enter your username" 
$password = read-host "Please enter your password"

#Assigning net use command to a string variable; workaround since net use won't take variables nicely
$net_command = "net use $drive_letter $mdt_server /user:dtcc\$username $password" 

$mdt_test = Test-Path -Path $drive_letter\$applications_dir 
  
################## Execution Block #####################

if ($mdt_test -eq $false){ # If Z:\applications isn't mounted, mount it by invoking net_command expression
    
        Invoke-Expression $net_command 
}

Start-Menu # Calls start menu function to retrieve desired application from user q


if ($room_method){

    get-pclist # calls function to get pc list by room number; assigns pcs to pc_list array
}
elseif ($list){

$pc_list = get-content $list # if list was provided, assigns $pc_list to the content of the list provided in the -l parameter
}

pc-health $pc_list # Calls pc health function to test connection on the pc_list; the ones that are able to be pinged get assigned to the alive_pcs array

remote-install $alive_pcs # calls remote-install function on the alive_pcs array. Uses invoke-command to run the remote installs in parallel with eachother
