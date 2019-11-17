function Get-FMSourceCollection($Collection) {
	$Database = $Collection.Database
	$views = Get-MdbcCollection system.views

	$r = Get-MdbcData @{_id = $Collection.CollectionNamespace.FullName} -Collection $views
	if ($r) {
		Get-MdbcCollection $r.viewOn
	}
	else {
		$Collection
	}
}
