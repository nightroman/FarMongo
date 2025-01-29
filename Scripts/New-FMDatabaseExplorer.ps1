
function New-FMDatabaseExplorer($Database) {
	$Explorer = [PowerShellFar.PowerExplorer]::new('f0dbf3cf-d45a-40fd-aa6f-7d8ccf5e3bf5')
	$Explorer.Data = @{Database = $Database}
	$Explorer.Functions = 'DeleteFiles, RenameFile'
	$Explorer.AsCreatePanel = ${function:FMDatabaseExplorer_AsCreatePanel}
	$Explorer.AsDeleteFiles = ${function:FMDatabaseExplorer_AsDeleteFiles}
	$Explorer.AsExploreDirectory = ${function:FMDatabaseExplorer_AsExploreDirectory}
	$Explorer.AsGetFiles = ${function:FMDatabaseExplorer_AsGetFiles}
	$Explorer.AsRenameFile = ${function:FMDatabaseExplorer_AsRenameFile}
	$Explorer
}

function FMDatabaseExplorer_AsCreatePanel($Explorer) {
	$panel = [FarNet.Panel]::new($Explorer)
	$panel.Title = 'Collections'
	$panel.ViewMode = 0
	$panel.SetPlan(0, ([FarNet.PanelPlan]::new()))
	$panel
}

function FMDatabaseExplorer_AsGetFiles($Explorer) {
	foreach($collection in Get-MdbcCollection -Database $Explorer.Data.Database) {
		New-FarFile -Name $collection.CollectionNamespace.CollectionName -Attributes 'Directory' -Data $collection
	}
}

function FMDatabaseExplorer_AsExploreDirectory($Explorer, $2) {
	New-FMCollectionExplorer $2.File.Data
}

function FMDatabaseExplorer_AsRenameFile($Explorer, $2) {
	$newName = ([string]$Far.Input('New name', $null, 'Rename', $2.File.Name)).Trim()
	if (!$newName) {return}
	Rename-MdbcCollection $2.File.Name $newName -Database $Explorer.Data.Database
	$2.PostName = $newName
}

function FMDatabaseExplorer_AsDeleteFiles($Explorer, $2) {
	# ask
	if ($2.UI) {
		$text = @"
$($2.Files.Count) collection(s):
$($2.Files[0..9] -join "`n")
"@
		if (Show-FarMessage $text Delete YesNo -LeftAligned) {return}
	}
	# drop
	foreach($file in $2.Files) {
		try {
			$collection = $file.Data
			if (!$2.Force -and (Get-MdbcData -Collection $collection -Count -First 1)) {
				throw "Collection '$($file.Name)' is not empty."
			}
			Remove-MdbcCollection $collection.CollectionNamespace.CollectionName -Database $Explorer.Data.Database
		}
		catch {
			$2.Result = 'Incomplete'
			$2.FilesToStay.Add($file)
			if ($2.UI) {Show-FarMessage "$_"}
		}
	}
}
