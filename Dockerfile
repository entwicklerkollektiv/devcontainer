# ARG TARGETARCH
ARG DEVCONTAINER_VERSION

# https://github.com/devcontainers/images
# https://github.com/devcontainers/features/tree/main/src/docker-in-docker
# base image for all devcontainers: https://github.com/docker-library/buildpack-deps

# FROM debian:trixie
FROM ubuntu:24.04
ENV LANG="C.UTF-8"

RUN <<EOT
  set -eux
  export DEBIAN_FRONTEND=noninteractive
  # restore manpages
  yes | unminimize 2>&1
  # install minimal base packages
  apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget \
    dialog gnupg sq apt-utils \
    tzdata locales-all \
    procps netbase apt-utils
  # add additional repos
  install -dm 755 /etc/apt/keyrings
  # -- mise (https://mise.jdx.dev)
  wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list;
  # install dev tooling
  apt-get update && apt-get install -y --no-install-recommends \
    mise \
    build-essential \
    sudo htop less bash-completion \
    bash zsh fish \
    zip mc ncdu tmux \
    git rsync openssh-client \
    ripgrep fzf fd-find jq eza
  # clean up after package installation
  apt-get autoremove -y
  apt-get clean -y
  rm -rf /var/lib/apt/lists/*
EOT

# set up system ------------------------------------------------------------
RUN <<EOT
  set -eux
  update-ca-certificates --fresh --verbose
  # try to remove ubuntu user (if present)
  userdel --force --remove ubuntu || true
  # create user and group
  groupadd devs 
  useradd --create-home --groups devs,sudo --shell /bin/bash user --uid 1000;
  # sudo without password
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sudo_devcontainer
  # keep some env vars after sudo
  echo 'Defaults env_keep += "ftp_proxy http_proxy https_proxy no_proxy "' >> /etc/sudoers.d/sudo_devcontainer
  # append version and build date to /etc/motd
  # echo " V ${DEVCONTAINER_VERSION}, build `date +\"%Y-%m-%dT%H:%M:%S%z\"` " >> /etc/motd
  echo '' >>/etc/motd
  echo 'eval "$(mise activate bash)"' >> /root/.bashrc
EOT

# set up user --------------------------------------------------------------
COPY --chown=user:user /user /home/user/

USER user
WORKDIR /home/user

RUN <<EOT
#!/usr/bin/env /usr/bin/bash
  set -eux
  eval "$(mise activate bash)"
  mise doctor
  # install global packages defined in ~/.config/mise/mise.toml
  mise install --yes
  # re-evaluate mise config
  eval "$(mise activate bash)"
  # bitwarden-cli (via npm so this will also work on arm64)
  npm install --global @bitwarden/cli
  # minimal mise bash setup
  echo 'eval "$(mise activate bash)"' >> /home/user/.bashrc
  echo 'eval "$(starship init bash)"' >> /home/user/.bashrc
EOT

# install other freqently used versions
RUN <<EOT
#!/usr/bin/env /usr/bin/bash
  set -eux
  eval "$(mise activate bash)"
  mise install --yes \
    node@18.16.0 \
    java@zulu-17.42.21 \
    java@zulu-21.36.19
EOT


ENV LANG       de_DE.UTF-8
ENV LANGUAGE   de_DE.UTF-8
ENV LC_ALL     de_DE.UTF-8
ENV TZ Europe/Berlin

CMD ["/usr/bin/bash"]
# CMD [ "sleep", "infinity" ]
