# Prometheus Exporters install scripts

Scripts to automatically install Exporters for Prometheus

## One-liners

- [install-node-exporter-rh6.sh](install-node-exporter-rh6.sh)

  ``` sh
  curl -s https://raw.githubusercontent.com/VouDoo/prometheus-exporters-install-scripts/master/install-node-exporter-rh6.sh | sudo bash
  ```

- [install-node-exporter-rh7.sh](install-node-exporter-rh7.sh)

  ``` sh
  curl -s https://raw.githubusercontent.com/VouDoo/prometheus-exporters-install-scripts/master/install-node-exporter-rh7.sh | sudo bash
  ```

- [Install-WindowsExporter.ps1](Install-WindowsExporter.ps1)

  _Run in a PowerShell console as Administrator._

  ``` pwsh
  iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/VouDoo/prometheus-exporters-install-scripts/master/Install-WindowsExporter.ps1'))
  ```
