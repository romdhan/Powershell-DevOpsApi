cls

#Chargement des variable globales
$path = $PSScriptRoot
$RootPath = Split-Path (Split-Path $path -Parent) -Parent
write-host "Chargement de donnees user" -foregroundcolor green
. "$PSScriptRoot/_config_par_user.ps1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))


$flagNombreMaxPipeline = 5
$flagShowDeployPhases = $false
$flagShowVariables = $false

$flagRunPipeline_id = 16

$filtreProject = "" #projet1/projet2
$filtreProjetEnvironnement = "" #integ/recette/prod
$filtreState = "" #inprogress, completed
$filtreResult = "" #succeeded,failed,

#https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/get?view=azure-devops-rest-6.0
#https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/list?view=azure-devops-rest-5.1
$response = Invoke-RestMethod "https://dev.azure.com/$collection/$projectName/_apis/pipelines?api-version=6.0-preview.1&searchText=$filtreProject" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}

foreach ($pipeline in $response.value){
    if( $filtreProject -eq "" -or $pipeline.name -like "*$filtreProject*"){
        $pipelineID = $pipeline.id
        write-host $pipeline.name "($pipelineID)"
        
        if($flagRunPipeline_id -gt 0 -and $pipelineID -eq $flagRunPipeline_id){
            #POST https://dev.azure.com/{organization}/{project}/_apis/pipelines/{pipelineId}/runs?api-version=6.0-preview.1
            
            $body = "{}"
            $responePipelineRunExecute = Invoke-RestMethod "https://dev.azure.com/$collection/$projectName/_apis/pipelines/$($pipelineID)/runs?api-version=6.0-preview.1" -Method 'POST' -body $body -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}    
            $responePipelineRunExecute
        }

        #recup des deployPhases definition
        $responsePipelineRuns = Invoke-RestMethod "https://dev.azure.com/$collection/$projectName/_apis/pipelines/$($pipelineID)/runs?api-version=6.0-preview.1" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
        #write-host $responseDeployPhases.environments
        foreach($rpr in $responsePipelineRuns.value | Select -First $flagNombreMaxPipeline ){
            if( $filtreState -eq "" -or $rpr.state -like "*$filtreState*"){        
                write-host "    $($rpr.name) - $($rpr.state) - " -NoNewline
                if($rpr.result -eq "succeeded"){
                    Write-Host "$($rpr.result)" -ForegroundColor Green
                }elseif($rpr.result -eq "failed"){
                    Write-Host "$($rpr.result)" -ForegroundColor Red
                }else{
                    Write-Host "$($rpr.result)" -ForegroundColor Magenta
                }
                #GET https://dev.azure.com/{organization}/{project}/_apis/pipelines/{pipelineId}/runs/{runId}/logs?api-version=6.0-preview.1
                #$responsePipelineRunLogs = Invoke-RestMethod "https://dev.azure.com/$collection/$projectName/_apis/pipelines/$($pipelineID)/runs/$($rpr.id)/logs?api-version=6.0-preview.1" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
            }
        }

        
    }
   
}
