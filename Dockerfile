# Use the official AvalancheGo image as base
FROM avaplatform/avalanchego:latest

# Set working directory
WORKDIR /avalanchego

# Install dependencies for building subnet-evm
USER root
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    go

# Set Go environment variables
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

# Clone and build subnet-evm plugin
RUN git clone https://github.com/ava-labs/subnet-evm.git /tmp/subnet-evm && \
    cd /tmp/subnet-evm && \
    go mod download && \
    ./scripts/build.sh

# Create plugins directory and copy the built plugin
RUN mkdir -p /avalanchego/plugins && \
    cp /tmp/subnet-evm/subnet-evm /avalanchego/plugins/

# Clean up build dependencies and temporary files
RUN rm -rf /tmp/subnet-evm && \
    apk del git make gcc musl-dev go && \
    rm -rf /go /root/.cache

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
