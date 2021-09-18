


#Le token generé depuis dev.azure.com (PAT)
#https://dev.azure.com/{company}/_usersSettings/tokens
$token = "##########################################"
#name of company : generalement il se trouve dans https://dev.azure.com/{company}
$collection = "company"
#nom du projet
#Exp : https://dev.azure.com/{company}/{project}/_boards/board/t/{nomEquipe}/{nameBoard}
$projectName = "project"



#getPipelines
#All parameters in the script
$getpipelines_flagNombreMaxPipeline = 5
$getpipelines_flagShowDeployPhases = $false
$getpipelines_flagShowVariables = $false
$getpipelines_flagRunPipeline_id = $null

$getpipelines_filtreProject = "" #projet1/projet2
$getpipelines_filtreState = "" #inprogress, completed
$getpipelines_filtreResult = "" #succeeded,failed,


#ReposGet (getrepositories)
#All parameters in the script
$reposget_filtreProjet = ""
