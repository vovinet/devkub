### 1. Gateway API

|               | CDSR | AUTH | SSL |
| ------------- | ---- | ---- | --- |
| HAProxy       |   +  |   +  |  +  |  
| NGinx         |   +  |   +  |  +  |
| Kong          |   +  |   +  |  +  |
| Traefik       |   +  |   -  |  +  |
| Linkerd       |   +  |   -  |  +  |
| Fabio         |   +  |   -  |  +  |
| Vulkand       |   -  |   -  |  -  |
| Neflix Zuul   |   +  |   +  |  +  |

--
CDSR - Маршрутизация запросов к нужному сервису на основе конфигурации
AUTH - Возможность проверки аутентификационной информации в запросах
SSL  - Обеспечение терминации HTTPS

В данном случае я бы выбирал между четырьмя решениями. Далее в расчёт я бы учёл предыдущий опыт команды, которой работать с данным проектом и направленность проекта. Для стриминговых сервисов выбрал бы Zuul, для общего случая HTTPS REST API выбрал бы NGinx, т.к. имею опыт работы с ним.

### 2. Брокеры сообщений

|                   | Кластеризаци | Буфер на диске |  Скорость |     Форматы     |  Права доступа |  Простота эксплуатации |
|:----------------- | ------------ | -------------- | --------- | --------------- | -------------- | ---------------------- |
| RabbitMQ          |       +      |        -       |     ++    |  AMQP 0.х       |        +       |           +            |
| Apache Qpid       |       +      |        -       |           |  AMQP           |                |                        |
| Apache ActiveMQ   |       +      |        +       |     +     |  AMQP, MQTT,    |                |                        |
|                   |              |                |           |  REST,          |                |                        |
|                   |              |                |           |  OpenWire, etc  |                |                        |
| Apache Kafka      |       +      |        +       |     +++   |  Двоичный       |        +       |           +            |

Исходя из технического задания я бы выбрал Apache Kafka

### 3. API Gateway

Чтобы security смог запуститься, убрал ограничение версии flask из requirements.txt (flash 1.1.x не работает с jinja2 после обновления 24.03.22).

