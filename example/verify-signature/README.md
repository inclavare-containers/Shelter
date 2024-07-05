# verify-signature

该示例程序旨在演示使用shelter运行一个制品签名验证程序的场景。

假设已经安装好shelter及其依赖库、mkosi。在项目根目录下运行以下命令

## 准备制品和制品签名

1. 生成用于签名的RSA公私钥对

    ~~~sh
    ./example/verify-signature/gen-keypair.sh
    ~~~
    密钥将产生在该示例的keys目录下

2. 准备制品并用私钥进行签名

    ~~~sh
    ./example/verify-signature/prepare-payload.sh
    ~~~
    制品和制品签名文件将产生在该示例的payload目录下


3. 为了和之后在shelter中运行作对比，我们可以先在主机环境中直接运行该验证程序

    ~~~sh
    ./example/verify-signature/verifier.sh ./example/verify-signature/keys/public_key.pem ./example/verify-signature/payload/archive.tar.gz.sig ./example/verify-signature/payload/archive.tar.gz
    ~~~

    可以观测到验证成功

## 在shelter运行验证程序

4. 使用准备好的配置文件，构建shelter镜像

    ~~~sh
    ./shelter build -c ./example/verify-signature/build.conf
    ~~~

    将在项目根目录下产生内核`image.vmlinuz`、initrd镜像`image`

5. 在shelter中运行验证程序

    ~~~sh
    ./shelter run verifier.sh /keys/public_key.pem /payload/archive.tar.gz.sig /payload/archive.tar.gz
    ~~~

    可以观测到和在主机环境中运行（步骤3里）一样的程序输出
