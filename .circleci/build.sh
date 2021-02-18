#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/Forenche/kernel_xiaomi_picasso -b  main  kernel
cd kernel
git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
git clone --depth=1 https://github.com/Forenche/AnyKernel3 -b picasso AnyKernel
git clone --depth=1 https://android.googlesource.com/platform/system/libufdt libufdt
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
export CONFIG_PATH=$PWD/arch/arm64/configs/picasso_user_defconfig
PATH="${PWD}/clang/bin:$PATH"
export ARCH=arm64
export KBUILD_BUILD_HOST=circleci
export KBUILD_BUILD_USER="forenche"
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAADBQADVAADaEQ4KS3kDsr-OWAUFgQ" \
        -d chat_id=$chat_id
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• picasso-Stormbreaker Kernel •</b>%0ABuild started on <code>Circle CI</code>%0AFor device <b>Poco x3</b> (picasso)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>Proton clang 12</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b> #AOSP-Alpha"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Poco x3 (picasso) for AOSP-Alpha</b> | <b>Proton clang 12</b>"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build threw an error(s)"
    exit 1
}
# Compile plox
function compile() {
printf "/n/n/n/n/n/n" | make O=out ARCH=arm64 picasso_user_defconfig
       make -j$(nproc --all) O=out \
                             ARCH=arm64 \
			     CC=clang \
			     CROSS_COMPILE=aarch64-linux-gnu- \
			     CROSS_COMPILE_ARM32=arm-linux-gnueabi-
   cp out/arch/arm64/boot/Image AnyKernel
   python2 "libufdt/utils/src/mkdtboimg.py" \
					create "out/arch/arm64/boot/dtbo.img" --page_size=4096 out/arch/arm64/boot/dts/qcom/*.dtbo
   cp out/arch/arm64/boot/dtbo.img AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 picasso-Stormbreaker-${TANGGAL}.zip *
    cd .. 
}
sticker
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
