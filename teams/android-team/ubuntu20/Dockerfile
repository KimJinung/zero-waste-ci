FROM zero-waste-ci/ubuntu20-base:latest

USER root

# Common scripts (almost never changes)
COPY common/install-packages.sh   /usr/local/bin/install-packages.sh
COPY common/install-toolchains.sh /usr/local/bin/install-toolchains.sh
RUN chmod +x /usr/local/bin/install-packages.sh \
             /usr/local/bin/install-toolchains.sh

# Utility tools (almost never changes)
# repo: AOSP source checkout tool (single binary, not available via apt)
RUN curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo \
        -o /usr/local/bin/repo \
    && chmod +x /usr/local/bin/repo

# Toolchains (occasionally changes)
COPY teams/android-team/ubuntu20/toolchains.txt /tmp/toolchains.txt
RUN install-toolchains.sh /tmp/toolchains.txt

# OS packages (most frequently changes)
COPY teams/android-team/ubuntu20/packages.txt /tmp/packages.txt
RUN install-packages.sh /tmp/packages.txt

# Use login shell so /etc/profile.d/toolchains.sh is sourced in subsequent layers
SHELL ["/bin/bash", "--login", "-c"]

USER builder
