param([switch]$Apply)
$ErrorActionPreference = 'Stop'
# Ejecutar con la sesión propietaria de Firebase CLI; nunca imprime credenciales ni nombres.
$configPath = Join-Path $env:APPDATA 'configstore/firebase-tools.json'
if (!(Test-Path $configPath)) { $configPath = Join-Path $env:USERPROFILE '.config/configstore/firebase-tools.json' }
$authConfig = Get-Content $configPath -Raw | ConvertFrom-Json
$headers = @{Authorization = 'Bearer ' + $authConfig.tokens.access_token}
$root = 'https://firestore.googleapis.com/v1/projects/petreminder-user-2026/databases/(default)/documents'
$query = @{structuredQuery = @{
  select = @{fields = @(@{fieldPath='name'}, @{fieldPath='nameKey'})}
  from = @(@{collectionId='pets'; allDescendants=$true})
}} | ConvertTo-Json -Depth 10
$results = Invoke-RestMethod -Method Post -Uri ($root + ':runQuery') -Headers $headers -ContentType 'application/json' -Body $query
$groups = @{}
foreach ($result in $results) {
  $document = $result.document
  if (!$document) { continue }
  $key = $document.fields.name.stringValue.Trim().ToLowerInvariant()
  $ownerPath = $document.name.Substring(0, $document.name.LastIndexOf('/pets/'))
  $groupKey = $ownerPath + '/petNames/' + $key
  if (!$groups.ContainsKey($groupKey)) { $groups[$groupKey] = @() }
  $groups[$groupKey] += $document
}
$writes = @()
foreach ($entry in $groups.GetEnumerator()) {
  $key = $entry.Key.Substring($entry.Key.LastIndexOf('/') + 1)
  $guardUrl = 'https://firestore.googleapis.com/v1/' + $entry.Key
  $guard = $null
  try { $guard = Invoke-RestMethod -Uri $guardUrl -Headers $headers }
  catch { if ([int]$_.Exception.Response.StatusCode -ne 404) { throw } }
  $ids = @($entry.Value | ForEach-Object { @{stringValue = $_.name.Substring($_.name.LastIndexOf('/') + 1)} })
  $condition = if ($guard) { @{updateTime=$guard.updateTime} } else { @{exists=$false} }
  $writes += @{update=@{name=$entry.Key; fields=@{petIds=@{arrayValue=@{values=$ids}}}}; currentDocument=$condition}
  foreach ($pet in $entry.Value) {
    $writes += @{update=@{name=$pet.name; fields=@{nameKey=@{stringValue=$key}}}; updateMask=@{fieldPaths=@('nameKey')}; currentDocument=@{updateTime=$pet.updateTime}}
  }
}
if ($writes.Count -gt 450) { throw 'Migración demasiado grande; dividir con transacciones antes de continuar.' }
if ($Apply -and $writes.Count -gt 0) {
  $body = @{writes=$writes} | ConvertTo-Json -Depth 20
  $null = Invoke-RestMethod -Method Post -Uri ($root + ':commit') -Headers $headers -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body))
}
[pscustomobject]@{applied=[bool]$Apply; pets=@($results | Where-Object {$_.document}).Count; groups=$groups.Count; legacyDuplicateGroups=@($groups.Values | Where-Object {$_.Count -gt 1}).Count} | ConvertTo-Json
