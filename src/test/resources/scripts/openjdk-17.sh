#!/bin/bash
set -euxo pipefail

sudo apt-get update && sudo apt-get upgrade
sudo apt-get install openjdk-17-jdk
java -version
javac -version

# nano ~/.bashrc
# export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
# export PATH=$PATH:$JAVA_HOME/bin

# source ~/.bashrc
# echo $JAVA_HOME
# echo $PATH
