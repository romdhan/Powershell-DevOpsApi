cls

#Chargement des variable globales
$path = $PSScriptRoot
$RootPath = Split-Path (Split-Path $path -Parent) -Parent
write-host "Chargement de donnees user" -foregroundcolor green
. "$PSScriptRoot/_config_par_user.ps1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))

$filtreProject = $reposget_filtreProjet
#$filtreProject = "" #projet1/projet2

#https://docs.microsoft.com/en-us/rest/api/azure/devops/git/repositories/list?view=azure-devops-rest-4.1
$response = Invoke-RestMethod "$URL_DEVOPS_COMPLETE/_apis/git/repositories?includeLinks=true&includeAllUrls=true&includeHidden=true&api-version=4.1" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
write-host "$($response.count) repositori(es)"
foreach ($repo in $response.value){
    if( $filtreProject -eq "" -or $repo.name -like "*$filtreProject*"){
        $repoID = $repo.id
        write-host $repo.name "($repoID)"
        write-host "   " $repo.remoteUrl -ForegroundColor Cyan
    }
   
}
