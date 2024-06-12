#!/bin/bash

set -Eeuo pipefail

# TODO: move all mkdir -p ?
mkdir -p /config/auto/scripts/
# mount scripts individually

echo $ROOT
ls -lha $ROOT

find "${ROOT}/scripts/" -maxdepth 1 -type l -delete
cp -vrfTs /config/auto/scripts/ "${ROOT}/scripts/"

# Set up config file
python /docker/config.py /config/auto/config.json

if [ ! -f /config/auto/ui-config.json ]; then
  echo '{}' >/config/auto/ui-config.json
fi

if [ ! -f /config/auto/styles.csv ]; then
  touch /config/auto/styles.csv
fi

# copy models from original models folder
mkdir -p /models/VAE-approx/ /models/karlo/

rsync -a --info=NAME ${ROOT}/models/VAE-approx/ /models/VAE-approx/
rsync -a --info=NAME ${ROOT}/models/karlo/ /models/karlo/

declare -A MOUNTS

MOUNTS["/root/.cache"]="/models/.cache"
MOUNTS["${ROOT}/models"]="/models"

MOUNTS["${ROOT}/embeddings"]="/models/embeddings"
MOUNTS["${ROOT}/config.json"]="/config/auto/config.json"
MOUNTS["${ROOT}/ui-config.json"]="/config/auto/ui-config.json"
MOUNTS["${ROOT}/styles.csv"]="/config/auto/styles.csv"
MOUNTS["${ROOT}/extensions"]="/config/auto/extensions"
MOUNTS["${ROOT}/config_states"]="/config/auto/config_states"

# extra hacks
MOUNTS["${ROOT}/repositories/CodeFormer/weights/facelib"]="/models/.cache"

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

echo "Installing extension dependencies (if any)"

# because we build our container as root:
chown -R root ~/.cache/
chmod 766 ~/.cache/

shopt -s nullglob
# For install.py, please refer to https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Developing-extensions#installpy
list=(./extensions/*/install.py)
for installscript in "${list[@]}"; do
  EXTNAME=$(echo $installscript | cut -d '/' -f 3)
  # Skip installing dependencies if extension is disabled in config
  if $(jq -e ".disabled_extensions|any(. == \"$EXTNAME\")" config.json); then
    echo "Skipping disabled extension ($EXTNAME)"
    continue
  fi
  PYTHONPATH=${ROOT} python "$installscript"
done

if [ -f "/config/auto/startup.sh" ]; then
  pushd ${ROOT}
  echo "Running startup script"
  . /config/auto/startup.sh
  popd
fi

exec "$@"
