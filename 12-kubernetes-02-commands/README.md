**1. Задание 1: Запуск пода из образа в деплойменте**  
  
Создадим деплой для hello-node с числом реплик 2  
```
$ kubectl create deployment hello-node --image=k8s.gcr.io/echoserver:1.4 --replicas=2  
deployment.apps/hello-node created  

$ kubectl get pods  
NAME                          READY   STATUS              RESTARTS   AGE  
hello-node-7567d9fdc9-kxnzb   0/1     ContainerCreating   0          8s  
hello-node-7567d9fdc9-vdqrh   0/1     ContainerCreating   0          8s  

$ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
hello-node-7567d9fdc9-kxnzb   1/1     Running   0          2m38s
hello-node-7567d9fdc9-vdqrh   1/1     Running   0          2m38s

```


**2. Создание пользователя в кластере с ограниченными правами.**  

Нам необходимо предоставить доступ к API-серверу пользователю для просмотра лога и конфигурации Pod'ов с дотупом по токену. Для этого нам может подойти Service Account.  

Создадим его:
```
$ kubectl create serviceaccount app-user --namespace app-namespace
serviceaccount/app-user created
```
Импортируем роль, описанную в файле [role.yml](role.yml)
```
$ kubectl apply -f role.yml
role.rbac.authorization.k8s.io/logs-describe-role created
```
Далее импортировуем сопоставление роли пользователю из файла [role_binding.yml](role_binding.yml)
```
$ kubectl apply -f role_binding.yaml 
rolebinding.rbac.authorization.k8s.io/app-user created
```

```
$ eport $TOKEN=$(kubectl -n app-namespace get secret $(kubectl -n app-namespace get sa/app-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}")
$ echo $TOKEN
eyJhbGciOiJSUzI1NiIsImtpZCI6InRLX2I0S3NVbExEUzFmbUlPUDRQN1VveTNReFJpa0laWTF6TzJadWxaTEEifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJhcHAtbmFtZXNwYWNlIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImFwcC11c2VyLXRva2VuLW1xMm52Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFwcC11c2VyIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiNjg5MjFiYTktYTUwOC00ODBhLWE1OWUtYmM2OWQ5YTNkOTUxIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmFwcC1uYW1lc3BhY2U6YXBwLXVzZXIifQ.hfFEHsxujdHTmTbGiNOOKMuVlc92jJ9I7kMdiv6vlOtzm1gWf_kLfPtL5AGkjkClF5r1Bttu-JZh-0JB8mAqAjBTZaXXYaRn3z6mYs2WuChGKiQERCG1xWT-R-UsSgJAeqLjoALDML43ievQ2aX3bWkiI7ZD1IcGaW5OteRjFHlViqgUWfwiEU0uk5O7Oo0OvIP1gghQN0OotmZfY3_F50_Vi9iYDR8sSlGmZX5cKFNjL2i5r3Nsij4YFo1bIsZ4Zd0upG552evSUpT0irRiObdW3r3MRbM2pYlr_GMU6pHeswhsxX8PJ9FG7qevDN5XoxnKLdOTBtr2rZ6i_7eNbQ
```

