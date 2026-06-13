#!/bin/bash
set -euxo pipefail
mvn clean install
mvn sonar:sonar \
  -Dsonar.projectKey=locker \
  -Dsonar.host.url=http://127.0.0.1:9000 \
  -Dsonar.login=sqa_e96c76009698b1910f78a82ea6d0473445eef69d
