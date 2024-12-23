本DEMO展示了如何用Shelter来运行KBS远程证明服务，并展示了如何通过kbs-client向KBS事先注册资源。

当需要把KBS远程服务与要保护的工作负载部署和运行在同一台主机上的时候，就会用到本DEMO所展示的方式来安全可信地运行KBS远程证明服务。

# 执行步骤

```shell
./shelter-run-kbs.sh
```

# 预期结果

```
[2024-12-19 19:06:58][INFO] Succeed to build the image "kbs"
[2024-12-19 19:06:58][INFO] Using Image ID: kbs
Running as unit: shelter_kbs.service
[2024-12-19T11:07:02Z INFO  kbs] Using config file /kbs/config.toml
[2024-12-19T11:07:02Z WARN  kbs] insecure APIs are enabled
[2024-12-19T11:07:02Z WARN  attestation_service::rvps] No RVPS address provided and will launch a built-in rvps
[2024-12-19T11:07:02Z INFO  attestation_service::token::simple] No Token Signer key in config file, create an ephemeral key and without CA pubkey cert
[2024-12-19T11:07:02Z INFO  kbs] Starting HTTP server at [0.0.0.0:6773]
[2024-12-19T11:07:02Z INFO  actix_server::builder] starting 2 workers
[2024-12-19T11:07:02Z INFO  actix_server::server] Tokio runtime found; starting in existing Tokio runtime
[2024-12-19T11:07:02Z INFO  actix_web::middleware::logger] 10.0.2.2 "POST /kbs/v0/resource/default/shelter/passphrase HTTP/1.1" 200 0 "-" "kbs-client/0.1.0" 0.000222
Set resource success 
 resource: kLbSC6kMBwxpvFtFR4QMVlrD3uLD5CIOmUmqqARLUS/x/5Zm7pKX7qDhtBEQA9Eh8+Drm2ux1jtJpier0/6Cpt58tLLL1zEBAeC9LKFHPoyoVyn6gu2SSjcCFa2WRK28Y/3k/QJgeRyywebJ3dgj02qXgs3O8ZEvfZi+ujl63T4PGYWeM16yuP2sFh0OiMO7MTwe8Bx4Q2LmLX68fB4mBgXuyWGKq5ePn83NWO7IODXqDVxgBUxb9cPpgC4TxZ41Bdy34c1G77uHUSFuplCeoRjq99BXgzgjYbLnvX8qxcuQd8PMgGDLmNqDibAaraEpDCA+bHEKKRRq4SDM3KKTq1tP584mgKmikK1eMcxtVp02JPYkwBvXswYafXULDtIR4gmQLIutpH2CJo0ectlpwK+B3+aAXYbimd+ffQpt4Srj7uld36GnHwqncj+6S7X9PCketIRDw8UED/VnC6N6ocIqwPAQ691BR1p/UrOucUQYBgXusGpkWPV8l1a6k3U24Vukq8ywFpQp7d9XfYwR97VfbW4ut/bAmM6LQHPIdnAsEe/quaSXCCbmIf6TutiUdNjeRhHDJhjP6C3J6OjApjVcTjWP4uDqjg7krbp5mkGnR1Ua7NGsN2XgrA0ZLf3dLiYkNEX9XrCsb157LjPUIhoVpImXpNWE9O5u8yG1NJT8XAlm4V7r5bGzJMDwnrCIvRBzJiPOgojX78MyH4A1IHCTiUEa4D+I7uKeTlLxCEpDhJjq5FOoFH+5cWb7POOX1Tz8feVD/OCjSam1A5OpMNb2aiyQ22Phjcwv9ygV9gOo7aOTFEPUoJZUy3NI+ToDahNPq60mvxwnV4eFrpcDBsmdvFAssBngLxoFOxyGC0i59OprsbWZ6wCYSmH31OwpSUehOjQN+221euQCBd+Q/uAz05ObSa8ymhLY47kltG1SKo1DzU3IkgKjw0eX838uW1L4ckWw3pb14Dq3YYbyHb190mtKIF0GCrgz1MjwQRANqGcOWNgySfCSfFtP4ZGs+3wcB/4ZWP08MZ5mm6Dls6uUSJu87+sJhCbwA5OQlYsLooEU8FnfMCFN8HtEb6SYLM+vjOVzmrrg17rFJO+rc9jzCIYeZ/4puCnEJlJY/DPw1/9XMGxLLZ7dDLd/mx1HuxHUOoeFflSCl/6iEdfafGkmnChfthA5HPkg6ZHxXjhxIUJsS7f8/OSswTUrycKubHW+WMN53zmdiZUoXpQMGej/03XHYwskVgoIvs45weeB3fiHz17yPkRLMlTox4Amig2eHvBXsrxllWC73ceiQcqcNx2xzN17sjuzdhWwNxThS1HDk+y+bq+oET6U4yYPbIVlOzQstyd8bW//bzzwgw==
 ```