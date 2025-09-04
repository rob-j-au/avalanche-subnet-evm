### Usage Examples

Build with default version (v0.6.8)

```
ARCH=amd64 docker build -t avalanche-subnet-evm .
```

Build with specific version (e.g. v0.6.7)

```
docker build -t avalanche-subnet-evm --build-arg SUBNET_EVM_VERSION=v0.6.7 .
```

Build with latest release

```
docker build --build-arg SUBNET_EVM_VERSION=latest -t avalanche-subnet-evm .
```

Run
```
docker run -it --rm --name avalanche-subnet-evm -p 9650:9650 -p 9651:9651 avalanche-subnet-evm
```

