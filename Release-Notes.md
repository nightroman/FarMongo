# FarMongo Release Notes

## v1.0.0

master -> main, updated links

## v0.4.2

Requires FarNet 5.2.22

<kbd>F4</kbd> in JSON editors calls `Edit-MongoJsonLine`.

On editing documents (<kbd>F4</kbd> in panels with documents), changing the
document `_id` is now allowed. As a result, you can kind of copy documents.

## v0.4.1

Requires Mdbc v6.5.1 and uses its new features to simplify some code.

## v0.4.0

Add `Edit-MongoJsonLine`, the JSON editor helper.
For now it should be invoked manually.

## v0.3.0

New parameter `BsonFile` of `Open-MongoPanel` opens .bson or .json files as special collections.
Requires [BsonFile](https://github.com/nightroman/BsonFile), see its help.

If you change data then on closing you are prompted to export data to the original file.
Alternatively, use the menu <kbd>F1</kbd> \ "Export data to file", any time.

## v0.2.0

Documents panel creates a new document by <kbd>F7</kbd>.
It opens the editor for the new document JSON.

## v0.1.0

Add parameter `Collection` to `Open-MongoPanel`.

## v0.0.1

Created from the retired script *Panel-Mongo-.ps1*.
