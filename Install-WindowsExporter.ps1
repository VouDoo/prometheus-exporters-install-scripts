#Requires -RunAsAdministrator

<#

.SYNOPSIS
Install Windows Exporter

.DESCRIPTION
Automatically download and install Windows Exporter.

.PARAMETER Version
Version of Windows Exporter.
Find out the latest release of Windows exporter on GitHub:
    https://github.com/prometheus-community/windows_exporter/releases

.PARAMETER Architecture
System architecture.
Find out the architectures supported by Windows exporter on GitHub:
    https://github.com/prometheus-community/windows_exporter/releases

.PARAMETER Collectors
Comma-separated list of collectors to use in Windows Exporter.
Find out the Windows Exporter collectors on GitHub:
    https://github.com/prometheus-community/windows_exporter#collectors

.PARAMETER InstallDirectoryPath
Path to the installation directory.

.PARAMETER FirewallProfile
Profile to which the Windows firewall rule is assigned.

.EXAMPLE
.\Install-WindowsExporter.ps1

.EXAMPLE
.\Install-WindowsExporter.ps1 -Version "0.16.0" -Architecture "amd64" -InstallDirectoryPath "C:\prometheus" -FirewallProfile Domain

.NOTES
(C) Copyright 2021, Maxence Grymonprez <maxgrymonprez@live.fr>

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
- PowerShell online documentation:
    https://docs.microsoft.com/en-us/powershell
- Windows Exporter GitHub repository:
    https://github.com/prometheus-community/windows_exporter

#>

[CmdletBinding()]
param (
    [Parameter(HelpMessage = "Version of Windows Exporter")]
    [ValidateNotNullOrEmpty()]
    [string] $Version = "0.16.0",

    [Parameter(HelpMessage = "System architecture")]
    [ValidateNotNullOrEmpty()]
    [string] $Architecture = "amd64",

    [Parameter(HelpMessage = "Comma-separated list of collectors to use in Windows Exporter")]
    [ValidateNotNullOrEmpty()]
    [string] $Collectors = "cpu,cs,logical_disk,net,os,service,system,textfile,tcp,process",

    [Parameter(HelpMessage = "Path to the installation directory")]
    [ValidateNotNullOrEmpty()]
    [Alias("Path")]
    [string] $InstallDirectoryPath = "C:\prometheus",

    [Parameter(HelpMessage = "Profile to which the Windows firewall rule is assigned")]
    [ValidateSet("Domain", "Private", "Public", "Any")]
    [string] $FirewallProfile = "Domain"
)

begin {
    $ErrorActionPreference = "Stop"
}

process {
    $InstallDirectoryPath = [System.IO.Path]::GetFullPath($InstallDirectoryPath)

    $Service = @{
        Name           = "PrometheusWindowsExporter"
        DisplayName    = "Prometheus Windows Exporter"
        Description    = "Export Windows system metrics for Prometheus"
        BinaryPathName = "`"$InstallDirectoryPath\windows_exporter.exe`" --collectors.enabled=`"$Collectors`" --collector.textfile.directory=`"$InstallDirectoryPath\textfile_inputs`""
        StartupType    = "Automatic"
    }

    $NetFirewallRule = @{
        Name        = "prometheus_windows_exporter"
        DisplayName = "Prometheus Windows Exporter"
        Protocol    = "TCP"
        LocalPort   = 9182
        Group       = "Prometheus"
        Action      = "Allow"
        Direction   = "Inbound"
        Profile     = $FirewallProfile
    }

    if (Test-Path -Path "$InstallDirectoryPath\windows_exporter.exe" -PathType Leaf) {
        throw "`"$InstallDirectoryPath\windows_exporter.exe`" already exists."
    }

    if (-not (Test-Path -Path $InstallDirectoryPath -PathType Container)) {
        Write-Verbose -Message "Create `"$InstallDirectoryPath`" directory."
        New-Item -Path $InstallDirectoryPath -ItemType Directory -Force | Out-Null
    }

    Write-Verbose -Message "Download executable."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        (New-Object System.Net.WebClient).DownloadFile(
            "https://github.com/prometheus-community/windows_exporter/releases/download/v$Version/windows_exporter-$Version-$Architecture.exe",
            "$InstallDirectoryPath\windows_exporter.exe"
        )
    }
    catch {
        throw "An error occurred while downloading: {0}" -f $_.Exception.Message
    }

    if (-not (Test-Path -Path "$InstallDirectoryPath\textfile_inputs" -PathType Container)) {
        Write-Verbose -Message "Create `"textfile_inputs`" subdirectory."
        New-Item -Path "$InstallDirectoryPath\textfile_inputs" -ItemType Directory | Out-Null
    }

    Write-Verbose -Message "Create Windows service."
    New-Service @Service | Out-Null

    Write-Verbose -Message "Set Windows service auto-restart on failure."
    & sc.exe failure $Service.Name reset= 30 actions= restart/5000 | Out-Null

    Write-Verbose -Message "Start Windows Service."
    Start-Service -Name $Service.Name

    Write-Verbose -Message "Add Windows firewall rule."
    New-NetFirewallRule @NetFirewallRule | Out-Null
}
