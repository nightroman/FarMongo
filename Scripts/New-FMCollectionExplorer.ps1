
function New-FMCollectionExplorer($Collection, $Pipeline) {
	New-Object PowerShellFar.ObjectExplorer -Property @{
		FileComparer = [PowerShellFar.FileMetaComparer]'_id'
		Data = @{
			Collection = $Collection
			Pipeline = $Pipeline
			Source = Get-FMSourceCollection $Collection
		}
		AsCreateFile = {FMCollectionExplorer_AsCreateFile @args}
		AsCreatePanel = {FMCollectionExplorer_AsCreatePanel @args}
		AsDeleteFiles = {FMCollectionExplorer_AsDeleteFiles @args}
		AsGetContent = {FMCollectionExplorer_AsGetContent @args}
		AsGetData = {FMCollectionExplorer_AsGetData @args}
		AsSetText = {FMCollectionExplorer_AsSetText @args}
	}
}

function FMCollectionExplorer_AsCreatePanel($1) {
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
			$new = [MongoDB.Bson.BsonDocument]::Parse($json)
			break
		}
		catch {
			Show-FarMessage $_
		}
	}

	# generate missing _id, to post
	if (!$new.Contains('_id')) {
		$id = [MongoDB.Bson.BsonObjectId]([MongoDB.Bson.ObjectId]::GenerateNewId())
		$id = New-Object MongoDB.Bson.BsonElement ('_id', $id)
		$new.InsertAt(0, $id)
	}

	# add document
	try {
		Add-MdbcData $new -Collection $1.Data.Source
	}
	catch {
		Show-FarMessage $_
		return
	}

	# post the dummy file with new _id
	$data = [PSCustomObject]@{_id = ([Mdbc.Dictionary]$new)._id}
	$2.PostFile = New-FarFile -Data $data

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
			Remove-MdbcData @{_id=$doc._id} -Collection $1.Data.Source
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

	$new = [MongoDB.Bson.BsonDocument]::Parse($2.Text)
	if ($id -cne $new['_id']) {
		Show-FarMessage "Cannot change _id."
		return
	}

	try {
		Set-MdbcData @{_id = $id} $new -Collection $1.Data.Source
	}
	catch {
		Show-FarMessage $_
	}

	$1.Cache.Clear()
	$Far.Panel.Update($true)
}
