#!/bin/bash

# shellcheck source=container/scripts/common.sh
source "${CONTAINER_BASE}/scripts/common.sh"

{
    # if the user has mounted their workdir in the container, then
    # make sure we are pulling it from the working copy
    if [ -d "${CONTAINER_BASE}/workdir" ]; then
        printf 'Getting things ready for local development...'
        # shellcheck disable=SC2016
        find "${XFCE_WORK_DIR}" -type f -name 'PKGBUILD' \
            -exec printf '\nupdating: {}...' \; \
            -execdir sh -c '
            dest="${CONTAINER_BASE}/workdir/${PWD##*/}"
            if [ ! -d $dest ]; then
                printf "skipped"
            else
                sed -i "s|\$url\.git|file://${dest}|" "$1"
                printf "done"
            fi
        ' _ '{}' \;
        echo
    fi
    # install xfce
    runuser -- "${PACMAN}" -Syu "xfce-test" --needed --noconfirm
} 2>&1 | less -E

# start xfce?
if ((${#@})); then
    exec "${@}"
else
    startxfce4 &
    exec "${SHELL:-/bin/sh}"
fi
