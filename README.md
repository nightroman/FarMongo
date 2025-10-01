# FarMongo

PowerShell module with MongoDB browser in Far Manager

For the requirements and details, see [about_FarMongo.help.txt](https://github.com/nightroman/FarMongo/blob/main/about_FarMongo.help.txt)

**How to start**

Get from [PSGallery](https://www.powershellgallery.com/packages/FarMongo)

```powershell
Save-Module FarMongo -Path $env:FARPROFILE\FarNet\PowerShellFar\Modules
```

You can use the usual `Install-Module FarMongo` command, too, it's fine.
But the module works only with Far Manager, FarNet, and PowerShellFar.
PowerShellFar has its own special directory for PowerShell modules.

Import the module and get help:

```powershell
Import-Module FarMongo
help about_FarMongo
```

**See also**

- [FarMongo Release Notes](https://github.com/nightroman/FarMongo/blob/main/Release-Notes.md)
- [FarLite, similar project for LiteDB](https://github.com/nightroman/FarLite)
