PREFIX ?= /usr/local
CONFIG_DIR ?= /etc/shelter.d

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
	apt update && \
	  install_pkg "socat" "kmod" "git" "sudo" "rsync" "busybox-static" \
	    "bubblewrap" "qemu-system-x86"

prepare: _depend # Download and configure the necessary components (network access required)
	@[ ! -d "mkosi" ] && { \
	    git clone https://github.com/systemd/mkosi --branch v23.1; \
	} || true

build: _depend # Build the necessary components (network access not required)

clean: # Clean the build artifacts

install: # Install the build artifacts
	@[ -d "mkosi" ] && { \
	    sudo cp -f mkosi/bin/mkosi "$(PREFIX)/bin"; \
	} || true

	@[ ! -d "$(CONFIG_DIR)" ] && { \
	    mkdir -p "$(CONFIG_DIR)"; \
	} || true; \
	cp -f 00_logger "$(CONFIG_DIR)"

	@sudo cp -f shelter "$(PREFIX)/bin"

uninstall: # Uninstall the build artifacts
	@cd "$(PREFIX)/bin" && { \
	  sudo rm -f mkosi shelter logger.sh; \
	} || true

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
