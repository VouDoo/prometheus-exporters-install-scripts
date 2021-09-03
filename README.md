# Prometheus Exporters install scripts

Scripts to automatically install Exporters for Prometheus

## One-liners

- [Install Node Exporter on Redhat 6 distributions](install-node-exporter-rh6.sh)

  ``` sh
  curl -s https://raw.githubusercontent.com/VouDoo/prometheus-exporters-install-scripts/master/install-node-exporter-rh6.sh | sudo bash
  ```

- [Install Node Exporter on Redhat 7 distributions](install-node-exporter-rh7.sh)

  ``` sh
  curl -s https://raw.githubusercontent.com/VouDoo/prometheus-exporters-install-scripts/master/install-node-exporter-rh7.sh | sudo bash
  ```

- [Install Windows Exporter on Windows OS](Install-WindowsExporter.ps1)

  _Run in a PowerShell console as Administrator._

  ``` pwsh
  iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/VouDoo/prometheus-exporters-install-scripts/master/Install-WindowsExporter.ps1'))
  ```
