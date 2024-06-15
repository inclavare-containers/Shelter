# shelter

Shelter是一个用于CVM Launcher的工具。

## Dependencies

~~~
mkosi rsync kmod socat busybox coreutils
~~~

## Usage

**shelter不需要root权限,也不建议使用root权限运行shelter(防止损坏host)**

~~~
./shelter
---
Usage: shelter {subcommand}
Available SubCommands:
    build   Build the shelter
    start   Start the shelter
    stop    Stop the shelter
    exec    exec a shell commad in shelter
    status  Query the status of shelter
    clean   Remove output image and cache

Options:
    -h, --help  Show this help message and exit
~~~

shelter默认构建的initramfs的发行版版本与host一致，支持的发行版有`debian`，`arch`，`opensuse`，`ubuntu`，`centos`，`rocky`，`alma`，`fedora`，`rhel-ubi`，`mageia`和`openmandriva`。

通过配置[build.conf](./build.conf)文件，可以实现在执行shelter构建时，将指定的文件和二进制文件复制到initramfs中，并且可以自动复制其依赖的.so文件。

## Example

1. 构建initramfs
    ~~~
    ./shelter build
    ~~~

2. 启动shelter
    ~~~
    ./shelter start
    ~~~

3. 运行命令
    ~~~
    ./shelter exec cat /proc/cpuinfo
    ~~~