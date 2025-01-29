<#
.Synopsis
	Shows MongoDB databases, collections, views, documents.

.Description
	This command connects MongoDB and shows databases, collections, views,
	documents including nested documents and arrays. Root documents may be
	viewed and edited as JSON. Nested documents may not be edited directly.

	Paging. Large collections is not a problem. Documents are shown 1000/page.
	Press [PgDn]/[PgUp] at last/first panel items to show next/previous pages.

	Aggregation pipelines may be defined for custom panel views of collections.
	If result documents have the same _id as the source collection then they
	are edited and deleted in the source collection from this custom view.

	KEYS AND ACTIONS

	[Del]
		Deletes selected documents and empty databases, collections, views.
		For deleting not empty containers use [ShiftDel].

	[ShiftDel]
		Deletes selected databases, collections, views, documents.

	[ShiftF6]
		Prompts for a new name and renames the current collection.

	[F4]
		Edits documents in the documents panel.
		It opens the editor with current document JSON.

	[F7]
		Creates new documents in the documents panel.
		It opens the modal editor for the new document JSON.

.Parameter ConnectionString
		Specifies the connection string. Use "." for the default local server.
		If DatabaseName and CollectionName are omitted then the panel shows
		databases.

.Parameter DatabaseName
		Specifies the database name. If CollectionName is omitted then the
		panel shows this database collections.

.Parameter CollectionName
		Specifies the collection name and tells to show collection documents.
		This parameter must be used together with DatabaseName. Use Pipeline
		in order to customise the view of this collection in the panel.

.Parameter Collection
		Specifies the collection instance.

.Parameter BsonFile
		Specifies the .bson or .json file to be opened by the BsonFile module.
		Requires: https://github.com/nightroman/BsonFile

		If you change data then on closing you are prompted to export data.
		Alternatively, use the menu [F1] \ "Export data to file", any time.

.Parameter Pipeline
		Aggregation pipeline for the custom view of the specified collection.

.Example
	># Panel local databases:
	Open-MongoPanel

.Example
	># Panel collections of "myDatabase":
	Open-MongoPanel . myDatabase

.Example
	># Panel documents of "myDatabase.myCollection":
	Open-MongoPanel . myDatabase myCollection
#>
function Open-MongoPanel {
	[CmdletBinding(DefaultParameterSetName='Connect')]
	param(
		[Parameter(ParameterSetName='Connect', Position=0)]
		[string]$ConnectionString = '.'
		,
		[Parameter(ParameterSetName='Connect', Position=1)]
		[string]$DatabaseName
		,
		[Parameter(ParameterSetName='Connect', Position=2)]
		[string]$CollectionName
		,
		[Parameter(ParameterSetName='Collection', Mandatory=1)]
		[MongoDB.Driver.IMongoCollection[MongoDB.Bson.BsonDocument]]$Collection
		,
		[Parameter(ParameterSetName='BsonFile', Mandatory=1)]
		[string]$BsonFile
		,
		[Parameter(ParameterSetName='Connect')]
		[Parameter(ParameterSetName='Collection')]
		[Parameter(ParameterSetName='BsonFile')]
		$Pipeline
	)

	trap {Write-Error -ErrorRecord $_}

	if ($Collection) {
		(New-FMCollectionExplorer $Collection $Pipeline).OpenPanel()
	}
	elseif ($CollectionName) {
		Connect-Mdbc $ConnectionString $DataBaseName $CollectionName
		(New-FMCollectionExplorer $Collection $Pipeline).OpenPanel()
	}
	elseif ($DatabaseName) {
		Connect-Mdbc $ConnectionString $DatabaseName
		(New-FMDatabaseExplorer $Database).OpenPanel()
	}
	elseif ($BsonFile) {
		Import-Module BsonFile
		Open-BsonFile $BsonFile
		(New-FMCollectionExplorer $Collection $Pipeline -BsonFile $BsonFile).CreatePanel().Open()
	}
	else {
		(New-FMServerExplorer $ConnectionString).CreatePanel().Open()
	}
}
