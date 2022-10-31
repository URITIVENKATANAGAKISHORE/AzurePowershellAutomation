
function RegenerateStorageKeys($resourceGroupName, $storageAccountName, $credentialId){
	Write-Host "Regenerating credential for Id : $credentialId "
    Write-Host "Resource Group : $resourceGroupName"
    Write-Host "Storage Account : $storageAccountName"
    Write-Host "`n"
    if ($credentialId -eq 'key1') {
        $newCredentialValue = $(New-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName -KeyName $credentialId)
    }
    elseif ($credentialId -eq 'key2')
	{
        $newCredentialValue = $(New-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName -KeyName $credentialId)
    }
	else{
	}
    return $newCredentialValue
}

function GetStorageKeys($resourceGroupName, $storageAccountName, $credentialId){
	Write-Host "Getting credential for Id : $credentialId"
    Write-Host "Resource Group : $resourceGroupName"
    Write-Host "Storage Account : $storageAccountName"
    Write-Host "`n"
	if ($credentialId -eq 'key1') {
        $CredentialValue = $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName | Where-Object {$_.KeyName -eq $credentialId}).value[0]
		Write-Host "Secret Value  : $CredentialValue"
	}
    elseif ($credentialId -eq 'key2') {
        $CredentialValue = $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName | Where-Object {$_.KeyName -eq $credentialId}).value[1]
		Write-Host "Secret Value  : $CredentialValue"
	}
	else {}
    return $CredentialValue
}

<#function GetCredentialId($resourceGroupName, $storageAccountName){
    If($(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).KeyName -eq 'key1'){
        $credentialId = "key1"
    }
    elseIf($(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).KeyName -eq 'key2'){
        $credentialId = "key2"
    }
	rerun $credentialId
}
#>
function AddSecretToKeyVault($resourceGroupName, $storageAccountName, $keyVaultName, $secretName, $secretvalue, $exprityDate, $activationDate){
    Write-Host "Adding Secret for credential Id : $credentialId "
    Write-Host "Resource Gorup : $resourceGroupName"
    Write-Host "Storage Account : $storageAccountName"
	Write-Host "Key Vault Name : $keyVaultName"
	Write-Host "Secret Name : $secretName "	
    Write-Host "Activation Date : $activationDate"
    Write-Host "Exprity Date : $exprityDate"
    Write-Host "`n"
	
	$keys = $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).KeyName
    foreach($credentialId in $keys)
	{
		Write-Host "Secret Name : $credentialId"
		If($credentialId -eq 'key1'){
			Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $credentialId -SecretValue $secretvalue -Expires $expiryDate -NotBefore $activationDate
		}
		If($credentialId -eq 'key2'){
			Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $credentialId -SecretValue $secretvalue -Expires $expiryDate -NotBefore $activationDate
		}
	}
}
 
