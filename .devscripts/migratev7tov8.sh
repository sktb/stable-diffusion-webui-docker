#!/bin/bash

set -Eeuo pipefail

echo "Renaming..."

# compatible with default auto-names
mv -v ./models/StableDiffusion ./models/Stable-diffusion
mv -v ./models/Deepdanbooru ./models/torch_deepdanbooru

# casing problem on windows
mv -v ./models/Hypernetworks ./models/hypernetworks1
mv -v ./models/hypernetworks1 ./models/hypernetworks

mv -v ./models/MiDaS ./models/midas1
mv -v ./models/midas1 ./models/midas


echo "Moving folders..."

mkdir -pv ./final

mv -v ./config ./final/config
mv -v ./models/.cache ./final/.cache
mv -v ./models/embeddings ./final/embeddings
mv -v ./data ./final/models

mv -v ./final ./data
