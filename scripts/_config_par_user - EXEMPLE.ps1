
#Le token generé depuis dev.azure.com (PAT)
#https://dev.azure.com/{company}/_usersSettings/tokens
$token = "##########################################"
#url de tfs/devops : exp : https://dev.azure.com
$URL_DEVOPS = "https://dev.azure.com"
#name of company : generalement il se trouve dans https://dev.azure.com/{company}
$collection = "company"
#nom du projet
#Exp : https://dev.azure.com/{company}/{project}/_boards/board/t/{nomEquipe}/{nameBoard}
$projectName = "project"
#Exp : 
$URL_DEVOPS_COLLECTION = "$URL_DEVOPS/$collection"
$URL_DEVOPS_COMPLETE = "$URL_DEVOPS/$collection/$projectName"


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
$pipelinesget_filtreNeverRun = $false #$null: nothing, $true:show only pipelines with 0 runs, $false:hide pipeline with 0 runs
$pipelinesget_filtreVariableNom = "" #nom ou partie du nom de la variable
$pipelinesget_filtreVariableValeur = "" #%valeur%


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



##############################################################
#AgentPoolsGet #All parameters in the script
##############################################################
$agentspoolget_filtreAgentPool = "" #le nom de l'agent pool
$agentspoolget_filtreAgentPoolAgent = "" #le nom de l'agent pool -> pool
$agentspoolget_filtreAgentPoolAgentSysCap = $true #bool show systemCapabilities
$agentspoolget_filtreAgentPoolAgentSysCapName = ""
$agentspoolget_filtreAgentPoolAgentSysCapValeur = ""
