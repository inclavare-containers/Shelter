include vars.mk

PREFIX ?= /usr/local
CONFIG_DIR ?= /etc/shelter.d
CONFIG ?= /etc/shelter.conf

SHELL := /bin/bash

IS_DEBIAN := $(shell \
    if [ -s "/etc/debian_version" ]; then \
        echo true; \
    elif [ -e "/etc/redhat-release" ]; then \
        echo false; \
    else \
        echo unknown; \
    fi)

ifeq ($(IS_DEBIAN), false)
IS_APSARA := $(shell \
    if [ -s "/etc/yum.repos.d/AlinuxApsara.repo" ]; then \
        echo true; \
    else \
        echo false; \
    fi)
else
IS_APSARA := false
endif

ifeq ($(IS_DEBIAN), false)
IS_APSARA := $(shell \
    if [ -s "/etc/yum.repos.d/AlinuxApsara.repo" ]; then \
        echo true; \
    else \
        echo false; \
    fi)
else
IS_APSARA := false
endif

.PHONE: help _depend_redhat _depend_debian _depend prepare build clean install uninstall test all sync container

help:
	@grep -E '^[a-zA-Z][a-zA-Z0-9_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo -e "\033[1;31mPlease read README.md for the details\033[0m"

_depend_redhat: # Install the build and runtime dependencies on redhat-like system
	@install_pkg() { \
	  for p in "$$@"; do \
	    local _p="$$p"; \
	    [[ "$$p" == +* ]] && _p="$${p:1}"; \
	    rpm -qi "$$_p" >/dev/null 2>&1 && continue; \
	    echo "Installing the package \"$$_p\" ..."; \
	    sudo yum install -y "$$_p"; \
	    if [ $$? -ne 0 ]; then \
	      if [ "$_p" != "$p" ]; then \
	        echo "Skip installing the absent package \"$$_p\""; \
	        continue; \
	      fi; \
	      echo "Failed to install the package \"$$_p\""; \
	      exit 1; \
	    fi; \
	  done; \
	}; \
	sudo true && \
	  install_pkg coreutils git sudo gawk grep python3.11 python3-pip \
	    diffutils rsync sed systemd socat podman-docker \
	    +busybox kmod bubblewrap qemu-kvm zstd \
	    tar openssl

	# Work around the python 3.6 lower than the requirement from mkosi
	@sudo ln -sfn `which python3.11` `which python3`

	# Work around mkosi for /usr/lib/os-release. See 1149444ef for the details
	@sudo ln -sfn /etc/os-release /usr/lib/os-release

ifeq ($(IS_APSARA), false)
	@sudo pip3 install toml-cli --proxy=$(HTTPS_PROXY)
endif

_depend_debian: # Install the build and runtime dependencies on debian-like system
	@install_pkg() { \
	  for p in "$$@"; do \
	    local _p="$$p"; \
	    [[ "$$p" == +* ]] && _p="$${p:1}"; \
	    dpkg -l "$$_p" >/dev/null 2>&1 && continue; \
	    echo "Installing the package \"$$_p\" ..."; \
	    sudo apt-get install -y "$$_p"; \
	    if [ $$? -ne 0 ]; then \
	      if [ "$_p" != "$p" ]; then \
	        echo "Skip installing the absent package \"$$_p\""; \
	        continue; \
	      fi; \
	      echo "Failed to install the package \"$$_p\""; \
	      exit 1; \
	    fi; \
	  done; \
	}; \
	sudo apt update && \
	  install_pkg coreutils git sudo gawk grep python3-socks python3-pip snapd \
	  diffutils rsync libc-bin sed systemd socat \
      busybox-static kmod bubblewrap qemu-system-x86 zstd \
      tar openssl

	@sudo pip install toml-cli --proxy=$(HTTPS_PROXY)

	@if ! which docker; then \
	    sudo apt-get install -y docker.io; \
	fi

