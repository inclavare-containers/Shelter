PREFIX ?= /usr/local
CONFIG_DIR ?= /etc/shelter.d
CONFIG ?= /etc/shelter.conf

SHELL := /bin/bash

.PHONE: help _depend prepare build clean install uninstall test all sync

help:
	@grep -E '^[a-zA-Z][a-zA-Z0-9_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo -e "\033[1;31mPlease read README.md for the details\033[0m"

_depend: # Install the build and runtime dependencies
	@install_pkg() { \
	  for p in "$$@"; do \
	    dpkg -l "$$p" >/dev/null 2>&1 && continue; \
	    echo "Installing the package \"$$p\" ..."; \
	    sudo apt-get install -y "$$p"; \
	    if [ $$? -ne 0 ]; then \
	      echo "Failed to install the package \"$$p\""; \
	      exit $${err}; \
	    fi; \
	    done; \
	}; \
	sudo apt update && \
	  install_pkg "socat" "kmod" "busybox-static" "bubblewrap" "qemu-system-x86" \
	    "git" "sudo" "sed" "gawk" "grep" "rsync" "openssl" "tar" "pipx" "python3-pip"

	@pip install -y toml-cli

	@if ! which mkosi; then \
	    sudo pipx install git+https://github.com/systemd/mkosi.git@v23.1; \
	else \
	    true; \
	fi

prepare: _depend # Download and configure the necessary components (network access required)

build: _depend # Build the necessary components (network access not required)

clean: # Clean the build artifacts

install: # Install the build artifacts
	sudo ln -sfn "$${HOME}/.local/bin/mkosi" "$(PREFIX)/mkosi"

	@[ ! -d "$(CONFIG_DIR)" ] && { \
	    sudo mkdir -p "$(CONFIG_DIR)"; \
	} || true; \
	sudo cp -f 00_logger "$(CONFIG_DIR)"
	sudo cp -f mkosi.conf mkosi.build mkosi.finalize mkosi.postinst rcS "$(CONFIG_DIR)"
	sudo cp -a conf "$(CONFIG_DIR)"

	@sudo cp -f shelter "$(PREFIX)/bin"
	@sudo cp -f shelter.conf "$(CONFIG)"

uninstall: # Uninstall the build artifacts
	@cd "$(PREFIX)/bin" && { \
	  sudo rm -f mkosi shelter; \
	} || true

	@sudo rm -rf "$(CONFIG_DIR)"
	@sudo rm -f "$(CONFIG)"

test: # Run verify-signature demo with shelter
	@./demos/verify-signature/gen-keypair.sh && \
	  ./demos/verify-signature/prepare-payload.sh && \
	  ./shelter build -c ./demos/verify-signature/build.conf && \
	  ./shelter run verifier.sh /keys/public_key.pem \
	    /payload/archive.tar.gz.sig /payload/archive.tar.gz

all: # Equivalent to make prepare build install
	@make prepare build install

sync: # Sync up this source code
	@git pull --recurse
	@git submodule update --init

version: # Show the version of Shelter
	@echo -e "\033[1;32mVersion:\033[0m $$(cat VERSION.env)"
	@echo -e "\033[1;32mCommit:\033[0m $$(git log -1 $$(git rev-list -n 1 $$(cat VERSION.env)))"
