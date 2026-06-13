#!/bin/bash
set -eo pipefail

me=locker
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
java_jar=${script_dir}/locker.jar
java_class=io.github.davidecolombo.locker.Locker

if [ -x "${script_dir}/jre/bin/java" ]; then
    java_bin="${script_dir}/jre/bin/java"
else
    java_bin=java
fi

option=""
key=""
data_file=${script_dir}/locker.dat

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--encrypt|-a|--append|-d|--decrypt)
            option=$1; shift ;;
        -f|--file)
            data_file=$2; shift 2 ;;
        *)
            key=$1; shift ;;
    esac
done

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
printf "Usage: %s [OPTION] [KEY] [--file PATH]\n\
  -e, --encrypt        printf \"secret\" | %s -e your_key\n\
  -a, --append         printf \"more\" | %s -a your_key\n\
  -d, --decrypt        %s -d your_key\n\
  -f, --file           path to the data file (default: locker.dat next to the script)\n\
  CTRL + D send the EOF character\n" \
  "${me}" "${me}" "${me}" "${me}"
;;
esac
exit $?
