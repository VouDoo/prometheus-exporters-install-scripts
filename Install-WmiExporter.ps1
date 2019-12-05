#Requires -Version 2.0
#Requires -RunAsAdministrator

<#

.SYNOPSIS
Install WMI Exporter

.DESCRIPTION
This script automatically downloads and installs WMI Exporter.

.EXAMPLE
.\Install-WmiExporter.ps1

.NOTES
(C) Copyright 2019, Maxence Grymonprez <maxgrymonprez@live.fr>

Install-WmiExporter.ps1 is free software: you can redistribute
it and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Install-WmiExporter.ps1 is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with help.sh. If not, see <http://www.gnu.org/licenses>.

.LINK
PowerShell online documentation:
https://docs.microsoft.com/en-us/powershell

WMI Exporter GitHub repository:
https://github.com/martinlindhe/wmi_exporter

#>

# Set verbose preference
Set-Variable -Name VerbosePreference -Value "Continue" -Scope Global

# You can replace the version number and the architecture name.
# Find out the latest release of WMI exporter on the official
# GitHub repository: https://github.com/martinlindhe/wmi_exporter/releases
# Version of WMI Exporter
$Version = "0.9.0"
# System architecture
$Arch = "amd64"

# Check if WMI Exporter is already in place
if (Test-Path -Path "C:\prometheus\wmi_exporter.exe" -PathType Leaf) {
    throw "wmi_exporter.exe already exists in C:\Prometheus\"
}

# Create prometheus directory if it does not exist
if (-not (Test-Path -Path "C:\prometheus" -PathType Container)) {
    Write-Verbose -Message "Create Prometheus directory"
    New-Item -ItemType Directory -Path "C:\prometheus"
}

# Download WMI Exporter
Write-Verbose -Message "Download WMI Exporter"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    (New-Object System.Net.WebClient).DownloadFile(
        "https://github.com/martinlindhe/wmi_exporter/releases/download/v$Version/wmi_exporter-$Version-$Arch.exe",
        "C:\prometheus\wmi_exporter.exe"
    )
} catch {
    throw ("An error occurred during the download of WMI Exporter. Error message: " + $_.Exception.Message)
}

# Create inputs directory for WMI Exporter if it does not exist
if (-not (Test-Path -Path "C:\prometheus\textfile_inputs" -PathType Container)) {
    Write-Verbose -Message "Create textfile_inputs directory for WMI Exporter"
    New-Item -ItemType Directory -Path "C:\prometheus\textfile_inputs"
}

# You can change the WMI Exporter collectors if required,
# more information on https://github.com/martinlindhe/wmi_exporter#collectors
$WmiExporterCollectors = "cpu,cs,logical_disk,net,os,service,system,textfile,tcp,process"
# Create Windows service
Write-Verbose -Message "Create Windows service for WMI Exporter"
New-Service -Name PrometheusWmiExporter `
    -DisplayName "Prometheus WMI Exporter" `
    -Description "Export Windows system metrics for Prometheus" `
    -binaryPathName "`"C:\\prometheus\\wmi_exporter.exe`" --collectors.enabled=`"$WmiExporterCollectors`" --collector.textfile.directory=`"C:\\prometheus\\textfile_inputs`""

# You can change the Windows firewall rule profile if required,
# more information on https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule
$FWRuleProfile = "Domain"
# Add Windows firewall rule
Write-Verbose -Message "Add Windows firewall rule for WMI Exporter"
New-NetFirewallRule -Name "prometheus_wmi_exporter" `
    -DisplayName "Prometheus WMI Exporter" `
    -Protocol TCP `
    -LocalPort 9182 `
    -Group "Prometheus" `
    -Action Allow `
    -Direction Inbound `
    -Profile  $FWRuleProfile

# Start Windows Service
Write-Verbose -Message "Start WMI Exporter Windows service"
Start-Service -Name PrometheusWmiExporter
