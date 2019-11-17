@{
	Author = 'Roman Kuzmin'
	ModuleVersion = '0.0.1'
	Description = 'MongoDB tools for Far Manager'
	CompanyName = 'https://github.com/nightroman'
	Copyright = 'Copyright (c) Roman Kuzmin'
	GUID = '9e8ed9eb-ca8a-487d-be47-d20f5e129b6f'

	RootModule = 'FarMongo.psm1'
	RequiredModules = 'Mdbc'
	PowerShellVersion = '3.0'
	DotNetFrameworkVersion = '4.5.2'

	AliasesToExport = @()
	CmdletsToExport = @()
	VariablesToExport = @()
	FunctionsToExport = 'Open-MongoPanel'

	PrivateData = @{
		PSData = @{
			Tags = 'FarManager', 'Mongo', 'MongoDB', 'Database'
			ProjectUri = 'https://github.com/nightroman/FarMongo'
			LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
			ReleaseNotes = 'https://github.com/nightroman/FarMongo/blob/master/Release-Notes.md'
		}
	}
}
