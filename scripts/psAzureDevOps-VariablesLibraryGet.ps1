﻿cls

#Chargement des variable globales
$path = $PSScriptRoot
$RootPath = Split-Path (Split-Path $path -Parent) -Parent
write-host "Chargement de donnees user" -foregroundcolor green
. "$PSScriptRoot/_config_par_user.ps1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))


$filtreProjet = ""
$filtreProjetEnvironnement = "" #prod/recette/integ
$filtreVariableNom = "" #nom ou partie du nom de la variable
$filtreVariableValeur = "" #%valeur%

#https://docs.microsoft.com/en-us/rest/api/azure/devops/distributedtask/variablegroups/get-variable-groups?view=azure-devops-rest-6.0
#GET https://dev.azure.com/{organization}/{project}/_apis/distributedtask/variablegroups?api-version=6.0-preview.2
$response = Invoke-RestMethod "$URL_DEVOPS_COMPLETE/_apis/distributedtask/variablegroups?groupName=*$filtreProjet*&api-version=6.0-preview.2" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
write-host $($response.count) "variableGroupe"


$response.value = $response.value | Sort-Object {$_.id}
foreach ($library in $response.value){
    if( (($filtreProjet -eq "") -or ($library.name -like "*$filtreProjet*" )) -and (  ($filtreProjetEnvironnement -eq "" ) -or ( $library.name -like "*$filtreProjetEnvironnement*" )) ){
        write-host "$($library.name) (id#$($library.id))"
        #$library.variables.GetType()
        #$library.variables.PSObject.Properties | Out-GridView
        foreach($libV in $library.variables.PSObject.Properties){
            if( ($filtreVariableNom -eq "" -or $libV.Name -like "*$($filtreVariableNom)*") -and ( $filtreVariableValeur -eq "" -or $libV.Value.value -like "*$filtreVariableValeur*")){
                #write-output $libV
                
                write-host "   "$libV.Name -NoNewline -ForegroundColor Cyan
                #write-host " ($($libV.id))" -NoNewline
                Write-Host " ==> " -NoNewline 
                write-host $libV.Value.value
            }
        }
        #return;
    }
}
