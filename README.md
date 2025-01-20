# Shelter

Shelter是一个将应用沙箱化的启动器。

## 平台支持情况

- [海光CSV](docs/HYGON.md)

## 开发者使用步骤

本节介绍在各种主机上编译、安装和运行shelter的步骤。

0. 下载本仓库：
  ```shell
  git clone https://github.com/inclavare-containers/Shelter.git -b 0.1.0
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
    shelter build -t $image_id
    ~~~

    > image_id 用于设置镜像的id， 默认为default， 注意：shelter会覆盖相同id的镜像

5. 查询构建的镜像信息
    ```sh
    shelter images
    ```

6. 直接运行shelter镜像中的指定命令
    ~~~sh
    shelter run $image_id cat /proc/cmdline
    ~~~

    也可以分步执行：
    - 创建shelter实例
      ~~~sh
      shelter $image_id start
      ~~~

    - 在创建的shelter实例中运行镜像中的指定命令
      ~~~sh
      shelter $image_id exec cat /proc/cmdline
      ~~~

    - 停止shelter实例
      ~~~sh
      shelter $image_id stop
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
    build   Build a shelter image
    clean   Remove output image and cache
    images  Show the images built by shelter
    start   Start a shelter instace with specified shelter image
    stop    Stop a shelter instance
    exec    Execute a command in a shelter instance
    run     Run the command with specified shelter image
    status  Query the status of shelter

Options:
    -h, --help  Show this help message and exit
~~~

Shelter默认构建的initramfs的发行版版本与host一致，通过mkosi工具可以支持的发行版有`debian`，`arch`，`opensuse`，`ubuntu`，`centos`，`rocky`，`alma`，`fedora`，`rhel-ubi`，`mageia`和`openmandriva`以及`Aliyun Linux 3`。

通过配置[build.conf](./build.conf)文件，可以实现在执行Shelter构建时将指定的文件和二进制文件复制到initramfs中，并且可以自动复制其依赖的.so文件。

#### build命令

构建一个shelter镜像。

用法：
```shell
shelter build [options]
```

- `-c/--config <path>`: 表示用于构建shelter镜像的配置文件路径。
- `-T/--image-type <disk|initrd>`: 表示待构建的shelter镜像的类型；合法值为initrd和disk。
- `-t/--tag <image_id>`: 表示要构建的shelter镜像的image id；默认值为`default`。
- `-P/--passphrase <path>`: 表示包含了制作加密disk镜像时使用的secret的文件路径。

#### clean命令

清除mkosi构建缓存。

用法：
```shell
shelter clean <image_id>
```

#### images命令

查看当前所有的shelter镜像信息。

用法：
```shell
shelter images
```

#### start命令

启动shelter实例运行指定的shelter镜像。

用法：
```shell
shelter start [options] [image_id] [--] commands
```

- `-v/--volume <src_path>[:<dst_path>]`: 表示要透传到shelter实例中的host文件路径；如果不指定`<dst_path>`，默认值与`<src_path>`相同。
- `-p/--port <port>`: 表示要透传到shelter实例中的host端口号；默认情况下不透传任何host端口到shelter实例中。
- `-c/--config <path>`: 表示shelter的配置文件路径；默认值为`/etc/shelter.conf`。
- `image_id`: 表示要运行的镜像名称；默认值为`default`。
- `commands`: 表示要在shelter实例中执行的命令。

#### stop命令

启动shelter实例。

用法：
```shell
shelter stop [image_id]
```

#### exec命令

执行start指定的命令。

用法：
```shell
shelter exec [image_id]
```

#### run命令

在shelter实例中运行指定的命令。

用法：
```shell
shelter run [options] [image_id] [--] commands
```

具体用法详见start命令。本质上，run命令是start+exec+stop。

#### status命令

检查shelter实例是否处于运行状态。

用法：
```shell
shelter status [image_id]
```

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

下面是一个镜像配置(./shelter.image.conf)的示例:
```
mem = "8G"
cpus = "4"
```
目前只支持`内存`和`cpu`数的定制。

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
shelter run default -v /root/dir0:/mnt/dir0 -v /root/dir1:/mnt/dir1 ls /mnt/dir0 /mnt/dir1
```

### 端口映射

通过指定-p选项可以映射guest上的端口到host上：

```shell 
shelter run default -p 8080:80 -p 8443:443
```
