#!/bin/bash -e

# shellcheck source=container/scripts/common.sh
source "${CONTAINER_BASE}/scripts/common.sh"

cd "${XFCE_WORK_DIR}"

runuser -- aur build \
    --ignorearch \
    --arg-file "${CONTAINER_BASE}/pkglist.txt" \
    --pkgver --database=custom \
    --margs --syncdeps --noconfirm

# while IFS= read -r pkg; do
#     # build the package
#     pushd "$pkg"
    # runuser -- aur build \
    #     --pkgver --prevent-downgrade \
    #     --margs --syncdeps --noconfirm
#     popd

#     if [ -n "${DEBUG}" ]; then
#         echo -e "\n\npackages in local aur:"
#         aur repo --list
#     fi
#     # install the pkg
#     pacman -S "$pkg" --needed --noconfirm

#     if [ -n "${DEBUG}" ]; then
#         echo -e "\n\npackage installed files:"
#         pacman -Ql "$pkg"
#     fi
# done < /container/pkglist.txt