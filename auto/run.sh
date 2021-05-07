#!/bin/bash -e

cd "$(dirname "$0")"

if [ ! -d ~/env/pillow-perf ]; then
  mkdir -p ~/env
  rm -rf ~/env/pillow-perf
  python3 -m venv ~/env/pillow-perf
  ~/env/pillow-perf/bin/pip install -U pip setuptools wheel
fi

source ~/env/pillow-perf/bin/activate
pip install -r ../testsuite/requirements.txt
pip install opencv-python==4.5.2.52 pgmagick==0.7.5


git clone https://github.com/uploadcare/pillow-simd.git Pillow || true

pushd Pillow

  git fetch

  function pillow_checkout {
    git checkout -f $1
    # Force rebuild
    mkdir -p src && touch ./_imaging.c ./src/_imaging.c
    CFLAGS="$2" python ./setup.py develop > build.log 2>&1
    grep --color=always "error:" build.log && exit || true
    echo "========================="
    echo "Pillow $1 $2"
    echo "========================="
  }

  # Tests with custom memory management:
  # MM $RUN scale filter -n5 "${@:2}"
  function MM {
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 \
    PILLOW_BLOCK_SIZE=128k \
    PILLOW_BLOCKS_MAX=2048 \
    PILLOW_ALIGNMENT=64 \
    "$@"
  }

  RUN=../../testsuite/run.py


  # ============
  # Pillow 2.6.2
  # ============
  pillow_checkout 2.6.2
  $RUN scale blur filter full_cycle -n5 "${@:2}"
  $RUN load convert composition rotate_right "${@:2}"


  # ============
  # Pillow 2.7.0
  # ============
  pillow_checkout 2.7.0
  $RUN scale blur filter full_cycle -n5 "${@:2}"
  $RUN load convert composition rotate_right "${@:2}"


  # ============
  # Pillow 4.3.0
  # ============
  pillow_checkout 4.3.0
  $RUN scale blur filter full_cycle -n5 "${@:2}"
  $RUN load convert composition rotate_right "${@:2}"

  pillow_checkout v4.3.0.post0 -msse4
  $RUN scale blur filter full_cycle load convert composition rotate_right "${@:2}"

  if [ "$1" != "no" ]; then
    pillow_checkout v4.3.0.post0 -mavx2
    $RUN scale filter full_cycle convert composition "${@:2}"
  fi


  # ============
  # Pillow 7.0.0
  # ============
  pillow_checkout 7.0.0
  $RUN scale blur filter full_cycle lut -n5 "${@:2}"
  $RUN load convert composition rotate_right "${@:2}"

  pillow_checkout v7.0.0.post3 -msse4
  $RUN scale blur filter full_cycle lut load convert composition rotate_right "${@:2}"

  if [ "$1" != "no" ]; then
    pillow_checkout v7.0.0.post3 -mavx2
    $RUN scale filter full_cycle lut convert composition "${@:2}"
  fi


  # ===========
  # Competitors
  # ===========
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
