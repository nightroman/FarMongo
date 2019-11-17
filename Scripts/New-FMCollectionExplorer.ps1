function New-FMCollectionExplorer($Collection, $Pipeline) {
	New-Object PowerShellFar.ObjectExplorer -Property @{
		Data = @{
			Collection = $Collection
			Pipeline = $Pipeline
			Source = Get-FMSourceCollection $Collection
		}
		FileComparer = [PowerShellFar.FileMetaComparer]'_id'
		AsCreatePanel = {
			param($1)
			$panel = [PowerShellFar.ObjectPanel]$1
			$title = $1.Data.Collection.CollectionNamespace.CollectionName
			if ($1.Data.Collection -ne $1.Data.Source) {
				$title = "$title ($($1.Data.Source.CollectionNamespace.CollectionName))"
			}
			if ($1.Data.Pipeline) {
				$panel.Title = $title + ' (aggregate)'
			}
			else {
				$panel.Title = $title
				$panel.PageLimit = 1000
			}
			$1.Data.Panel = $panel
			$panel
		}
		AsGetData = {
			param($1, $2)
			if ($2.NewFiles -or !$1.Cache) {
				if ($1.Data.Pipeline) {
					Invoke-MdbcAggregate $1.Data.Pipeline -Collection $1.Data.Collection -As PS
				}
				else {
					Get-MdbcData -Collection $1.Data.Collection -First $2.Limit -Skip $2.Offset -As PS
				}
			}
			else {
				, $1.Cache
			}
		}
		AsDeleteFiles = {
			param($1, $2)
			# ask
			if ($2.UI) {
				$text = "$($2.Files.Count) documents(s)"
				if (Show-FarMessage $text Delete YesNo) {return}
			}
			# remove
			try {
				foreach($doc in $2.FilesData) {
					Remove-MdbcData @{_id=$doc._id} -Collection $1.Data.Source -ErrorAction 1
				}
			}
			catch {
				$2.Result = 'Incomplete'
				if ($2.UI) {Show-FarMessage "$_"}
			}
			$1.Data.Panel.NeedsNewFiles = $true
		}
		AsGetContent = {
			param($1, $2)

			$id = $2.File.Data._id
			if ($null -eq $id) {
				$doc = New-MdbcData $2.File.Data
			}
			else {
				$doc = Get-MdbcData @{_id = $id} -Collection $1.Data.Source
			}

			$2.UseText = $doc.Print()
			$2.UseFileExtension = '.js'
			$2.CanSet = $true
		}
		AsSetText = {
			param($1, $2)

			$id = $2.File.Data._id
			if ($null -eq $id) {
				Show-FarMessage "Document must have _id."
				return
			}

			$new = [MongoDB.Bson.BsonDocument]::Parse($2.Text)
			if ($id -cne $new['_id']) {
				Show-FarMessage "Cannot change _id."
				return
			}

			try {
				Set-MdbcData @{_id = $id} $new -Collection $1.Data.Source -ErrorAction 1
			}
			catch {
				Show-FarMessage $_
			}

			$1.Cache.Clear()
			$Far.Panel.Update($true)
		}
	}
}
