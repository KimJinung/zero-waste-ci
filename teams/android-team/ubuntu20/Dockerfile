FROM zero-waste-ci/ubuntu20-base:latest

USER root

COPY common/install-packages.sh   /usr/local/bin/install-packages.sh
COPY common/install-toolchains.sh /usr/local/bin/install-toolchains.sh
RUN chmod +x /usr/local/bin/install-packages.sh \
             /usr/local/bin/install-toolchains.sh

COPY teams/android-team/ubuntu20/packages.txt   /tmp/packages.txt
COPY teams/android-team/ubuntu20/toolchains.txt /tmp/toolchains.txt

RUN install-packages.sh /tmp/packages.txt

# repo: AOSP source checkout tool (single binary, not available via apt)
RUN curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo \
        -o /usr/local/bin/repo \
    && chmod +x /usr/local/bin/repo

RUN install-toolchains.sh /tmp/toolchains.txt

# Use login shell so /etc/profile.d/toolchains.sh is sourced in subsequent layers
SHELL ["/bin/bash", "--login", "-c"]

USER builder
