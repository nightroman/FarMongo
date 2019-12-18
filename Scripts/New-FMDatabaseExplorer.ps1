
function New-FMDatabaseExplorer($Database) {
	New-Object PowerShellFar.PowerExplorer f0dbf3cf-d45a-40fd-aa6f-7d8ccf5e3bf5 -Property @{
		Data = @{Database = $Database}
		Functions = 'DeleteFiles, RenameFile'
		AsCreatePanel = {FMDatabaseExplorer_AsCreatePanel @args}
		AsDeleteFiles = {FMDatabaseExplorer_AsDeleteFiles @args}
		AsExploreDirectory = {FMDatabaseExplorer_AsExploreDirectory @args}
		AsGetFiles = {FMDatabaseExplorer_AsGetFiles @args}
		AsRenameFile = {FMDatabaseExplorer_AsRenameFile @args}
	}
}

function FMDatabaseExplorer_AsCreatePanel {
	param($1)
	$panel = [FarNet.Panel]$1
	$panel.Title = 'Collections'
	$panel.ViewMode = 0
	$panel.SetPlan(0, (New-Object FarNet.PanelPlan))
	$panel
}

function FMDatabaseExplorer_AsGetFiles($1) {
	foreach($collection in Get-MdbcCollection -Database $1.Data.Database) {
		New-FarFile -Name $collection.CollectionNamespace.CollectionName -Attributes 'Directory' -Data $collection
	}
}

function FMDatabaseExplorer_AsExploreDirectory($1, $2) {
	New-FMCollectionExplorer $2.File.Data
}

function FMDatabaseExplorer_AsRenameFile($1, $2) {
	$newName = ([string]$Far.Input('New name', $null, 'Rename', $2.File.Name)).Trim()
	if (!$newName) {return}
	Rename-MdbcCollection $2.File.Name $newName -Database $1.Data.Database
	$2.PostName = $newName
}

function FMDatabaseExplorer_AsDeleteFiles($1, $2) {
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
			Remove-MdbcCollection $collection.CollectionNamespace.CollectionName -Database $1.Data.Database
		}
		catch {
			$2.Result = 'Incomplete'
			$2.FilesToStay.Add($file)
			if ($2.UI) {Show-FarMessage "$_"}
		}
	}
}
