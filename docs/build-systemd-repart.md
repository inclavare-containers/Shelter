# systemd-repart构建文档
## libcryptsetup

`Alibaba Cloud Linux 8`的系统软件源里的libcryptsetup的版本过低，需要自行编译安装

repo url: https://gitlab.com/cryptsetup/cryptsetup

依赖如下：

~~~
git gcc make autoconf automake gettext-devel pkgconfig openssl-devel popt-devel device-mapper-devel libuuid-devel json-c-devel libblkid-devel findutils libtool libssh-devel tar

Optionally: libargon2-devel libpwquality-devel
~~~

编译示例：

~~~
curl -O -L https://www.kernel.org/pub/linux/utils/cryptsetup/v2.7/cryptsetup-2.7.4.tar.xz

tar xvf cryptsetup-2.7.4.tar.xz

cd cryptsetup-2.7.4

./autogen.sh

./configure --prefix=/root/cryptsetup --disable-asciidoc

make 

make install
~~~

## systemd
依赖如下：

~~~
meson git gperf libcap-devel cmake libmount-devel libfdisk-devel
~~~

~~~
pip3 install jinja2
~~~

编译示例：
~~~
export PKG_CONFIG_PATH=/root/cryptsetup/lib/pkgconfig

meson setup --auto-features=disabled -Drepart=enabled -Dlibcryptsetup=enabled -Dfdisk=enabled -Dblkid=enabled -Dc_args="-I/root/cryptsetup/include" build

meson compile -C build

DESTDIR=/root/systemd/ meson install -C build
~~~

**meson install时最好加上`DESTDIR`环境变量，meson setup的`--prefix`选项不会改变systemd配置文件的安装位置，如果不带`DESTDIR`可能会覆盖系统本身的systemd配置文件。**

## 安装
先将前面编译好的产物复制到shelter的二进制文件默认安装目录(`$(PREFIX)/libexec/shelter/systemd`)，并将cryptsetup的动态链接库复制到`$(PREFIX)/libexec/shelter/systemd/lib64/systemd/`，该位置为systemd的默认动态加载库位置(`Library rpath`)。

`mkosi`的`--extra-search-path=`选项指定为systemd-repart的安装目录(`$(PREFIX)/libexec/shelter/systemd/bin`)。

## 加密磁盘检查的相关命令

~~~
losetup -P -f disk.raw

cryptsetup -d passphrase open /dev/loop0p1 root

mount /dev/mapper/root /mnt/

umount /mnt

cryptsetup close root

losetup -D
~~~