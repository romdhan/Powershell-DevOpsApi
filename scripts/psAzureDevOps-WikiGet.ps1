cls

#Chargement des variable globales
$path = $PSScriptRoot
$RootPath = Split-Path (Split-Path $path -Parent) -Parent
write-host "Chargement de donnees user" -foregroundcolor green
. "$PSScriptRoot/_config_par_user.ps1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))

$filtrePage = "" #page/partieWiki : wiki name
$filtreMotCle = "test"

$response = Invoke-RestMethod "$URL_DEVOPS_COLLECTION/_apis/wiki/wikis?api-version=6.0" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}

foreach ($wiki in $response.value){
    write-host "wikiName : $($wiki.name)"
    

    $responsePages = Invoke-RestMethod "$($wiki.url)/Pages?api-version=6.0&includeContent=true&recursionLevel=full" -Method 'GET' -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}    
    #write-host $responsePages.subPages.Count
    function ShowSubPages{ #($respPage, $nv){
        Param
        (
                $respPage,
                [int]$nv
        )
        
        if( $respPage -ne $null -and $respPage.subPages -ne $null -and $respPage.subPages.Count -gt 0){
            #write-host " show sub pages" -ForegroundColor Magenta
            foreach($rp in $respPage.subPages){
                if($filtrePage -eq "" -or $rp.path -like  "*$filtrePage*"){
                    write-host " $("`t"*$nv) $($rp.path)" -NoNewline

                    if( $filtreMotCle -ne ""){
                        $responseContent = Invoke-RestMethod "$($wiki.url)/Pages?path=$($rp.path)&api-version=6.0&includeContent=true&path=$($rp.path)" -Method 'GET' -ContentType "application/json" -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}    
                        if($responseContent.content -ne $null -and $responseContent.content -ne ""){
                            #write-host "`t$($responseContent.content)" -ForegroundColor cyan
                            write-host "`t$(  $responseContent.content.Substring(0, [System.Math]::Min(100, $responseContent.content.length)) -replace '\r','#N#' -replace '\n','#N#')" -ForegroundColor cyan
                        }else{
                            write-host "`t content vide####"
                            #content vide
                        }
                    }else{
                        write-host ""
                    }

                    #Affichage du niveau suivant
                    $nv2 = $nv + 1
                    #write-host $niveau.GetType()
                    ShowSubPages -respPage $rp -nv $nv2
                }
            }   
        }else{
            #write-output $respPage
            #write-host "`telse"
        }
    }

    ShowSubPages -respPage $responsePages -nv 0

}
