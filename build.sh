#!/bin/bash
set -euo pipefail

release=false
for arg in "$@"; do
    case $arg in --release) release=true ;; esac
done

mvn clean install
mvn sonar:sonar \
    "-Dsonar.projectKey=locker" \
    "-Dsonar.host.url=http://127.0.0.1:9000" \
    "-Dsonar.login=sqa_e96c76009698b1910f78a82ea6d0473445eef69d"

if [ "${release}" = true ]; then
    version=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
    tag="v${version}"
    if [ -n "$(git status --porcelain)" ]; then
        echo "Working tree is not clean. Commit or stash changes before releasing."; exit 1
    fi
    git tag "${tag}"
    git push origin "${tag}"
    echo "Tag ${tag} pushed. GitHub Actions will build and publish the release."
fi
