cls

#Chargement des variable globales
$path = $PSScriptRoot
$RootPath = Split-Path (Split-Path $path -Parent) -Parent
write-host "Chargement de donnees user" -foregroundcolor green
. "$PSScriptRoot/_config_par_user.ps1"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $token)))


$filtreProjet = "simba - integ"
$filtreProjetID = 9

$variableAAjouterOuModifier = @{}
$variableAAjouterOuModifier.Add("ApplicationCode", "SimbaProject MODIFICATION")
#$variableAAjouterOuModifier.Add("ApplicationCodePostit", "SimbaProject")
$variableAAjouterOuModifier.Add("LOG4NET_SOURCETECH_APIEXTERNAL", @{value= "Simba-ApiExternal-INTEG"})
$variableAAjouterOuModifier.Add("LOG4NET_SOURCETFONC_APIEXTERNAL", @{value= "Simba-ApiExternal-INTEG"})


#https://docs.microsoft.com/en-us/rest/api/azure/devops/distributedtask/variablegroups/get-variable-groups?view=azure-devops-rest-6.0
#GET https://dev.azure.com/{organization}/{project}/_apis/distributedtask/variablegroups?api-version=6.0-preview.2
$response = Invoke-RestMethod "https://dev.azure.com/$collection/$projectName/_apis/distributedtask/variablegroups/$($filtreProjetID)?groupName=*$filtreProjet*&api-version=6.0-preview.2" -Method 'GET' -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
write-host $($response) ""

if( $response -ne $null -and $response.name -eq "$filtreProjet" -and $response.id -eq $filtreProjetID ){
    write-host "$($response.name) (id#$($response.id))"
    #$response.variables.GetType()
    #$response.variables.PSObject.Properties | Out-GridView
    
    #$response.variables += New-Object -Name "AAAAAAAAAAAAAAAAA" -TypeName psobject -Property @{value="AAAAAAAASXSXSX"}
    #Add-Member -InputObject $response.variables -MemberType NoteProperty -Name "AAAAAAAAAAAAA" -Value @{value="jkljkljkl"}

    if( $variableAAjouterOuModifier.keys.Count -gt 0){
        foreach($vv in $variableAAjouterOuModifier.keys){
            #write-host " $vv => $($variableAAjouterOuModifier[$vv])"
            if( $response.variables.PSObject.Properties.Name -eq $vv){
                write-host "update de $vv [$($response.variables.$vv.value) => $($variableAAjouterOuModifier[$vv])]" -ForegroundColor Green
                $response.variables.$vv = $variableAAjouterOuModifier[$vv]

                #write-output $response.variables.$vv
            }else{
                write-host "creation de $vv [$($variableAAjouterOuModifier[$vv].value)]" -ForegroundColor Yellow
                Add-Member -InputObject $response.variables -MemberType NoteProperty -Name $vv -Value $variableAAjouterOuModifier[$vv]
                #$response.variables |Add-Member -Name $vv -Value $variableAAjouterOuModifier[$vv] # not working
                #$response.variables += $vv # not working
            }
        }

        $varJson = ConvertTo-Json $response
        $varJson
        return
        foreach($libV in $response.variables.PSObject.Properties){        
            #write-output $libV
            write-host "   "$libV.Name -NoNewline -ForegroundColor Cyan
            #write-host " ($($libV.id))" -NoNewline
            Write-Host " ==> " -NoNewline 
            write-host $libV.Value.value
        
        }
    }else{
        write-host "rien à faire " -ForegroundColor Cyan
    }
}

