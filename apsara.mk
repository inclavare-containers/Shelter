.PHONE: _depend_apsara _install_apsara

_depend_apsara: # Install the build and runtime dependencies on apsara system
	@if [ ! -d "Shelter-Apsara" ]; then \
	    git clone http://gitlab.alibaba-inc.com/OSSecurity/Shelter-Apsara.git; \
	else \
	    cd Shelter-Apsara && git pull; \
	fi

	@cd Shelter-Apsara && sudo rpm -ivh RPMs/*.rpm

_install_apsara: # Install the build artifacts for apsara system
	@cd Shelter-Apsara && sudo rpm -ivh RPMs/busybox-1.35.0-3.el8.x86_64.rpm
	@sudo pip3 install Wheels/*.whl