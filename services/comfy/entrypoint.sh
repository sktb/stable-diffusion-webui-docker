#!/bin/bash

set -Eeuo pipefail

mkdir -vp /config/comfy/custom_nodes
mkdir -vp /usr/share/fonts/truetype

declare -A MOUNTS

MOUNTS["/root/.cache"]="/models/.cache"
MOUNTS["${ROOT}/input"]="/config/comfy/input"
MOUNTS["${ROOT}/output"]="/output/comfy"

for to_path in "${!MOUNTS[@]}"; do
  set -Eeuo pipefail
  from_path="${MOUNTS[${to_path}]}"
  rm -rf "${to_path}"
  if [ ! -f "$from_path" ]; then
    mkdir -vp "$from_path"
  fi
  mkdir -vp "$(dirname "${to_path}")"
  ln -sT "${from_path}" "${to_path}"
  echo Mounted $(basename "${from_path}")
done

if [ -f "/config/comfy/startup.sh" ]; then
  pushd ${ROOT}
  . /config/comfy/startup.sh
  popd
fi

exec "$@"
