# Install Maven 3.9.13 (manual install)
$destDir = "$env:USERPROFILE\LocalData\bin"
$url     = "https://downloads.apache.org/maven/maven-3/3.9.13/binaries/apache-maven-3.9.13-bin.zip"
Invoke-WebRequest $url -OutFile "$destDir\apache-maven-3.9.13-bin.zip"
Expand-Archive "$destDir\apache-maven-3.9.13-bin.zip" $destDir
Remove-Item "$destDir\apache-maven-3.9.13-bin.zip"

# Set environment variables permanently
[Environment]::SetEnvironmentVariable("MAVEN_HOME", "$destDir\apache-maven-3.9.13", "User")
[Environment]::SetEnvironmentVariable("PATH", [Environment]::GetEnvironmentVariable("PATH", "User") + ";$destDir\apache-maven-3.9.13\bin", "User")

mvn -v
