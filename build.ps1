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

    # Always (re)release the current commit under the pom.xml version. If the tag
    # already exists from a previous run, recreate it on HEAD so the release never
    # publishes stale assets from an older commit.
    if (git tag --list $tag) {
        git tag -d $tag
        if ($LASTEXITCODE -ne 0) { throw "git tag -d $tag failed." }
    }
    git tag $tag
    if ($LASTEXITCODE -ne 0) { throw "git tag $tag failed." }
    # --force overwrites the remote tag (if any), re-triggering the release workflow.
    git push --force origin $tag
    if ($LASTEXITCODE -ne 0) { throw "git push of $tag failed." }
    Write-Host "Tag $tag pushed. GitHub Actions will build and publish the release."
}