```
$ docker-compose up --build
Building uploader
[+] Building 7.0s (11/11) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                                                                                                   0.1s
 => => transferring dockerfile: 37B                                                                                                                                                                                                    0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                      0.0s
 => => transferring context: 34B                                                                                                                                                                                                       0.0s
 => [internal] load metadata for docker.io/library/node:alpine                                                                                                                                                                         6.4s
 => [auth] library/node:pull token for registry-1.docker.io                                                                                                                                                                            0.0s
 => [1/5] FROM docker.io/library/node:alpine@sha256:57106b8c14fdfc6d1ee2b27de320a4d17db55032c4e6e99ff1021d81ef01c328                                                                                                                   0.0s
 => => resolve docker.io/library/node:alpine@sha256:57106b8c14fdfc6d1ee2b27de320a4d17db55032c4e6e99ff1021d81ef01c328                                                                                                                   0.0s
 => [internal] load build context                                                                                                                                                                                                      0.1s
 => => transferring context: 128B                                                                                                                                                                                                      0.0s
 => CACHED [2/5] WORKDIR /app                                                                                                                                                                                                          0.0s
 => CACHED [3/5] COPY package*.json ./                                                                                                                                                                                                 0.0s
 => CACHED [4/5] RUN npm install                                                                                                                                                                                                       0.0s
 => CACHED [5/5] COPY src ./                                                                                                                                                                                                           0.0s
 => exporting to image                                                                                                                                                                                                                 0.1s
 => => exporting layers                                                                                                                                                                                                                0.0s
 => => writing image sha256:38bed5cefa04df39e859b12d63ece117a3e8c246e41fec9681923bdf81524844                                                                                                                                           0.0s
 => => naming to docker.io/library/docker-compose_uploader                                                                                                                                                                             0.0s

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
Building security
[+] Building 5.7s (11/11) FINISHED
 => [internal] load build definition from Dockerfile                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 38B                                                                                                                                                                                                    0.0s
 => [internal] load .dockerignore                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/python:3.9-alpine                                                                                                                                                                   5.3s
 => [auth] library/python:pull token for registry-1.docker.io                                                                                                                                                                          0.0s
 => [1/5] FROM docker.io/library/python:3.9-alpine@sha256:b5938e9fada4908ce04ada3a79de04a486f3375b5ac45f42e2c6c272c19655cd                                                                                                             0.0s
 => => resolve docker.io/library/python:3.9-alpine@sha256:b5938e9fada4908ce04ada3a79de04a486f3375b5ac45f42e2c6c272c19655cd                                                                                                             0.0s
 => [internal] load build context                                                                                                                                                                                                      0.1s
 => => transferring context: 93B                                                                                                                                                                                                       0.0s
 => CACHED [2/5] WORKDIR /app                                                                                                                                                                                                          0.0s
 => CACHED [3/5] COPY requirements.txt .                                                                                                                                                                                               0.0s
 => CACHED [4/5] RUN pip install -r requirements.txt                                                                                                                                                                                   0.0s
 => CACHED [5/5] COPY src ./                                                                                                                                                                                                           0.0s
 => exporting to image                                                                                                                                                                                                                 0.1s
 => => exporting layers                                                                                                                                                                                                                0.0s
 => => writing image sha256:2bfb12ca8a56f41c16bf6bb74368427cb4f84d7e74c930ffe351337159d9eff3                                                                                                                                           0.0s
 => => naming to docker.io/library/docker-compose_security                                                                                                                                                                             0.0s

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
Starting docker-compose_storage_1  ... done
Starting docker-compose_security_1      ... done
Starting docker-compose_createbuckets_1 ... done
Starting docker-compose_uploader_1      ... done
Starting docker-compose_gateway_1       ... done
Attaching to docker-compose_storage_1, docker-compose_security_1, docker-compose_createbuckets_1, docker-compose_uploader_1, docker-compose_gateway_1
createbuckets_1  | Added `storage` successfully.
storage_1        | Finished loading IAM sub-system (took 0.0s of 0.0s to load data).
security_1       |  * Serving Flask app 'server' (lazy loading)
security_1       |  * Environment: production
security_1       |    WARNING: This is a development server. Do not use it in a production deployment.
security_1       |    Use a production WSGI server instead.
security_1       |  * Debug mode: off
createbuckets_1  | Bucket created successfully `storage/data`.
gateway_1        | /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
gateway_1        | /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
storage_1        | API: http://172.20.0.3:9000  http://127.0.0.1:9000
createbuckets_1  | Access permission for `storage/data` is set to `download`
security_1       |  * Running on all addresses (0.0.0.0)
security_1       |    WARNING: This is a development server. Do not use it in a production deployment.
security_1       |  * Running on http://127.0.0.1:3000
security_1       |  * Running on http://172.20.0.2:3000 (Press CTRL+C to quit)
gateway_1        | /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
storage_1        |
storage_1        | Console: http://172.20.0.3:44263 http://127.0.0.1:44263
storage_1        |
storage_1        | Documentation: https://docs.min.io
storage_1        |
storage_1        | WARNING: Console endpoint is listening on a dynamic port (44263), please use --console-address ":PORT" to choose a static port.
uploader_1       | S3: storage:9000 data
gateway_1        | 10-listen-on-ipv6-by-default.sh: info: IPv6 listen already enabled
gateway_1        | /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
gateway_1        | /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
docker-compose_createbuckets_1 exited with code 0
uploader_1       | Listening on port 3000
gateway_1        | /docker-entrypoint.sh: Configuration complete; ready for start up
uploader_1       | (node:1) [DEP0152] DeprecationWarning: Custom PerformanceEntry accessors are deprecated. Please use the detail property.
uploader_1       | (Use `node --trace-deprecation ...` to show where the warning was created)
security_1       | 172.20.0.4 - - [05/Apr/2022 19:42:28] "POST /v1/token HTTP/1.0" 200 -
gateway_1        | 172.20.0.1 - - [05/Apr/2022:19:42:28 +0000] "POST /v1/token HTTP/1.1" 200 99 "-" "curl/7.68.0"
security_1       | 172.20.0.4 - - [05/Apr/2022 19:42:43] "GET /v1/token/validation HTTP/1.0" 200 -
uploader_1       | Detected file type: image/jpeg
uploader_1       | Saved file: 21f2e729-7af7-4607-b6ca-c313b27985ae.jpg
gateway_1        | 172.20.0.1 - - [05/Apr/2022:19:42:43 +0000] "POST /v1/upload HTTP/1.1" 200 80 "-" "curl/7.68.0"
gateway_1        | 172.20.0.1 - - [05/Apr/2022:19:42:57 +0000] "GET /images/a8fc5a9a5-3343-4e93-8d05-699946c8f715.jpg HTTP/1.1" 404 369 "-" "curl/7.68.0"
gateway_1        | 172.20.0.1 - - [05/Apr/2022:19:43:19 +0000] "GET /images/21f2e729-7af7-4607-b6ca-c313b27985ae.jpg HTTP/1.1" 200 73236 "-" "curl/7.68.0"
security_1       | 172.20.0.4 - - [05/Apr/2022 19:43:41] "GET /v1/token/validation HTTP/1.0" 200 -
gateway_1        | 172.20.0.1 - - [05/Apr/2022:19:43:41 +0000] "GET /v1/user/21f2e729-7af7-4607-b6ca-c313b27985ae.jpg HTTP/1.1" 200 73236 "-" "curl/7.68.0"
```

Проверка:
```
$ curl -X POST -H 'Content-Type: application/json' -d '{"login":"bob", "password":"qwe123"}' http://localhost/v1/token
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I

$ curl -X POST -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I' -H 'Content-Type: octet/stream' --data-binary @optimize.jpg http://localhost/v1/upload
{"filename":"21f2e729-7af7-4607-b6ca-c313b27985ae.jpg"}

$ curl localhost/images/21f2e729-7af7-4607-b6ca-c313b27985ae.jpg > 21f2e729-7af7-4607-b6ca-c313b27985ae.jpg
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 73236  100 73236    0     0  7946k      0 --:--:-- --:--:-- --:--:-- 7946k

$ curl -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I' localhost/v1/user/21f2e729-7af7-4607-b6ca-c313b27985ae.jpg > 21f2e729-7af7-4607-b6ca-c313b27985ae.jpg
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 73236  100 73236    0     0  4207k      0 --:--:-- --:--:-- --:--:-- 4207k

```