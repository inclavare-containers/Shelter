# 通过remote attestation获取LUKS2的passphrase

## 使用步骤

上传解密加密卷的passphrase(密码):

~~~bash
kbs-client \
  config \
   --auth-private-key ~/kbs/private.key \
  set-resource \
   --resource-file /var/lib/shelter/images/$IMAGE_ID/passphrase \
   --path default/$IMAGE_ID/passphrase
~~~

Guest中的init进程通过Guest内核命令行参数来获得访问KBS的URL和passphrase路径信息，因此需要事先配置好shelter.conf:

~~~toml
image_type = "disk"
vmm = "qemu"

[qemu]
bin = "/usr/libexec/qemu-kvm"
mem = "4G"
cpus = "2"
firmware =""
kern_cmdline = "KBS_URL=http://$KBS_ADDRESS:$KBS_PORT PASSPHRASE_PATH=default/$IMAGE_ID/passphrase"
opts = ""
~~~

## 备注

独立通过qemu来运行通过remote attestation获取LUKS2 passphrase的参考命令:

~~~bash
qemu-system-x86_64 \
 -accel kvm -m 4g -kernel kernel -initrd initrd \
 --device vhost-vsock-pci,guest-cid=21 \
 -drive file=disk,format=raw,if=virtio \
 --device virtio-net-pci,netdev=net0 \
 -netdev user,id=net0 --append "loglevel=9 panic=0 \
  KBS_URL=http://$KBS_ADDRESS:$KBS_PORT \
  PASSPHRASE_PATH=$path_to_passphrase"
~~~