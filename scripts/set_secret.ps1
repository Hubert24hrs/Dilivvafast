# Stores a Cloud Functions secret (Paystack or Anthropic key) in Secret Manager.
#
#   & .\scripts\set_secret.ps1 -Name PAYSTACK_SECRET_KEY -Project dilivvafast-staging
#
# The Firebase CLI's own masked prompt does not accept input in every terminal,
# so the value is read here with PowerShell's hidden prompt, written to a
# temporary file without a trailing newline (the functions use the value
# verbatim, and a stray newline breaks the Authorization header), handed to
# `firebase functions:secrets:set --data-file`, and the file is deleted.

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('PAYSTACK_SECRET_KEY', 'ANTHROPIC_API_KEY')]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [ValidateSet('dilivvafast-staging', 'fast-delivery-d8d5c')]
    [string]$Project
)

$ErrorActionPreference = 'Stop'
$isProduction = $Project -eq 'fast-delivery-d8d5c'

Write-Host ''
Write-Host "Set $Name for $Project" -ForegroundColor Cyan
if ($Name -eq 'PAYSTACK_SECRET_KEY') {
    $expected = if ($isProduction) { 'sk_live_' } else { 'sk_test_' }
    Write-Host "Paste your Paystack SECRET key (starts with $expected) and press Enter."
} else {
    Write-Host 'Paste your Anthropic API key (starts with sk-ant-) and press Enter.'
}
Write-Host 'To paste: right-click, or Ctrl+Shift+V. Nothing is shown while you paste.'
Write-Host ''

$secure = Read-Host 'Key' -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try { $value = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr).Trim() }
finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }

if ([string]::IsNullOrEmpty($value)) {
    Write-Host 'Nothing was entered. No change made.' -ForegroundColor Yellow
    exit 1
}

if ($Name -eq 'PAYSTACK_SECRET_KEY') {
    if ($value.StartsWith('pk_')) {
        Write-Host 'That is the PUBLIC key (pk_...). Use the SECRET key (sk_...). No change made.' -ForegroundColor Yellow
        exit 1
    }
    if (-not $value.StartsWith('sk_')) {
        Write-Host 'That does not look like a Paystack secret key (sk_test_... or sk_live_...). No change made.' -ForegroundColor Yellow
        exit 1
    }
    if ($isProduction -and $value.StartsWith('sk_test_')) {
        $answer = Read-Host 'This is a TEST key going to PRODUCTION, so real customers could not pay. Continue? (y/N)'
        if ($answer -ne 'y') { Write-Host 'No change made.'; exit 1 }
    }
    if (-not $isProduction -and $value.StartsWith('sk_live_')) {
        $answer = Read-Host 'This is a LIVE key going to STAGING, so test payments would charge real money. Continue? (y/N)'
        if ($answer -ne 'y') { Write-Host 'No change made.'; exit 1 }
    }
} elseif (-not $value.StartsWith('sk-ant-')) {
    Write-Host 'That does not look like an Anthropic API key (sk-ant-...). No change made.' -ForegroundColor Yellow
    exit 1
}

$tmp = Join-Path $env:TEMP ("dlv-secret-" + [guid]::NewGuid().ToString('N') + '.txt')
try {
    [IO.File]::WriteAllText($tmp, $value)
    $value = $null
    & firebase functions:secrets:set $Name --project $Project --data-file $tmp --force
    if ($LASTEXITCODE -ne 0) { throw "firebase could not store $Name." }
}
finally {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host "Saved $Name for $Project." -ForegroundColor Green
Write-Host 'Tell Claude "done" - the functions must be redeployed to start using it.'
