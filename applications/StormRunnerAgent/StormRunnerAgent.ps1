Start-Transcript -path C:\output.txt -append
dir env:

# Choco & friends
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install googlechrome -y
choco install firefox -y
# Microsoft Visual C++ Redistributable for Visual Studio 2015 Update 3 (with hotfix 2016-09-14)
choco install vcredist140 --version=14.0.24215.1 -y