Пробуем подключаться, используя полученный токен:
```
$ curl -k -v --cacert ca.crt -H "Authorization: Bearer $TOKEN" https://10.10.10.133:8443/api/v1/namespaces/app-namespace/pods
*   Trying 10.10.10.133:8443...
* TCP_NODELAY set
* Connected to 10.10.10.133 (10.10.10.133) port 8443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: ca.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: O=system:masters; CN=minikube
*  start date: Dec 24 12:07:45 2021 GMT
*  expire date: Dec 24 12:07:45 2024 GMT
*  issuer: CN=minikubeCA
*  SSL certificate verify ok.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x55c245876e10)
> GET /api/v1/namespaces/app-namespace/pods HTTP/2
> Host: 10.10.10.133:8443
> user-agent: curl/7.68.0
> accept: */*
> authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6InRLX2I0S3NVbExEUzFmbUlPUDRQN1VveTNReFJpa0laWTF6TzJadWxaTEEifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJhcHAtbmFtZXNwYWNlIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImFwcC11c2VyLXRva2VuLW1xMm52Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFwcC11c2VyIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiNjg5MjFiYTktYTUwOC00ODBhLWE1OWUtYmM2OWQ5YTNkOTUxIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmFwcC1uYW1lc3BhY2U6YXBwLXVzZXIifQ.hfFEHsxujdHTmTbGiNOOKMuVlc92jJ9I7kMdiv6vlOtzm1gWf_kLfPtL5AGkjkClF5r1Bttu-JZh-0JB8mAqAjBTZaXXYaRn3z6mYs2WuChGKiQERCG1xWT-R-UsSgJAeqLjoALDML43ievQ2aX3bWkiI7ZD1IcGaW5OteRjFHlViqgUWfwiEU0uk5O7Oo0OvIP1gghQN0OotmZfY3_F50_Vi9iYDR8sSlGmZX5cKFNjL2i5r3Nsij4YFo1bIsZ4Zd0upG552evSUpT0irRiObdW3r3MRbM2pYlr_GMU6pHeswhsxX8PJ9FG7qevDN5XoxnKLdOTBtr2rZ6i_7eNbQ
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* Connection state changed (MAX_CONCURRENT_STREAMS == 250)!
< HTTP/2 200 
< audit-id: b3c71592-48ff-452d-b03a-05f4799a40f1
< cache-control: no-cache, private
< content-type: application/json
< x-kubernetes-pf-flowschema-uid: ce087f6c-221b-44d7-bfc0-3586b6f8c8ce
< x-kubernetes-pf-prioritylevel-uid: 26d374d2-86d8-485f-86c8-ba026ca75fdb
< date: Sun, 26 Dec 2021 14:59:17 GMT
< 
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "76813"
  },
  "items": [
    {
      "metadata": {
        "name": "hello-node-7567d9fdc9-tzkt9",
        "generateName": "hello-node-7567d9fdc9-",
        "namespace": "app-namespace",
        "uid": "ec5bc2c2-775c-4ac3-9bf9-650c30c82019",
        "resourceVersion": "70638",
        "creationTimestamp": "2021-12-26T12:55:55Z",
        "labels": {
          "app": "hello-node",
          "pod-template-hash": "7567d9fdc9"
        },
        "ownerReferences": [
          {
            "apiVersion": "apps/v1",
            "kind": "ReplicaSet",
            "name": "hello-node-7567d9fdc9",
            "uid": "e806ff3e-33cf-450c-9b79-7e73582ab9bb",
            "controller": true,
            "blockOwnerDeletion": true
          }
        ],
        "managedFields": [
          {
            "manager": "kube-controller-manager",
            "operation": "Update",
            "apiVersion": "v1",
            "time": "2021-12-26T12:55:55Z",
            "fieldsType": "FieldsV1",
            "fieldsV1": {"f:metadata":{"f:generateName":{},"f:labels":{".":{},"f:app":{},"f:pod-template-hash":{}},"f:ownerReferences":{".":{},"k:{\"uid\":\"e806ff3e-33cf-450c-9b79-7e73582ab9bb\"}":{}}},"f:spec":{"f:containers":{"k:{\"name\":\"echoserver\"}":{".":{},"f:image":{},"f:imagePullPolicy":{},"f:name":{},"f:resources":{},"f:terminationMessagePath":{},"f:terminationMessagePolicy":{}}},"f:dnsPolicy":{},"f:enableServiceLinks":{},"f:restartPolicy":{},"f:schedulerName":{},"f:securityContext":{},"f:terminationGracePeriodSeconds":{}}}
          },
          {
            "manager": "kubelet",
            "operation": "Update",
            "apiVersion": "v1",
            "time": "2021-12-26T12:56:03Z",
            "fieldsType": "FieldsV1",
            "fieldsV1": {"f:status":{"f:conditions":{"k:{\"type\":\"ContainersReady\"}":{".":{},"f:lastProbeTime":{},"f:lastTransitionTime":{},"f:status":{},"f:type":{}},"k:{\"type\":\"Initialized\"}":{".":{},"f:lastProbeTime":{},"f:lastTransitionTime":{},"f:status":{},"f:type":{}},"k:{\"type\":\"Ready\"}":{".":{},"f:lastProbeTime":{},"f:lastTransitionTime":{},"f:status":{},"f:type":{}}},"f:containerStatuses":{},"f:hostIP":{},"f:phase":{},"f:podIP":{},"f:podIPs":{".":{},"k:{\"ip\":\"172.17.0.9\"}":{".":{},"f:ip":{}}},"f:startTime":{}}},
            "subresource": "status"
          }
        ]
      },
      "spec": {
        "volumes": [
          {
            "name": "kube-api-access-5kmbp",
            "projected": {
              "sources": [
                {
                  "serviceAccountToken": {
                    "expirationSeconds": 3607,
                    "path": "token"
                  }
                },
                {
                  "configMap": {
                    "name": "kube-root-ca.crt",
                    "items": [
                      {
                        "key": "ca.crt",
                        "path": "ca.crt"
                      }
                    ]
                  }
                },
                {
                  "downwardAPI": {
                    "items": [
                      {
                        "path": "namespace",
                        "fieldRef": {
                          "apiVersion": "v1",
                          "fieldPath": "metadata.namespace"
                        }
                      }
                    ]
                  }
                }
              ],
              "defaultMode": 420
            }
          }
        ],
        "containers": [
          {
            "name": "echoserver",
            "image": "k8s.gcr.io/echoserver:1.4",
            "resources": {
              
            },
            "volumeMounts": [
              {
                "name": "kube-api-access-5kmbp",
                "readOnly": true,
                "mountPath": "/var/run/secrets/kubernetes.io/serviceaccount"
              }
            ],
            "terminationMessagePath": "/dev/termination-log",
            "terminationMessagePolicy": "File",
            "imagePullPolicy": "IfNotPresent"
          }
        ],
        "restartPolicy": "Always",
        "terminationGracePeriodSeconds": 30,
        "dnsPolicy": "ClusterFirst",
        "serviceAccountName": "default",
        "serviceAccount": "default",
        "nodeName": "worker1",
        "securityContext": {
          
        },
        "schedulerName": "default-scheduler",
        "tolerations": [
          {
            "key": "node.kubernetes.io/not-ready",
            "operator": "Exists",
            "effect": "NoExecute",
            "tolerationSeconds": 300
          },
          {
            "key": "node.kubernetes.io/unreachable",
            "operator": "Exists",
            "effect": "NoExecute",
            "tolerationSeconds": 300
          }
        ],
        "priority": 0,
        "enableServiceLinks": true,
        "preemptionPolicy": "PreemptLowerPriority"
      },
      "status": {
        "phase": "Running",
        "conditions": [
          {
            "type": "Initialized",
            "status": "True",
            "lastProbeTime": null,
            "lastTransitionTime": "2021-12-26T12:55:56Z"
          },
          {
            "type": "Ready",
            "status": "True",
            "lastProbeTime": null,
            "lastTransitionTime": "2021-12-26T12:56:03Z"
          },
          {
            "type": "ContainersReady",
            "status": "True",
            "lastProbeTime": null,
            "lastTransitionTime": "2021-12-26T12:56:03Z"
          },
          {
            "type": "PodScheduled",
            "status": "True",
            "lastProbeTime": null,
            "lastTransitionTime": "2021-12-26T12:55:55Z"
          }
        ],
        "hostIP": "10.10.10.133",
        "podIP": "172.17.0.9",
        "podIPs": [
          {
            "ip": "172.17.0.9"
          }
        ],
        "startTime": "2021-12-26T12:55:56Z",
        "containerStatuses": [
          {
            "name": "echoserver",
            "state": {
              "running": {
                "startedAt": "2021-12-26T12:56:02Z"
              }
            },
            "lastState": {
              
            },
            "ready": true,
            "restartCount": 0,
            "image": "k8s.gcr.io/echoserver:1.4",
            "imageID": "docker-pullable://k8s.gcr.io/echoserver@sha256:5d99aa1120524c801bc8c1a7077e8f5ec122ba16b6dda1a5d3826057f67b9bcb",
            "containerID": "docker://ff88debb794afcf25fc727b1180ae689968bb4b616489a3459be44a5a2c488b4",
            "started": true
          }
        ],
        "qosClass": "BestEffort"
      }
    }
  ]
* Connection #0 to host 10.10.10.133 left intact
```

