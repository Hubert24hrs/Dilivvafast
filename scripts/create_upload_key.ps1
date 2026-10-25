# Creates the Google Play upload key and android/key.properties.
#
# Run once, from the repository root:
#   & .\scripts\create_upload_key.ps1
#
# The password is typed here and never leaves this machine. Both output files
# are git-ignored. Back up android/app/upload-keystore.jks and the password
# somewhere off this computer: every future Play update must be signed with it.

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$keystore = Join-Path $root 'android\app\upload-keystore.jks'
$props = Join-Path $root 'android\key.properties'
$cert = Join-Path $root 'android\app\upload_certificate.pem'
$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'

if (Test-Path $keystore) {
    Write-Host "An upload key already exists at $keystore. Not overwriting it." -ForegroundColor Yellow
    exit 1
}
if (-not (Test-Path $keytool)) {
    Write-Host "keytool not found at $keytool" -ForegroundColor Red
    exit 1
}

function Read-Plain([string]$prompt) {
    $secure = Read-Host $prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

Write-Host ''
Write-Host 'Dilivvafast - create the Google Play upload key' -ForegroundColor Cyan
Write-Host 'Choose a strong password (at least 8 characters) and save it in a password manager.'
Write-Host 'Nothing is shown while you type.'
Write-Host ''

while ($true) {
    $pass = Read-Plain 'Upload key password'
    if ($pass.Length -lt 8) { Write-Host 'Use at least 8 characters.' -ForegroundColor Yellow; continue }
    # key.properties is plain ASCII and trims leading spaces.
    if ($pass -match '[^\x21-\x7E]') {
        Write-Host 'Use letters, digits and symbols only (no spaces or accented letters).' -ForegroundColor Yellow
        continue
    }
    $again = Read-Plain 'Type it again'
    if ($pass -ne $again) { Write-Host 'They do not match. Try again.' -ForegroundColor Yellow; continue }
    break
}

$owner = Read-Host 'Name on the certificate (e.g. Dilivvafast Technologies)'
if ([string]::IsNullOrWhiteSpace($owner)) { $owner = 'Dilivvafast' }
# Commas and other separators would break the distinguished name.
$owner = ($owner -replace '[,=+<>#;"\\]', ' ').Trim()

# Handed to keytool through the environment rather than the command line, so
# it does not appear in the process list.
$env:DLV_UPLOAD_KEY_PASS = $pass
try {
    & $keytool -genkeypair -keystore $keystore -storetype PKCS12 `
        -alias upload -keyalg RSA -keysize 2048 -validity 10000 `
        -dname "CN=$owner, O=$owner, L=Lagos, C=NG" `
        -storepass:env DLV_UPLOAD_KEY_PASS -keypass:env DLV_UPLOAD_KEY_PASS
    if ($LASTEXITCODE -ne 0) { throw 'keytool could not create the key.' }

    # The public certificate (not secret): used to register the fingerprint
    # with Firebase so Google sign-in works in Play builds.
    & $keytool -exportcert -rfc -keystore $keystore -alias upload `
        -storepass:env DLV_UPLOAD_KEY_PASS -file $cert
    if ($LASTEXITCODE -ne 0) { throw 'keytool could not export the certificate.' }
}
finally {
    Remove-Item Env:\DLV_UPLOAD_KEY_PASS -ErrorAction SilentlyContinue
}

# Java .properties treats a backslash as an escape character.
$escaped = $pass -replace '\\', '\\'
@(
    "storePassword=$escaped"
    "keyPassword=$escaped"
    'keyAlias=upload'
    'storeFile=upload-keystore.jks'
) | Set-Content -Path $props -Encoding ASCII
$pass = $null; $again = $null; $escaped = $null

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host "  Key:        $keystore"
Write-Host "  Settings:   $props"
Write-Host "  Public cert: $cert"
Write-Host ''
Write-Host 'Now back up upload-keystore.jks and your password somewhere safe (not only this PC).' -ForegroundColor Yellow
& $keytool -printcert -file $cert | Select-String 'SHA1:|SHA256:'
