#!/bin/bash
set -euxo pipefail
mvn clean install
mvn sonar:sonar \
  -Dsonar.projectKey=locker \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=e3947d9beb3eae44b4f12d2e402992ebcf63833a
