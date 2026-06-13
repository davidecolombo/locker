#!/bin/bash
set -eo pipefail

#me="./$(basename "$0")"
me=locker
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
java_home=$(dirname "$(dirname "$(readlink -f "$(which java)")")")
java_bin=${java_home}/bin/java
java_jar=${script_dir}/locker.jar
java_class=io.github.davidecolombo.locker.Locker
data_file=${script_dir}/locker.dat

option=$1
key=$2

encrypt_command="${java_bin} -cp ${java_jar} ${java_class} --key ${key}"
decrypt_command="${java_bin} -cp ${java_jar} ${java_class} --key ${key} --decrypt"

case ${option} in
  -e | --encrypt)
    ${encrypt_command} > "${data_file}"
  ;;
  -a | --append)
    temp=$( ${decrypt_command} < "${data_file}" )
    ( echo "${temp}" ; echo -n "$( </dev/stdin )" ) | ${encrypt_command} > "${data_file}"
  ;;
  -d | --decrypt)
    ${decrypt_command} < "${data_file}"
  ;;
*)
printf "Usage: %s [OPTION] [KEY]\n\
  -e, --encrypt        printf \"secret\" | %s -e your_key\n\
  -a, --append         printf \"more\" | %s -a your_key\n\
  -d, --decrypt        %s -d your_key\n\
  CTRL + D send the EOF character\n" \
  "${me}" "${me}" "${me}" "${me}"
;;
esac
exit $?