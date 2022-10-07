# **Azure-Keyvault-Secret-Locator**
The entire purpose of this script is to simply locate a secret in an environment which contains many key vaults. In some cases the sheer number of secrets inside a key vault, or simply the number of key vaults in an environmnt can make finding a specifc secret a bit painful. This will enumerate key vaults for which you have access to, and present you with a list of secrets. From that list of secrets you can select one to get that secret information right in your terminal. 

This script uses Get-AzKeyVault and Get-AzKeyVaultSecret rather than using the AZ CLI commands: "az keyvault list" and "az keyvault secret list" simply because this method appears to be significantly faster. With PowerShell core's foreach -parallel capability this may change.

# **Assumptions**
1) The Azure RM module is already installed
2) You're already loged in with Login-AzAccount
3) You've selected the specifc subscription you want to work in with Select-AzSubscription or Set-AzContext.

# **To-do**
# **Secure string to plain text context**
https://github.com/Azure/azure-powershell/issues/12953
https://learn.microsoft.com/en-us/dotnet/api/system.runtime.interopservices.marshal.securestringtobstr?view=net-6.0
https://learn.microsoft.com/en-us/dotnet/api/system.runtime.interopservices.marshal.ptrtostringbstr?view=net-6.0


# **References:**
https://learn.microsoft.com/en-us/powershell/module/az.keyvault/get-azkeyvault?view=azps-8.3.0
https://learn.microsoft.com/en-us/powershell/module/az.keyvault/get-azkeyvaultsecret?view=azps-8.3.0
https://github.com/Azure/azure-powershell/issues/12953
https://learn.microsoft.com/en-us/dotnet/api/system.runtime.interopservices.marshal.securestringtobstr?view=net-6.0
https://learn.microsoft.com/en-us/dotnet/api/system.runtime.interopservices.marshal.ptrtostringbstr?view=net-6.0