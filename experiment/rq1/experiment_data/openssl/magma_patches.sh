# !/bin/bash


# apply Magma setup and bug patches
# SSL005, SSL008, SSL010, SSL016, SSL019

git -C $BFC_REPOSITORY_PATH reset --hard && \
git -C $BFC_REPOSITORY_PATH clean -xdf

git -C $BIC_REPOSITORY_PATH reset --hard && \
git -C $BIC_REPOSITORY_PATH clean -xdf

# apply only selected bugs
if [ -n "$HARD_MAGMA_BUGS" ]; then
    # option1: apply hard-to-fuzz bugs only
    PATCH_PATH="""/magma/targets/openssl/patches/bugs/SSL005.patch
    /magma/targets/openssl/patches/bugs/SSL008.patch
    /magma/targets/openssl/patches/bugs/SSL010.patch
    /magma/targets/openssl/patches/bugs/SSL016.patch
    /magma/targets/openssl/patches/bugs/SSL019.patch """
else
    # option2: apply all bugs
    PATCH_PATH=$(find "/magma/targets/openssl/patches/setup" \
    "/magma/targets/openssl/patches/bugs" -name "*.patch" )
fi

for patch in $PATCH_PATH; do
echo "Applying $patch"
    name=${patch##*/}
    name=${name%.patch}
    echo $name
    sed "s/%MAGMA_BUG%/$name/g" "$patch" | patch -p1 -d $BFC_REPOSITORY_PATH
    sed "s/%MAGMA_BUG%/$name/g" "$patch" | patch -p1 -d $BIC_REPOSITORY_PATH
done