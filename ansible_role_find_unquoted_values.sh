#!/bin/sh

# A script to find not quoted values in Ansible roles.

for binary in grep cut wc ; do
  which "${binary}" > /dev/null 2>&1 || (echo "Missing ${binary}, please install it." ; exit 1)
done

checker() {
  for directory in defaults handlers tasks meta molecule vars ; do
    sub_folder="${1}"
    for folder in $sub_folder/$directory ; do
      if [ -d "${folder}" ] ; then
        var_name_pattern='^.*:[a-zA-z0-9\-\_]*:'
        version_pattern='[a-zA-z0-9\-\_]*: [0-9].*\.'
        colon_pattern='[a-zA-z0-9\-\_]*: [a-zA-z0-9\-\_].*:.*'
        pattern="(${version_pattern}|${colon_pattern})"
        matches=$(find "${folder}" -name '*.yml' -exec grep -HE "^${pattern}" {} \; | grep -oE ${var_name_pattern} | sed -e 's/.$//' -e 's/:/: /')
        match_count=$(echo "${matches}" | wc -l)
        if [ -n "${match_count}" ] ; then
          if [ "${match_count}" -gt 0 ] ; then
            echo "Found $((match_count * 1)) risky and unquoted values in ${folder}:"
            echo "${matches}"
          fi
        fi
      fi
    done
  done
}

while getopts 'f:' OPTION; do
  case "$OPTION" in
    f)
      sub_folder="$OPTARG"
      ;;
    *)
      echo "Unknow argument: $0 [-f path]" >&2
      exit 1
    ;;
  esac
done
shift "$((OPTIND -1))"

if [ -z "$sub_folder" ]; then
  sub_folder="."
fi

# Save the errors in a variable "errors".
errors=$(checker "${sub_folder}")

# If the "errors" variable has content, something is wrong.
if [ -n "${errors}" ] ; then
  echo "${errors}"
  exit 1
fi
