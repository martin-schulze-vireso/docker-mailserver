#! /bin/bash

# executed  from scripts in target/bin/
# task      provides frequently used functions

function errex
{
  echo "${@}" 1>&2
  exit 1
}

function escape
{
  echo "${1//./\\.}"
}
