
function New-FMServerExplorer($ConnectionString) {
	Connect-Mdbc $ConnectionString
	New-Object PowerShellFar.PowerExplorer 35495dbe-e693-45c6-ab0d-30f921b9c46f -Property @{
		Data = @{Client = $Client}
		Functions = 'DeleteFiles'
		AsCreatePanel = {FMServerExplorer_AsCreatePanel @args}
		AsExploreDirectory = {FMServerExplorer_AsExploreDirectory @args}
		AsGetFiles = {FMServerExplorer_AsGetFiles @args}
		AsDeleteFiles = {FMServerExplorer_AsDeleteFiles @args}
	}
}

function FMServerExplorer_AsCreatePanel($1) {
	$panel = [FarNet.Panel]$1
	$panel.Title = 'Databases'
	$panel.ViewMode = 0
	$panel.SetPlan(0, (New-Object FarNet.PanelPlan))
	$panel
}

function FMServerExplorer_AsExploreDirectory($1, $2) {
	New-FMDatabaseExplorer $2.File.Data
}

function FMServerExplorer_AsGetFiles($1) {
	foreach($database in Get-MdbcDatabase -Client $1.Data.Client) {
		New-FarFile -Name $database.DatabaseNamespace.DatabaseName -Attributes Directory -Data $database
	}
}

function FMServerExplorer_AsDeleteFiles($1, $2) {
	# ask
	if ($2.UI) {
		$text = @"
$($2.Files.Count) database(s):
$($2.Files[0..9] -join "`n")
"@
		if (Show-FarMessage $text Delete YesNo -LeftAligned) {return}
	}
	# drop
	foreach($file in $2.Files) {
		try {
			$database = $file.Data
			if (!$2.Force) {
				$collections = @(Get-MdbcCollection -Database $database)
				if ($collections) {
					throw "Database '$($file.Name)' is not empty, $($collections.Count) collections."
				}
			}
			Remove-MdbcDatabase $database.DatabaseNamespace.DatabaseName -Client $1.Data.Client
		}
		catch {
			$2.Result = 'Incomplete'
			$2.FilesToStay.Add($file)
			if ($2.UI) {Show-FarMessage "$_"}
		}
	}
}
