
function New-FMServerExplorer($ConnectionString) {
	Connect-Mdbc $ConnectionString
	$Explorer = [PowerShellFar.PowerExplorer]::new('35495dbe-e693-45c6-ab0d-30f921b9c46f')
	$Explorer.Data = @{Client = $Client}
	$Explorer.Functions = 'DeleteFiles'
	$Explorer.AsCreatePanel = ${function:FMServerExplorer_AsCreatePanel}
	$Explorer.AsExploreDirectory = ${function:FMServerExplorer_AsExploreDirectory}
	$Explorer.AsGetFiles = ${function:FMServerExplorer_AsGetFiles}
	$Explorer.AsDeleteFiles = ${function:FMServerExplorer_AsDeleteFiles}
	$Explorer
}

function FMServerExplorer_AsCreatePanel($Explorer) {
	$panel = [FarNet.Panel]::new($Explorer)
	$panel.Title = 'Databases'
	$panel.ViewMode = 0
	$panel.SetPlan(0, ([FarNet.PanelPlan]::new()))
	$panel
}

function FMServerExplorer_AsExploreDirectory($Explorer, $2) {
	New-FMDatabaseExplorer $2.File.Data
}

function FMServerExplorer_AsGetFiles($Explorer) {
	foreach($database in Get-MdbcDatabase -Client $Explorer.Data.Client) {
		New-FarFile -Name $database.DatabaseNamespace.DatabaseName -Attributes Directory -Data $database
	}
}

function FMServerExplorer_AsDeleteFiles($Explorer, $2) {
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
			Remove-MdbcDatabase $database.DatabaseNamespace.DatabaseName -Client $Explorer.Data.Client
		}
		catch {
			$2.Result = 'Incomplete'
			$2.FilesToStay.Add($file)
			if ($2.UI) {Show-FarMessage "$_"}
		}
	}
}
