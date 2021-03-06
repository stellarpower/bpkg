#!/bin/bash

[ -z "${BASH_SOURCE}" ] && BPKG_DIR="$(dirname "${0}")" || BPKG_DIR="$(dirname "${BASH_SOURCE}")"
BPKG_DIR="$(readlink -f "${BPKG_DIR}")"


## Collection of shared bpkg functions

## Init local config and set environmental defaults
bpkg_initrc() {
  local global_config=${BPKG_GLOBAL_CONFIG:-"/etc/bpkgrc"}
  [ -f "$global_config" ] && source "$global_config"
  local config=${BPKG_CONFIG:-"$HOME/.bpkgrc"}
  [ -f "$config" ] && source "$config"
  ## set defaults
  if [ ${#BPKG_REMOTES[@]} -eq 0 ]; then
    BPKG_REMOTES[0]=${BPKG_REMOTE-https://raw.githubusercontent.com}
    BPKG_GIT_REMOTES[0]=${BPKG_GIT_REMOTE-https://github.com}
  fi
  BPKG_USER="${BPKG_USER:-"bpkg"}"
  BPKG_INDEX=${BPKG_INDEX:-"$HOME/.bpkg/index"}
}

## check parameter consistency
bpkg_validate () {
  bpkg_initrc
  if [ ${#BPKG_GIT_REMOTES[@]} -ne ${#BPKG_REMOTES[@]} ]; then
    mesg='BPKG_GIT_REMOTES[%d] differs in size from BPKG_REMOTES[%d] array'
    fmesg=$(printf "$mesg" "${#BPKG_GIT_REMOTES[@]}" "${#BPKG_REMOTES[@]}")
    error "$fmesg"
    return 1
  fi
  return 0
}

## format and output message
bpkg_message () {
  if type -f "${BPKG_DIR}/bpkg-term" > /dev/null 2>&1; then
    "${BPKG_DIR}/bpkg-term" color "${1}"
  fi

  shift
  printf "    ${1}"
  shift

  if type -f "${BPKG_DIR}/bpkg-term" > /dev/null 2>&1; then
    "${BPKG_DIR}/bpkg-term" reset
  fi

  printf ": "

  if type -f "${BPKG_DIR}/bpkg-term" > /dev/null 2>&1; then
    "${BPKG_DIR}/bpkg-term" reset
    "${BPKG_DIR}/bpkg-term" bright
  fi

  printf "%s\n" "${@}"

  if type -f "${BPKG_DIR}/bpkg-term" > /dev/null 2>&1; then
    "${BPKG_DIR}/bpkg-term" reset
  fi
}

## output error
bpkg_error () {
  {
    bpkg_message "red" "error" "${@}"
  } >&2
}

## output warning
bpkg_warn () {
  {
    bpkg_message "yellow" "warn" "${@}"
  } >&2
}

## output info
bpkg_info () {
  local title="info"
  if (( "${#}" > 1 )); then
    title="${1}"
    shift
  fi
  bpkg_message "cyan" "${title}" "${@}"
}

## takes a remote and git-remote and sets the globals:
##  BPKG_REMOTE: raw remote URI
##  BPKG_GIT_REMOTE: git remote for cloning
##  BPKG_AUTH_GIT_REMOTE: git remote with oauth info embedded,
##  BPKG_OAUTH_TOKEN: token for x-oauth-basic
##  BPKG_CURL_AUTH_PARAM: auth arguments for raw curl requests
##  BPKG_REMOTE_INDEX: location of local index for remote
bpkg_select_remote () {
  local remote=$1
  local git_remote=$2
  BPKG_REMOTE_HOST=$(echo "$git_remote" | sed 's/.*:\/\///' | sed 's/\/$//' | tr '/' '_')
  BPKG_REMOTE_INDEX="$BPKG_INDEX/$BPKG_REMOTE_HOST"
  BPKG_REMOTE_INDEX_FILE="$BPKG_REMOTE_INDEX/index.txt"
  BPKG_OAUTH_TOKEN=""
  BPKG_CURL_AUTH_PARAM=""
  BPKG_GIT_REMOTE=$git_remote
  BPKG_AUTH_GIT_REMOTE=$git_remote
  if [ "${remote:0:10}" == "raw-oauth|" ]; then
    OLDIFS="${IFS}"
    IFS="|"
    local remote_parts=($remote)
    IFS="${OLDIFS}"
    BPKG_OAUTH_TOKEN=${remote_parts[1]}
    BPKG_CURL_AUTH_PARAM="-u $BPKG_OAUTH_TOKEN:x-oauth-basic"
    BPKG_REMOTE=${remote_parts[2]}
    if [[ "$git_remote" == https://* ]] && [[ "$git_remote" != *x-oauth-basic* ]] && [[ "$git_remote" != *${BPKG_OAUTH_TOKEN}* ]]; then
      BPKG_AUTH_GIT_REMOTE=${git_remote/https:\/\//https:\/\/$BPKG_OAUTH_TOKEN:x-oauth-basic@}
    fi
  else
    BPKG_REMOTE=$remote
  fi
}

## given a user and name, sets BPKG_RAW_PATH using the available
## BPKG_REMOTE and BPKG_OAUTH_TOKEN details
bpkg_select_raw_path() {
  local user=$1
  local name=$2
  if [ "$BPKG_OAUTH_TOKEN" == "" ]; then
    BPKG_RAW_PATH="$BPKG_REMOTE/$user/$name"
  else
    BPKG_RAW_PATH="$BPKG_REMOTE/$user/$name/raw"
  fi
  return 0
}

export -f bpkg_initrc
export -f bpkg_validate

export -f bpkg_message
export -f bpkg_warn
export -f bpkg_error
export -f bpkg_info

export -f bpkg_select_remote
export -f bpkg_select_raw_path
