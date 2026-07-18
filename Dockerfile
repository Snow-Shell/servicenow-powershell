# LTS image
FROM mcr.microsoft.com/powershell:7.4-alpine-3.20 AS installer

# Opt-out of telemetry
ENV POWERSHELL_TELEMETRY_OPTOUT=1

# Install the ServiceNow module to a specific path
# We use -Scope CurrentUser to keep the path predictable for the 'COPY' step later
RUN pwsh -Command "Install-Module -Name 'ServiceNow' -Force -AllowClobber -Scope CurrentUser"

# -----------------------------------------------------------------------------

FROM mcr.microsoft.com/powershell:7.4-alpine-3.20

# Metadata labels
LABEL org.opencontainers.image.title="ServiceNow PowerShell Module" \
      org.opencontainers.image.description="Container with ServiceNow PowerShell module" \
      org.opencontainers.image.vendor="Snow-Shell" \
      org.opencontainers.image.source="https://github.com/Snow-Shell/servicenow-powershell"

RUN apk add --no-cache icu-libs
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
ENV POWERSHELL_TELEMETRY_OPTOUT=1

# Copy module to system-wide location that's in PSModulePath
COPY --from=installer /root/.local/share/powershell/Modules/ServiceNow /opt/microsoft/powershell/7/Modules/ServiceNow

# Create a non-root user
RUN adduser -D psworker
USER psworker
WORKDIR /home/psworker

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pwsh -NoProfile -Command "Import-Module ServiceNow; exit 0"

# Default to interactive pwsh; pass -Command "..." for one-off commands
ENTRYPOINT ["pwsh", "-NoProfile"]
