cls

#Chargement des variable globales
$path = $PSScriptRoot
$RootPath = Split-Path (Split-Path $path -Parent) -Parent
write-host "Chargement de donnees user" -foregroundcolor green
. "$PSScriptRoot/_config_par_user.ps1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))

#chargement des variables globales
$flagShowEnvironments = $releasedefinitionsget_flagShowEnvironments
$flagShowDeployPhases = $releasedefinitionsget_flagShowDeployPhases
$flagShowVariables = $releasedefinitionsget_flagShowVariables
$filtreProject = $releasedefinitionsget_filtreProject #projet1/projet2
$filtreProjetEnvironnement = $releasedefinitionsget_filtreProjetEnvironnement #integ/recette/prod
$filtreVariableNom = $releasedefinitionsget_filtreVariableNom #connexion
$filtreVariableValeur = $releasedefinitionsget_filtreVariableValeur #server

<#
$flagShowEnvironments = $false
$flagShowDeployPhases = $false
$flagShowVariables = $false
$filtreProject = "" #projet1/projet2
$filtreProjetEnvironnement = "" #integ/recette/prod
$filtreVariableNom = "" #connexion
$filtreVariableValeur = "" #server
#>

#https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/get?view=azure-devops-rest-6.0
#https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/list?view=azure-devops-rest-5.1
$response = Invoke-RestMethod "https://vsrm.dev.azure.com/$collection/$projectName/_apis/release/definitions?`$expand=Environments,Artifacts,Variables,lastRelease,tags,triggers&`$top=100&api-version=5.1&searchText=$filtreProject" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}

#$response 
#$response.value.Count

#return
foreach ($releaseDefinition in $response.value  | Sort-Object -Property name){
    if( $filtreProject -eq "" -or $releaseDefinition.name -like "*$filtreProject*"){
        $releaseDefinitionID = $releaseDefinition.id
        write-host $releaseDefinition.name "($releaseDefinitionID)"
        
        if( $flagShowEnvironments -or $flagShowDeployPhases){
            #recup des deployPhases definition
            $responseDeployPhases = Invoke-RestMethod "https://vsrm.dev.azure.com/$collection/$projectName/_apis/release/definitions/$($releaseDefinitionID)?api-version=5.1" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
            #write-host $responseDeployPhases.environments

            #write-host "--------------------------------------------------"
            foreach ($environment in $responseDeployPhases.environments){
                if(  ($filtreProjetEnvironnement -eq "" ) -or ( $environment.name -like "*$filtreProjetEnvironnement*" )){
                    write-host "   $($environment.name)"                
                    $definitionEnvironmentId = $environment.id

                    if($flagShowDeployPhases){
                        #####################################                
                        Write-host "      Affichage des deployPhases " -ForegroundColor Yellow
                        foreach($dp in $environment.deployPhases){
                            write-host "      $($dp.name)"
                            foreach( $dpTask in $dp.workflowTasks){
                                write-host "         $($dpTask.name)"    
                            }
                        }
                    }


                    if($flagShowVariables){
                        #####################################
                        #Write-output $environment.variables
                        Write-host "      Affichage des variable " -ForegroundColor Yellow
                        foreach($libV in $environment.variables.PSObject.Properties){
                            if( ($filtreVariableNom -eq "" -or $libV.Name -like "*$($filtreVariableNom)*") -and ( $filtreVariableValeur -eq "" -or $libV.Value.value -like "*$filtreVariableValeur*")){
                                write-host "     "$libV.Name -NoNewline -ForegroundColor Cyan
                                Write-Host " ==> " -NoNewline 
                                write-host $libV.Value.value
                            }
                        }
                    }
                    #recup des deployments
                    #$response = Invoke-RestMethod "https://vsrm.dev.azure.com/$collection/$projectName/_apis/release/deployments?api-version=5.0&deploymentStatus=succeeded&latestAttemptsOnly=true&definitionEnvironmentId=$definitionEnvironmentId&`$top=1" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
                    #write-host $response.value[0].release.name $response.value[0].deploymentStatus $response.value[0].completedOn
                }
            }
            #write-host "--------------------------------------------------"

        }
    }
   
}
