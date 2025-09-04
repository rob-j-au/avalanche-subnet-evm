# Use Debian-based image for package management
ARG ARCH=linux/amd64
FROM --platform=$ARCH debian:bullseye-slim

# Set working directory
WORKDIR /avalanchego

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

# Set default subnet-evm version (can be overridden at build time)
ARG SUBNET_EVM_VERSION=v0.6.8

# Clone and build subnet-evm plugin
RUN git clone https://github.com/ava-labs/subnet-evm.git /tmp/subnet-evm && \
    cd /tmp/subnet-evm && \
    git checkout ${SUBNET_EVM_VERSION} && \
    go mod download && \
    ./scripts/build.sh /tmp/subnet-evm/subnet-evm

# Create plugins directory and copy the built plugin
RUN mkdir -p /avalanchego/plugins && \
    cp /tmp/subnet-evm/subnet-evm /avalanchego/plugins/

# Clean up build dependencies and temporary files
RUN rm -rf /tmp/subnet-evm && \
    apt-get remove -y git make gcc libc6-dev wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /go /root/.cache

# Switch back to avalanche user
USER avalanche

# Expose standard AvalancheGo ports
EXPOSE 9650 9651

# Default command to start AvalancheGo with plugin support
CMD ["/avalanchego/avalanchego", \
     "--plugin-dir=/avalanchego/plugins", \
     "--http-host=0.0.0.0", \
     "--staking-enabled=true", \
     "--network-id=local"]
