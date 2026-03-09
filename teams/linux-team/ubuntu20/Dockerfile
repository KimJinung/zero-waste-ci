FROM zero-waste-ci/ubuntu20-base:latest

USER root

# Common scripts (almost never changes)
COPY common/install-packages.sh   /usr/local/bin/install-packages.sh
COPY common/install-toolchains.sh /usr/local/bin/install-toolchains.sh
RUN chmod +x /usr/local/bin/install-packages.sh \
             /usr/local/bin/install-toolchains.sh

# Utility tools (almost never changes)
# kas: Yocto build environment manager (not available via apt on Ubuntu 20.04)
RUN pip3 install --no-cache-dir kas

# Toolchains (occasionally changes)
COPY teams/linux-team/ubuntu20/toolchains.txt /tmp/toolchains.txt
RUN install-toolchains.sh /tmp/toolchains.txt

# OS packages (most frequently changes)
COPY teams/linux-team/ubuntu20/packages.txt /tmp/packages.txt
RUN install-packages.sh /tmp/packages.txt

# Use login shell so /etc/profile.d/toolchains.sh is sourced in subsequent layers
SHELL ["/bin/bash", "--login", "-c"]

USER builder
