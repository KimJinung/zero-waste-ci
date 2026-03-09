FROM ubuntu:20.04

ARG BUILD_USER=builder
ARG BUILD_UID=1000
ARG BUILD_GID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core build tools
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    make \
    patch \
    pkg-config \
    unzip \
    wget \
    # Archive utilities
    bzip2 \
    gzip \
    tar \
    xz-utils \
    zstd \
    # Shell & scripting
    bash \
    file \
    locales \
    rsync \
    # Network utilities
    iputils-ping \
    net-tools \
    openssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Create build user (non-root)
RUN groupadd --gid ${BUILD_GID} ${BUILD_USER} \
    && useradd --uid ${BUILD_UID} --gid ${BUILD_GID} \
               --shell /bin/bash \
               --create-home \
               ${BUILD_USER}

USER ${BUILD_USER}
WORKDIR /home/${BUILD_USER}

CMD ["/bin/bash"]