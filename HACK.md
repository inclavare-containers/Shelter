# Apsara上遇到的问题

## nesting depth or /proc/sys/user/max_*_namespaces exceeded (ENOSPC)

错误现象为：

```
‣ Including configuration file /etc/shelter.d/mkosi.conf
‣ + stat --file-system --format %T /var/tmp/mkosi-workspace-qjqzqck8
bwrap: Creating new namespace failed: nesting depth or /proc/sys/user/max_*_namespaces exceeded (ENOSPC)
‣ "bwrap --unshare-net --die-with-parent --proc /proc --setenv SYSTEMD_OFFLINE 0 --unsetenv TMPDIR --tmpfs /tmp --unshare-ipc --dev /dev --symlink usr/bin /bin --symlink usr/sbin /sbin --symlink usr/lib /lib --symlink usr/lib64 /lib64 --setenv PATH /scripts:/home/shuguang-176E/.local/bin:/home/shuguang-176E/bin:/usr/ali/bin/:/usr/ali/sbin/:/sbin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/X11R6/bin:/opt/satools --ro-bind /etc/alternatives /etc/alternatives --ro-bind /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /proxy.cacert --ro-bind /usr /usr --bind /var/tmp/mkosi-workspace-qjqzqck8/tmp/mkosi-var-tmp-8becba40d7a34d04 /var/tmp --ro-bind /var/tmp/mkosi-workspace-qjqzqck8 /var/tmp/mkosi-workspace-qjqzqck8 --symlink ../proc/self/mounts /etc/mtab sh -c 'chmod 1777 /dev/shm && chmod 755 /etc && exec $0 "$@"' stat --file-system --format %T /var/tmp/mkosi-workspace-qjqzqck8" returned non-zero exit code 1.
‣ + rm -rf -- /var/tmp/mkosi-workspace-qjqzqck8
```

解决方法：`sysctl -w user.max_user_namespaces=65535`

## PermissionError: [Errno 13] Permission denied: '/var/cache/dnf/metadata_lock.pid'

错误现象为：

```
DNF version: 4.4.2
Command: dnf --assumeyes --best --releasever=3 --installroot=/buildroot --setopt=keepcache=1 --setopt=logdir=/var/log --setopt=cachedir=/var/cache/dnf --setopt=persistdir=/var/lib/dnf --setopt=install_weak_deps=0 --setopt=check_config_file_age=0 --disableplugin=* --enableplugin builddep --enableplugin versionlock --setopt=debuglevel=10 --nodocs --config=/etc/dnf/dnf.conf --setopt=reposdir=/etc/yum.repos.d --setopt=varsdir=/etc/dnf/vars --setopt=proxy_sslcacert=/proxy.cacert makecache
Installroot: /buildroot
Releasever: 3
cachedir: /buildroot/var/cache/dnf
Base command: makecache
Extra commands: ['--assumeyes', '--best', '--releasever=3', '--installroot=/buildroot', '--setopt=keepcache=1', '--setopt=logdir=/var/log', '--setopt=cachedir=/var/cache/dnf', '--setopt=persistdir=/var/lib/dnf', '--setopt=install_weak_deps=0', '--setopt=check_config_file_age=0', '--disableplugin=*', '--enableplugin', 'builddep', '--enableplugin', 'versionlock', '--setopt=debuglevel=10', '--nodocs', '--config=/etc/dnf/dnf.conf', '--setopt=reposdir=/etc/yum.repos.d', '--setopt=varsdir=/etc/dnf/vars','--setopt=proxy_sslcacert=/proxy.cacert', 'makecache']
Making cache files for all metadata files.
os: has expired and will be refreshed.
updates: has expired and will be refreshed.
module: has expired and will be refreshed.
plus: has expired and will be refreshed.
powertools: has expired and will be refreshed.

Traceback (most recent call last):
  File "/usr/lib/python3.6/site-packages/dnf/cli/main.py", line 122, in cli_run
    cli.run()
  File "/usr/lib/python3.6/site-packages/dnf/cli/cli.py", line 1067, in run
    return self.command.run()
  File "/usr/lib/python3.6/site-packages/dnf/cli/commands/makecache.py", line 50, in run
    return self.base.update_cache(timer)
  File "/usr/lib/python3.6/site-packages/dnf/base.py", line 365, in update_cache
    self.fill_sack(load_system_repo=False, load_available_repos=True)  # performs the md sync
  File "/usr/lib/python3.6/site-packages/dnf/base.py", line 376, in fill_sack
    with lock:
  File "/usr/lib/python3.6/site-packages/dnf/lock.py", line 131, in __enter__
    pid = self._try_lock(my_pid)
  File "/usr/lib/python3.6/site-packages/dnf/lock.py", line 81, in _try_lock
    fd = os.open(self.target, os.O_CREAT | os.O_RDWR, 0o644)
PermissionError: [Errno 13] Permission denied: '/var/cache/dnf/metadata_lock.pid'
[Errno 13] Permission denied: '/var/cache/dnf/metadata_lock.pid'
Cleaning up.
‣ "bwrap --die-with-parent --proc /proc --setenv SYSTEMD_OFFLINE 1 --unsetenv TMPDIR --tmpfs /tmp --unshare-ipc --dev /dev --symlink usr/bin /bin --symlink usr/sbin /sbin --symlink usr/lib /lib --symlink usr/lib64 /lib64 --setenv PATH /scripts:/home/shuguang-176E/.local/bin:/home/shuguang-176E/bin:/usr/ali/bin/:/usr/ali/sbin/:/sbin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/X11R6/bin:/opt/satools --uid 0 --gid 0 --cap-add ALL --dir /work/src --chdir /work/src --bind /var/tmp/mkosi-workspace-wfp_kbzo/root /buildroot --bind /var/tmp/mkosi-workspace-wfp_kbzo/pkgmngr/etc /etc --ro-bind /etc/alternatives /etc/alternatives --ro-bind /etc/pki /etc/pki --bind/etc/resolv.conf /etc/resolv.conf --ro-bind /etc/ssl /etc/ssl --ro-bind /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /proxy.cacert --ro-bind /usr /usr --bind '/var/cache/mkosi/alinux~3~x86-64/cache/dnf' /var/cache/dnf --bind '/var/cache/mkosi/alinux~3~x86-64/lib/dnf' /var/lib/dnf --bind /var/tmp/mkosi-workspace-wfp_kbzo/pkgmngr/var/log /var/log --bind /var/tmp/mkosi-workspace-wfp_kbzo/tmp/mkosi-var-tmp-4796d6a3b3904764 /var/tmp --bind /var/tmp/mkosi-workspace-wfp_kbzo/packages /work/packages --bind /etc/shelter.d /work/src sh -c 'chmod 1777 /dev/shm && chmod 755 /etc && exec $0 "$@"' dnf --assumeyes --best --releasever=3 --installroot=/buildroot --setopt=keepcache=1 --setopt=logdir=/var/log --setopt=cachedir=/var/cache/dnf --setopt=persistdir=/var/lib/dnf --setopt=install_weak_deps=0 --setopt=check_config_file_age=0 '--disableplugin=*' --enableplugin builddep --enableplugin versionlock --setopt=debuglevel=10 --nodocs --config=/etc/dnf/dnf.conf --setopt=reposdir=/etc/yum.repos.d --setopt=varsdir=/etc/dnf/vars --setopt=proxy_sslcacert=/proxy.cacert makecache" returned non-zero exit code 1.
```

解决方法：`sudo su -`
