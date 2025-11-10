FROM debian:13.1
WORKDIR /workspace

# Install development packages
RUN apt-get update && apt-get install -yqq --no-install-recommends \
    curl \
    git \
    iputils-ping \
    jq \
    openssh-client \
    python3-dev \
    python-is-python3 \
    shfmt \
    vim \
    && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*    

# Copy bash profile files to the environment
COPY ./.devcontainer/config/.bashrc ./.devcontainer/config/.bash_completion /root/
