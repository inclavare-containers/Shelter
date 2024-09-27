.PHONE: _depend_apsara _install_apsara

_depend_apsara: # Install the build and runtime dependencies on apsara system
	@sudo rpm -ivh RPMs/*.rpm

_install_apsara: # Install the build artifacts for apsara system
	@sudo rpm -ivh RPMs/busybox-1.35.0-3.el8.x86_64.rpm
	@sudo pip3 install Wheels/*.whl
