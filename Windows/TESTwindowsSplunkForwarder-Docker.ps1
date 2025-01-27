# PowerShell script to install and configure Splunk Universal Forwarder on Windows Server 2019

# Define variables
$SPLUNK_VERSION = "9.1.1"
$SPLUNK_BUILD = "64e843ea36b1"
$SPLUNK_MSI = "splunkforwarder-${SPLUNK_VERSION}-${SPLUNK_BUILD}-x64-release.msi"
$SPLUNK_DOWNLOAD_URL = "https://download.splunk.com/products/universalforwarder/releases/${SPLUNK_VERSION}/windows/${SPLUNK_MSI}"
$INSTALL_DIR = "C:\Program Files\SplunkUniversalForwarder"
$INDEXER_IP = "172.20.241.20"
$RECEIVER_PORT = "9997"

# Download Splunk Universal Forwarder MSI
Write-Host "Downloading Splunk Universal Forwarder MSI..."
Invoke-WebRequest -Uri $SPLUNK_DOWNLOAD_URL -OutFile $SPLUNK_MSI

# Install Splunk Universal Forwarder
Write-Host "Installing Splunk Universal Forwarder..."
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $SPLUNK_MSI AGREETOLICENSE=Yes RECEIVING_INDEXER=${INDEXER_IP}:${RECEIVER_PORT} /quiet" -Wait

# Configure inputs.conf for monitoring
$inputsConfPath = "$INSTALL_DIR\etc\system\local\inputs.conf"
$hostname = (Get-WmiObject Win32_ComputerSystem).Name
Write-Host "Configuring inputs.conf for monitoring with hostname $hostname..."
@"
[default]
host = Windows-AD

[WinEventLog://Security]
disabled = 0
index = main

[WinEventLog://Application]
disabled = 0
index = main

[WinEventLog://System]
disabled = 0
index = main

[WinEventLog://DNS Server]
disabled = 0
index = main

[WinEventLog://Directory Service]
disabled = 0
index = main

[WinEventLog://Windows Powershell]
disabled = 0
index = main
"@ | Out-File -FilePath $inputsConfPath -Encoding ASCII

# Disable KVStore if necessary
$serverConfPath = "$INSTALL_DIR\etc\system\local\server.conf"
Write-Host "Disabling KVStore in server.conf..."
@"
[kvstore]
disabled = true
"@ | Out-File -FilePath $serverConfPath -Encoding ASCII

# Start Splunk Universal Forwarder service
Write-Host "Starting Splunk Universal Forwarder service..."
Start-Process -FilePath "$INSTALL_DIR\bin\splunk.exe" -ArgumentList "start" -Wait

# Set Splunk Universal Forwarder to start on boot
Write-Host "Setting Splunk Universal Forwarder to start on boot..."
Start-Process -FilePath "$INSTALL_DIR\bin\splunk.exe" -ArgumentList "enable boot-start" -Wait

Write-Host "Splunk Universal Forwarder installation and configuration complete!"
