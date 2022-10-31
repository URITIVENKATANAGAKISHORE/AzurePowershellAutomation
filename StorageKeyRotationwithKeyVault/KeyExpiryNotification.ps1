
function SendNotification($resourceGroupName,$keyVaultName) {
    $KeyVault = Get-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $keyVaultName 
    $secrets = Get-AzKeyVaultSecret -VaultName $keyVaultName  
    #$Date = Get-Date (Get-Date).AddDays(30) 
    $CurrentDate = Get-Date 
    $NearExpirationSecrets = @()

    foreach($secret in $secrets) {
        if($secret.Expires) {
            
            $secretExpiration = Get-Date $secret.Expires 
            $Date = Get-Date ($secretExpiration).AddDays(-30) 
            $Notification = ($secretExpiration - $Date).TotalDays
            if( $Notification -eq 30 -and $Date -gt $CurrentDate) {
                $NearExpirationSecrets += New-Object PSObject -Property @{
                            Name           = $secret.Name;
                            Category       = 'SecretNearExpiration';
                            KeyVaultName   = $KeyVault.VaultName;
                            ExpirationDate = $secret.Expires;
                        }

            }
        }
    }
    $From = "YourEmail@gmail.com"
    $To = "AnotherEmail@YourDomain.com"
    $Cc = "YourBoss@YourDomain.com"
    #$Attachment = "C:\temp\Some random file.txt"
    $Subject = "Email Subject"
    $Body = "Insert body text here"
    $SMTPServer = "smtp.gmail.com"
    $SMTPPort = "587"
    Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential (Get-Credential) #-Attachments $Attachment
}

$keyVaultName = "keyrotation-kvs"
$resourceGroupName = $(Get-AzKeyVault -VaultName $keyVaultName).ResourceGroupName

Write-Host "Resource Group Name: $resourceGroupName"
Write-Host "Key Vault Name: $keyVaultName"

#Rotate secret
Write-Host "Secret Rotation started."
#Write-Host "Current Zone : $(Get-TimeZone)"
SendNotification $resourceGroupName $keyVaultName 
Write-Host "Secret Rotation Successfully"
