FROM archlinux:latest
LABEL maintainer="noblechuk5[at]web[dot]de"

# only works for ArchLinux
ENV TAG=archlinux
ARG DISPLAY=":1"
ENV DISPLAY="${DISPLAY}"
ARG TRAVIS=false
# default shell for user: bash or zsh
ARG USERSHELL='zsh'
ARG DEFAULT_USER
# pacman helper: pikaur, paru, yay, etc
ARG PACMAN_HELPER='pikaur'
ARG PACMAN_HELPER_URL="https://aur.archlinux.org/${PACMAN_HELPER}.git"
ENV PACMAN="${PACMAN_HELPER}"
# Line used to invalidate all git clones
ARG DOWNLOAD_DATE
ENV DOWNLOAD_DATE="${DOWNLOAD_DATE}"
ARG MAIN_BRANCH='master'
ENV MAIN_BRANCH="${MAIN_BRANCH}"
# useful for affecting compilation
ARG CFLAGS='-O2 -pipe'
ENV CFLAGS="${CFLAGS}"

ENV USER_HOME="/home/${DEFAULT_USER}"

RUN pacman -Syu --noconfirm \
    && pacman -S base-devel git ${USERSHELL} --noconfirm --needed

WORKDIR /container

# Setup the test user
RUN useradd --create-home --no-log-init --shell "/bin/${USERSHELL}" "${DEFAULT_USER}" \
    && install -dm755 /etc/sudoers.d/ \
    && sed 's:\${DEFAULT_USER}:'"${DEFAULT_USER}:g" etc/sudoers.d/20-xfce-test.in > /etc/sudoers.d/20-xfce-test

# for makepkg
ENV PACKAGER="${DEFAULT_USER} <xfce4-dev@xfce.org>"
ENV BUILDDIR=/var/cache/makepkg-build/
RUN install -dm755 --owner="${DEFAULT_USER}" ${BUILDDIR}

# build pacman helper
RUN runuser -u "${DEFAULT_USER}" \
    -- git clone --depth=1 "${PACMAN_HELPER_URL}" /tmp/${PACMAN_HELPER} \
    && cd /tmp/${PACMAN_HELPER} \
    && sudo runuser -u "${DEFAULT_USER}" -- makepkg \
        --install --force --syncdeps --rmdeps --noconfirm --needed

# install more packages required for the next few steps
# RUN runuser -u ${DEFAULT_USER} -- ${PACMAN} -S python-behave gsettings-desktop-schemas --noconfirm --needed
RUN sudo runuser -u ${DEFAULT_USER} -- ${PACMAN} -S aurutils --noconfirm --needed

# needed for LDTP and friends
# RUN /usr/bin/dbus-run-session /usr/bin/gsettings set org.gnome.desktop.interface toolkit-accessibility true

# copy in our scripts
# TODO: Install the PKGBUILD to have it copy these
# COPY --chown=$DEFAULT_USER scripts /scripts
# COPY --chown="${DEFAULT_USER}" xfce/db /usr/local/share/xfce-test

RUN /container/scripts/local_db.sh
RUN install -dm755 --group=${DEFAULT_USER} /git/xfce-test \
    && cp -R /container/xfce/* /git/xfce-test \
    && chgrp -R ${DEFAULT_USER} /git/xfce-test \
    && chmod -R g+ws /git/xfce-test

WORKDIR /git/xfce-test
RUN /container/scripts/install-packages.sh

# Install _all_ languages for testing
# RUN ${PACMAN} -Syu --noconfirm \
#  && ${PACMAN} -S transifex-client xautomation intltool \
#     opencv python-google-api-python-client \
#     python-oauth2client --noconfirm --needed

# RUN /container_scripts/build_time/create_automate_langs.sh

# Group all repos here
# RUN install -dm755 --owner=${DEFAULT_USER} /git

# Rather use my patched version
# TODO: Create an AUR package for ldtp2
# RUN cd git \
#  && git clone -b python3 https://github.com/schuellerf/ldtp2.git \
#  && cd ldtp2 \
#  && sudo pip3 install -e .

# ENV PKG_CONFIG_PATH="${PKG_CONFIG_PATH}${PKG_CONFIG_PATH:+:}/usr/local/lib/pkgconfig"
# RUN env PKG_CONFIG_PATH="$(pkg-config --variable=pc_path pkg-config):${PKG_CONFIG_PATH} \
#         /container_scripts/build_all-${TAG}.sh

# clean the install cache
RUN runuser -u ${DEFAULT_USER} -- ${PACMAN} -Sc --noconfirm

COPY behave /behave_tests

RUN mkdir /data

COPY xfce-test /usr/bin/

RUN chmod a+x /usr/bin/xfce-test && ln -s /usr/bin/xfce-test /xfce-test

COPY --chown=${DEFAULT_USER} .tmuxinator "${USER_HOME}/.tmuxinator"

COPY --chown=${DEFAULT_USER} extra_files/mimeapps.list "${USER_HOME}/.config/"

RUN install -dm755 --owner=${DEFAULT_USER} "${USER_HOME}/Desktop"

RUN ln --symbolic /data "${USER_HOME}/Desktop/data"

RUN ln --symbolic "${USER_HOME}/version_info.txt" "${USER_HOME}"/Desktop

# switch to the test-user
USER "${DEFAULT_USER}"

WORKDIR /data

CMD [ "/container_scripts/entrypoint.sh" ]