#!/bin/bash
IMG_FILE="flash-image"
UBOOT_FILE="u-boot-sunxi-with-spl.bin"
DTB_FILE="sun8i-v3s-qcqpi.dtb"
KERNEL_FILE="zImage"
ROOTFS_FILE="rootfs.squashfs"
OVERLAYFS_FILE="data.jffs2"

# 制作镜像
function make_image() {
    set -e
    # 生成32M空文件
    dd if=/dev/zero of=$IMG_FILE bs=1M count=32
    # offset=0 写入uboot
    dd if=$UBOOT_FILE of=$IMG_FILE bs=1K seek=0 conv=notrunc
    # offset=512K 写入dtb
    dd if=$DTB_FILE of=$IMG_FILE bs=1K seek=512 conv=notrunc
    # offset=544K 写入内核
    dd if=$KERNEL_FILE of=$IMG_FILE bs=1K seek=544 conv=notrunc
    # offset=7.5M 写入rootfs
    dd if=$ROOTFS_FILE of=$IMG_FILE bs=1K seek=7680 conv=notrunc
    # offset=24M 写入data.jffs2
    dd if=$OVERLAYFS_FILE of=$IMG_FILE bs=1K seek=24576 conv=notrunc
}

# 检查flash是否存在
function ckeck_flash() {
    local RESULT="$(sudo ./sunxi-fel spiflash-info)"
    test "$RESULT" = "Manufacturer: Winbond (EFh), model: 40h, size: 33554432 bytes."
}

function flash_image() {
    make_image
    echo "镜像制作完成，开始刷写镜像"
    ckeck_flash && sudo ./sunxi-fel -p spiflash-write 0 $IMG_FILE || echo "没有找到Flash"
}

function flash_uboot() {
    echo "开始刷写uboot"
    ckeck_flash && sudo ./sunxi-fel -p spiflash-write 0 $UBOOT_FILE || echo "没有找到Flash"
}

function flash_dtb() {
    echo "开始刷写dtb"
    ckeck_flash && sudo ./sunxi-fel -p spiflash-write 524288 $DTB_FILE || echo "没有找到Flash"
}

function flash_kernel() {
    echo "开始刷写kernel"
    ckeck_flash && sudo ./sunxi-fel -p spiflash-write 557056 $KERNEL_FILE || echo "没有找到Flash"
}

function flash_rootfs() {
    echo "开始刷写rootfs"
    ckeck_flash && sudo ./sunxi-fel -p spiflash-write 7864320 $ROOTFS_FILE || echo "没有找到Flash"
}

function flash_data() {
    echo "开始刷写data"
    ckeck_flash && sudo ./sunxi-fel -p spiflash-write 25165824 $OVERLAYFS_FILE || echo "没有找到Flash"
}

function print_usage() {
    echo "flash image|uboot|dtb|kernel|rootfs|data|all"
}

echo "测试sudo权限"
sudo echo "成功" || echo "无法执行sudo"

for CMD in "$@"; do
    case $CMD in
    "uboot" | "dtb" | "kernel" | "rootfs" | "data") ;;
    "image")
        flash_image
        exit 0
        ;;
    "all")
        flash_uboot
        flash_dtb
        flash_kernel
        flash_rootfs
        flash_data
        exit 0
        ;;
    *)
        print_usage
        exit 1
        ;;
    esac
done

for CMD in "$@"; do
    flash_${CMD}
done
