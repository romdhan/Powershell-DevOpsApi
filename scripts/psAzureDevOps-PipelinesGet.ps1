cls

Remove-Variable * -ErrorAction SilentlyContinue

#Chargement des variable globales
$path = $PSScriptRoot
$RootPath = Split-Path (Split-Path $path -Parent) -Parent
write-host "Chargement de donnees user ..." -foregroundcolor green
. "$PSScriptRoot/_config_par_user.ps1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))

#list of flags
$flagNombreMaxPipeline = $pipelinesget_flagNombreMaxPipeline
$flagShowDeployPhases =  $pipelinesget_flagShowDeployPhases
$flagShowDeployPhasesDetails = $pipelinesget_flagShowDeployPhasesDetails #show runs details/numbers
$flagShowVariables =     $pipelinesget_flagShowVariables
$flagShowTriggers =     $pipelinesget_flagShowTriggers
$flagShowProcess =     $pipelinesget_flagShowProcess
$flagRunPipeline_id =    $pipelinesget_flagRunPipeline_id

#list of filters
$filtreProject = $pipelinesget_filtreProject
$filtreState =   $pipelinesget_filtreState
$filtreResult =  $pipelinesget_filtreResult
$filtreVariableNom = $pipelinesget_filtreVariableNom #nom ou partie du nom de la variable
$filtreVariableValeur = $pipelinesget_filtreVariableValeur #%valeur%

$filtreNeverRun = $pipelinesget_filtreNeverRun #$null: nothing, $true:show pipeline with 0 runs, $false:hide pipeline with 0 runs
$filtreOnlyLastFailed = $pipelinesget_filtreOnlyLastFailed #$null: nothing, $true:show pipeline with 0 runs, $false:hide pipeline with 0 runs

#$flagNombreMaxPipeline = 5
#$flagShowDeployPhases = $false
#$flagShowVariables = $false
#$flagRunPipeline_id = 16
#$filtreProject = "" #projet1/projet2
#$filtreState = "" #inprogress, completed
#$filtreResult = "" #succeeded,failed,

#intervention le 20220519
$filtreProject = "*critical*"
$flagShowVariables = $true

if($filtreProject -ne ""){
    write-host "*** recherche de [Project] $filtreProject" -ForegroundColor Yellow
}

$allPipelines = @()
#https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/get?view=azure-devops-rest-6.0
#https://docs.microsoft.com/en-us/rest/api/azure/devops/release/definitions/list?view=azure-devops-rest-5.1
$response = Invoke-RestMethod "$URL_DEVOPS_COMPLETE/_apis/build/definitions?api-version=6.0&includeAllProperties=true&searchText=$filtreProject" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}

