param (

 [Parameter(Mandatory=$false)][string]$list,
 [Parameter(Mandatory=$false)][switch]$room_method,
 [Parameter(Mandatory=$true)][string]$application

 )

$credential = Get-Credential 


function pc-health {

$check = $args[0]
If ( Test-Connection -BufferSize 32 -Count 1 -ComputerName $check -Quiet )
{  }
else
{ Write-Host " $check is not available " -ForegroundColor Red
  continue }
 
}

function list-computers {

$roomarray = @() 
$global:results = @()

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
$global:results += $getad.cn

}}


function local-test {

    $Share_test = Test-Path Z:\Applications
     
    if ($Share_test){ } # do nothing if the path already exists 

    else {

    New-PSDrive -name "Z" -PSProvider FileSystem -Root \\s-mdt-w10\distribution$ -Credential $credential # mounting distribution share locally to Z: if doesn't exist. 
    } 

    $app_search = Get-ChildItem -Path Z:\Applications | select-string $application | sort # Querying the Applications folder for the application specified by user 

    $pathtest = Test-Path "Z:\Applications\$application" # Testing to see if the folder for the user-specified application exists. 

    if ($pathtest){

    cd "Z:\Applications\$application"}

    else {

    Write-Host "Error! Can't find designated application. Please ensure to type the application exactly as it appears in the distribution share" -BackgroundColor Red 
    echo ""
    echo "Below are some potential matches to the application you typed"
    echo ""
    echo $app_search 

    exit 1
 
   }

    $cmd_file = Get-ChildItem -path "Z:\Applications\$application" | Where-Object Name -like "*.cmd" | select -exp Name

    if ($cmd_file){

    echo "This application does have a .cmd file" 

    }

    else{

    echo "this application does not have a .cmd file. This application cannot be installed"
    exit 1 
    }

    $global:local_test = $true
}

function remote-install {

Invoke-Command -ComputerName $args[0] {

    New-PSDrive -name "Z" -PSProvider FileSystem -Root \\s-mdt-w10\distribution$ -Credential $credential

    cd "Z:\Applications\$application"

    $cmd_file = Get-ChildItem -path "Z:\Applications\$application" | Where-Object Name -like "*.cmd" | select -exp Name
    
    Invoke-Expression .\$cmd_file 

    }

}

 
 if ($Global:local_test){ # if the local testing of directories went well, this is executed

    
    if ($room_method){

        foreach ($comp in $global:results){
        
        pc-health $comp 

        remote-install $comp 

        }
  }


    elseif ($list) {
    $computers = get-content $list 

    foreach ($comp in $computers){

    pc-health $comp 

    remote-install $comp 


    }}


    else{  #change error handling to be relevant to the actual script, not bios_check

    echo ""
    echo "Please designate if you want to use a list or manually select rooms" -BackgroundColor Red 
    echo ""
    echo "Example:"
    echo ""
    echo ".\bios_check -l <list path here> -d <desired version here>"
    echo ""
    echo "OR"
    echo ""
    echo ".\bioscheck.ps1 -r -d <desired version>" 
    }
 

 }







