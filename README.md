# Shelter

Shelter是一个将应用沙箱化的启动器。

## 平台支持情况

- [海光CSV](docs/HYGON.md)

## 开发者使用步骤

本节介绍在各种主机上编译、安装和运行shelter的步骤。

0. 下载本仓库：
  ```shell
  git clone https://github.com/inclavare-containers/Shelter.git -b 0.0.11
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
    shelter build -t <image_id>
    ~~~

    > image_id 用于设置镜像的id， 默认为default， 注意：shelter会覆盖相同id的镜像

5. 查询构建的镜像信息
    ```sh
    shelter images
    ```

6. 直接运行shelter镜像中的指定命令
    ~~~sh
    shelter run <image_id> cat /proc/cmdline
    ~~~

    也可以分步执行：
    - 创建shelter实例
      ~~~sh
      shelter <image_id> start
      ~~~

    - 在创建的shelter实例中运行镜像中的指定命令
      ~~~sh
      shelter <image_id> exec cat /proc/cmdline
      ~~~

    - 停止shelter实例
      ~~~sh
      shelter <image_id> stop
      ~~~
    > image_id 为需要启动的image的id，默认为default 

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
    images  show the images built by shelter

Options:
    -h, --help  Show this help message and exit
~~~

Shelter默认构建的initramfs的发行版版本与host一致，支持的发行版有`debian`，`arch`，`opensuse`，`ubuntu`，`centos`，`rocky`，`alma`，`fedora`，`rhel-ubi`，`mageia`和`openmandriva`。

通过配置[build.conf](./build.conf)文件，可以实现在执行Shelter构建时将指定的文件和二进制文件复制到initramfs中，并且可以自动复制其依赖的.so文件。

### 配置Shelter

Shelter的配置文件分为全局配置和shelter镜像配置，全局配置位于`/etc/shelter.conf`；格式为TOML，shelter镜像配置需要放置在`/var/run/shelter/<image_id>/shelter.conf`， shelter镜像配置不是必须的，若提供了，则会覆盖默认配置中对应的配置 

下面是一个默认配置(./shelter.hygon.conf)的示例：
```toml
image_type = "initrd"
vmm = "qemu"

[qemu]
bin = "/usr/libexec/qemu-kvm"
mem = "4G"
cpus = "2"
kern_cmdline = ""
firmware = "/usr/share/edk2/ovmf/OVMF_CODE.cc"
opts = "-object sev-guest,id=sev0,policy=0x1,cbitpos=47,reduced-phys-bits=5 -machine q35,memory-encryption=sev0"
```

下面是一个镜像配置(./shelter.image.conf)的示例
```
mem = "8G"
cpus = "4"
```
目前只支持`内存`和`cpu`数的定制

### 调试

可通过环境变量`LOG_LEVEL`设置Shelter的日志级别，例如`LOG_LEVEL=3`将日志级别设为DEBUG。默认的日志级别为INFO。

目前有效的日志级别和对应的数字如下：

```txt
ERROR=0
WARN=1
INFO=2
DEBUG=3
```

### 挂载目录

通过指定-v选项可以将host上的目录透传给guest使用：

```shell
shelter run -v /root/dir0:/mnt/dir0 -v /root/dir1:/mnt/dir1 ls /mnt/dir0 /mnt/dir1
```

### 端口映射

通过指定-p选项可以映射guest上的端口到host上：

```shell 
shelter run -p 8080:80 -p 8443:443
```