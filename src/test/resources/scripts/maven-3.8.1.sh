#!/bin/bash
set -euxo pipefail

cd ${HOME}
pwd
wget https://downloads.apache.org/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz
tar -zxvf apache-maven-3.8.1-bin.tar.gz

# nano ~/.bashrc
# export MAVEN_HOME=${HOME}/apache-maven-3.8.1
# export PATH=$PATH:$MAVEN_HOME/bin

# source ~/.bashrc
# echo $MAVEN_HOME
# echo $PATH
