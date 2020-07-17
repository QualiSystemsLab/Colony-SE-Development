Start-Transcript -path C:\output.txt -append
dir env:
# Config & run Agent
# Set ACL
$drive = "C:/"
$folder = $drive + "Agent"
$agent_zip = $folder + "/Agent.zip"
$config_file = $folder + "/" + "config.cmd"
$run_file = $folder + "/" + "run.cmd"
$username = "Network Service"
$token = $env:AzureDevOpsPAT
$pool = $env:AgentPoolName
$url = $env:AzureDevOpsURL
$project = $url.split("/")[-1]
$agent_name = $env:AgentName
$agent_install_url = $env:AgentInstallURL
$local_user = $env:LocalUser
$local_password = $env:LocalUserPassword

# Create local account
net user /add /Y $local_user $local_password
net localgroup administrators $local_user /add

# download file
New-Item -Path "c:\" -Name "Agent" -ItemType "directory"
Invoke-WebRequest -Uri $agent_install_url -OutFile $agent_zip
Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory($agent_zip, $folder)

# Config service
$out = ""
$out = cmd.exe /C $config_file --unattended --auth pat --token $token --url $url --pool $pool --agent $agent_name --acceptTeeEula --runAsAutoLogon --WindowsLogonAccount $local_user --WindowsLogonPassword $local_password --noRestart --replace
echo $out


# set registery for auto login

$registry_path = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$key_name = "DefaultPassword"
New-ItemProperty -Path $registry_path -Name $key_name -Value $local_password -PropertyType String -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value "0" -Force

# Disable IE Security
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

# Choco & friends

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install python3 -y
choco install selenium-all-drivers -y
choco install googlechrome -y
choco install jdk8 -y
choco install maven -y

# Start Agent
start-job -scriptblock {cmd.exe /C $run_file }
# Restart
$r = start-job -scriptblock {cmd.exe /C shutdown -r -t 120 }
start-sleep -s 5
get-job