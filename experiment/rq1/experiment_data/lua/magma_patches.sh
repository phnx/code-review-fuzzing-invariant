# !/bin/bash


# apply Magma setup and bug patches

git -C $BFC_REPOSITORY_PATH reset --hard && \
git -C $BFC_REPOSITORY_PATH clean -xdf

git -C $BIC_REPOSITORY_PATH reset --hard && \
git -C $BIC_REPOSITORY_PATH clean -xdf

# option2: apply all bugs (unmatched selection criteria for hard bugs)
find \
    "/magma/targets/lua/patches/setup" \
    "/magma/targets/lua/patches/bugs" -name "*.patch" | \
while read patch; do
echo "Applying $patch"
    name=${patch##*/}
    name=${name%.patch}
    echo $patch
    echo $name
    sed "s/%MAGMA_BUG%/$name/g" "$patch" | patch -p1 -d $BFC_REPOSITORY_PATH
    sed "s/%MAGMA_BUG%/$name/g" "$patch" | patch -p1 -d $BIC_REPOSITORY_PATH
done