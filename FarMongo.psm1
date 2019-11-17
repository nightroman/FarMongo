Import-Module Mdbc

. $PSScriptRoot\Scripts\Get-FMSourceCollection.ps1
. $PSScriptRoot\Scripts\New-FMCollectionExplorer.ps1
. $PSScriptRoot\Scripts\New-FMDatabaseExplorer.ps1
. $PSScriptRoot\Scripts\New-FMServerExplorer.ps1
. $PSScriptRoot\Scripts\Open-MongoPanel.ps1

Export-ModuleMember -Function Open-MongoPanel
