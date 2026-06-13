param([switch]$Release)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

mvn clean install
mvn sonar:sonar `
    "-Dsonar.projectKey=locker" `
    "-Dsonar.host.url=http://127.0.0.1:9000" `
    "-Dsonar.login=sqa_e96c76009698b1910f78a82ea6d0473445eef69d"

if ($Release) {
    $version = ([xml](Get-Content pom.xml)).project.version
    $tag = "v$version"
    $dirty = git status --porcelain
    if ($dirty) { throw "Working tree is not clean. Commit or stash changes before releasing." }
    git tag $tag
    git push origin $tag
    Write-Host "Tag $tag pushed. GitHub Actions will build and publish the release."
}
