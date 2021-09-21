
#Le token generé depuis dev.azure.com (PAT)
#https://dev.azure.com/{company}/_usersSettings/tokens
$token = "##########################################"
#name of company : generalement il se trouve dans https://dev.azure.com/{company}
$collection = "company"
#nom du projet
#Exp : https://dev.azure.com/{company}/{project}/_boards/board/t/{nomEquipe}/{nameBoard}
$projectName = "project"


##############################################################
#PipelinesGet #All parameters in the script
##############################################################
$pipelinesget_flagNombreMaxPipeline = 5
$pipelinesget_flagShowDeployPhases = $false
$pipelinesget_flagShowVariables = $false
$pipelinesget_flagRunPipeline_id = $null #pipelineId to run

$pipelinesget_filtreProject = "" #projet1/projet2
$pipelinesget_filtreState = "" #inprogress, completed
$pipelinesget_filtreResult = "" #succeeded,failed,

##############################################################
#ReleaseDefinitionsGet.ps1 #All parameters in the script
##############################################################
$releasedefinitionsget_flagShowEnvironments = $false
$releasedefinitionsget_flagShowDeployPhases = $false
$releasedefinitionsget_flagShowVariables = $false

$releasedefinitionsget_filtreProject = "" #projet1/projet2
$releasedefinitionsget_filtreProjetEnvironnement = "" #integ/recette/prod
$releasedefinitionsget_filtreVariableNom = "" #connexion
$releasedefinitionsget_filtreVariableValeur = "" #server

##############################################################
#ReposGet (getrepositories) #All parameters in the script
##############################################################
$reposget_filtreProjet = ""

##############################################################
#VariablesLibraryGet #All parameters in the script
##############################################################


##############################################################
#VariablesLibrarySet #All parameters in the script
##############################################################
