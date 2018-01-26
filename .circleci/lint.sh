#!/bin/bash

exitCode=0

# Run is a wrapper around the execution of functions. It captures non-zero exit
# codes and remembers an error happened. This enables running all the linters
# and capturing if any of them failed.
run() {
  $@
  local ret=$?
  if [ $ret -ne 0 ]; then
    exitCode=1
  fi
}

# Lint the Chart.yaml and values.yaml files for Helm
yamllinter() {
  printf "\nLinting the Chart.yaml and values.yaml files at ${1}\n"

  # If a Chart.yaml file is present lint it. Otherwise report an error
  # because one should exist
  if [ -e $1/Chart.yaml ]; then
    run yamllint -c .circleci/lintconf.yml $1/Chart.yaml
  else
    echo "Error $1/Chart.yaml file is missing"
    exitCode=1
  fi

  # If a values.yaml file is present lint it. Otherwise report an error
  # because one should exist
  if [ -e $1/values.yaml ]; then
    run yamllint -c .circleci/lintconf.yml $1/values.yaml
  else
    echo "Error $1/values.yaml file is missing"
    exitCode=1
  fi
}

printf "\nRunning helm dep build...\n"
run helm dep build ${CHART_DIR}

printf "\nRunning helm lint...\n"
run helm lint ${CHART_DIR}

yamllinter ${CHART_DIR}

exit $exitCode
