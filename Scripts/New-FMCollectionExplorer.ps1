
function New-FMCollectionExplorer {
	param(
		[Parameter(Position=0)]
		$Collection,
		[Parameter(Position=1)]
		$Pipeline,
		$BsonFile
	)

	$Explorer = [PowerShellFar.ObjectExplorer]::new()
	$Explorer.Data = @{
		Collection = $Collection
		Pipeline = $Pipeline
		BsonFile = $BsonFile
		Source = Get-FMSourceCollection $Collection
		ChangeCount = 0
	}
	$Explorer.FileComparer = [PowerShellFar.FileMetaComparer]::new('_id')
	$Explorer.AsCreateFile = ${function:FMCollectionExplorer_AsCreateFile}
	$Explorer.AsCreatePanel = ${function:FMCollectionExplorer_AsCreatePanel}
	$Explorer.AsDeleteFiles = ${function:FMCollectionExplorer_AsDeleteFiles}
	$Explorer.AsGetContent = ${function:FMCollectionExplorer_AsGetContent}
	$Explorer.AsGetData = ${function:FMCollectionExplorer_AsGetData}
	$Explorer.AsSetText = ${function:FMCollectionExplorer_AsSetText}
	$Explorer
}

function FMCollectionPanel_Escaping {
	# skip not changed
	if ($this.Explorer.Data.ChangeCount -eq 0) {
		return
	}

	# prompt to export
	$r = Show-FarMessage 'Export data to file?' -Caption Export -Buttons YesNoCancel
	if ($r -eq 0) {
		# save, let close
		Save-BsonFile -Collection $this.Explorer.Data.Source
	}
	elseif ($r -ne 1) {
		# do not close
		$_.Ignore = $true
	}
}

function FMCollectionPanel_MenuCreating {
	# save data and reset change counter
	$_.Menu.Items.Add((New-FarItem -Text 'Export data to file' -Click {
		Save-BsonFile -Collection $this.Explorer.Data.Source
		$this.Explorer.Data.ChangeCount = 0
	}))
}

function FMCollectionExplorer_AsCreatePanel($Explorer) {
	$panel = [PowerShellFar.ObjectPanel]::new($Explorer)

	if ($Explorer.Data.BsonFile) {
		$title = [System.IO.Path]::GetFileName($Explorer.Data.BsonFile)
		$panel.add_Escaping({FMCollectionPanel_Escaping})
		$panel.add_MenuCreating({FMCollectionPanel_MenuCreating})
	}
	else {
		$title = $Explorer.Data.Collection.CollectionNamespace.CollectionName
		if ($Explorer.Data.Collection -ne $Explorer.Data.Source) {
			$title = "$title ($($Explorer.Data.Source.CollectionNamespace.CollectionName))"
		}
	}

	if ($Explorer.Data.Pipeline) {
		$panel.Title = $title + ' (aggregate)'
	}
	else {
		$panel.Title = $title
		$panel.PageLimit = 1000
	}

	$Explorer.Data.Panel = $panel
	$panel
}

function FMCollectionExplorer_EditorOpened {
	$this.add_KeyDown({
		if ($_.Key.KeyDown -and $_.Key.Is([FarNet.KeyCode]::F4)) {
			$_.Ignore = $true
			Edit-MongoJsonLine
		}
	})
}

function FMCollectionExplorer_AsCreateFile($Explorer, $2) {
	# edit new json
	$json = ''
	for() {
		$arg = [FarNet.EditTextArgs]::new()
		$arg.Title = 'New document (JSON)'
		$arg.Extension = 'js'
		$arg.Text = $json
		$arg.EditorOpened = ${function:FMCollectionExplorer_EditorOpened}
		$json = $Far.AnyEditor.EditText($arg)
		if (!$json) {
			return
		}
		try {
			$new = [Mdbc.Dictionary]::FromJson($json)
			break
		}
		catch {
			Show-FarMessage $_
		}
	}

	# _id to post
	$new.EnsureId()

	# add document
	try {
		++$Explorer.Data.ChangeCount
		Add-MdbcData $new -Collection $Explorer.Data.Source
	}
	catch {
		Show-FarMessage $_
		return
	}

	# post dummy file with _id
	$2.PostFile = New-FarFile -Data ([PSCustomObject]@{_id = $new._id})
	$Explorer.Data.Panel.NeedsNewFiles = $true
}

function FMCollectionExplorer_AsDeleteFiles($Explorer, $2) {
	# ask
	if ($2.UI) {
		$text = "$($2.Files.Count) documents(s)"
		if (Show-FarMessage $text Delete YesNo) {return}
	}
	# remove
	try {
		foreach($doc in $2.FilesData) {
			++$Explorer.Data.ChangeCount
			Remove-MdbcData @{_id = $doc._id} -Collection $Explorer.Data.Source
		}
	}
	catch {
		$2.Result = 'Incomplete'
		if ($2.UI) {Show-FarMessage "$_"}
	}
	$Explorer.Data.Panel.NeedsNewFiles = $true
}

function FMCollectionExplorer_AsGetContent($Explorer, $2) {
	$id = $2.File.Data._id
	if ($null -eq $id) {
		$doc = New-MdbcData $2.File.Data
	}
	else {
		$doc = Get-MdbcData @{_id = $id} -Collection $Explorer.Data.Source
	}

	$2.UseText = $doc.Print()
	$2.UseFileExtension = 'js'
	$2.CanSet = $true
	$2.EditorOpened = ${function:FMCollectionExplorer_EditorOpened}
}

function FMCollectionExplorer_AsGetData($Explorer, $2) {
	if ($2.NewFiles -or !$Explorer.Cache) {
		if ($Explorer.Data.Pipeline) {
			Invoke-MdbcAggregate $Explorer.Data.Pipeline -Collection $Explorer.Data.Collection -As PS
		}
		else {
			Get-MdbcData -Collection $Explorer.Data.Collection -First $2.Limit -Skip $2.Offset -As PS
		}
	}
	else {
		, $Explorer.Cache
	}
}

function FMCollectionExplorer_AsSetText($Explorer, $2) {
	$new = [Mdbc.Dictionary]::FromJson($2.Text)
	$new.EnsureId()

	try {
		++$Explorer.Data.ChangeCount
		$new | Set-MdbcData -Add -Collection $Explorer.Data.Source
	}
	catch {
		Show-FarMessage $_
		return
	}

	$Explorer.Cache.Clear()
	$Far.Panel.Update($true)
}