Лог же в нашем случае оказался пуст:
```
$ curl -k -v --cacert ca.crt -H "Authorization: Bearer $TOKEN" https://10.10.10.133:8443/api/v1/namespaces/app-namespace/pods/hello-node-7567d9fdc9-tzkt9/log
*   Trying 10.10.10.133:8443...
* TCP_NODELAY set
* Connected to 10.10.10.133 (10.10.10.133) port 8443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: ca.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: O=system:masters; CN=minikube
*  start date: Dec 24 12:07:45 2021 GMT
*  expire date: Dec 24 12:07:45 2024 GMT
*  issuer: CN=minikubeCA
*  SSL certificate verify ok.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x55f20103be10)
> GET /api/v1/namespaces/app-namespace/pods/hello-node-7567d9fdc9-tzkt9/log HTTP/2
> Host: 10.10.10.133:8443
> user-agent: curl/7.68.0
> accept: */*
> authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6InRLX2I0S3NVbExEUzFmbUlPUDRQN1VveTNReFJpa0laWTF6TzJadWxaTEEifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJhcHAtbmFtZXNwYWNlIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImFwcC11c2VyLXRva2VuLW1xMm52Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFwcC11c2VyIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiNjg5MjFiYTktYTUwOC00ODBhLWE1OWUtYmM2OWQ5YTNkOTUxIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmFwcC1uYW1lc3BhY2U6YXBwLXVzZXIifQ.hfFEHsxujdHTmTbGiNOOKMuVlc92jJ9I7kMdiv6vlOtzm1gWf_kLfPtL5AGkjkClF5r1Bttu-JZh-0JB8mAqAjBTZaXXYaRn3z6mYs2WuChGKiQERCG1xWT-R-UsSgJAeqLjoALDML43ievQ2aX3bWkiI7ZD1IcGaW5OteRjFHlViqgUWfwiEU0uk5O7Oo0OvIP1gghQN0OotmZfY3_F50_Vi9iYDR8sSlGmZX5cKFNjL2i5r3Nsij4YFo1bIsZ4Zd0upG552evSUpT0irRiObdW3r3MRbM2pYlr_GMU6pHeswhsxX8PJ9FG7qevDN5XoxnKLdOTBtr2rZ6i_7eNbQ
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* Connection state changed (MAX_CONCURRENT_STREAMS == 250)!
< HTTP/2 200 
< audit-id: f4bcae66-4da0-4c3d-9162-df57134b98ee
< cache-control: no-cache, private
< content-type: text/plain
< date: Sun, 26 Dec 2021 15:00:58 GMT
< 
* Connection #0 to host 10.10.10.133 left intact
```

