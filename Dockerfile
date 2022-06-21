FROM mcr.microsoft.com/powershell:latest

RUN pwsh -Command 'Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-Module ServiceNow -ErrorAction Stop'

ENV SNOW_SERVER=${SNOW_SERVER}
ENV SNOW_TOKEN=${SNOW_TOKEN}
ENV SNOW_USER=${SNOW_USER}
ENV SNOW_PASS=${SNOW_PASS}
ENV POWERSHELL_TELEMETRY_OPTOUT=1

SHELL ["pwsh"]
