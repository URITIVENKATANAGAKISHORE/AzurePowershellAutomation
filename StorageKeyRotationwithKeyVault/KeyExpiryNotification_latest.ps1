Param(
        [string]$SubscriptionID,
        [int]$DaysNearExpiration,
        [string]$VaultName
)
 
Select-AzSubscription -SubscriptionId $SubscriptionID | Out-Null
 
$ExpiredSecrets = @()
$NearExpirationSecrets = @()
 
#gather all key vaults from subscription
if ($VaultName) {
    $KeyVaults = Get-AzKeyVault -VaultName $VaultName
}
else {
    $KeyVaults = Get-AzKeyVault
}
#check date which will notify about expiration
$ExpirationDate = (Get-Date (Get-Date).AddDays($DaysNearExpiration) -Format yyyyMMdd)
$CurrentDate = (Get-Date -Format yyyyMMdd)
 
# iterate across all key vaults in subscription
foreach ($KeyVault in $KeyVaults) {
    # gather all secrets in each key vault
    $SecretsArray = Get-AzKeyVaultSecret -VaultName $KeyVault.VaultName
    foreach ($secret in $SecretsArray) {
        # check if expiration date is set
        if ($secret.Expires) {
            $secretExpiration = Get-date $secret.Expires -Format yyyyMMdd
            # check if expiration date set on secret is before notify expiration date
            if ($ExpirationDate -gt $secretExpiration) {
                # check if secret did not expire yet but will expire soon
                if ($CurrentDate -lt $secretExpiration) {
                    $NearExpirationSecrets += New-Object PSObject -Property @{
                        Name           = $secret.Name;
                        Category       = 'SecretNearExpiration';
                        KeyVaultName   = $KeyVault.VaultName;
                        ExpirationDate = $secret.Expires;
                    }
                }
                # secret is already expired
                else {
                    $ExpiredSecrets += New-Object PSObject -Property @{
                        Name           = $secret.Name;
                        Category       = 'SecretNearExpiration';
                        KeyVaultName   = $KeyVault.VaultName;
                        ExpirationDate = $secret.Expires;
                    }
                }
 
            }
        }
    }
         
}
 
Write-Output "Total number of expired secrets: $($ExpiredSecrets.Count)"
$ExpiredSecrets
  
Write-Output "Total number of secrets near expiration: $($NearExpirationSecrets.Count)"
$NearExpirationSecrets