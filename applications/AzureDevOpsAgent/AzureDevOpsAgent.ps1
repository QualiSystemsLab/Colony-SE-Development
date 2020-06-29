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

#Set folder ACL
$acl = get-acl $folder
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"FullControl","Allow")
$acl.SetAccessRule($rule)
$acl | Set-Acl $folder

# Config service
$out = ""
$out = cmd.exe /C $config_file --unattended --auth pat --token $token --url $url --pool $pool --agent $agent_name --acceptTeeEula --runAsAutoLogon --WindowsLogonAccount $local_user --WindowsLogonPassword $local_password --noRestart
echo $out

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