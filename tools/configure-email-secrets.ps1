$ErrorActionPreference = 'Stop'
$env:NODE_OPTIONS = '--use-system-ca'
$project = 'petreminder-user-2026'
Write-Host 'PetReminder: configurar el envio desde eileen.nopal20@gmail.com.'
Write-Host 'Primero activa el plan Blaze en Firebase y crea una contrasena de aplicacion de Google.'
Write-Host 'Introduce SOLO la contrasena de aplicacion en el campo oculto de Firebase. No uses tu contrasena habitual.'
firebase functions:secrets:set GMAIL_APP_PASSWORD --project $project
if ($LASTEXITCODE -ne 0) { throw 'No se guardo GMAIL_APP_PASSWORD. Revisa Blaze y vuelve a ejecutar este archivo.' }

# Generate locally and stream directly to Secret Manager; never print the key.
node -e "process.stdout.write(require('node:crypto').randomBytes(32).toString('hex'))" | firebase functions:secrets:set EMAIL_CODE_HASH_KEY --data-file - --project $project
if ($LASTEXITCODE -ne 0) { throw 'No se guardo EMAIL_CODE_HASH_KEY.' }
Write-Host 'Configuracion terminada: ambos secretos estan guardados en Firebase.' -ForegroundColor Green
Write-Host 'Avisa en el chat que terminaste. No compartas los secretos.'
