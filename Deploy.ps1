param(
    [switch]$WhatIf
)
$ParametersObj = Get-Content -Path .\Deploy\parameters.bicep.json | ConvertFrom-JSON
if ($WhatIf.IsPresent) {
    # $Deployment = New-AzResourceGroupDeployment -ResourceGroupName "rg-dev-nsgflowlogs" -TemplateFile .\Deploy\template.bicep -TemplateParameterFile .\Deploy\parameters.bicep.json
    az deployment group what-if --resource-group $ParametersObj.parameters.resourceGroupName.value `
        --template-file ".\Deploy\template.bicep" --parameters ".\Deploy\parameters.bicep.json"
}
else {
    $DeploymentResult = az deployment group create --resource-group $ParametersObj.parameters.resourceGroupName.value `
        --template-file ".\Deploy\template.bicep" --parameters ".\Deploy\parameters.bicep.json"
    $DesploymentSucceededText = ($DeploymentResult | ConvertFrom-Json).properties.provisioningState
    $DesploymentSucceededText
}

if ($DesploymentSucceededText -eq "Succeeded") {
    # Start Zip Deploy into the Azure function
    # Write-Host "Compressng .\AzureFunction\bin\Release"
    # Compress-Archive -Path "AzureFunction\bin\Release\netcoreapp3.1\*" -DestinationPath ".\Deploy\AzureFunction.zip" -Force

    # Write-Host "Compressng .\AzureFunction\bin\Release"

    az functionapp deployment source config-zip -g $ParametersObj.parameters.resourceGroupName.value `
        -n  $ParametersObj.parameters.functionName.value --src ".\Deploy\AzureFunction.zip"
}
