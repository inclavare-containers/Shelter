# Run nginx in shelter

该示例程序旨在演示使用shelter运行nginx服务。

假设已经安装好shelter、依赖库以及mkosi。在项目根目录下运行以下命令：

## build shelter image of nginx
    
~~~sh
    ./shelter build -c ./demos/nginx/build.conf -t nginx
~~~

## shelter run
1. 在shelter中运行nginx程序

    ~~~sh
    ./shelter start nginx -p 8081:80
    ~~~
    
    其中 `-p 8081:80` 为设置端口映射，shelter中的80端口映射到主机的8081端口上,从而用户可通过宿主机上的端口访问到nginx服务

2. 查询运行状态
   ~~~sh
   ./shelter status nginx
   ~~~

3. 若正常运行，即可通过宿主机ip和端口访问nginx
   ~~~sh
   curl <宿主机IP>:8081
   ~~~


    
