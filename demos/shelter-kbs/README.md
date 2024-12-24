本DEMO展示了如何用Shelter来运行KBS远程证明服务，并展示了如何通过kbs-client向KBS注册资源，并通过KBS下载资源。

当需要把KBS远程服务与要保护的工作负载部署和运行在同一台主机上的时候，就会用到本DEMO所展示的方式来安全可信地运行KBS远程证明服务。

# 执行步骤

```shell
./run-shelter-kbs.sh
```

# 预期结果

```
[2024-12-24T05:04:10Z INFO  kbs::http::attest] Auth API called.
[2024-12-24T05:04:10Z INFO  actix_web::middleware::logger] 10.0.2.2 "POST /kbs/v0/auth HTTP/1.1" 200 74 "-" "attestation-agent-kbs-client/0.1.0" 0.000107
[2024-12-24T05:04:10Z INFO  kbs::http::attest] Attest API called.
[2024-12-24T05:04:10Z INFO  attestation_service] Sample Verifier/endorsement check passed.
[2024-12-24T05:04:10Z INFO  attestation_service] Policy check passed.
[2024-12-24T05:04:10Z INFO  attestation_service] Attestation Token (Simple) generated.
[2024-12-24T05:04:10Z INFO  actix_web::middleware::logger] 10.0.2.2 "POST /kbs/v0/attest HTTP/1.1" 200 2171 "-" "attestation-agent-kbs-client/0.1.0" 0.002196
[2024-12-24T05:04:10Z INFO  kbs::http::resource] Cookie 80cddda728794f6c808aa58f2741667e request to get resource
[2024-12-24T05:04:10Z INFO  kbs::http::resource] Get resource from kbs:///default/run-shelter-kbs-demo/passphrase
[2024-12-24T05:04:10Z INFO  kbs::http::resource] Resource access request passes policy check.
[2024-12-24T05:04:10Z INFO  actix_web::middleware::logger] 10.0.2.2 "GET /kbs/v0/resource/default/run-shelter-kbs-demo/passphrase HTTP/1.1" 200 529 "-" "attestation-agent-kbs-client/0.1.0" 0.000448
Succeed to retrieve the sample passphrase from shelter-kbs
[2024-12-24 13:04:11][INFO] Using Image ID: shelter-kbs-demo
```