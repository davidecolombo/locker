#!/bin/bash
set -euxo pipefail

cd ${HOME}
pwd
wget https://downloads.apache.org/maven/maven-3/3.9.13/binaries/apache-maven-3.9.13-bin.tar.gz
tar -zxvf apache-maven-3.9.13-bin.tar.gz

# nano ~/.bashrc
# export MAVEN_HOME=${HOME}/apache-maven-3.9.13
# export PATH=$PATH:$MAVEN_HOME/bin

# source ~/.bashrc
# echo $MAVEN_HOME
# echo $PATH
