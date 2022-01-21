cls

#Chargement des variable globales
$path = $PSScriptRoot
$RootPath = Split-Path (Split-Path $path -Parent) -Parent
write-host "Chargement de donnees user" -foregroundcolor green
. "$PSScriptRoot/_config_par_user.ps1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))

#list of flags
#$flagNombreMaxPipeline = $pipelinesget_flagNombreMaxPipeline

#list of filters
$filtreAgentPool = $agentspoolget_filtreAgentPool
$filtreAgentPoolAgent =   $agentspoolget_filtreAgentPoolAgent
$filtreAgentPoolAgentSysCap = $agentspoolget_filtreAgentPoolAgentSysCap
$filtreAgentPoolAgentSysCapName = $agentspoolget_filtreAgentPoolAgentSysCapName
$filtreAgentPoolAgentSysCapValeur = $agentspoolget_filtreAgentPoolAgentSysCapValeur


#GET https://dev.azure.com/{organization}/_apis/distributedtask/pools?api-version=6.0
$getpools = Invoke-RestMethod "$URL_DEVOPS_COLLECTION/_apis/distributedtask/pools?api-version=6.0" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}

if( $getpools.value.Count -gt 0){
    write-host "$($getpools.value.Count) agent pools found" -ForegroundColor Magenta
    foreach ($agentpool in $getpools.value){
        if( $filtreAgentPool -eq "" -or $agentpool.name -like "*$filtreAgentPool*"){
            $agentpoolid = $agentpool.id
            write-host $agentpool.name "(#$agentpoolid)"

            #GET https://dev.azure.com/{organization}/_apis/distributedtask/pools/{poolId}?api-version=6.0
            <#
            $agentpoolById = Invoke-RestMethod "$URL_DEVOPS_COLLECTION/_apis/distributedtask/pools/$($agentpoolid)?api-version=6.0" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
            write-output $agentpoolById
            return
            foreach($rpr in $responsePipelineDefinitions.variables.PSObject.Properties){
                write-host "   "$rpr.Name -NoNewline -ForegroundColor Cyan
                #write-host " ($($libV.id))" -NoNewline
                Write-Host " ==> " -NoNewline 
                write-host $rpr.Value.value                   
            }
            #>  

            #get agents
            $agentsById = Invoke-RestMethod "$URL_DEVOPS_COLLECTION/_apis/distributedtask/pools/$($agentpoolid)/agents?agentName=&includeCapabilities=true&includeAssignedRequest=true&includeLastCompletedRequest=true&propertyFilters=&demands=&api-version=6.0" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
            if($agentsById.value.Count -gt 0){
                write-host "    $($agentsById.value.Count) agents found" -ForegroundColor Magenta
                foreach($agent in $agentsById.value){
                    if( $filtreAgentPoolAgent -eq "" -or $agent.name -like "*$filtreAgentPoolAgent*"){
                        write-host "   "$agent.Name "(#$($agent.id))" -ForegroundColor Cyan
                        #affichage des systemCapabilities
                        foreach($agentsyscap in $agent.systemCapabilities.PSObject.Properties){
                            if( ($filtreAgentPoolAgentSysCapName -eq "" -or $agentsyscap.Name -like "*$($filtreAgentPoolAgentSysCapName)*") -and ( $filtreAgentPoolAgentSysCapValeur -eq "" -or $agentsyscap.Value.value -like "*$filtreAgentPoolAgentSysCapValeur*")){
                                write-host "`t`t"$agentsyscap.Name -ForegroundColor Cyan -NoNewline
                                Write-Host " ==> " -NoNewline 
                                write-host $agentsyscap.value   
                            }
                        }
                    }
                }
            }else{
                write-host "    no agents found" -ForegroundColor Magenta
            }
        }
    }
}else{
    write-host "no agent pools found" -ForegroundColor Magenta
}
