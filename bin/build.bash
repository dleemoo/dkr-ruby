#!/usr/bin/env bash

root_dir=$(realpath $(dirname $0)/..)

function get_files() {
  files=$(echo $@ |
    sed s/'\<force\>'//g
  )

  if [ ${#files} -eq 0 ]; then
    find build-envs -name '*.env'
  else
    echo $files
  fi
}

function get_options() {
  local options=""
  echo $@ | grep -q '\<force\>' && options="--no-cache"
  echo $options
}

function abort_if_missing_file() {
  if [[ ! -f $1 ]]; then
    echo "$1: isn't a file!" 1>&2
    exit 1
  fi
}

function build_args() {
  args=""
  while IFS="=" read name value; do
    if [[ $value =~ " " ]]; then
      args="${args} --build-arg ${name}=\"${value}\""
    else
      args="${args} --build-arg ${name}=${value}"
    fi
  done <<< $(cat $1)
  echo $args
}

function tag_name() {
  grep '^NAME=' $1 | cut -d'=' -f2
}

function tag() {
  grep '^VERSION=' $1 | cut -d'=' -f2
}

function latest() {
  grep '^LATEST=' $1 | cut -d'=' -f2
}

cd $root_dir &&
  for benv in $(get_files $@); do
    abort_if_missing_file $benv
    name=$(tag_name $benv)
    version=$(tag $benv)
    build_args=$(build_args $benv)
    options=$(get_options $@)
    latest=$(latest $benv)

    cmd1="docker build --rm -f build.Dockerfile $options $build_args -t $name:$version-build ."
    cmd2="docker build --rm $options $build_args -t $name:$version ."
    success=1
    bash -c "$cmd1" &&
      bash -c "$cmd2" &&
      success=0 &&
      [[ $latest == "true" ]] &&
        docker tag $name:$version $name:latest

    [[ $success -eq 0 ]] || exit 2
  done &&
    echo 'Use docker push dleemoo/ruby to upload new images'
