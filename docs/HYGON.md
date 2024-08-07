# 支持海光CSV

## 配置和运行shelter

```shell
vi /etc/shelter.conf
```

在`opts`行中进行如下配置：

```shell
opts = "-drive if=pflash,format=raw,unit=0,file=/usr/share/edk2/ovmf/OVMF_CODE.cc.fd,readonly=on -object sev-guest,id=sev0,policy=0x1,cbitpos=47,reduced-phys-bits=5 -machine q35,memory-encryption=sev0"
```

然后运行`shelter run cat /proc/cpuinfo`。示例输出如下：

```
processor       : 0
vendor_id       : HygonGenuine
cpu family      : 24
model           : 2
model name      : Hygon C86 7365 24-core Processor
stepping        : 2
microcode       : 0x80901047
cpu MHz         : 2199.998
cache size      : 512 KB
physical id     : 0
siblings        : 1
core id         : 0
cpu cores       : 1
apicid          : 0
initial apicid  : 0
fpu             : yes
fpu_exception   : yes
cpuid level     : 13
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm rep_good nopl cpuid extd_apicid tsc_known_freq pni pclmulqdq ssse3 fma cx16 sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm cmp_legacy svm cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw perfctr_core cpb ssbd ibpb vmmcall fsgsbase tsc_adjust bmi1 avx2 smep bmi2 rdseed adx smap clflushopt sha_ni xsaveopt xsavec xgetbv1 xsaves clzero xsaveerptr virt_ssbd arat npt nrip_save arch_capabilities
bugs            : sysret_ss_attrs null_seg spectre_v1 spectre_v2 spec_store_bypass retbleed
bogomips        : 4399.99
TLB size        : 1024 4K pages
clflush size    : 64
cache_alignment : 64
address sizes   : 48 bits physical, 48 bits virtual
power management:
```

## 验证

下载和安装HAG工具，并使用该工具查询当前系统上正在运行的CSV guest的个数：

```shell
git clone https://gitee.com/anolis/hygon-devkit.git
sudo cp hygon-devkit/bin/hag /usr/local/sbin
sudo chmod +x /usr/local/sbin/hag
hag csv platform_status
```

假设系统中只有shelter创建的一个CSV guest，且shelter运行过程尚未结束。运行`hag`工具时，guest_count`行将显示为1：

```
api_major:          1
api_minor:          3
platform_state:     CSV_STATE_WORKING
owner:              PLATFORM_STATE_SELF_OWN
chip_secure:        SECURE
fw_enc:             ENCRYPTED
fw_sign:            SIGNED
CSV:                CSV CSV2
build id:           2011
guest_count:        1
is HGSC imported:   YES
supported csv guest:15
platform_status command success!

[csv] Command successful!
```

注意：该行统计的只有CSV guest的个数，不包含非CSV guest的个数。
