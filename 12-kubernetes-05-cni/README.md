1. Установка кластера Kubernetes
Установку кластера было решено произвести на локальных мощностях: 1 control-plane и 3 рабочие ноды. Установка производилась с помощью kubespray. На этапе установки возникали различные сложности, но все они были преодолены. Кластер развёрнут, настроена маршрутизация и утилита kubectl для подключения с локальной машины. В качестве CNI установлен плагин Calico.
```
$ kubectl get nodes -o wide
NAME    STATUS   ROLES                  AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
cp1     Ready    control-plane,master   65m   v1.23.1   10.10.10.20   <none>        Ubuntu 20.04.3 LTS   5.4.0-99-generic   containerd://1.5.9
node1   Ready    <none>                 64m   v1.23.1   10.10.10.21   <none>        Ubuntu 20.04.3 LTS   5.4.0-99-generic   containerd://1.5.9
node2   Ready    <none>                 64m   v1.23.1   10.10.10.22   <none>        Ubuntu 20.04.3 LTS   5.4.0-99-generic   containerd://1.5.9
node3   Ready    <none>                 64m   v1.23.1   10.10.10.23   <none>        Ubuntu 20.04.3 LTS   5.4.0-99-generic   containerd://1.5.9
```
В качестве тестового приложения использовал связку из репозитория [aak74/kubernetes-for-beginners](https://github.com/aak74/kubernetes-for-beginners/tree/master/16-networking/20-network-policy/templates)

Развернул поды:
```
$ kubectl get po -o wide
NAME                        READY   STATUS    RESTARTS   AGE   IP            NODE    NOMINATED NODE   READINESS GATES
backend-f785447b9-nfjlb     1/1     Running   0          21m   10.233.90.1   node1   <none>           <none>
cache-b4f65b647-z2vpb       1/1     Running   0          21m   10.233.96.2   node2   <none>           <none>
frontend-8645d9cb9c-64z4k   1/1     Running   0          21m   10.233.92.1   node3   <none>           <none>
```  
Сервисы:
```
$ kubectl get services
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
backend      ClusterIP   10.233.1.57     <none>        80/TCP    21m
cache        ClusterIP   10.233.59.175   <none>        80/TCP    21m
frontend     ClusterIP   10.233.52.36    <none>        80/TCP    21m
kubernetes   ClusterIP   10.233.0.1      <none>        443/TCP   79m


```

Доступ к подам из локальной сети, друг к другу как по IP пода, так и по IP/имени сервиса - без проблем:
```
$ curl 10.233.1.57
Praqma Network MultiTool (with NGINX) - backend-f785447b9-nfjlb - 10.233.90.1
$ curl 10.233.59.175
Praqma Network MultiTool (with NGINX) - cache-b4f65b647-z2vpb - 10.233.96.2
$ curl 10.233.52.36
Praqma Network MultiTool (with NGINX) - frontend-8645d9cb9c-64z4k - 10.233.92.1
```

Т.к. по условиям задачи нет строго указания на конечное состояние, я решил написать политику таким образом, чтобы pod'ы не были доступны друг другу или из сети напрямую, а только через опубликованные сервисы, а доступ к сервисам, в свою очередь был огрничен следующим образом (как будто у нас используется очередь сообщений между frontend и backend, frontend отдаёт данные из cache, а backend готовит запрашиваемые данные и помещает их в cache для отдачи клиентам):
- frontend был доступен без ограничений;
- cache был доступен для frontend и backend
- backend доступен только для frontend


Получившиеся [манифесты](network-policy/) работают так, как и задумано:
```
$ kubectl exec frontend-8645d9cb9c-64z4k -- curl cache
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    76  100    76    0     0  38133      0 --:--:-- --:--:-- --:--:-- 76000
Praqma Network MultiTool (with NGINX) - cache-b4f65b647-z2vpb - 10.233.96.2
$ kubectl exec frontend-8645d9cb9c-64z4k -- curl backend
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    78  100    78    0     0  36329      0 --:--:-- --:--:-- --:--:-- 39000
Praqma Network MultiTool (with NGINX) - backend-f785447b9-nfjlb - 10.233.90.1
$ kubectl exec cache-b4f65b647-z2vpb -- curl frontend
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:12 --:--:--     0^C
$ kubectl exec cache-b4f65b647-z2vpb -- curl backend
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:11 --:--:--     0^C
$ kubectl exec backend-f785447b9-nfjlb -- curl frontend
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:06 --:--:--     0^C
$ kubectl exec backend-f785447b9-nfjlb -- curl cache
Praqma Network MultiTool (with NGINX) - cache-b4f65b647-z2vpb - 10.233.96.2
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    76  100    76    0     0  45130      0 --:--:-- --:--:-- --:--:-- 76000
```

# Задание 2
Установил calicoctl в виде модуля kubectl на локальную машину.

``` 
$ kubectl calico get node --allow-version-mismatch -o wide
NAME    ASN       IPV4             IPV6   
cp1     (64512)   10.10.10.20/24          
node1   (64512)   10.10.10.21/24          
node2   (64512)   10.10.10.22/24          
node3   (64512)   10.10.10.23/24          
  
$ kubectl calico get ipPool --allow-version-mismatch
NAME           CIDR             SELECTOR   
default-pool   10.233.64.0/18   all()      
  
$ kubectl calico get profile --allow-version-mismatch
NAME                                                 
projectcalico-default-allow                          
kns.cni-test                                         
kns.default                                          
kns.kube-node-lease                                  
kns.kube-public                                      
kns.kube-system                                      
ksa.cni-test.default                                 
ksa.default.default                                  
ksa.kube-node-lease.default                          
ksa.kube-public.default                              
ksa.kube-system.attachdetach-controller              
ksa.kube-system.bootstrap-signer                     
ksa.kube-system.calico-kube-controllers              
ksa.kube-system.calico-node                          
ksa.kube-system.certificate-controller               
ksa.kube-system.clusterrole-aggregation-controller   
ksa.kube-system.coredns                              
ksa.kube-system.cronjob-controller                   
ksa.kube-system.daemon-set-controller                
ksa.kube-system.default                              
ksa.kube-system.deployment-controller                
ksa.kube-system.disruption-controller                
ksa.kube-system.dns-autoscaler                       
ksa.kube-system.endpoint-controller                  
ksa.kube-system.endpointslice-controller             
ksa.kube-system.endpointslicemirroring-controller    
ksa.kube-system.ephemeral-volume-controller          
ksa.kube-system.expand-controller                    
ksa.kube-system.generic-garbage-collector            
ksa.kube-system.horizontal-pod-autoscaler            
ksa.kube-system.job-controller                       
ksa.kube-system.kube-proxy                           
ksa.kube-system.namespace-controller                 
ksa.kube-system.node-controller                      
ksa.kube-system.nodelocaldns                         
ksa.kube-system.persistent-volume-binder             
ksa.kube-system.pod-garbage-collector                
ksa.kube-system.pv-protection-controller             
ksa.kube-system.pvc-protection-controller            
ksa.kube-system.replicaset-controller                
ksa.kube-system.replication-controller               
ksa.kube-system.resourcequota-controller             
ksa.kube-system.root-ca-cert-publisher               
ksa.kube-system.service-account-controller           
ksa.kube-system.service-controller                   
ksa.kube-system.statefulset-controller               
ksa.kube-system.token-cleaner                        
ksa.kube-system.ttl-after-finished-controller        
ksa.kube-system.ttl-controller                       


```  

### Использованные дополнительные материалы:

Для визуализации правил также был использован Kubernetes Dashboard:
```
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml  
```   

Создание токена доступа:   
```
$ kubectl apply -f dashboard/access/  
$kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"  
```