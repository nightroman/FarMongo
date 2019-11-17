<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>

Set-StrictMode -Version Latest
$ModuleName = 'FarMongo'

# Synopsis: Remove temp files.
task Clean {
	remove z
}

# Synopsis: Set $script:Version.
task Version {
	$script:Version = switch -Regex -File Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {$Matches[1]; break} }
	$data = & ([scriptblock]::Create([IO.File]::ReadAllText("$ModuleName.psd1")))
	assert ($data.ModuleVersion -eq $Version)
	$Version
}

# Synopsis: Make the package in z\$ModuleName.
task Package {
	remove z
	$null = mkdir z\$ModuleName\Scripts

	Copy-Item -Destination z\$ModuleName\Scripts -Path `
	Scripts\*

	Copy-Item -Destination z\$ModuleName -LiteralPath `
	"about_$ModuleName.help.txt",
	"$ModuleName.psd1",
	"$ModuleName.psm1",
	LICENSE.txt
}

# Synopsis: Make and push the PSGallery package.
task PushPSGallery Version, Package, {
	$NuGetApiKey = Read-Host NuGetApiKey
	Publish-Module -Path z\$ModuleName -NuGetApiKey $NuGetApiKey
},
Clean

# Synopsis: Push to the repository with a version tag.
task PushRelease Version, {
	$changes = exec { git status --short }
	assert (!$changes) "Please, commit changes."

	exec { git push }
	exec { git tag -a "v$Version" -m "v$Version" }
	exec { git push origin "v$Version" }
}
