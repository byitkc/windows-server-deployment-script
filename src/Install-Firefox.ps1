<#

.SYNOPSIS

Download and Install Latest Firefox

.DESCRIPTION

Running this script will download and install the latest version of the Firefox Web Browser

.EXAMPLE 

.\Install-Firefox.ps1

.NOTES
  Version:        0.0.1
  Author:         Brandon Young <brandon@byitkc.com>
  Creation Date:  2021-06-28
  Modified Date:  2021-06-28
  Purpose/Change: Initial Commit

#>


<# Initializtion #>
function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

<# Variables #>

$tempdir = New-TemporaryDirectory
$source = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
$destination = "$tempdir\firefox.exe"

<# Execution #>

if (Test-Path -Path $tempdir -PathType Container)
{
    Write-Host "Temporary Directory Created: $tempdir"
}
else {
    Write-Error "Failre to create temporary directory, please review logs and try again..."
    Exit 1001
}

if (Get-Command 'Invoke-Webrequest')
{
    Invoke-WebRequest -UseBasicParsing $source -OutFile $destination
}
else
{
    $WebClient = New-Object System.Net.WebClient
    $webclient.DownloadFile($source, $destination)
}


if (Test-Path -Path "$tempdir\firefox.exe") {
    Write-Host "Download Completed, starting installation now..."
}
else {
    Write-Error "Failed to download Firefox Installer, please check the logs and try again..."
    Exit 1002
}

Start-Process -FilePath "$tempdir\firefox.exe" -ArgumentList "/S" -Wait

Write-Host "Installation Completed"

Write-Host "Removing $tempdir"
Remove-Item -Path -Recurse -Force $tempdir

if (Test-Path -Path $tempdir )
{
    Write-Warning "Failed to remove temporary directory $tempdir"
    Exit 1003
}
else {
    Write-Host "$tempdir Removed Successfully"
}

