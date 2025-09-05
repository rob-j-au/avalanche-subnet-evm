### Avalanche with subnet-evm plugin

Build with default version (v0.6.8)

```
docker buildx build --platform=linux/amd64 --load -t avalanche-subnet-evm . 
docker push robjau/avalanche-subnet-evm
```

Build with specific version (e.g. v0.6.7)

```
docker buildx build --platform=linux/amd64 --load -t robjau/avalanche-subnet-evm:v0.6.7 --build-arg SUBNET_EVM_VERSION=v0.6.7 .
docker push robjau/avalanche-subnet-evm:v0.6.7
```

