# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_deb", "pkg_tar")

pkg_tar(
    name = "pulseaudio-config",
    srcs = [
        "daemon.conf",
        "default.pa",
    ],
    mode = "0644",
    package_dir = "/usr/share/cros-pulse-config",
)

pkg_tar(
    name = "debian-data",
    extension = "tar.gz",
    deps = [
        ":pulseaudio-config",
    ],
)

pkg_deb(
    name = "deb",
    architecture = "all",
    data = ":debian-data",
    depends = ["pulseaudio"],
    description_file = "deb-description",
    homepage = "https://chromium.googlesource.com/chromiumos/docs/+/HEAD/containers_and_vms.md",
    maintainer = "The Chromium OS Authors <chromium-os-dev@chromium.org>",
    package = "cros-pulse-config",
    postinst = "postinst",
    prerm = "prerm",
    section = "misc",
    version = "0.2.0",
    visibility = ["//cros-debs:__pkg__"],
)
