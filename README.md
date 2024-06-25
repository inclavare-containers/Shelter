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

## An example for running shelter on ubuntu 22.04 host

1. 安装依赖
    ~~~sh
    apt update && apt install -y rsync socat busybox-static kmod bubblewrap qemu-system-x86
    ~~~

2. 安装新版mkosi
    ~~~sh
    git clone https://github.com/systemd/mkosi --branch v23.1
    ln -s $PWD/mkosi/bin/mkosi /usr/local/bin/mkosi
    mkosi --version
    ~~~

3. 配置./build.conf文件
    该sh文件中包含了要被拷贝到guest系统的程序/文件。
    - `binary=()`：指定要拷贝的可执行文件列表，程序依赖的动态库也会自动被拷贝到initrd中
    - `file=()`：指定要拷贝的普通文件列表

    默认内容为：
    ~~~
    binary=(/usr/bin/socat /usr/bin/busybox /usr/bin/kmod)
    file=()
    ~~~
    这些文件是目前版本的shelter运行所必需的。
    
    在当前的实现中，用户可以按照以上格式增加新路径以实现将程序/文件拷贝到initrd中。

4. 构建shelter
    ~~~sh
    ./shelter build
    cd shelter
    ~~~

5. 启动shelter
    ~~~sh
    ./shelter start
    ~~~

6. 运行命令
    ~~~sh
    ./shelter exec cat /proc/cpuinfo
    ~~~

7. 停止shelter
    ~~~sh
    ./shelter stop
    ~~~

