# 小技巧

## 查看QEMU启动日志

```shell
journalctl -f
```

# 解密加密磁盘镜像

```shell
losetup -f --show /var/lib/shelter/images/shelter-demos/disk.raw
partprobe /dev/loop0
echo -n "Test" | cryptsetup open -d - /dev/loop0p1 root
mkdir rootfs
mount /dev/mapper/root rootfs
ls rootfs
```

---

# KBS相关

假设曾经运行过`make test`。

## 启动本地KBS服务

```shell
NAME=local-kbs \
  /usr/local/libexec/shelter/kbs/start-kbs
```

## 注册passphrase

```shell
# 将PASSPHRASE明文进行hex string编码
passphrase_hex="$(echo -ne ${PASSPHRASE} | xxd -p | tr -d "\n")"
# 配置本地KBS服务
PASSPHRASE="${passphrase_hex}" \
  /usr/local/libexec/shelter/kbs/config-kbs >shelter.conf
```

## 通过远程证明过程授权得到passphrase

```shell
shelter run \
  -c shelter.conf \
  shelter-demos -- \
    "/usr/local/libexec/shelter/kbs-client \
      --url http://10.0.2.2:6773 \
      get-resource \
        --path default/shelter/passphrase | base64 -d"
```

## 停止本地KBS服务

```shell
systemctl --user stop local-kbs
```

---

# Shelter KBS相关

假设曾经运行过`demos/shelter-kbs/run-shelter-kbs.sh`。

## 启动Shelter KBS服务

```shell
SHELTER_KBS=1 \
  NAME=shelter-kbs-demo \
  /usr/local/libexec/shelter/kbs/start-kbs
```

## 注册新的passphrase

假设记录下了执行`demos/shelter-kbs/run-shelter-kbs.sh`过程中打印的`Shelter KBS private key: `信息。

```shell
# 将private key的内容保存为文件
echo -ne "${PRIVATE_KEY}" >private_key
# 将要注册的PASSPHRASE明文进行hex string编码
passphrase_hex="$(echo -ne ${PASSPHRASE} | xxd -p | tr -d "\n")"
# 将PASSPHRASE注册到Shelter KBS服务中
PASSPHRASE="${passphrase_hex}" \
  PASSPHRASE_PATH=default/run-shelter-kbs-demo/passphrase \
  PRIVATE_KEY_PATH="${PRIV_KEY}" \
  /usr/local/libexec/shelter/kbs/config-kbs >shelter.conf
```

## 通过远程证明过程授权得到passphrase

假设曾经运行过`make test`。

```shell
KBS_ADDRESS=10.0.2.2 \
  /usr/local/libexec/shelter/kbs/config-kbs >shelter.conf
shelter run \
  -c shelter.conf \
  shelter-demos -- \
    "/usr/local/libexec/shelter/kbs-client \
      --url http://10.0.2.2:6773 \
      get-resource \
        --path default/run-shelter-kbs-demo/passphrase | base64 -d"
```

## 停止Shelter KBS服务

```shell
shelter stop shelter-kbs-demo
```

## 得到IKM（hex string编码）

```shell
shelter run cbmkpasswd -- \
  cbmkpasswd \
    --salt shelter-kbs-salt \
    --iter 1000 \
    -n 256
```

## 得到passphrase明文（hex string编码）

```shell
/usr/local/libexec/shelter/encp-decoder ${ENCP} ${IKM} | \
  xxd -p -r | xxd -p | tr -d "\n"
```