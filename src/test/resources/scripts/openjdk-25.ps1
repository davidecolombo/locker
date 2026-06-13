# Install OpenJDK 25 via winget
winget install Microsoft.OpenJDK.25
java -version
javac -version

# To set JAVA_HOME permanently:
# [Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Microsoft\jdk-25.0.0.37-hotspot", "Machine")
# [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$env:JAVA_HOME\bin", "Machine")
