cls

#Chargement des variable globales
$path = $PSScriptRoot
$RootPath = Split-Path (Split-Path $path -Parent) -Parent
write-host "Chargement de donnees user" -foregroundcolor green
. "$PSScriptRoot/_config_par_user.ps1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))

#list of flags
$flagNombreMaxPipeline = $pipelinesget_flagNombreMaxPipeline
$flagShowDeployPhases =  $pipelinesget_flagShowDeployPhases
$flagShowDeployPhasesDetails = $pipelinesget_flagShowDeployPhasesDetails #show runs details/numbers
$flagShowVariables =     $pipelinesget_flagShowVariables
$flagRunPipeline_id =    $pipelinesget_flagRunPipeline_id

#list of filters
$filtreProject = $pipelinesget_filtreProject
$filtreState =   $pipelinesget_filtreState
$filtreResult =  $pipelinesget_filtreResult

$filtreNeverRun = $pipelinesget_filtreNeverRun #$null: nothing, $true:show pipeline with 0 runs, $false:hide pipeline with 0 runs

#$flagNombreMaxPipeline = 5
#$flagShowDeployPhases = $false
#$flagShowVariables = $false
#$flagRunPipeline_id = 16
#$filtreProject = "" #projet1/projet2
#$filtreState = "" #inprogress, completed
#$filtreResult = "" #succeeded,failed,

if($filtreProject -ne ""){
    write-host "*** recherche de $filtreProject" -ForegroundColor Yellow
}

#https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/get?view=azure-devops-rest-6.0
#https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/list?view=azure-devops-rest-5.1
$response = Invoke-RestMethod "$URL_DEVOPS_COMPLETE/_apis/pipelines?api-version=6.0-preview.1&searchText=$filtreProject" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}

foreach ($pipeline in $response.value){
    if( $filtreProject -eq "" -or $pipeline.name -like "*$filtreProject*"){
        $pipelineID = $pipeline.id
        $strpipeline = $pipeline.name + "(#$pipelineID)"
        if( $filtreNeverRun -in ($null)){
            write-host $strpipeline
        }
        
        #run a defined pipeline
        if($flagRunPipeline_id -gt 0 -and $pipelineID -eq $flagRunPipeline_id){
            write-host "   démarrage du pipeline ... " -ForegroundColor Green
            $body = "{}"
            $responePipelineRunExecute = Invoke-RestMethod "$URL_DEVOPS_COMPLETE/_apis/pipelines/$($pipelineID)/runs?api-version=6.0-preview.1" -Method 'POST' -body $body -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}    
            $responePipelineRunExecute
        }
        
        #recup des deployPhases definition
        if( $flagShowDeployPhases -eq $true -or $flagShowDeployPhasesDetails -eq $true){
            $responsePipelineRuns = Invoke-RestMethod "$URL_DEVOPS_COMPLETE/_apis/pipelines/$($pipelineID)/runs?api-version=6.0-preview.1" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
            #write-host $responseDeployPhases.environments
            if($responsePipelineRuns.value.Count -gt 0){
                if($filtreNeverRun -eq $false){                    
                    write-host $strpipeline -NoNewline
                }
                if($filtreNeverRun -in ($false, $null)){
                    $lastRunsResult = $($responsePipelineRuns.value | Sort-Object {$_.id} | Select-Object -Last 1).result
                    $nbreRunsResultSucceded = $($responsePipelineRuns.value | Where-Object {$_.result -eq "succeeded"}).count
                    $nbreRunsResultFailed = $($responsePipelineRuns.value | Where-Object {$_.result -eq "failed"}).count

                    
                    write-host "`t" -NoNewline
                    if($lastRunsResult -eq "succeeded"){
                        Write-Host "$($lastRunsResult)" -NoNewline -ForegroundColor Green
                    }elseif($lastRunsResult -eq "failed"){
                        Write-Host "$($lastRunsResult)" -NoNewline -ForegroundColor Red
                    }else{
                        Write-Host "$($lastRunsResult)" -NoNewline -ForegroundColor Magenta
                    }

                    write-host " [$($responsePipelineRuns.value.Count) : " -NoNewline -ForegroundColor Magenta
                    Write-Host "$($nbreRunsResultSucceded) ok, " -NoNewline -ForegroundColor Green
                    write-host "$($nbreRunsResultFailed) failed]" -ForegroundColor Red

                    <#
                    $col=@(                        
                        [PSCustomObject]@{namepipeline=$strpipeline},
                        [PSCustomObject]@{nbBuilds=$responsePipelineRuns.value.Count}
                    )
                    $col | Format-Table namepipeline,nbBuilds -AutoSize
                    #>

                    if( $flagShowDeployPhases -eq $true){
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
            }
            else{
                if($filtreNeverRun -eq $true){
                    write-host $strpipeline -NoNewline
                }
                if( $filtreNeverRun -ne $false){
                    write-host "`tnever runned" -ForegroundColor Red
                }
            }
        }

        #recup variables
        if($flagShowVariables -eq $true){
            write-host "   affichage des variables ... " -ForegroundColor Magenta
            $responsePipelineDefinitions = Invoke-RestMethod "$URL_DEVOPS_COMPLETE/_apis/build/definitions/$($pipelineID)?api-version=6.0" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
            #write-output $responsePipelineDefinitions
            #return
            foreach($rpr in $responsePipelineDefinitions.variables.PSObject.Properties){
                write-host "   "$rpr.Name -NoNewline -ForegroundColor Cyan
                #write-host " ($($libV.id))" -NoNewline
                Write-Host " ==> " -NoNewline 
                write-host $rpr.Value.value                   
            }
        }        
    }   
}
