
param (

 [Parameter(Mandatory=$false)][string]$list,
 [Parameter(Mandatory=$false)][switch]$room_method,
 [Parameter(Mandatory=$true)][string]$desired_version

 )


 #Defining Functions

 function pc-health {

$check = $args[0]
If ( Test-Connection -BufferSize 32 -Count 1 -ComputerName $check -Quiet )
{  }
else
{ Write-Host " $check is not available " -ForegroundColor Red
  continue }
 
}

function get-pclist {

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

function check-bios {

$computer = $args[0]
$desired_version += "*"

$bios=Get-WmiObject -Class Win32_BIOS -ComputerName $computer | select -exp Name  
 
 

           if ($bios -like $desired_version){
           #$computer | Out-File -FilePath C:\Users\jreece2\bios_final\updated.txt -Append
           Write-Host "$computer has a bios version of $bios" -ForegroundColor Green}
           
           else{
            
           Write-Host "$computer has a bios version of $bios" -ForegroundColor Yellow 
           # $computer | Out-File -FilePath C:\Users\jreece2\bios_final\neeeeds_update -Append
           }

} 


# Execution Block 

if ($list){
  
    $check_list = get-content $list 

    foreach ($computer in $check_list){

    pc-health $computer 

    check-bios $computer 

    } 
  }
   
elseif ($room_method){

    get-pclist  

foreach ($computer in $global:results){

    pc-health $computer

    check-bios $computer

}
}


else { #Error handling 

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

exit 1 
}





