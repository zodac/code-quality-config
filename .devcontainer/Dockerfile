FROM debian:13.4-slim
WORKDIR /workspace

# Install development packages
# BEGIN DEBIAN PACKAGES
RUN apt-get update && \
    apt-get install -yqq --no-install-recommends \
        ca-certificates="20250419" \
        curl="8.14.1-2+deb13u2" \
        git="1:2.47.3-0+deb13u1" \
        gnupg="2.4.7-21+deb13u1" \
        iputils-ping="3:20240905-3" \
        jq="1.7.1-6+deb13u1" \
        lsb-release="12.1-1" \
        openssh-client="1:10.0p1-7+deb13u2" \
        python3-dev="3.13.5-1" \
        python-is-python3="3.13.3-1" \
        shfmt="3.8.0-1+b8" \
        vim="2:9.1.1230-2" \
    && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# END DEBIAN PACKAGES

# Install docker
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -yqq --no-install-recommends \
    docker-ce-cli="5:28.1.0-1~debian.13~trixie" \
    && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy bash profile files to the environment
COPY ./.devcontainer/config/.bashrc ./.devcontainer/config/.bash_completion /root/