foreach ($pipeline in $response.value | Sort-Object {$_.name}){
    $pkgInfo = @{
        'Pipeline' = $pipeline
        'variables' = $pipeline.variables
        'variableGroups' = $pipeline.variableGroups
        'triggers' = $pipeline.triggers
        'process' = $pipeline.process
    }

    if( $filtreProject -eq "" -or $pipeline.name -like "*$filtreProject*"){
        $pipelineID = $pipeline.id
        $strpipeline = $pipeline.name + "(#$pipelineID)"
        if($filtreNeverRun -in ($null)){
            if( $flagShowDeployPhases -eq $true -or $flagShowDeployPhasesDetails -eq $true){
                write-host $strpipeline "1st" -NoNewline
            }else{
                Write-Host $strpipeline "2nd"
            }
        }
        elseif($flagShowDeployPhases -eq $false -and $flagShowDeployPhasesDetails -eq $false){
            Write-Host $strpipeline "5th"
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
                if($filtreNeverRun -in ($true)){
                    continue
                }
                elseif($filtreNeverRun -in ($false)){
                    Write-Host $strpipeline "4th" -NoNewline
                }

                $lastRun = $($responsePipelineRuns.value | Sort-Object {$_.id} | Select-Object -Last 1)
                $lastRunsResult = $($responsePipelineRuns.value | Sort-Object {$_.id} | Select-Object -Last 1).result
                $nbreRunsResultRunning    = ($responsePipelineRuns.value | Where-Object {$_.result -eq $null}  | Measure-Object).Count
                $nbreRunsResultSucceded   = ($responsePipelineRuns.value | Where-Object {$_.result -eq "succeeded"} | Measure-Object).Count
                $nbreRunsResultFailed     = ($responsePipelineRuns.value | Where-Object {$_.result -eq "failed"} | Measure-Object).Count
                $nbreRunsResultCanceled   = ($responsePipelineRuns.value | Where-Object {$_.result -eq "canceled"} | Measure-Object).Count
                    
                if($filtreOnlyLastFailed -in ($true)){
                    if($lastRunsResult -ne "failed"){
                        continue
                    }
                }

                write-host "`t" -NoNewline
                if($lastRunsResult -eq "succeeded"){
                    Write-Host "$($lastRunsResult)/$($lastRun.state)" -NoNewline -ForegroundColor Green
                }
                elseif($lastRunsResult -eq "failed"){
                    Write-Host "$($lastRunsResult)/$($lastRun.state)" -NoNewline -ForegroundColor Red
                }
                else{
                    Write-Host "$($lastRunsResult)/$($lastRun.state)" -NoNewline -ForegroundColor Magenta
                }

                write-host " [$('{0:d3}' -f $responsePipelineRuns.value.Count) : " -NoNewline -ForegroundColor Magenta
                Write-Host "$($nbreRunsResultRunning) en cours, " -NoNewline -ForegroundColor Blue
                Write-Host "$($nbreRunsResultSucceded) ok, " -NoNewline -ForegroundColor Green
                write-host "$($nbreRunsResultFailed) failed, " -NoNewline -ForegroundColor Red
                write-host "$($nbreRunsResultCanceled) canceled]" -ForegroundColor Magenta

                if( $flagShowDeployPhases -eq $true){
                    foreach($rpr in $responsePipelineRuns.value | Select -First $flagNombreMaxPipeline ){
                        if( $filtreState -eq "" -or $rpr.state -like "*$filtreState*"){        
                            write-host "    $($rpr.name) (#$($rpr.id)) - $($rpr.state)" -NoNewline
                            if($rpr.state -ne "inprogress"){
                                if($rpr.result -eq "succeeded"){
                                    Write-Host " - $($rpr.result)" -ForegroundColor Green
                                }
                                elseif($rpr.result -eq "failed"){
                                    Write-Host " - $($rpr.result)" -ForegroundColor Red
                                }
                                else{
                                    Write-Host " - $($rpr.result)" -ForegroundColor Magenta
                                }   
                            }else{
                                write-host ""
                            }
                            #GET https://dev.azure.com/{organization}/{project}/_apis/pipelines/{pipelineId}/runs/{runId}/logs?api-version=6.0-preview.1
                            #$responsePipelineRunLogs = Invoke-RestMethod "https://dev.azure.com/$collection/$projectName/_apis/pipelines/$($pipelineID)/runs/$($rpr.id)/logs?api-version=6.0-preview.1" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
                        }
                    }
                }
            }
            else{
                if($filtreNeverRun -in ($true)){
                    Write-Host $strpipeline "3rd" -NoNewline
                }
                elseif($filtreNeverRun -in ($false)){
                    continue
                }
                write-host "`tnever runned" -ForegroundColor Red
            }
        }
           
        #recup triggers
        if( $flagShowTriggers -eq $true ){
            if($pkgInfo.triggers.Count -gt 0){
                #write-host "`t$($responsePipelineDefinitions.Triggers.Count) triggers trouvés"
                write-host "`t$($pkgInfo.triggers.triggerType)"
            }
        }
      
        #recup variables
        if( $flagShowVariables -eq $true ){
            write-host "    affichage des variables ... " -ForegroundColor Magenta
            foreach($rpr in $pkgInfo.variables.PSObject.Properties | Sort-Object {$_.name} ){
                if( ($filtreVariableNom -eq "" -or $rpr.Name -like "*$($filtreVariableNom)*") -and ( $filtreVariableValeur -eq "" -or $rpr.Value.value -like "*$filtreVariableValeur*")){
                    write-host "   "$rpr.Name -NoNewline -ForegroundColor Cyan
                    #write-host " ($($libV.id))" -NoNewline
                    Write-Host " ==> " -NoNewline 
                    write-host $rpr.Value.value                   
                }
            }

            if($pkgInfo.variableGroups.Count -gt 0){
                #write-host "`taffichage des variables groups ... " -ForegroundColor Magenta
                foreach($pvg in $pkgInfo.variableGroups){
                    #write-host "`t$($pvg.name)"
                    write-host "`taffichage des variables de $($pvg.name) ... " -ForegroundColor Magenta
                    foreach($pvg_v in $pvg.variables.PSObject.Properties | Sort-Object {$_.name}){
                        if( ($filtreVariableNom -eq "" -or $pvg_v.Name -like "*$($filtreVariableNom)*") -and ( $filtreVariableValeur -eq "" -or $pvg_v.Value.value -like "*$filtreVariableValeur*")){
                            write-host "   "$pvg_v.Name -NoNewline -ForegroundColor Cyan
                            #write-host " ($($libV.id))" -NoNewline
                            Write-Host " ==> " -NoNewline 
                            write-host $pvg_v.Value.value                   
                        }
                    }
                }
            }
        }

        #show process
        if( $flagShowProcess -eq $true ){
            foreach($php in $pkgInfo.process.phases ){
                write-host "`t$($php.name)"
                foreach($phpS in $php.steps){
                    write-host "`t`t$($phpS.displayName)" -NoNewline 
                    if($phpS.task.definitionType -eq "metaTask"){
                        write-host " ($($phpS.task.definitionType))" -ForegroundColor Red
                    }else{
                        write-host " ($($phpS.task.definitionType))"
                    }
                    if($false -eq $true){ #todo flag show tasks input
                        foreach($phpSInp in $phpS.inputs.PSObject.Properties){
                            write-host "`t`t`t$($phpSInp.Name)" -NoNewline -ForegroundColor Cyan
                            Write-Host " ==> " -NoNewline 
                            write-host $phpSInp.Value  
                        }
                    }

                    if($phpS.task.definitionType -eq "metaTask"){
                        #GET https://dev.azure.com/{organization}/{project}/_apis/distributedtask/taskgroups/{taskGroupId}?api-version=6.0-preview.1
                        $tasksFromMetaTask = Invoke-RestMethod "$URL_DEVOPS_COMPLETE/_apis/distributedtask/taskgroups/$($phpS.task.id)?api-version=6.0-preview.1&expanded=True" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
                        foreach($tasks in $tasksFromMetaTask.value){
                            foreach($task in $tasks.tasks){
                                write-host "`t`t`t$($task.displayName) ($($task.task.definitionType))" 
                            }
                        }
                    }
                }
            }
        }
    }


    # add the table as PSobject to variable with all the package information
    $allPipelines += New-Object psobject -Property $pkgInfo
}