3. Масштабируем наше приложение  
  
Имеем 2 реплики нашего приложения
```
$ kubectl get deployment hello-minikube  
NAME             READY   UP-TO-DATE   AVAILABLE   AGE  
hello-minikube   1/2     2            1           6h23m  

$ kubectl get pods  
NAME                              READY   STATUS    RESTARTS        AGE  
hello-minikube-5d9b964bfb-hr6m7   1/1     Running   1 (4h52m ago)   6h23m  
hello-minikube-5d9b964bfb-kld6s   1/1     Running   0               11s  
```

Увеличиваем число реплик до 5
```
$ kubectl scale --replicas=5 deployment/hello-minikube  
deployment.apps/hello-minikube scaled  
```

Видим, что контейнеры начали создаваться

```
$ kubectl get pods
NAME                              READY   STATUS              RESTARTS        AGE  
hello-minikube-5d9b964bfb-8nnh4   0/1     ContainerCreating   0               3s  
hello-minikube-5d9b964bfb-c52zc   0/1     ContainerCreating   0               3s  
hello-minikube-5d9b964bfb-hr6m7   1/1     Running             1 (4h58m ago)   6h29m  
hello-minikube-5d9b964bfb-kld6s   1/1     Running             0               5m39s  
hello-minikube-5d9b964bfb-psrvx   0/1     ContainerCreating   0               3s  
```
И спустя минуту приходит к такому виду:
```
$ kubectl get pods
NAME                              READY   STATUS    RESTARTS        AGE  
hello-minikube-5d9b964bfb-8nnh4   1/1     Running   0               64s  
hello-minikube-5d9b964bfb-c52zc   1/1     Running   0               64s  
hello-minikube-5d9b964bfb-hr6m7   1/1     Running   1 (4h59m ago)   6h30m  
hello-minikube-5d9b964bfb-kld6s   1/1     Running   0               6m40s  
hello-minikube-5d9b964bfb-psrvx   1/1     Running   0               64s  
```