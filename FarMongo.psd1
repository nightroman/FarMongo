@{
	Author = 'Roman Kuzmin'
	ModuleVersion = '0.0.0'
	Description = 'MongoDB browser in Far Manager'
	CompanyName = 'https://github.com/nightroman'
	Copyright = 'Copyright (c) Roman Kuzmin'
	GUID = '9e8ed9eb-ca8a-487d-be47-d20f5e129b6f'

	RootModule = 'FarMongo.psm1'
	RequiredModules = 'Mdbc'

	AliasesToExport = @()
	CmdletsToExport = @()
	VariablesToExport = @()
	FunctionsToExport = @(
		'Edit-MongoJsonLine'
		'Open-MongoPanel'
	)

	PrivateData = @{
		PSData = @{
			Tags = 'FarManager', 'Mongo', 'MongoDB', 'Database'
			ProjectUri = 'https://github.com/nightroman/FarMongo'
			LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
			ReleaseNotes = 'https://github.com/nightroman/FarMongo/blob/main/Release-Notes.md'
		}
	}
}
