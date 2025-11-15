# !/bin/bash

# TODO split fuzz/coverage binary if performance is affected

# update ldflags for libfuzzer
if [ "$FUZZING_TOOL" = "libfuzzer" ]; then
    export LIB_FUZZING_ENGINE="-fsanitize=fuzzer"
fi


# BFC
cd $BFC_REPOSITORY_PATH

export BFC_BUILD=/workdir/bfc_build

# copy driver - just in case
cp /workdir/hb-shape-fuzzer.cc $BFC_REPOSITORY_PATH/test/fuzzing/hb-shape-fuzzer.cc

# build coverage target
echo "build BFC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS

# Disable:
# 1. UBSan vptr since target built with -fno-rtti.
export CFLAGS="$CFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"
export CXXFLAGS="$CXXFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"

rm -rf $BFC_BUILD
mkdir -p $BFC_BUILD

meson --default-library=static --wrap-mode=nodownload \
      -Dexperimental_api=true \
      -Dfuzzer_ldflags="$(echo $LIB_FUZZING_ENGINE)" \
      $BFC_BUILD \
  || (cat build/meson-logs/meson-log.txt && false)

# Build only shape fuzzer
ninja -v -j$(nproc) -C $BFC_BUILD test/fuzzing/hb-shape-fuzzer
mv $BFC_BUILD/test/fuzzing/hb-shape-fuzzer $BFC_BINARY_PATH

# Update binary targets
cp $BFC_BINARY_PATH/hb-shape-fuzzer $BFC_TARGET



# BIC
cd $BIC_REPOSITORY_PATH
export BIC_BUILD=/workdir/bic_build

# copy driver
cp /workdir/hb-shape-fuzzer.cc $BIC_REPOSITORY_PATH/test/fuzzing/hb-shape-fuzzer.cc

# build coverage target
echo "build BIC coverage target"

export CFLAGS="-g -O0 -fprofile-instr-generate -fcoverage-mapping"
export CXXFLAGS=$CFLAGS


# Disable:
# 1. UBSan vptr since target built with -fno-rtti.
export CFLAGS="$CFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"
export CXXFLAGS="$CXXFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"

rm -rf $BIC_BUILD
mkdir -p $BIC_BUILD

meson --default-library=static --wrap-mode=nodownload \
      -Dexperimental_api=true \
      -Dfuzzer_ldflags="$(echo $LIB_FUZZING_ENGINE)" \
      $BIC_BUILD \
  || (cat build/meson-logs/meson-log.txt && false)

# Build only shape fuzzer
ninja -v -j$(nproc) -C $BIC_BUILD test/fuzzing/hb-shape-fuzzer
mv $BIC_BUILD/test/fuzzing/hb-shape-fuzzer $BIC_BINARY_PATH

# Update binary targets
cp $BFC_BINARY_PATH/hb-shape-fuzzer $BIC_TARGET

# collect initial corpus
cd $BFC_REPOSITORY_PATH
for d in \
	test/shape/data/in-house/fonts \
	test/shape/data/aots/fonts \
	test/shape/data/text-rendering-tests/fonts \
	test/api/fonts \
	test/fuzzing/fonts \
	perf/fonts \
	; do
	cp $d/* $INITIAL_SEED_PATH
done
