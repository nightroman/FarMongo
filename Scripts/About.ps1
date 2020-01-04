$ErrorActionPreference = 1
Import-Module Mdbc

. $PSScriptRoot\Edit-MongoJsonLine.ps1
. $PSScriptRoot\New-FMCollectionExplorer.ps1
. $PSScriptRoot\New-FMDatabaseExplorer.ps1
. $PSScriptRoot\New-FMServerExplorer.ps1
. $PSScriptRoot\Open-MongoPanel.ps1

function Get-FMSourceCollection($Collection) {
	$Database = $Collection.Database
	$views = Get-MdbcCollection system.views

	$r = Get-MdbcData @{_id = $Collection.CollectionNamespace.FullName} -Collection $views
	if ($r) {
		Get-MdbcCollection $r.viewOn
	}
	else {
		$Collection
	}
}
