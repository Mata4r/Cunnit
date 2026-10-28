# Build the Cunnit ISO on Windows using Docker Desktop (Linux containers).
# Output lands in .\out\cunnit-trixie-amd64.iso
$ErrorActionPreference = 'Stop'
docker run --rm --privileged `
  -v "${PSScriptRoot}:/src" `
  -e SRC=/src `
  debian:trixie `
  bash -c "tr -d '\r' < /src/build.sh > /tmp/build.sh && bash /tmp/build.sh"
