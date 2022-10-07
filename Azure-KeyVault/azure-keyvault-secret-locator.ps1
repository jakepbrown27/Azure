#initialize an array
$initSecretArray = @()

#get a list of accessible key vaults, and secrets within those key vaults. This will only return secrets that you already have access to.
$initSecretArray = Get-AzKeyVault | Get-AzKeyVaultSecret -ErrorAction SilentlyContinue | Out-GridView -PassThru

#From here, we have options on what do to. In this particular case we'll display the secret info.
#it is a good idea to go ahead and clear all memory after this runs.
foreach($secret in $initSecretArray){
    #get specific secret info
    $secretInfo = Get-AzKeyVaultSecret -VaultName $secret.VaultName -Name $secret.Name

    #copy the contents of the managed secure string to a plain text value. more info in the readme.
    $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretInfo.SecretValue)
    $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)

    #write out relevant information on the selected secret.
    Write-Host ("Secret name is: " + $secretInfo.Name)
    Write-Host ("Secret context is: " + $secretInfo.ContentType)
    Write-Host "Secret Value is:" $secretValueText
}

#just clear all variables
$initSecretArray.clear()
$secretInfo.clear()
$secretValueText = $null
$ssPtr = $null

#run garbage collection to just clear any used memory (this may or may not work)
[System.GC]::Collect()

#clear command history. this is very likely unnecessary.
Clear-History