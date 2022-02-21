# Домашнее задание к занятию "13.2 разделы и монтирование"

Helm и nfs storage provider я установил ещё в рамках развёртывания StatefulSet в прошлом задании. Но утсановлен он у меня был на Control Plane. В данном задании я решил установить его на свой рабочий ПК:

```
$ curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 11156  100 11156    0     0  96172      0 --:--:-- --:--:-- --:--:-- 96172
Downloading https://get.helm.sh/helm-v3.8.0-linux-amd64.tar.gz
Verifying checksum... Done.
Preparing to install helm into /usr/local/bin
helm installed into /usr/local/bin/helm  

$ helm repo add stable https://charts.helm.sh/stable && helm repo update
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /home/kisa/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /home/kisa/.kube/config
"stable" has been added to your repositories
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /home/kisa/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /home/kisa/.kube/config
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
```

На команде добавления компонентов, я, естетственно, получил ошибку, т.к. компонент у меня уже был установлен:
```
$ helm install nfs-server stable/nfs-server-provisioner
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /home/kisa/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /home/kisa/.kube/config
WARNING: This chart is deprecated
Error: INSTALLATION FAILED: rendered manifests contain a resource that already exists. Unable to continue with install: StorageClass "nfs" in namespace "" exists and cannot be imported into the current release: invalid ownership metadata; annotation validation error: key "meta.helm.sh/release-namespace" must equal "my-app-prod": current value is "default"  
  
$ kubectl get sc
NAME         PROVISIONER                                       RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc   rbd.csi.ceph.com                                  Delete          Immediate           true                   9h
nfs          cluster.local/nfs-server-nfs-server-provisioner   Delete          Immediate           true                   4d17h

$ kubectl describe sc nfs
Name:                  nfs
IsDefaultClass:        No
Annotations:           meta.helm.sh/release-name=nfs-server,meta.helm.sh/release-namespace=default
Provisioner:           cluster.local/nfs-server-nfs-server-provisioner
Parameters:            <none>
AllowVolumeExpansion:  True
MountOptions:
  vers=3
ReclaimPolicy:      Delete
VolumeBindingMode:  Immediate
Events:             <none>
```

## Задание 1: подключить для тестового конфига общую папку  

В этом задании речь, как я понял, идёт даже не о PV, а об EmptyFolder, существующих, пока живы контейнеры.

Добработал [манифест](manifests/stage), сменил namespace, применил конфигурацию и смотрю результат:  
```
$ kubectl config set-context --current --namespace=my-app-stage
Context "kubernetes-admin@k8s.int.zubarev.su" modified.  
$ kubectl apply -f manifests/stage/
service/db-stage unchanged
persistentvolume/my-app-stage-dbdata unchanged
statefulset.apps/db-stage configured
service/my-app-stage unchanged
configmap/configset-env unchanged
deployment.apps/my-app configured
$ kubectl get po
NAME                      READY   STATUS        RESTARTS   AGE
db-stage-0                1/1     Running       0          11h
my-app-779556594d-qbmb7   2/2     Running       0          31s
my-app-b44db4689-s4mvl    2/2     Terminating   0          11h
$ kubectl get po
NAME                      READY   STATUS    RESTARTS   AGE
db-stage-0                1/1     Running   0          11h
my-app-779556594d-qbmb7   2/2     Running   0          2m31s

$ kubectl describe po my-app-779556594d-qbmb7
Name:         my-app-779556594d-qbmb7
Namespace:    my-app-stage
Priority:     0
Node:         node3/10.10.10.23
Start Time:   Mon, 21 Feb 2022 09:41:52 +0300
Labels:       app=my-app
              pod-template-hash=779556594d
Annotations:  cni.projectcalico.org/containerID: 98ac58ec08f568411a4d085b8289b5c25c68089783c3146d5f7bb50ef8b7645d
              cni.projectcalico.org/podIP: 10.233.92.21/32
              cni.projectcalico.org/podIPs: 10.233.92.21/32
Status:       Running
IP:           10.233.92.21
IPs:
  IP:           10.233.92.21
Controlled By:  ReplicaSet/my-app-779556594d
Containers:
  frontend:
    Container ID:   containerd://3d36023285acfd7b3cfca38fa48bcff07f343d97da4569215e1647854fbe78be
    Image:          vovinet/13-kubernetes-config_frontend
    Image ID:       docker.io/vovinet/13-kubernetes-config_frontend@sha256:6900c5bfd896b2d2f747fb40dd09b028430f63f2c9b27a8436f31a41203a7636
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Mon, 21 Feb 2022 09:41:53 +0300
    Ready:          True
    Restart Count:  0
    Environment Variables from:
      configset-env  ConfigMap  Optional: false
    Environment:     <none>
    Mounts:
      /static from shared-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-jzkcz (ro)
  backend:
    Container ID:   containerd://e2121f65216922f2edef0dff3db5700f427ec0891b3f820c6a77f3a22e3e67a4
    Image:          vovinet/13-kubernetes-config_backend
    Image ID:       docker.io/vovinet/13-kubernetes-config_backend@sha256:c2a2a7c0f8207f5b36ced83547e1f7c2b290d1112ae0fff49c22eb80e5502be8
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Mon, 21 Feb 2022 09:41:53 +0300
    Ready:          True
    Restart Count:  0
    Environment Variables from:
      configset-env  ConfigMap  Optional: false
    Environment:     <none>
    Mounts:
      /static from shared-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-jzkcz (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  shared-data:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
    SizeLimit:  <unset>
  kube-api-access-jzkcz:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  8m20s  default-scheduler  Successfully assigned my-app-stage/my-app-779556594d-qbmb7 to node3
  Normal  Pulled     8m19s  kubelet            Container image "vovinet/13-kubernetes-config_frontend" already present on machine
  Normal  Created    8m19s  kubelet            Created container frontend
  Normal  Started    8m19s  kubelet            Started container frontend
  Normal  Pulled     8m19s  kubelet            Container image "vovinet/13-kubernetes-config_backend" already present on machine
  Normal  Created    8m19s  kubelet            Created container backend
  Normal  Started    8m19s  kubelet            Started container backend
```

