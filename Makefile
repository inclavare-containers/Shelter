PREFIX ?= /usr/local
CONFIG_DIR ?= /etc/shelter.d
CONFIG ?= /etc/shelter.conf

include vars.mk

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

ifeq ($(IS_APSARA), true)
include apsara.mk
endif

.PHONE: help _depend_redhat _depend_debian _depend prepare build clean \
    install uninstall test all sync _build_container container FORCE

help:
	@grep -E '^[a-zA-Z][a-zA-Z0-9_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo -e "\033[1;31mPlease read README.md for the details\033[0m"

FORCE:

_depend_redhat: # Install the build and runtime dependencies on redhat-like system
	@install_pkg() { \
	  for p in "$$@"; do \
	    local _p="$$p"; \
	    [[ "$$p" == +* ]] && _p="$${p:1}"; \
	    rpm -q "$$_p" >/dev/null 2>&1 && \
	      yum check-update "$$_p" >/dev/null 2>&1 && continue; \
	    echo "Installing the package \"$$_p\" ..."; \
	    sudo yum install --best -y "$$_p"; \
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
	  install_pkg coreutils git sudo gawk grep +python3.11 python3-pip \
	    python3-pysocks which util-linux cryptsetup curl libseccomp-devel \
	    libcap-ng-devel \
	    diffutils rsync sed systemd socat +podman-docker \
	    +busybox kmod bubblewrap qemu-kvm zstd glib2-devel \
	    tar openssl dhcp-client

ifeq ($(IS_APSARA), true)
	@$(MAKE) _depend_apsara
endif

	# Work around the python 3.6 lower than the requirement from mkosi
	@sudo ln -sfn `which python3.11` `which python3`

	# Work around mkosi for /usr/lib/os-release. See 1149444ef for the details
	@sudo ln -sfn /etc/os-release /usr/lib/os-release

	@if [ ! -x "libexec/redhat/virtiofsd" ]; then \
	    [ ! -d "virtiofsd" ] && \
	        git clone https://gitlab.com/virtio-fs/virtiofsd.git -b v1.11.1; \
	        cd virtiofsd && { \
	            git config user.name "shelter-dev"; \
	            git config user.email "shelter-dev"; \
	            git am ../patches/virtiofsd/virtiofs-Force-VIRTIO_F_IOMMU_PLATFORM-feature-to-su.patch; \
	        }; \
	    [ ! -s "$${HOME}/.cargo/env" ] && \
	        curl https://sh.rustup.rs -sSf | sh; \
	fi

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
	  install_pkg apt-utils coreutils git sudo gawk grep python3-socks \
	    python3-pip util-linux cryptsetup systemd-repart curl \
	    libseccomp-dev libcap-ng-dev \
	    diffutils rsync libc-bin sed systemd socat \
	    busybox-static kmod bubblewrap qemu-system-x86 zstd \
	    tar openssl isc-dhcp-client

	@sudo pip install toml-cli --proxy=$(HTTPS_PROXY)

	@if ! which docker >/dev/null 2>&1; then \
	    sudo apt-get install -y docker.io; \
	fi

	@if [ ! -x "libexec/debian/virtiofsd" ]; then \
	    [ ! -d "virtiofsd" ] && \
	        git clone https://gitlab.com/virtio-fs/virtiofsd.git -b v1.11.1; \
	    [ ! -s "$${HOME}/.cargo/env" ] && \
	        curl https://sh.rustup.rs -sSf | sh; \
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
ifeq ($(IS_DEBIAN), true)
	@if [ ! -x "libexec/debian/virtiofsd" -a -d virtiofsd ]; then \
		! which cargo >/dev/null && source $${HOME}/.cargo/env || true; \
	    cd virtiofsd && cargo build --release && \
	      cp -f target/release/virtiofsd ../libexec/debian; \
	fi
else ifeq ($(IS_DEBIAN), false)
	@if [ ! -x "libexec/redhat/virtiofsd" -a -d virtiofsd ]; then \
		! which cargo >/dev/null && source $${HOME}/.cargo/env || true; \
	    cd virtiofsd && cargo build --release && \
	      cp -f target/release/virtiofsd ../libexec/redhat; \
	fi
endif

clean: # Clean the build artifacts

install: # Install the build artifacts
	@sudo install -D -d 0755 "$(CONFIG_DIR)" && \
	  sudo install -m 0644 00_logger "$(CONFIG_DIR)"; \
	for d in initrd disk; do \
	    dest="$(CONFIG_DIR)/$${d}"; \
	    sudo install -D -d 0755 "$${dest}" && { \
	        sudo install -D -d 0755 "$${dest}/conf" && { \
	            sudo install -m 0755 "images/conf/power" "$${dest}/conf"; \
	            sudo install -m 0644 "images/conf/acpid.conf" "$${dest}/conf"; \
	            sudo install -m 0644 "images/conf/blacklist.conf" "$${dest}/conf"; \
	        }; \
	        cd images/$${d}; \
	        sudo install -m 0644 "mkosi.conf" "$${dest}"; \
	        sudo install -m 0755 \
	            mkosi.build mkosi.finalize mkosi.postinst rcS \
	            "$${dest}"; \
	        cd - >/dev/null; \
	    }; \
	done; \
	dest="$(CONFIG_DIR)/disk/mkosi.repart"; \
	sudo install -D -d 0755 "$${dest}" && { \
	    sudo install -m 0644 "images/disk/mkosi.repart/10-root.conf" \
	      "$${dest}"; \
	}

	@sudo install -D -m 0755 shelter "$(PREFIX)/bin"

ifeq ($(IS_DEBIAN), true)
	@sudo install -m 0755 shelter.debian.conf "$(CONFIG)"
else ifeq ($(IS_DEBIAN), false)
	@sudo install -m 0755 shelter.redhat.conf "$(CONFIG)"
else
	@echo "Unknown Linux distribution"; \
	exit 1
endif

	@sudo install -D -d 0755 "$(PREFIX)/libexec/shelter/mkosi" && \
	  sudo cp -r libexec/mkosi/* "$(PREFIX)/libexec/shelter/mkosi"

	# FIXIME: assume hygon platforms only support redhat-like system
	@if lscpu | grep -q -o 'HygonGenuine'; then \
	    sudo install -m 0755 libexec/hygon/hag /usr/local/sbin/hag; \
	    sudo install -m 0755 shelter.hygon.conf "$(CONFIG)"; \
	fi
ifeq ($(IS_DEBIAN), true)
	@install -m 0755 libexec/debian/virtiofsd "$(PREFIX)/libexec/shelter"
else ifeq ($(IS_DEBIAN), false)
	@install -m 0755 libexec/redhat/virtiofsd "$(PREFIX)/libexec/shelter"
endif

ifeq ($(IS_APSARA), true)
	@$(MAKE) _install_apsara
endif

uninstall: # Uninstall the build artifacts
	@cd "$(PREFIX)/bin" && { \
	  sudo rm -f shelter; \
	} || true

	@sudo rm -rf "$(CONFIG_DIR)"
	@sudo rm -f "$(CONFIG)"

	@sudo rm -f /usr/local/sbin/hag
	@sudo rm -rf "$(PREFIX)/libexec/shelter"

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

	@echo -e "\033[1;31mRunning the DEMO mount at host ...\033[0m"
	@ls -l demos libexec

	@echo -e "\033[1;31mRunning the DEMO mount at shelter guest ...\033[0m"
	@./shelter run -v demos:/root/demos -v libexec:/root/libexec \
	  ls -l /root/demos /root/libexec

all: # Equivalent to make prepare build install
	@make prepare build install

sync: # Sync up this source code
	@git pull --recurse
	@git submodule update --init

_build_container: FORCE # Create the Shelter container image
ifeq ($(IS_DEBIAN), true)
	@docker build -f docker/Dockerfile.ubuntu \
	  --build-arg COMMIT=$(COMMIT) \
	  --build-arg USER_NAME=$(USER_NAME) \
	  --build-arg USER_PASSWORD=$(USER_PASSWORD) \
	  --build-arg HTTPS_PROXY=$(HTTPS_PROXY) \
	  --network=host \
	  -t shelter-ubuntu:$$(cat VERSION.env) .
else
	@docker build -f docker/Dockerfile.alinux \
	  --build-arg COMMIT=$(COMMIT) \
	  --build-arg USER_NAME=$(USER_NAME) \
	  --build-arg USER_PASSWORD=$(USER_PASSWORD) \
	  --build-arg HTTPS_PROXY=$(HTTPS_PROXY) \
	  --network=host \
	  -t shelter-alinux:$$(cat VERSION.env) .
endif

container: _build_container # Run the Shelter container image
ifeq ($(IS_DEBIAN), true)
	@docker run --name shelter-ubuntu-$$(cat VERSION.env) \
	  --rm --privileged -v tmp:/var/tmp -it --network=host \
	  shelter-ubuntu:$$(cat VERSION.env) bash
else
	@docker run --name shelter-alinux-$$(cat VERSION.env) \
	  --rm --privileged -v tmp:/var/tmp -it --network=host \
	  localhost/shelter-alinux:$$(cat VERSION.env) bash
endif

version: # Show the version of Shelter
	@echo -e "\033[1;32mVersion:\033[0m $$(cat VERSION.env)"
	@echo -e "\033[1;32mCommit:\033[0m $$(git log -1 $$(git rev-list -n 1 $$(cat VERSION.env)))"
