#Requires -Version 2.0
#Requires -RunAsAdministrator

<#

.SYNOPSIS
Install Windows Exporter

.DESCRIPTION
This script automatically downloads and installs Windows Exporter.

.EXAMPLE
.\Install-WindowsExporter.ps1

.NOTES
(C) Copyright 2019, Maxence Grymonprez <maxgrymonprez@live.fr>

Install-WindowsExporter.ps1 is free software: you can redistribute
it and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Install-WindowsExporter.ps1 is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with help.sh. If not, see <http://www.gnu.org/licenses>.

.LINK
PowerShell online documentation:
https://docs.microsoft.com/en-us/powershell

Windows Exporter GitHub repository:
https://github.com/prometheus-community/windows_exporter

#>

# Set verbose preference
Set-Variable -Name VerbosePreference -Value "Continue" -Scope Global

# You can replace the version number and the architecture name.
# Find out the latest release of Windows exporter on the official
# GitHub repository: https://github.com/prometheus-community/windows_exporter/releases
# Version of Windows Exporter
$Version = "0.14.0"
# System architecture
$Arch = "amd64"

# Check if Windows Exporter is already in place
if (Test-Path -Path "C:\prometheus\windows_exporter.exe" -PathType Leaf) {
    throw "windows_exporter.exe already exists in C:\Prometheus\"
}

# Create prometheus directory if it does not exist
if (-not (Test-Path -Path "C:\prometheus" -PathType Container)) {
    Write-Verbose -Message "Create Prometheus directory"
    New-Item -ItemType Directory -Path "C:\prometheus"
}

# Download Windows Exporter
Write-Verbose -Message "Download Windows Exporter"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    (New-Object System.Net.WebClient).DownloadFile(
        "https://github.com/prometheus-community/windows_exporter/releases/download/v$Version/windows_exporter-$Version-$Arch.exe",
        "C:\prometheus\windows_exporter.exe"
    )
} catch {
    throw ("An error occurred during the download of Windows Exporter. Error message: " + $_.Exception.Message)
}

# Create inputs directory for Windows Exporter if it does not exist
if (-not (Test-Path -Path "C:\prometheus\textfile_inputs" -PathType Container)) {
    Write-Verbose -Message "Create textfile_inputs directory for Windows Exporter"
    New-Item -ItemType Directory -Path "C:\prometheus\textfile_inputs"
}

# You can change the Windows Exporter collectors if required,
# more information on https://github.com/prometheus-community/windows_exporter#collectors
$WindowsExporterCollectors = "cpu,cs,logical_disk,net,os,service,system,textfile,tcp,process"
# Create Windows service
Write-Verbose -Message "Create Windows service for Windows Exporter"
New-Service -Name PrometheusWindowsExporter `
    -DisplayName "Prometheus Windows Exporter" `
    -Description "Export Windows system metrics for Prometheus" `
    -binaryPathName "`"C:\\prometheus\\windows_exporter.exe`" --collectors.enabled=`"$WindowsExporterCollectors`" --collector.textfile.directory=`"C:\\prometheus\\textfile_inputs`""

# You can change the Windows firewall rule profile if required,
# more information on https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule
$FWRuleProfile = "Domain"
# Add Windows firewall rule
Write-Verbose -Message "Add Windows firewall rule for Windows Exporter"
New-NetFirewallRule -Name "prometheus_windows_exporter" `
    -DisplayName "Prometheus Windows Exporter" `
    -Protocol TCP `
    -LocalPort 9182 `
    -Group "Prometheus" `
    -Action Allow `
    -Direction Inbound `
    -Profile  $FWRuleProfile

# Start Windows Service
Write-Verbose -Message "Start Windows Exporter Windows service"
Start-Service -Name PrometheusWindowsExporter
