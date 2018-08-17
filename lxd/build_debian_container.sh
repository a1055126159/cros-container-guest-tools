#!/bin/bash
# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -ex

LXD="/snap/bin/lxd"
LXC="/snap/bin/lxc"

RELEASE="stretch"
SRC_IMAGE="images:debian/${RELEASE}"

build_container() {
    local arch=$1
    local results_dir=$2
    local setup_script=$3
    local apt_dir=$4

    local base_image="${SRC_IMAGE}/${arch}"
    local tempdir="$(mktemp -d /tmp/lxd-image.XXXXXX)"
    ${LXC} image export "${base_image}" "${tempdir}/image"

    local rootfs="${tempdir}/rootfs"
    unsquashfs -d "${rootfs}" "${tempdir}/image.root"

    if [ "${arch}" = "arm64" ]; then
        cp /usr/bin/qemu-aarch64-static "${rootfs}/usr/bin/"
    fi

    mkdir -p "${rootfs}/opt/google/cros-containers"
    mount --bind /tmp/cros-containers "${rootfs}/opt/google/cros-containers"
    mount --bind /run/resolvconf/resolv.conf "${rootfs}/etc/resolv.conf"
    mount --bind /dev/pts "${rootfs}/dev/pts"
    mount -t proc none "${rootfs}/proc"
    mount -t tmpfs tmpfs "${rootfs}/run"
    mount -t tmpfs tmpfs "${rootfs}/tmp"

    cp "${setup_script}" "${rootfs}/run/"
    mkdir "${rootfs}/run/apt"
    cp -r "${apt_dir}"/* "${rootfs}/run/apt"

    chroot "${rootfs}" /run/"$(basename ${setup_script})"

    umount "${rootfs}/tmp"
    umount "${rootfs}/run"
    umount "${rootfs}/proc"
    umount "${rootfs}/dev/pts"
    umount "${rootfs}/etc/resolv.conf"
    umount "${rootfs}/opt/google/cros-containers"
    rm -rf "${rootfs}/opt/google"
    if [ "${arch}" = "arm64" ]; then
        rm "${rootfs}/usr/bin/qemu-aarch64-static"
    fi

    # Repack into 2 tarballs + squashfs for distribution via simplestreams.
    # Combined sha256 is lxd.tar.xz | rootfs.
    # rootfs.tar.xz is raw rootfs tar'd up.
    # rootfs.squashfs is raw rootfs squash'd.
    # lxd.tar.xz is metadata.yaml and templates dir.
    cp "${tempdir}/image" "${results_dir}/lxd_${RELEASE}_${arch}.tar.xz"
    tar capf "${results_dir}/rootfs_${RELEASE}_${arch}.tar.xz" -C "${rootfs}" .
    mksquashfs "${rootfs}"/* "${results_dir}/rootfs_${RELEASE}_${arch}.squashfs"

    rm -rf "${tempdir}"
}

main() {
    local results_dir=$1
    local setup_script=$2
    local apt_dir=$3

    if [ -z "${results_dir}" -o ! -d "${results_dir}" ]; then
        echo "Results directory '${results_dir}' doesn't exist."
        return 1
    fi

    if [ ! -f "${setup_script}" ]; then
        echo "Setup script '${setup_script}' doesn't exist."
        return 1
    fi

    if [ ! -d "${apt_dir}" ]; then
        echo "Apt repo directory '${apt_dir}' doesn't exist."
        return 1
    fi

    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root to repack rootfs tarballs."
        return 1
    fi

    # Make dummy sommelier paths for update-alternatives.
    local dummy_path="/tmp/cros-containers"
    mkdir -p "${dummy_path}"/{bin,lib}
    touch "${dummy_path}"/bin/sommelier
    touch "${dummy_path}"/lib/swrast_dri.so

    build_container "amd64" "${results_dir}" "${setup_script}" "${apt_dir}"
    build_container "arm64" "${results_dir}" "${setup_script}" "${apt_dir}"
}

main "$@"
