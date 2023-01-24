# Wrapper for specter

Specter is a GUI for Bitcoin Core optimized to work with hardware wallets. This repository creates the `s9pk` package that is installed to run `specter` on [embassyOS](https://github.com/Start9Labs/embassy-os/).

## Embassy Service Pre-Requisites: 

- [Bitcoin Core](https://github.com/Start9Labs/bitcoind-wrapper)

## Dependencies

The following set of dependencies are required to build this project. You can find detailed steps to setup your environment below, and in the service packaging [documentation](https://github.com/Start9Labs/service-pipeline#development-environment).

- [docker](https://docs.docker.com/get-docker)
- [docker-buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [yq](https://mikefarah.gitbook.io/yq)
- [toml](https://crates.io/crates/toml-cli)
- [embassy-sdk](https://github.com/Start9Labs/embassy-os/tree/master/backend)
- [make](https://www.gnu.org/software/make/)

## Build environment
Prepare your embassyOS build environment. In this example we are using Ubuntu 20.04.

1. Install docker
```
curl -fsSL https://get.docker.com -o- | bash
sudo usermod -aG docker "$USER"
exec sudo su -l $USER
```
2. Set buildx as the default builder
```
docker buildx install
docker buildx create --use
```
3. Enable cross-arch emulated builds in docker
```
docker run --privileged --rm linuxkit/binfmt:v0.8
```
4. Install yq
```
sudo snap install yq
```
5. Install essentials build packages
```
sudo apt-get install -y build-essential openssl libssl-dev libc6-dev clang libclang-dev ca-certificates
```
6. Install Rust
```
curl https://sh.rustup.rs -sSf | sh
# Choose nr 1 (default install)
source $HOME/.cargo/env
```
7. Install toml
```
cargo install toml-cli
```
8. Build and install embassy-sdk
```
cd ~/ && git clone https://github.com/Start9Labs/embassy-os.git
cd embassy-os/backend/
./install-sdk.sh
```

## Cloning

Clone the project locally. Note the submodule link to the original project. 

```
git clone https://github.com/Start9Labs/specter-wrapper.git
cd specter-wrapper
git submodule update --init --recursive
```
## Building

To build the `specter` package, run the following command:

```
make
```

## Installing (on embassyOS)

Run the following commands to determine successful install:
> :information_source: Change embassy-server-name.local to your Embassy address

```
embassy-cli auth login
# Enter your embassy password
embassy-cli --host https://embassy-server-name.local package install specter.s9pk
```

If you already have your `embassy-cli` config file setup with a default `host`, you can install simply by running:

```
make install
```

> **Tip:** You can also install the specter.s9pk using **Sideload Service** under the **Embassy > Settings** section.

### Verify Install

Go to your Embassy Services page, select **Specter**, configure and start the service. Then, verify its interfaces are accessible.

#Done