Контейнеры запустились, папка пуста:
```
$ kubectl exec -ti my-app-779556594d-qbmb7 --container backend -- ls /static
$ kubectl exec -ti my-app-779556594d-qbmb7 --container frontend -- ls /static
```

Далее немного прошёлся по граблям, команда echo в файл не сработала, хотя touch файлы успешно создавал:
```
$ kubectl exec -ti my-app-779556594d-qbmb7 --container backend -- touch /static/backend-test.txt
$ kubectl exec -ti my-app-779556594d-qbmb7 --container backend -- "echo test from backend > /static/backend-test.txt"
error: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "0ffc0b805c1deb7225ef97edd8078bdd4f6c214153293feb0db9fbdc40721141": OCI runtime exec failed: exec failed: container_linux.go:380: starting container process caused: exec: "echo test from backend > /static/backend-test.txt": stat echo test from backend > /static/backend-test.txt: no such file or directory: unknown
$ kubectl exec -ti my-app-779556594d-qbmb7 --container frontend -- ls /static
backend-test.txt

```

Изменил команду и всё получилось:
```
$ kubectl exec -ti my-app-779556594d-qbmb7 --container backend -- bash -c "echo test from backend > /static/backend-test.txt"
$ kubectl exec -ti my-app-779556594d-qbmb7 --container frontend -- bash -c "echo test from backend > /static/frontend-test.txt"
$ kubectl exec -ti my-app-779556594d-qbmb7 --container backend -- bash -c "cat /static/frontend-test.txt"
test from backend
$ kubectl exec -ti my-app-779556594d-qbmb7 --container backend -- bash -c "cat /static/backend-test.txt"
test from backend
$ kubectl exec -ti my-app-779556594d-qbmb7 --container frontend -- bash -c "cat /static/backend-test.txt"
test from backend
$ kubectl exec -ti my-app-779556594d-qbmb7 --container frontend -- bash -c "cat /static/frontend-test.txt"
test from backend
```

Теперь найдём где эти файлы хранятся:
```
$ kubectl get po my-app-779556594d-qbmb7 -o yaml | grep nodeName
  nodeName: node3

root@node3:~# find /var/lib/kubelet/ -name shared-data | grep volumes
/var/lib/kubelet/pods/7c105047-45b9-4f13-94e6-a3bd132bd95c/volumes/kubernetes.io~empty-dir/shared-data

root@node3:~# find /var/lib/kubelet/ -name shared-data | grep volumes | xargs ls -la
total 16
drwxrwxrwx 2 root root 4096 фев 21 07:03 .
drwxr-xr-x 3 root root 4096 фев 21 06:41 ..
-rw-r--r-- 1 root root   18 фев 21 07:02 backend-test.txt
-rw-r--r-- 1 root root   18 фев 21 07:03 frontend-test.txt
```

