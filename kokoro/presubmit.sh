#!/bin/bash
# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -ex

. "$(dirname "$0")/common.sh" || exit 1

main() {
    require_kokoro_artifacts

    # This is used in other scripts to skip things like apt signing that
    # shouldn't be done to unsubmitted code.
    touch ${KOKORO_ARTIFACTS_DIR}/running_presubmits
}

main "$@"