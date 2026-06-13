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

if [ -z "${key}" ]; then
    printf 'Passphrase: ' > /dev/tty
    IFS= read -r -s key < /dev/tty
    printf '\n' > /dev/tty
fi

write_int32_be() {
    local n=$1
    printf "\\$(printf '%03o' $(( (n >> 24) & 0xFF )))"
    printf "\\$(printf '%03o' $(( (n >> 16) & 0xFF )))"
    printf "\\$(printf '%03o' $(( (n >> 8)  & 0xFF )))"
    printf "\\$(printf '%03o' $(( n         & 0xFF )))"
}

pipe_passphrase() {
    write_int32_be "${#key}"
    printf '%s' "${key}"
}

java_cmd=("${java_bin}" -cp "${java_jar}" "${java_class}")

case ${option} in
  -e | --encrypt)
    { pipe_passphrase; cat; } | "${java_cmd[@]}" > "${data_file}"
  ;;
  -a | --append)
    temp=$( { pipe_passphrase; cat "${data_file}"; } | "${java_cmd[@]}" --decrypt )
    { pipe_passphrase; printf '%s\n' "${temp}"; cat; } | "${java_cmd[@]}" > "${data_file}"
  ;;
  -d | --decrypt)
    { pipe_passphrase; cat "${data_file}"; } | "${java_cmd[@]}" --decrypt
  ;;
*)
printf "Usage: %s [OPTION] [PASSPHRASE] [--file PATH]\n\
  -e, --encrypt        printf \"secret\" | %s -e\n\
  -a, --append         printf \"more\"   | %s -a\n\
  -d, --decrypt        %s -d\n\
  -f, --file           path to the data file (default: locker.dat next to the script)\n\
  If PASSPHRASE is omitted, it is prompted interactively with no echo.\n\
  CTRL + D send the EOF character\n" \
  "${me}" "${me}" "${me}" "${me}"
;;
esac
exit $?