_depend: # Install the build and runtime dependencies
ifeq ($(IS_DEBIAN), true)
	@$(MAKE) _depend_debian
else ifeq ($(IS_DEBIAN), false)
	@$(MAKE) _depend_redhat
else
	@echo "Unknown Linux distribution"; \
	exit 1
endif

prepare: _depend # Download and configure the necessary components (network access required)

build: # Build the necessary components (network access not required)

clean: # Clean the build artifacts

install: # Install the build artifacts
	@[ ! -d "$(CONFIG_DIR)" ] && { \
	    sudo mkdir -p "$(CONFIG_DIR)"; \
	} || true
	@sudo cp -f 00_logger "$(CONFIG_DIR)"
	@sudo cp -f mkosi.conf mkosi.build mkosi.finalize mkosi.postinst rcS "$(CONFIG_DIR)"
	@sudo cp -a conf "$(CONFIG_DIR)"

	@sudo cp -f shelter "$(PREFIX)/bin"

ifeq ($(IS_DEBIAN), true)
	@sudo cp -f shelter.debian.conf "$(CONFIG)"
else ifeq ($(IS_DEBIAN), false)
	@sudo cp -f shelter.redhat.conf "$(CONFIG)"
else
	@echo "Unknown Linux distribution"; \
	exit 1
endif

	@sudo install -D -d 0755 "$(PREFIX)/libexec/shelter/mkosi" && \
	  sudo cp -r libexec/mkosi/* "$(PREFIX)/libexec/shelter/mkosi" && \
	  sudo ln -sfn "$(PREFIX)/libexec/shelter/mkosi/bin/mkosi" "$(PREFIX)/bin/mkosi"

ifeq ($(IS_APSARA), true)
	@sudo rpm -ivh --force libexec/apsara/busybox-1.35.0-3.el8.x86_64.rpm
	@sudo pip3 install libexec/apsara/*.whl
endif

uninstall: # Uninstall the build artifacts
	@cd "$(PREFIX)/bin" && { \
	  sudo rm -f mkosi shelter; \
	} || true

	@sudo rm -rf "$(CONFIG_DIR)"
	@sudo rm -f "$(CONFIG)"

test: # Run verify-signature demo with shelter
	@./demos/verify-signature/gen-keypair.sh && \
	  ./demos/verify-signature/prepare-payload.sh

	@echo -e "\033[1;31mRunning the DEMO verify-signature at host ...\033[0m"
	@./demos/verify-signature/verifier.sh \
	  ./demos/verify-signature/keys/public_key.pem \
	  ./demos/verify-signature/payload/archive.tar.gz.sig \
	  ./demos/verify-signature/payload/archive.tar.gz

	@echo -e "\033[1;31mRunning the DEMO verify-signature at shelter guest ...\033[0m" 
	@./shelter build -c ./demos/verify-signature/build.conf && \
	  ./shelter run verifier.sh \
	    /keys/public_key.pem \
	    /payload/archive.tar.gz.sig \
	    /payload/archive.tar.gz

all: # Equivalent to make prepare build install
	@make prepare build install

sync: # Sync up this source code
	@git pull --recurse
	@git submodule update --init

container: # Create the Shelter container image
ifeq ($(IS_DEBIAN), true)
	@docker build -f docker/Dockerfile.ubuntu \
	  --build-arg COMMIT=$(COMMIT) \
	  --build-arg USER_NAME=$(USER_NAME) \
	  --build-arg USER_PASSWORD=$(USER_PASSWORD) \
	  --build-arg HTTPS_PROXY=$(HTTPS_PROXY) \
	  --network=host \
	  -t shelter-ubuntu:$$(cat VERSION.env) .
endif

version: # Show the version of Shelter
	@echo -e "\033[1;32mVersion:\033[0m $$(cat VERSION.env)"
	@echo -e "\033[1;32mCommit:\033[0m $$(git log -1 $$(git rev-list -n 1 $$(cat VERSION.env)))"
