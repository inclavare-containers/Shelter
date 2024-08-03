# The Dockerfile for Shelter Makefile

FROM ubuntu:22.04 as builder

# The build arguments with docker build --build-arg NAME=VALUE

# Define the default commit of source code
ARG COMMIT=HEAD
ARG USER_NAME
ARG USER_PASSWORD
# Define the https proxy
ARG HTTPS_PROXY

ENV DEBIAN_FRONTEND=noninteractive
ENV HTTPS_PROXY=${HTTPS_PROXY}

WORKDIR /usr/src

# Install the build dependencies
RUN apt-get update && \
    apt-get install -y git sudo gawk grep python3-socks python3-pip snapd

RUN git clone \
      https://${USER_NAME}:${USER_PASSWORD}@github.com/inclavare-containers/Shelter.git && \
    cd Shelter && git checkout ${COMMIT} && make build && make install


# The Dockerfile for shelter tool

FROM ubuntu:22.04

# Define the source of this Shelter image
LABEL org.opencontainers.image.source="https://github.com/inclavare-containers/Shelter"

# Define the https proxy
ARG HTTPS_PROXY

ENV DEBIAN_FRONTEND=noninteractive
ENV HTTPS_PROXY=${HTTPS_PROXY}

WORKDIR /usr/src

RUN apt-get update && apt-get install -y python3-socks python3-pip git

# Install the runtime dependencies for shelter
RUN apt-get install -y \
      coreutils gawk diffutils rsync libc-bin grep sed systemd socat \
      busybox-static kmod bubblewrap qemu-system-x86

# Install toml-cli
RUN pip install toml-cli

# Install mkosi
RUN git clone https://github.com/systemd/mkosi.git -b v23.1 && \
    ln -s /usr/src/mkosi/bin/mkosi /usr/bin/mkosi

# Install the runtime dependencies for verify-signature demo
RUN apt-get install -y tar openssl

# Install the useful tools
RUN apt-get install -y dracut-core tree

# Install the shelter tool
COPY --from=builder /etc/shelter.d/ /etc/shelter.d/
COPY --from=builder /usr/local/bin/shelter /usr/local/bin/shelter
COPY --from=builder /etc/shelter.conf /etc/shelter.conf

CMD [ "shelter" ]
