# Variables

$timeserver = ntp.home.byitkc.com 

# Install Chocolatey, of course

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Setup Time

w32tm /config /manualpeerlist:$timeserver /reliable:yes
Restart-Service W32Time

