#!/bin/bash


[ -z "${BASH_SOURCE}" ] && BPKG_DIR="$(dirname "${0}")" || BPKG_DIR="$(dirname "${BASH_SOURCE}")"~
BPKG_DIR="$(readlink -f "${BPKG_DIR}")"

## output usage
usage () {
  echo "usage: bpkg-package [-h|--help]"
  echo "   or: bpkg-package <prop>"
  echo "   or: bpkg-package"
}

## Read a package property
bpkg_package () {
  local prop="${1}"
  local cwd="$(pwd)"
  local pkg="${cwd}/package.json"

  ## parse flags
  case "${prop}" in
    -h|--help)
      usage
      return 0
      ;;
  esac

  ## ensure there is a package to read
  if ! test -f "${pkg}"; then
    echo 2>&1 "error: Unable to find \`package.json' in $(pwd)"
    return 1
  fi

  if [ -z "${prop}" ]; then
    ## output all propertyies if property
    ## is ommited
    {
      cat "${pkg}" | "${BPKG_DIR}/bpkg-json" -b
    }
  else
    ## show value for a specific property
    ## in 'package.json'
    {
      cat "${pkg}" | "${BPKG_DIR}/bpkg-json" -b | grep "${prop}" | awk '{ $1=""; printf $0 }'
      echo
    }
  fi

  return 0
}

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  export -f bpkg_package
else
  bpkg_package "${@}"
  exit $?
fi
