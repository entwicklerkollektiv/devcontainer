FROM debian:stable-slim AS builder
ARG TARGETARCH
RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends ca-certificates ninja-build gettext cmake curl build-essential

RUN \
  curl -sL https://github.com/neovim/neovim/archive/refs/tags/stable.tar.gz | tar -xzC /tmp 2>&1 && \
  echo "Building neovim" && \
  cd /tmp/neovim-stable && \
  make CMAKE_BUILD_TYPE=Release && \
  make CMAKE_INSTALL_PREFIX=/usr/local/nvim install


FROM debian:stable-slim
COPY --from=builder /usr/local/nvim /usr/local/nvim
ENV LANG=en_US.UTF-8

# symlink: ln -s /usr/local/nvim/bin/nvim /usr/local/bin/nvim

CMD ["/usr/bin/bash"]
