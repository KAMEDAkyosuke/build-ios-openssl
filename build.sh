#!/bin/sh

ORIG_PATH=$PATH
CURRENT_DIR=`pwd`

ARCH=(iphoneos-cross ios-cross ios64-cross)

if [ ! -e openssl ]; then
    git clone git@github.com:openssl/openssl.git openssl
fi

cd openssl
git checkout -b OpenSSL_1_1_1c refs/tags/OpenSSL_1_1_1c
cd ../


rm -rf include
mkdir include
cp -r openssl/include/openssl include/

rm -rf lib
mkdir lib

len=$((${#ARCH[@]} - 1))
for i in `seq 0 $len`; do
    cd $CURRENT_DIR
    mkdir -p lib/${ARCH[$i]}

    cd openssl

    set +e
    make distclean
    set -e

    ./Configure ${ARCH[$i]}

    if [ ${ARCH[$i]} = iphoneos-cross ]; then
        export CROSS_COMPILE=`xcode-select --print-path`/Toolchains/XcodeDefault.xctoolchain/usr/bin/
        export CROSS_TOP=`xcode-select --print-path`/Platforms/iPhoneSimulator.platform/Developer
        export CROSS_SDK=iPhoneSimulator.sdk
    else
        export CROSS_COMPILE=`xcode-select --print-path`/Toolchains/XcodeDefault.xctoolchain/usr/bin/
        export CROSS_TOP=`xcode-select --print-path`/Platforms/iPhoneOS.platform/Developer
        export CROSS_SDK=iPhoneOS.sdk
    fi
    make -j 4

    cp libcrypto.a $CURRENT_DIR/lib/${ARCH[$i]}/libcrypto.a
    cp libssl.a $CURRENT_DIR/lib/${ARCH[$i]}/libssl.a
done

lipo -create $CURRENT_DIR/lib/iphoneos-cross/libcrypto.a \
     $CURRENT_DIR/lib/ios-cross/libcrypto.a \
     $CURRENT_DIR/lib/ios64-cross/libcrypto.a \
     -output $CURRENT_DIR/lib/libcrypto.a

lipo -create $CURRENT_DIR/lib/iphoneos-cross/libssl.a \
     $CURRENT_DIR/lib/ios-cross/libssl.a \
     $CURRENT_DIR/lib/ios64-cross/libssl.a \
     -output $CURRENT_DIR/lib/libssl.a