function RotateStoragekeyandKeyVaultSecret($keyVaultName,$resourceGroupName){
    Write-Host "Rotate Storage key and KeyVault Secret "
    #Retrieve Secret
    $secrets = $(Get-AzKeyVaultSecret -VaultName $keyVaultName)
    $storageAccountName = $(Get-AzStorageAccount -ResourceGroupName $resourceGroupName).StorageAccountName
	$currentDate = $(Get-Date)
	$validityPeriodDays = 2
    $exprityDate = $(Get-Date).AddDays([int]$validityPeriodDays)
    
	
    Write-Host "Resource Group Name : $resourceGroupName"
    Write-Host "Storage Account Name : $storageAccountName"
	Write-Host "Exprity Date : $exprityDate"
	Write-Host "Current Date : $currentDate"
    Write-Host "`n"
	foreach($secret in $secrets){
		If ($secret.Name -eq 'key1') {
			if($secret.Expires) 
			{	
				$credentialId = $secret.Name
				$secretExpiration = Get-Date $secret.Expires 
				$RenewDate = Get-Date $secretExpiration.AddDays(-2) 
				Write-Host "Secret Name  : $credentialId"
				Write-Host "Secret Expiration Date : $secretExpiration"
				Write-Host "Renew Date : $RenewDate"
                Write-Host "`n"
				$RotationDate = ($secretExpiration - $RenewDate).TotalDays
                #Write-Host "$secretExpiration -eq $RenewDate -or $currentDate -gt $RenewDate"
				if($RotationDate -eq 2 -and $currentDate -lt $secretExpiration)
				{
					RegenerateStorageKeys $resourceGroupName $storageAccountName $credentialId
                    Start-Sleep -Seconds 60
					$newsecretvalue = (GetStorageKeys $resourceGroupName $storageAccountName $credentialId )
					#Add new credential to Key Vault
					#$newSecretVersionTags = @{}
					#$newSecretVersionTags.ValidityPeriodDays = $validityPeriodDays
					#$newSecretVersionTags.CredentialId=$credentialId
					#$newSecretVersionTags.ProviderAddress = $providerAddress

					$secretvalue = ConvertTo-SecureString "$newsecretvalue" -AsPlainText -Force
					AddSecretToKeyVault $resourceGroupName $storageAccountName $keyVaultName $credentialId $secretvalue $exprityDate $currentDate
				}
			}
		}
		If ($secret.Name -eq 'key2') {
			if($secret.Expires) 
			{	
				$credentialId = $secret.Name
				$secretExpiration = Get-Date $secret.Expires 
				$RenewDate = Get-Date $secretExpiration.AddDays(-2) 
				Write-Host "Secret Name  : $credentialId"
				Write-Host "Secret Expiration Date : $secretExpiration"
				Write-Host "Renew Date : $RenewDate"
                Write-Host "`n"
				$RotationDate = ($secretExpiration - $RenewDate).TotalDays
                #Write-Host "$secretExpiration -eq $RenewDate -or $currentDate -gt $RenewDate"
				if($RotationDate -eq 2 -and $currentDate -gt $secretExpiration)
				{
					RegenerateStorageKeys $resourceGroupName $storageAccountName $credentialId
                    Start-Sleep -Seconds 60
					$newsecretvalue = (GetStorageKeys $resourceGroupName $storageAccountName $credentialId )
					$secretvalue = ConvertTo-SecureString $newsecretvalue -AsPlainText -Force
					AddSecretToKeyVault $resourceGroupName $storageAccountName $keyVaultName $credentialId $secretvalue $exprityDate $currentDate
				}
			}
		}
		if ($secret.Name -notmatch "\S") {
			$keys = $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).KeyName
			foreach($credentialId in $keys){
				If($credentialId -eq 'key1')
				{
					Write-Host "Secret Name  : $credentialId" 
                    Write-Host "`n" 
					$newsecretvalue = (GetStorageKeys $resourceGroupName $storageAccountName $credentialId )
					$secretvalue = ConvertTo-SecureString $newsecretvalue -AsPlainText -Force
					AddSecretToKeyVault $resourceGroupName $storageAccountName $keyVaultName $credentialId $secretvalue $exprityDate $currentDate
					
				}
				If($credentialId -eq 'key2')
				{
					Write-Host "Secret Name  : $credentialId"
                    Write-Host "`n"
					$newsecretvalue = (GetStorageKeys $resourceGroupName $storageAccountName $credentialId )
					$secretvalue = ConvertTo-SecureString "$newsecretvalue" -AsPlainText -Force
					AddSecretToKeyVault $resourceGroupName $storageAccountName $keyVaultName $credentialId $secretvalue $exprityDate $currentDate
				}
			}
		}
	}
    Write-Host "Secret Retrieved"
}

$keyVaultName = "keyrotation-kvs"
$resourceGroupName = $(Get-AzKeyVault -VaultName $keyVaultName).ResourceGroupName

Write-Host "Resource Group Name: $resourceGroupName"
Write-Host "Key Vault Name: $keyVaultName"

#Rotate secret
Write-Host "Secret Rotation started."
#Write-Host "Current Zone : $(Get-TimeZone)"
RotateStoragekeyandKeyVaultSecret $keyVaultName $resourceGroupName
Write-Host "Secret Rotation Successfully"
