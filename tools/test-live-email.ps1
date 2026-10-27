$ErrorActionPreference = 'Stop'
$project = 'petreminder-user-2026'
$config = Get-Content (Join-Path $PSScriptRoot '../android/app/google-services.json') -Raw | ConvertFrom-Json
$apiKey = $config.client[0].api_key[0].current_key
$suffix = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$email = "eileen.nopal20+pet-test-$suffix@gmail.com"
$account = $null
$resultPath = Join-Path $env:TEMP 'pet-email-live-result.json'
try {
  $password = 'Prueba privada ' + [guid]::NewGuid().ToString('N')
  $account = Invoke-RestMethod -Method Post -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey" -ContentType 'application/json' -Body (@{email=$email;password=$password;returnSecureToken=$true} | ConvertTo-Json)
  $headers = @{Authorization='Bearer '+$account.idToken}
  $base = "https://us-central1-$project.cloudfunctions.net"
  $sent = Invoke-RestMethod -Method Post -Headers $headers -Uri "$base/sendEmailCode" -ContentType 'application/json' -Body '{"data":{}}'
  Write-Host "Revisa el codigo recibido en tu Gmail ($email). Revisa tambien spam."
  Write-Host 'No pegues el codigo en el chat; introducelo solo en esta ventana.'
  $secureCode = Read-Host 'Codigo de 5 digitos' -AsSecureString
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureCode)
  try {
    $code = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    if ($code -notmatch '^\d{5}$') { throw 'El codigo debe tener cinco digitos.' }
    $verified = Invoke-RestMethod -Method Post -Headers $headers -Uri "$base/verifyEmailCode" -ContentType 'application/json' -Body (@{data=@{code=$code}} | ConvertTo-Json)
    if ($verified.result.verified -ne $true) { throw 'El servidor no confirmo el correo.' }
  } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer); $code = $null }
  $renewed = Invoke-RestMethod -Method Post -Uri "https://securetoken.googleapis.com/v1/token?key=$apiKey" -ContentType 'application/x-www-form-urlencoded' -Body @{grant_type='refresh_token';refresh_token=$account.refreshToken}
  $lookup = Invoke-RestMethod -Method Post -Uri "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$apiKey" -ContentType 'application/json' -Body (@{idToken=$renewed.id_token} | ConvertTo-Json)
  if ($lookup.users[0].emailVerified -ne $true) { throw 'Auth no reconoce el correo verificado.' }
  @{status='passed';uid=$account.localId;verifiedAt=[DateTimeOffset]::UtcNow.ToString('o');test='real Gmail delivery, five-digit code, refreshed Auth verification'} | ConvertTo-Json | Set-Content -LiteralPath $resultPath -Encoding UTF8
  Write-Host 'Prueba real aprobada: recepcion, codigo y correo confirmado en Firebase.' -ForegroundColor Green
} catch {
  @{status='failed';checkedAt=[DateTimeOffset]::UtcNow.ToString('o');message='No se completo la prueba real. Revisar configuracion y reintentar.'} | ConvertTo-Json | Set-Content -LiteralPath $resultPath -Encoding UTF8
  Write-Host 'No se completo la prueba. Revisa el codigo recibido, la conexion y la configuracion.' -ForegroundColor Red
} finally {
  if ($account) {
    try {
      Invoke-RestMethod -Method Post -Uri "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$apiKey" -ContentType 'application/json' -Body (@{idToken=$account.idToken} | ConvertTo-Json) | Out-Null
      Write-Host 'Cuenta temporal de prueba eliminada.'
    } catch { Write-Host 'Avisar: falta eliminar la cuenta temporal de prueba.' }
  }
  $account = $null; $renewed = $null; $password = $null
}
