cls

<#
    Analyse du service azure devops
    - nombre de roots : TODO 
    - nombre/list de projects
    - nombre/liste de repos
#>

#Chargement des variable globales
$path = $PSScriptRoot
$RootPath = Split-Path (Split-Path $path -Parent) -Parent
write-host "Chargement de donnees user" -foregroundcolor green
. "$PSScriptRoot/_config_par_user.ps1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))

$flagShowRepos = $AAnalyseDevOps_flagShowRepos

$getprojects = Invoke-RestMethod "$URL_DEVOPS_COLLECTION/_apis/projects?api-version=6.0" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}

if( $getprojects.value.Count -gt 0){
    write-host "$($getprojects.value.Count) projects found" -ForegroundColor Magenta
    foreach ($proj in $getprojects.value){
        write-host "$($proj.name) (#$($proj.id))"

        # show all repositories
        if( $flagShowRepos -eq $true){
            $getprojRepos = Invoke-RestMethod "$URL_DEVOPS_COLLECTION/$($proj.name)/_apis/git/repositories?includeLinks=true&includeAllUrls=true&includeHidden=true&api-version=4.1" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
            if( $getprojRepos.value.Count -gt 0){
                write-host "`t$($getprojRepos.value.Count) repositories found" -ForegroundColor Magenta
                foreach ($projRepo in $getprojRepos.value){
                    write-host "`t$($projRepo.name) - ($($projRepo.remoteUrl))"
                }
            }else{
                write-host "`tNo repositories found" -ForegroundColor Red
            }
        }

        # show all pipelines
        if($flagShowPipelines -eq $true){
            $getprojPipelines = Invoke-RestMethod "$URL_DEVOPS_COLLECTION/$($proj.name)/_apis/pipelines?api-version=6.0-preview.1&searchText=$filtreProject" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
            
            foreach ($pipeline in $getprojPipelines.value){
                if( $filtreProject -eq "" -or $pipeline.name -like "*$filtreProject*"){
                    $pipelineID = $pipeline.id
                    $strpipeline = $pipeline.name + "(#$pipelineID)"
                    if( $filtreNeverRun -in ($null) -or $flagShowVariables -eq $true){
                        write-host $strpipeline
                    }
                }
            }
        }
    }
}else{
    write-host "NO projects found" -ForegroundColor Red
}