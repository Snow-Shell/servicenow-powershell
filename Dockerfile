# LTS image
FROM mcr.microsoft.com/powershell:7.4-alpine-3.20 AS installer

# Opt-out of telemetry
ENV POWERSHELL_TELEMETRY_OPTOUT=1

# Install the ServiceNow module to a specific path
# We use -Scope CurrentUser to keep the path predictable for the 'COPY' step later
RUN pwsh -Command "Install-Module -Name 'ServiceNow' -Force -AllowClobber -Scope CurrentUser"

# -----------------------------------------------------------------------------

FROM mcr.microsoft.com/powershell:7.4-alpine-3.20

RUN apk add --no-cache icu-libs
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
ENV POWERSHELL_TELEMETRY_OPTOUT=1

# Copy only the installed module from the builder stage
COPY --from=installer /root/.local/share/powershell/Modules/ServiceNow /usr/local/share/powershell/Modules/ServiceNow

# Create a non-root user
RUN adduser -D psworker
USER psworker
WORKDIR /home/psworker

ENTRYPOINT ["pwsh"]