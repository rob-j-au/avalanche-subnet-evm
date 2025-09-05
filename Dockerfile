# Build for amd64 (NB. compilation fails on arm64)
ARG ARCH=linux/amd64



FROM --platform=$ARCH debian:bullseye-slim

# Set working directory
WORKDIR /avalanchegos

# Install dependencies for building subnet-evm and running AvalancheGo
USER root
RUN apt-get update && apt-get install -y \
    git \
    make \
    gcc \
    libc6-dev \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.21 (compatible with subnet-evm)
RUN wget https://go.dev/dl/go1.21.12.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.12.linux-amd64.tar.gz && \
    rm go1.21.12.linux-amd64.tar.gz

# Set Go environment variables
ENV GOPATH=/go
ENV PATH=/usr/local/go/bin:$GOPATH/bin:$PATH

# Set default versions (can be overridden at build time)
ARG AVALANCHEGO_VERSION=v1.11.11
ARG SUBNET_EVM_VERSION=v0.6.8
ARG SUBNET_EVM_VM_ID=srEXiWaHuhNyGwPUi444Tu47ZEDwxTWrbQiuD7FmgSAQ6X7Dy

# Install AvalancheGo
RUN wget https://github.com/ava-labs/avalanchego/releases/download/${AVALANCHEGO_VERSION}/avalanchego-linux-amd64-${AVALANCHEGO_VERSION}.tar.gz && \
    tar -xzf avalanchego-linux-amd64-${AVALANCHEGO_VERSION}.tar.gz && \
    mv avalanchego-${AVALANCHEGO_VERSION}/avalanchego /usr/local/bin/ && \
    mkdir -p /avalanchego/plugins && \
    rm -rf avalanchego-linux-amd64-${AVALANCHEGO_VERSION}.tar.gz avalanchego-${AVALANCHEGO_VERSION}

# Clone and build subnet-evm plugin
RUN git clone https://github.com/ava-labs/subnet-evm.git /tmp/subnet-evm && \
    cd /tmp/subnet-evm && \
    git checkout ${SUBNET_EVM_VERSION} && \
    go mod download && \
    ./scripts/build.sh /tmp/subnet-evm/subnet-evm

# Copy the built plugin to plugins directory with proper VM ID name
RUN cd /tmp/subnet-evm && \
    echo "Testing subnet-evm binary..." && \
    ./subnet-evm --version || echo "Version command failed" && \
    VM_ID="${SUBNET_EVM_VM_ID}" && \
    echo "Using VM ID: $VM_ID" && \
    rm -f /avalanchego/plugins/subnet-evm && \
    cp /tmp/subnet-evm/subnet-evm /avalanchego/plugins/$VM_ID && \
    ls -la /avalanchego/plugins/ && \
    echo "Plugin installed as: $VM_ID"

# Clean up build dependencies and temporary files
RUN rm -rf /tmp/subnet-evm && \
    apt-get remove -y git make gcc libc6-dev wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /go /root/.cache

# Create avalanche user and set ownership
RUN useradd -m -s /bin/bash avalanche && \
    chown -R avalanche:avalanche /avalanchego

# Create data directory and set ownership
RUN mkdir /data && chown avalanche:avalanche /data

# Switch to avalanche user
USER avalanche

# Expose standard AvalancheGo ports
EXPOSE 9650 9651

# Default command to start AvalancheGo with plugin support
CMD ["avalanchego"]