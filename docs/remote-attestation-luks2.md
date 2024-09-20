# 通过remote attestation获取luks2的passphrase

# kbs-client参数配置

利用linux kernel的非内核设置参数的kernl cmdline会作为环境变量传给init进程的feature来配置`kbs-client get-resource`的`url`和`path`。

# 示例

上传机密资源
~~~bash
kbs-client config --auth-private-key ~/kbs/private.key set-resource --resource-file /var/lib/shelter/images/default/passphrase --path default/test/passphrase
~~~

qemu示例启动命令:
~~~bash
qemu-system-x86_64 -accel kvm -m 4g -kernel kernel -initrd initrd --device vhost-vsock-pci,guest-cid=21 -drive file=disk,format=raw,if=virtio --device virtio-net-pci,netdev=net0 -netdev user,id=net0 --append "loglevel=9 panic=0  KBS_URL=http://kbs_address:8081 PASSPHRASE_PATH=default/test/passphrase"
~~~

shelter.conf示例文件
~~~toml
image_type = "disk"
vmm = "qemu"

[qemu]
bin = "/usr/libexec/qemu-kvm"
mem = "4G"
cpus = "2"
firmware =""
kern_cmdline = "KBS_URL=http://192.168.10.51:8080 PASSPHRASE_PATH=default/test/passphrase"
opts = ""
~~~

**kbs_address不要填写本地环回地址**

**每次shelter build镜像后都需要重新上传passphrase**