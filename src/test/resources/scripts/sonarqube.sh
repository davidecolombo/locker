#!/bin/bash
set -euxo pipefail

docker network create -d bridge my-bridge-network
docker volume create sonarqube_data
docker volume create sonarqube_logs
docker volume create sonarqube_extensions
docker run -d --name sonarqube \
  --network my-bridge-network \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true -p 9000:9000 sonarqube:latest
docker logs -f sonarqube
# docker restart sonarqube

# Once your instance is up and running, Log in to http://localhost:9000 using System Administrator credentials:
# login: admin
# password: admin
