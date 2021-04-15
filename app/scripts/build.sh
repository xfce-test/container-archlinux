#!/bin/bash

# shellcheck source=app/scripts/common-args.sh
source "$(dirname "$(readlink --canonicalize "${BASH_SOURCE[0]}")")/common-args.sh"

docker build \
    --pull \
    --force-rm \
    --build-arg USER_NAME \
    --build-arg USER_SHELL \
    --build-arg DISPLAY \
    --build-arg MAIN_BRANCH \
    --build-arg DOWNLOAD_DATE \
    --build-arg TRAVIS \
    --build-arg PACMAN_HELPER \
    --build-arg PACMAN_HELPER_URL \
    --build-arg CONTAINER_BASE \
    --build-arg CFLAGS \
    --build-arg CPPFLAGS \
    --tag xfce-test/xfce-test:archlinux --file Dockerfile .