
function New-FMCollectionExplorer {
	param(
		[Parameter(Position=0)]
		$Collection,
		[Parameter(Position=1)]
		$Pipeline,
		$BsonFile
	)
	New-Object PowerShellFar.ObjectExplorer -Property @{
		Data = @{
			Collection = $Collection
			Pipeline = $Pipeline
			BsonFile = $BsonFile
			Source = Get-FMSourceCollection $Collection
			ChangeCount = 0
		}
		FileComparer = [PowerShellFar.FileMetaComparer]'_id'
		AsCreateFile = {FMCollectionExplorer_AsCreateFile @args}
		AsCreatePanel = {FMCollectionExplorer_AsCreatePanel @args}
		AsDeleteFiles = {FMCollectionExplorer_AsDeleteFiles @args}
		AsGetContent = {FMCollectionExplorer_AsGetContent @args}
		AsGetData = {FMCollectionExplorer_AsGetData @args}
		AsSetText = {FMCollectionExplorer_AsSetText @args}
	}
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

function FMCollectionExplorer_AsCreatePanel($1) {
	$panel = [PowerShellFar.ObjectPanel]$1

	if ($1.Data.BsonFile) {
		$title = [System.IO.Path]::GetFileName($1.Data.BsonFile)
		$panel.add_Escaping({FMCollectionPanel_Escaping})
		$panel.add_MenuCreating({FMCollectionPanel_MenuCreating})
	}
	else {
		$title = $1.Data.Collection.CollectionNamespace.CollectionName
		if ($1.Data.Collection -ne $1.Data.Source) {
			$title = "$title ($($1.Data.Source.CollectionNamespace.CollectionName))"
		}
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

function FMCollectionExplorer_AsCreateFile($1, $2) {
	# edit new json
	$json = ''
	for() {
		$arg = New-Object FarNet.EditTextArgs -Property @{
			Title = 'New document (JSON)'
			Extension = '.js'
			Text = $json
		}
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
		++$1.Data.ChangeCount
		Add-MdbcData $new -Collection $1.Data.Source
	}
	catch {
		Show-FarMessage $_
		return
	}

	# post dummy file with _id
	$2.PostFile = New-FarFile -Data ([PSCustomObject]@{_id = $new._id})
	$1.Data.Panel.NeedsNewFiles = $true
}

function FMCollectionExplorer_AsDeleteFiles($1, $2) {
	# ask
	if ($2.UI) {
		$text = "$($2.Files.Count) documents(s)"
		if (Show-FarMessage $text Delete YesNo) {return}
	}
	# remove
	try {
		foreach($doc in $2.FilesData) {
			++$1.Data.ChangeCount
			Remove-MdbcData @{_id = $doc._id} -Collection $1.Data.Source
		}
	}
	catch {
		$2.Result = 'Incomplete'
		if ($2.UI) {Show-FarMessage "$_"}
	}
	$1.Data.Panel.NeedsNewFiles = $true
}

function FMCollectionExplorer_AsGetContent($1, $2) {
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

function FMCollectionExplorer_AsGetData($1, $2) {
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

function FMCollectionExplorer_AsSetText($1, $2) {
	$id = $2.File.Data._id
	if ($null -eq $id) {
		Show-FarMessage "Document must have _id."
		return
	}

	$new = [Mdbc.Dictionary]::FromJson($2.Text)
	if ($id -cne $new['_id']) {
		Show-FarMessage "Cannot change _id."
		return
	}

	try {
		++$1.Data.ChangeCount
		Set-MdbcData @{_id = $id} $new -Collection $1.Data.Source
	}
	catch {
		Show-FarMessage $_
	}

	$1.Cache.Clear()
	$Far.Panel.Update($true)
}
