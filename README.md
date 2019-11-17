# FarMongo

PowerShell module with MongoDB tools for Far Manager

**WARNING**: With this module tools you can change and delete databases,
collections, documents, and data. Use it on your own risk and be careful.

Requires:

- [Far Manager, FarNet, PowerShellFar](https://github.com/nightroman/FarNet/wiki)
- [MongoDB server](http://www.mongodb.org/)
- [Mdbc module](https://www.powershellgallery.com/packages/Mdbc)

**How to use**

Install the module from the PowerShell gallery by this command:

```powershell
Save-Module FarMongo -Path $env:FARHOME\FarNet\Modules\PowerShellFar\Modules
```

You can use the usual `Install-Module FarMongo` command, too, it's fine.
But the module works only with Far Manager, FarNet, and PowerShellFar.
PowerShellFar has its own special directory for PowerShell modules.

In Far Manager, import the module:

```
ps: Import-Module FarMongo
```

See command help:

```
ps: help Open-MongoPanel -full
```

The module provides the following commands:

- [Open-MongoPanel](https://github.com/nightroman/FarMongo/blob/master/Scripts/Open-MongoPanel.ps1)

See also

- [Release Notes](https://github.com/nightroman/FarMongo/blob/master/Release-Notes.md)
