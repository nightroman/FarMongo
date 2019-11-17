function New-FMDatabaseExplorer($Database) {
	New-Object PowerShellFar.PowerExplorer f0dbf3cf-d45a-40fd-aa6f-7d8ccf5e3bf5 -Property @{
		Data = @{Database = $Database}
		Functions = 'DeleteFiles, RenameFile'
		AsCreatePanel = {
			param($1)
			$panel = [FarNet.Panel]$1
			$panel.Title = 'Collections'
			$panel.ViewMode = 0
			$panel.SetPlan(0, (New-Object FarNet.PanelPlan))
			$panel
		}
		AsGetFiles = {
			param($1)
			foreach($collection in Get-MdbcCollection -Database $1.Data.Database) {
				New-FarFile -Name $collection.CollectionNamespace.CollectionName -Attributes 'Directory' -Data $collection
			}
		}
		AsExploreDirectory = {
			param($1, $2)
			New-FMCollectionExplorer $2.File.Data
		}
		AsRenameFile = {
			param($1, $2)
			$newName = ([string]$Far.Input('New name', $null, 'Rename', $2.File.Name)).Trim()
			if (!$newName) {return}
			Rename-MdbcCollection $2.File.Name $newName -Database $1.Data.Database
			$2.PostName = $newName
		}
		AsDeleteFiles = {
			param($1, $2)
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
	}
}
