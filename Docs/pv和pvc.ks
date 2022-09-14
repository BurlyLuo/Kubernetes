kubernetes存储[pv和pvc]
1.手工指定的pv供pvc使用。[静态pv]
1.1在nfs server上创建5个目录。
[root@localhost volumes]# mkdir v{1,2,3,4,5}
[root@localhost volumes]# ll
total 4
-rw-r--r--. 1 root root 27 Mar  5 20:13 index.html
drwxr-xr-x. 2 root root  6 Mar  5 20:50 v1
drwxr-xr-x. 2 root root  6 Mar  5 20:50 v2
drwxr-xr-x. 2 root root  6 Mar  5 20:50 v3
drwxr-xr-x. 2 root root  6 Mar  5 20:50 v4
drwxr-xr-x. 2 root root  6 Mar  5 20:50 v5
[root@localhost volumes]# exportfs -arv
exporting 172.12.1.0/24:/data/volumes/v5
exporting 172.12.1.0/24:/data/volumes/v4
exporting 172.12.1.0/24:/data/volumes/v3
exporting 172.12.1.0/24:/data/volumes/v2
exporting 172.12.1.0/24:/data/volumes/v1
1.2创建pv。
[root@k8s-1 volume]# kubectl apply -f pv-nfs.yaml
persistentvolume/pv01 created
persistentvolume/pv02 created
persistentvolume/pv03 created
persistentvolume/pv04 created
persistentvolume/pv05 created
[root@k8s-1 volume]# less pv-nfs.yaml
##[root@k8s-1 volume]# kubectl explain pv.spec
##[root@k8s-1 volume]# kubectl explain pv.spec.nfs
KIND:     PersistentVolume
VERSION:  v1

RESOURCE: nfs <Object>

DESCRIPTION:
     NFS represents an NFS mount on the host. Provisioned by an admin. More
     info: https://kubernetes.io/docs/concepts/storage/volumes#nfs

     Represents an NFS mount that lasts the lifetime of a pod. NFS volumes do
     not support ownership management or SELinux relabeling.

FIELDS:
   path <string> -required-
     Path that is exported by the NFS server. More info:
     https://kubernetes.io/docs/concepts/storage/volumes#nfs

   readOnly     <boolean>
     ReadOnly here will force the NFS export to be mounted with read-only
     permissions. Defaults to false. More info:
     https://kubernetes.io/docs/concepts/storage/volumes#nfs

   server       <string> -required-
     Server is the hostname or IP address of the NFS server. More info:
     https://kubernetes.io/docs/concepts/storage/volumes#nfs

[root@k8s-1 volume]#
[root@k8s-1 volume]# less pv-nfs.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv01
  labels:
    name: pv01

spec:
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 2Gi
  nfs:
    path: /data/volumes/v1
    server: 172.12.1.20
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv02
  labels:
    name: pv02

spec:
  accessModes: ["ReadWriteOnce"]
  capacity:
    storage: 5Gi
  nfs:
    path: /data/volumes/v2
    server: 172.12.1.20
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv03
  labels:
    name: pv03

spec:
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 20Gi
  nfs:
    path: /data/volumes/v3
    server: 172.12.1.20
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv04
  labels:
    name: pv04

spec:
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 10Gi
  nfs:
    path: /data/volumes/v4
    server: 172.12.1.20
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv05
  labels:
    name: pv05

spec:
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 10Gi
  nfs:
    path: /data/volumes/v5
    server: 172.12.1.20
---
[root@k8s-1 volume]#
[root@k8s-1 volume]#
[root@k8s-1 volume]# kubectl apply -f pv-nfs.yaml
persistentvolume/pv01 created
persistentvolume/pv02 created
persistentvolume/pv03 created
persistentvolume/pv04 created
persistentvolume/pv05 created
[root@k8s-1 volume]#
[root@k8s-1 volume]# kubectl get  pv -o wide
NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM             STORAGECLASS   REASON   AGE
pv01   2Gi        RWO,RWX        Retain           Available                                             8m3s
pv02   5Gi        RWO            Retain           Available                                             8m3s
pv03   20Gi       RWO,RWX        Retain           Available                                             8m3s
pv04   10Gi       RWO,RWX        Retain           Bound       default/pvc-nfs                           8m3s
pv05   10Gi       RWO,RWX        Retain           Available                                             8m3s
[root@k8s-1 volume]#
1.3创建pod，以pvc的方式。
[root@k8s-1 volume]# less pvc-nfs.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs
  namespace: default

spec:
  accessModes: ["ReadWriteMany"]
  resources:
    requests:
      storage: 6Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-pvc
  namespace: default
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports:
    - name: myapp-port
      containerPort: 80
    volumeMounts:
    - mountPath: /usr/share/nginx/html/
      name: pvc-test
  volumes:
  - name: pvc-test
    persistentVolumeClaim:
      claimName: pvc-nfs
[root@k8s-1 volume]#
现在对该yaml做一下解说：
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs
  namespace: default

spec:
  accessModes: ["ReadWriteMany"]
  resources:
    requests:
      storage: 6Gi
这一部分是pvc的yaml文件。下边是调用。
[root@k8s-1 volume]# kubectl get  pv -o wide
NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM             STORAGECLASS   REASON   AGE
pv01   2Gi        RWO,RWX        Retain           Available                                             14m
pv02   5Gi        RWO            Retain           Available                                             14m
pv03   20Gi       RWO,RWX        Retain           Available                                             14m
pv04   10Gi       RWO,RWX        Retain           Bound       default/pvc-nfs                           14m
pv05   10Gi       RWO,RWX        Retain           Available                                             14m
[root@k8s-1 volume]# kubectl get  pvc -o wide
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nfs   Bound    pv04     10Gi       RWO,RWX                       14m
[root@k8s-1 volume]#
####测试发现，当pv被占用时候，也就是pod还没有删除时。如果手工把pv删除，会发现，此时删除会一直卡在那里。也就是说，pv被Bond的时候，不能被删除。//
2.动态pv和pvc
//待补充//   Update：
https://www.cnblogs.com/00986014w/p/9406962.html
https://www.jianshu.com/p/839ac3acf294




For More Information:BurlyLuo:<olaf.luo@foxmail.com>



