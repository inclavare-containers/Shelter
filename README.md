# Shelter

Shelter是一个轻松方便在VM中运行应用的启动器。

## 开发者使用步骤

本节介绍在各种主机上编译、安装和运行shelter的步骤。

0. 下载本仓库：
  ```shell
  https://github.com/inclavare-containers/Shelter.git -b 0.0.6
  ```
  或更新本仓库至最新版本:
  ```shell
  make sync
  ```

1. 编译和安装
    ~~~sh
    make all
    ~~~

2. 运行测试
    ```shell
    make test
    ```

3. 配置./build.conf文件
    该文件定义了需要被拷贝到guest系统的程序/文件列表。
    - `binary=()`：指定要拷贝的可执行文件列表，程序依赖的动态库也会自动被拷贝到initrd中
    - `file=()`：指定要拷贝的普通文件列表
    具体的配置说明请查看[./build.conf](./build.conf)文件中的注释；可参考verify-signature demo中的[build.conf](demos/verify-signature/build.conf)。

4. 构建shelter镜像
    ~~~sh
    shelter build
    ~~~

5. 直接运行shelter镜像中的指定命令
    ~~~sh
    shelter run cat /proc/cmdline
    ~~~

    也可以分步执行：
    - 创建shelter实例
      ~~~sh
      shelter start
      ~~~

    - 在创建的shelter实例中运行镜像中的指定命令
      ~~~sh
      shelter exec cat /proc/cmdline
      ~~~

    - 停止shelter实例
      ~~~sh
      shelter stop
      ~~~

## 构建和运行Shelter容器镜像

首先需要编辑vars.mk，将个人的github登录名和密码配置到USER_NAME和USER_PASSWORD变量中；必要的话可以将网络代理服务器的地址配置到HTTPS_PROXY变量中。

然后执行以下命令构建并运行Shelter容器镜像：
```shell
make container
```

## Shelter的详细用法

**运行Shelter不需要root权限，也不建议使用root权限运行Shelter(防止损坏host)。**

### 命令行选项

~~~txt
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

Shelter默认构建的initramfs的发行版版本与host一致，支持的发行版有`debian`，`arch`，`opensuse`，`ubuntu`，`centos`，`rocky`，`alma`，`fedora`，`rhel-ubi`，`mageia`和`openmandriva`。

通过配置[build.conf](./build.conf)文件，可以实现在执行Shelter构建时将指定的文件和二进制文件复制到initramfs中，并且可以自动复制其依赖的.so文件。

### 配置Shelter

Shelter的配置文件位于`/etc/shelter.conf`；格式为TOML。

下面是一个示例：
```toml
vmm = "qemu"

[qemu]
bin = "/usr/bin/qemu-system-x86_64"
mem = "4G"
kern_cmdline = ""
```

### 调试

可通过环境变量`LOG_LEVEL`设置Shelter的日志级别，例如`LOG_LEVEL=3`将日志级别设为DEBUG。默认的日志级别为INFO。

目前有效的日志级别和对应的数字如下：

```txt
ERROR=0
WARN=1
INFO=2
DEBUG=3
```
