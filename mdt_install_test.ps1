param (

 [Parameter(Mandatory=$false)][string]$list,
 [Parameter(Mandatory=$false)][switch]$room_method
 )

function Start-Menu {

    $apps = Get-ChildItem -Path C:\Users\jeree\script_test | Select-Object -exp Name 
    $app_length = $apps.Length -1
    $apps_hashtable = @{}
     
    for ($x = 0; $x -lt $apps.Length; $x++){
   
       $apps_hashtable.Add("$x", $apps[$x])
   
    }

    While ($true){

    $apps_hashtable.GetEnumerator() | Sort-Object  Value |  Format-Table 
    Write-host "[s] Search for Application"
    Write-host "[0 - $app_length] Install Corresponding Applicaiton" 
    Write-host "[q] Exit this Script"
    $search = read-host 

    if ($search -like "s"){

        $search = read-host "Please enter the name of the application you'd like to search"
        $global:result = $apps_hashtable.GetEnumerator() | Where-Object Value -like *$search* | Sort-Object Name | Format-Table  
        
        if ( $null -eq $global:result ){
            Write-host "There were no matches with your search, Please try again"
            Write-host ""
            Write-Host "Returning to Beginning of Menu..."
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

    elseif ($search -le $apps.Length){

        $global:result = $apps_hashtable.GetEnumerator() | Where-Object Name -eq $search | select -exp Value 
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

    elseif ($search -eq "q"){
        Write-Host "Exiting this Script"
        exit 1 
    }

    elseif ($search -gt $apps.Length){

        Write-Host"the value you input is too high, please try again"
        Start-sleep -seconds 3 
    }
    }

}

function remote-install {

    Invoke-Command -ComputerName $args[0] {
    
        Invoke-Expression $net_command
    
        cd "Z:\Applications\$result"
    
        $cmd_file = Get-ChildItem -path "Z:\Applications\$result" | Where-Object Name -like "*.cmd" | select -exp Name
        
        Invoke-Expression .\$cmd_file 
    
        }
    
    }

function pc-health {

    $check = $args[0]
    If ( Test-Connection -BufferSize 32 -Count 1 -ComputerName $check -Quiet )
    { 
        $alive_pcs += $check 
    }
    else
    { Write-Host " $check is not available " -ForegroundColor Red
         continue }
         
    }
function get-pclist {

    do {
        $room = Read-Host "Please enter your room number(s). Press q and enter when finished"
            
            if ($room -notlike "q"){
            
            $roomarray += $room
                
            }
        } until ($room -like "q")
            
              
    foreach ($room in $roomarray){
            
            
        $length =$room.Length 
        $room = $room.Insert($length,"-*")
        $room = $room.Insert(0,"s-")
                
        $getad = (([adsisearcher]"(&(objectCategory=Computer)(name=$room))").findall()).properties
                    
        $pc_list += $getad.cn
            
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

if (($list -eq "") -and ($room_method -eq $false) -or ($list -ne "") -and ($room_method = $true)){ # logic to catch inputs for both or neither of the two parameters for PC lists

    Write-Host "Error! You must choose (only) 1 method of importing PC Names" -BackgroundColor Red 

    exit 1 

}

#Prompting for User Credentials 
$username = read-host "Please enter your username" 
$password = read-host "Please enter your password"

#Assigning net use command to a string variable; workaround since net use won't take variables nicely
$net_command = "net use $drive_letter $mdt_server /user:dtcc\$username $password" 

 

$mdt_test = Test-Path -Path Z:\Applications 


if ($mdt_test -eq $false){ # If Z:\applications isn't mounted, mount it by invoking net_command expression
    
        Invoke-Expression $net_command 
}

Start-Menu # Calls start menu function to retrieve desired application from user q


if ($room_method){

    get-pclist # calls function to get pc list by room number; assigns pcs to pc_list array
}
elseif ($list){

$pc_list = get-content $list # assigns $pc_list to the content of the list provided in the -l parameter
}

pc-health $pc_list # Calls pc health function to test connection on the pc_list; the ones that are connected get assigned to the alive_pcs array

remote-install $alive_pcs # calls remote-install function on the alive_pcs array. Uses invoke-command to run the remote installs in parallel with eachother