Также возникла проблема, поды висели в статусе ```ContainerCreating```. В describe увидел следующее:
```
Output: mount: /var/lib/kubelet/pods/84b1bfe1-967f-46ec-bb70-4e00023587d0/volumes/kubernetes.io~nfs/pvc-9aa5816d-8c4a-4897-8e59-3a947b9a2435: bad option; for several filesystems (e.g. nfs, cifs) you might need a /sbin/mount.<type> helper program.
  Warning  FailedMount  2m6s  kubelet  Unable to attach or mount volumes: unmounted volumes=[static], unattached volumes=[kube-api-access-hd2qm static]: timed out waiting for the condition
```
Проверка монтирования вручную показала отсутсвие пакета ```nfs-common``` на рабочих нодах. Кроме того, пришлось пересоздать provisioner (на подготовительном этапе я посчитал, что уже созданного будет достаточно, но нет, понадобилось пересоздать его в нашем пространстве имён) Также увеличил число реплик. После установки поды поднялись успешно:
```
$ kubectl get po,pvc,pv -o wide
NAME                                        READY   STATUS    RESTARTS      AGE     IP             NODE    NOMINATED NODE   READINESS GATES
pod/db-prod-0                               1/1     Running   1 (45m ago)   12h     10.233.92.25   node3   <none>           <none>
pod/my-app-backend-prod-767d944b6d-b6rdk    1/1     Running   0             3m49s   10.233.90.14   node1   <none>           <none>
pod/my-app-backend-prod-767d944b6d-xrldz    1/1     Running   0             3m49s   10.233.96.21   node2   <none>           <none>
pod/my-app-frontend-prod-5c499fcf8b-8n2r4   1/1     Running   0             3m49s   10.233.92.27   node3   <none>           <none>
pod/my-app-frontend-prod-5c499fcf8b-n6q86   1/1     Running   0             3m49s   10.233.90.13   node1   <none>           <none>
pod/nfs-server-nfs-server-provisioner-0     1/1     Running   0             4m43s   10.233.90.12   node1   <none>           <none>

NAME                                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE     VOLUMEMODE
persistentvolumeclaim/my-app-db-prod-db-prod-0   Bound    pvc-0889a599-ec6f-44e3-9fbd-df8b5a9c417a   5Gi        RWO            csi-rbd-sc     12h     Filesystem
persistentvolumeclaim/my-app-prod-pvc            Bound    pvc-d2c9750d-9d83-4062-8280-4b54905626fb   100Mi      RWX            nfs            3m49s   Filesystem

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                                  STORAGECLASS        REASON   AGE     VOLUMEMODE
persistentvolume/my-app-stage-dbdata                        1Gi        RWO            Retain           Bound         my-app-stage/db-data-db-stage-0        my-app-stage-stor            16h     Filesystem
persistentvolume/pvc-0889a599-ec6f-44e3-9fbd-df8b5a9c417a   5Gi        RWO            Delete           Bound         my-app-prod/my-app-db-prod-db-prod-0   csi-rbd-sc                   12h     Filesystem
persistentvolume/pvc-d2c9750d-9d83-4062-8280-4b54905626fb   100Mi      RWX            Delete           Bound         my-app-prod/my-app-prod-pvc            nfs                          3m49s   Filesystem
```

Проверяем:
```
$ kubectl exec -ti pod/my-app-backend-prod-767d944b6d-b6rdk -- bash -c "echo some test text > /static/test1.txt"
$ kubectl exec -ti pod/my-app-frontend-prod-5c499fcf8b-n6q86 -- bash -c "cat /static/test1.txt"
some test text
$ kubectl exec -ti pod/my-app-frontend-prod-5c499fcf8b-8n2r4 -- bash -c "echo foo bar >> /static/test1.txt"
$ kubectl exec -ti pod/my-app-backend-prod-767d944b6d-xrldz -- bash -c "cat /static/test1.txt"
some test text
foo bar
```
