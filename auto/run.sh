#!/bin/bash -e

cd "$(dirname "$0")"

if [ ! -d ~/env/pillow-perf ]; then
  mkdir -p ~/env
  rm -rf ~/env/pillow-perf
  virtualenv ~/env/pillow-perf
fi

source ~/env/pillow-perf/bin/activate
pip install -r ../testsuite/requirements.txt
pip install opencv-python==4.1.2.30 pgmagick==0.7.4


git clone https://github.com/uploadcare/pillow-simd.git Pillow || true

pushd Pillow

  git fetch

  function pillow_checkout {
    git checkout -f $1
    touch ./_imaging.c
    CFLAGS="$2" python ./setup.py develop > build.log 2>&1
    grep --color=always "error:" build.log && exit || true
    echo "========================="
    echo "Pillow $1 $2"
    echo "========================="
  }

  function MM {
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 \
    PILLOW_BLOCK_SIZE=128k \
    PILLOW_BLOCKS_MAX=2048 \
    PILLOW_ALIGNMENT=64 \
    "$@"
  }

  RUN=../../testsuite/run.py
  
  pillow_checkout 2.6.2
  $RUN scale filter full_cycle -n5 "${@:2}"
  $RUN load composition rotate_right "${@:2}"
  
  pillow_checkout 2.7.0
  $RUN scale blur full_cycle -n5 "${@:2}"
  $RUN convert rotate_right "${@:2}"

  pillow_checkout 3.3.3
  $RUN scale -n5 "${@:2}"
  $RUN convert "${@:2}"

  pillow_checkout 3.4.2
  $RUN scale -n5 "${@:2}"
  
  pillow_checkout 4.3.0
  $RUN scale filter -n5 "${@:2}"
  $RUN load convert composition rotate_right "${@:2}"
  MM $RUN scale filter -n5 "${@:2}"
  MM $RUN load convert composition rotate_right "${@:2}"
  

  pillow_checkout v3.2.0.post3 -msse4
  $RUN scale blur "${@:2}"

  if [ "$1" != "no" ]; then
    pillow_checkout v3.2.0.post3 -mavx2
    $RUN scale "${@:2}"
  fi

  pillow_checkout v3.3.3.post0 -msse4
  $RUN scale convert composition "${@:2}"

  if [ "$1" != "no" ]; then
    pillow_checkout v3.3.3.post0 -mavx2
    $RUN scale convert composition "${@:2}"
  fi

  pillow_checkout v3.4.1.post2 -msse4
  $RUN scale "${@:2}"

  if [ "$1" != "no" ]; then
    pillow_checkout v3.4.1.post2 -mavx2
    $RUN scale "${@:2}"
  fi

  pillow_checkout v4.3.0.post0 -msse4
  $RUN scale blur full_cycle convert composition filter "${@:2}"
  MM $RUN scale blur full_cycle convert composition filter "${@:2}"

  if [ "$1" != "no" ]; then
    pillow_checkout v4.3.0.post0 -mavx2
    $RUN scale convert full_cycle composition filter "${@:2}"
    MM $RUN scale convert full_cycle composition filter "${@:2}"
  fi

  $RUN wand_scale wand_full_cycle -n5 "${@:2}"
  $RUN wand_blur wand_lut -n3 "${@:2}"
  $RUN wand_load wand_convert wand_composition wand_rotate_right "${@:2}"

  $RUN pgmagick_scale pgmagick_lut -n5 "${@:2}"
  $RUN pgmagick_blur -n3 "${@:2}"
  $RUN pgmagick_load pgmagick_convert pgmagick_composition pgmagick_rotate_right "${@:2}"

  $RUN cv2_scale cv2_blur cv2_full_cycle -n5 "${@:2}"
  $RUN cv2_load cv2_filter cv2_rotate_right "${@:2}"

  $RUN vips_load vips_full_cycle "${@:2}"
popd
