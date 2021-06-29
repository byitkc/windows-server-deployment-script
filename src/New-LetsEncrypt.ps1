#requires -Module Posh-ACME
#requires -RunAsAdministrator

<#

.SYNOPSIS

Creates a new Certificate using Let's Encrypt

.DESCRIPTION

  UNTESTED AND UNVALIDATED, MAY CONNECT TO UNKNOWN SERVICES! DO NOT USE UNTIL CLEANED UP!
  This script will create a new certificate using the options that are provided to it.

  Required Options:
    -FQDN = The Fully Qualified Domain Name of the Certificate to Protect
    -EMAIL = Email Address to validate Domain Name

.EXAMPLE 

New-LetsEncrypt -FQDN server.corp.domain.com

.NOTES
  Version:        0.0.0
  Author:         Brandon Young <brandon@byitkc.com>
  Creation Date:  2021-06-28
  Modified Date:  2021-06-28
  Purpose/Change: Initial Commit
  

#>


<# Initializtion #>


<# Variables #>


<# Execution #>



#region Information Gathering
Set-PAServer LE_PROD
 
$CFAuthEmail = 'Email@domain.com'
$CFAuthKey = 'xxxxxxxxYourCloudFlareAPIKeyxxxxxxxxxx'
$FriendlyName = "LetsEncrypt_$((Get-Date).AddDays(90).ToString('yyyy-MM-dd'))"
$CFParams = @{CFAuthEmail=$CFAuthEmail; CFAuthKey=$CFAuthKey}
$PFXPass = 'StrongPFXPasswordGoesHere'
$Domains = "*.thesysadminchannel.com","*.ad.thesysadminchannel.com","thesysadminchannel.com"

$DownloadPath = "\\PAC-FS01\Apps\_LetsEncryptCerts\$((Get-Date).ToString('yyyyMM'))"
$ContactEmail = 'email@domain.com'
#endregion


#region Create Lets Encrypt SSL Cert
$NewCertificate = New-PACertificate $Domains -AcceptTOS -Contact $ContactEmail -DnsPlugin Cloudflare -PluginArgs $CFParams -DNSSleep 180 -PfxPass $PFXPass -Force
$NewCertificate
#endregion


#region Copy to fileserver
#ProdPath = "$env:LOCALAPPDATA\Posh-ACME\acme-v02.api.letsencrypt.org"
mkdir $DownloadPath
$Path = Get-PACertificate | select -ExpandProperty CertFile
$Path = $Path.Substring(0,$Path.LastIndexOf('\'))
Copy-Item "$Path\cert.cer" $DownloadPath -Force
Copy-Item "$Path\cert.key" $DownloadPath -Force
Copy-Item "$Path\cert.pfx" $DownloadPath -Force
#endregion


#region Import PFXPassword, ComputerList and Thumbprint
$PFXPassword = $PFXPass | ConvertTo-SecureString -AsPlainText -Force

#Enter the array of computers needing the cert
$ComputerList = "PAC-EXCH01"#, "PAC-WIN1002"
$Thumbprint = $NewCertificate.Thumbprint
#endregion


#region Deploy to remote machines
foreach ($Computer in $ComputerList) {
    Copy-Item "$DownloadPath\Cert.pfx" "\\$Computer\c$"
}

Invoke-Command -ComputerName $ComputerList -ScriptBlock {
    Import-PfxCertificate -FilePath "C:\cert.pfx" -CertStoreLocation Cert:\LocalMachine\My\ -Exportable:$false -Password $Using:PFXPassword
    $Cert = Get-ChildItem Cert:\LocalMachine\My\$($Using:Thumbprint)
    $Cert.FriendlyName = $Using:FriendlyName
}

foreach ($Computer in $ComputerList) {
    Remove-Item "\\$Computer\c$\cert.pfx"
}
#endregion


#region Install SSL Cert on Exchange Server
$Exchange = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://pac-exch01.ad.thesysadminchannel.com/powershell
Import-PSSession $Exchange

Enable-ExchangeCertificate -Services 'SMTP,IIS' -Thumbprint $Thumbprint -Confirm:$false -Force
#endregion


#region Cleanup
Invoke-Command -ComputerName $ComputerList -ScriptBlock {
    Get-ChildItem Cert:\LocalMachine\My\ | Where-Object {($_.Subject -eq 'CN=*.thesysadminchannel.com') -and ($_.ThumbPrint -ne $Using:Thumbprint)} | Remove-Item -Force
}
#endregion