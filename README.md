# ZeroTrustAVDBluePrint
a Zero Trust Architecture blueprint for  VDI using Hub/Spoke 


### Import viA PowerShell
To Import the Blueprint to our Azure Subscription we need to follow some steps :

1. Launch PowerShell and install / import those module:
   ```powershell
   Install-Module -Name Az.Blueprint
   Import-Module Az.Blueprint
   ```
2. Ensure to Connect to the Account / Subscription where you want to deploy your blueprint
   ```powershell
   Connect-AzAccount -TenantId XXXXX-XXXX-XXXXX-XXXXXX
   Select-AzSubscription -SubscriptionId XXXXX-XXXX-XXXXX-XXXXXX
   ```
3. Run the following command to import artifacts as blueprint and save it within the specified subscription
   ```powershell
   Import-AzBlueprintWithArtifact -Name "ZeroTrustAVD" -SubscriptionId XXXXX-XXXX-XXXXX-XXXXXX -InputPath "$HOME\blueprint"
   ```

4. You can now check the blueprint within the Azure Portal under Blueprint section and select "Blueprint definitions" and you should see your newly imported blueprint
   and follow the steps to publish and assign it.[Learn how to assign a blueprint](https://docs.microsoft.com/en-us/azure/governance/blueprints/create-blueprint-portal#assign-a-blueprint)


