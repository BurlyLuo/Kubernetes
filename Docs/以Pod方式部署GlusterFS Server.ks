kubernetes 以Pod方式部署GlusterFS Server
https://blog.51cto.com/billy98/2337874
https://techdev.io/en/developer-blog/deploying-glusterfs-in-your-bare-metal-kubernetes-cluster
背景：
前时间完成了外部系统提供的glusterfs的节点，而对于NTAS来说，它使用的是kubernetes的node节点来完成的glusterfs存储。本一直想弄清楚这样使用的逻辑原理，参考了"DEPLOYING GLUSTERFS IN YOUR BARE METAL KUBERNETES CLUSTER" 该文章。发现，是结合Heketi
一起讲解的，而google了多数博客，发现国内很多博客多事仿照该帖子写的。所以，想自己单独探索一下只部署pod类型的glusterfs的实现原理。
文中说道，需要使用三个node节点来做，而迫于资源有限，算上master节点也只有两个节点。恐于由于试探造成平台的奔溃，所以就现在kubernetes playground---https://www.katacoda.com/courses/kubernetes/playground
做了尝试，发现能基本实现glusterfs的节点。[1.部署完成了两个ds类型的glusterfs pod。 2.添加两个节点的/etc/hosts文件以后，尝试创建peer，发现成功。3.然后创建对应的volume，发现也能成功。到底，对于glusterfs server算是基本完成，接下来就是调用，如果调用成功，那就ok！]
基本分析过程
现在对本次的探索做详细的描述：
1.由于glusterfs server使用ds方式部署，所以，我们需要对kubernetes的节点进行相应的label，以便使在特定的节点进行对应的ds类型的pod的部署，避免误伤！
[root@k8s-1 pod-gluster]# kubectl label node k8s-1 storagenode=glusterfs
node/k8s-1 labeled
[root@k8s-1 pod-gluster]# kubectl label node k8s-2 storagenode=glusterfs
node/k8s-2 labeled
[root@k8s-1 pod-gluster]# kubectl get nodes --show-labels -o wide
NAME    STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION          CONTAINER-RUNTIME   LABELS
k8s-1   Ready    master   18d   v1.13.3   172.12.1.10   <none>        CentOS Linux 7 (Core)   3.10.0-957.el7.x86_64   docker://18.9.2     beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=k8s-1,node-role.kubernetes.io/master=,storagenode=glusterfs
k8s-2   Ready    <none>   18d   v1.13.3   172.12.1.11   <none>        CentOS Linux 7 (Core)   3.10.0-957.el7.x86_64   docker://18.9.2     beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=k8s-2,storagenode=glusterfs
[root@k8s-1 pod-gluster]#
2. 以ds类型部署glusterfs server。[这里强调一下：[hostNetwokr: true]为了是集群中的节点都能够访问到该glusterfs server，好处：这种Pod的网络模式有一个用处就是可以将网络插件包装在Pod中然后部署在每个宿主机上，这样该Pod就可以控制该宿主机上的所有网络。] 
[root@k8s-1 pod-gluster]#less glusterfs-ds.yaml
https://raw.githubusercontent.com/gluster/gluster-kubernetes/master/deploy/kube-templates/glusterfs-daemonset.yaml
---
kind: DaemonSet
apiVersion: extensions/v1beta1
metadata:
  name: glusterfs
  labels:
    glusterfs: daemonset
  annotations:
    description: GlusterFS DaemonSet
    tags: glusterfs
spec:
  template:
    metadata:
      name: glusterfs
      labels:
        glusterfs: pod
        glusterfs-node: pod
    spec:
      nodeSelector:
        storagenode: glusterfs
      hostNetwork: true
      containers:
      - image: gluster/gluster-centos:latest
        imagePullPolicy: IfNotPresent
        name: glusterfs
        env:
        # alternative for /dev volumeMount to enable access to *all* devices
        - name: HOST_DEV_DIR
          value: "/mnt/host-dev"
        # set GLUSTER_BLOCKD_STATUS_PROBE_ENABLE to "1" so the
        # readiness/liveness probe validate gluster-blockd as well
        - name: GLUSTER_BLOCKD_STATUS_PROBE_ENABLE
          value: "1"
        - name: GB_GLFS_LRU_COUNT
          value: "15"
        - name: TCMU_LOGDIR
          value: "/var/log/glusterfs/gluster-block"
        resources:
          requests:
            memory: 100Mi
            cpu: 100m
        volumeMounts:
        - name: glusterfs-heketi
          mountPath: "/var/lib/heketi"
        - name: glusterfs-run
          mountPath: "/run"
        - name: glusterfs-lvm
          mountPath: "/run/lvm"
        - name: glusterfs-etc
          mountPath: "/etc/glusterfs"
        - name: glusterfs-logs
          mountPath: "/var/log/glusterfs"
        - name: glusterfs-config
          mountPath: "/var/lib/glusterd"
        - name: glusterfs-host-dev
          mountPath: "/mnt/host-dev"
        - name: glusterfs-misc
          mountPath: "/var/lib/misc/glusterfsd"
        - name: glusterfs-block-sys-class
          mountPath: "/sys/class"
        - name: glusterfs-block-sys-module
          mountPath: "/sys/module"
        - name: glusterfs-cgroup
          mountPath: "/sys/fs/cgroup"
          readOnly: true
        - name: glusterfs-ssl
          mountPath: "/etc/ssl"
          readOnly: true
        - name: kernel-modules
          mountPath: "/usr/lib/modules"
          readOnly: true
        securityContext:
          capabilities: {}
          privileged: true
        readinessProbe:
          timeoutSeconds: 3
          initialDelaySeconds: 40
          exec:
            command:
            - "/bin/bash"
            - "-c"
            - "if command -v /usr/local/bin/status-probe.sh; then /usr/local/bin/status-probe.sh readiness; else systemctl status glusterd.service; fi"
          periodSeconds: 25
          successThreshold: 1
          failureThreshold: 50
        livenessProbe:
          timeoutSeconds: 3
          initialDelaySeconds: 40
          exec:
            command:
            - "/bin/bash"
            - "-c"
            - "if command -v /usr/local/bin/status-probe.sh; then /usr/local/bin/status-probe.sh liveness; else systemctl status glusterd.service; fi"
          periodSeconds: 25
          successThreshold: 1
          failureThreshold: 50
      volumes:
      - name: glusterfs-heketi
        hostPath:
          path: "/var/lib/heketi"
      - name: glusterfs-run
      - name: glusterfs-lvm
        hostPath:
          path: "/run/lvm"
      - name: glusterfs-etc
        hostPath:
          path: "/etc/glusterfs"
      - name: glusterfs-logs
        hostPath:
          path: "/var/log/glusterfs"
      - name: glusterfs-config
        hostPath:
          path: "/var/lib/glusterd"
      - name: glusterfs-host-dev
        hostPath:
          path: "/dev"
      - name: glusterfs-misc
        hostPath:
          path: "/var/lib/misc/glusterfsd"
      - name: glusterfs-block-sys-class
        hostPath:
          path: "/sys/class"
      - name: glusterfs-block-sys-module
        hostPath:
          path: "/sys/module"
      - name: glusterfs-cgroup
        hostPath:
          path: "/sys/fs/cgroup"
      - name: glusterfs-ssl
        hostPath:
          path: "/etc/ssl"
      - name: kernel-modules
        hostPath:
          path: "/usr/lib/modules"
[root@k8s-1 pod-gluster]# kubectl apply -f glusterfs-ds.yaml
效果如下：
[root@k8s-1 pod-gluster]# kubectl get pods -o wide
NAME              READY   STATUS    RESTARTS   AGE   IP            NODE    NOMINATED NODE   READINESS GATES
glusterfs-8gm8l   1/1     Running   0          50s   172.12.1.10   k8s-1   <none>           <none>
glusterfs-8qdxz   1/1     Running   0          50s   172.12.1.11   k8s-2   <none>           <none> 
3.pod方式部署的glusterfs server已经ok，现在开始在该server上创建可供gluseter client调用的volume。
在glusterfs-8gm8l的pod中，检查 /etc/hosts
[root@k8s-1 ~]# more /etc/hosts 
# Kubernetes-managed hosts file (host network).
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6


172.12.1.10 k8s-1
172.12.1.11 k8s-2
在glusterfs-8qdxz的pod中，检查/etc/hosts
[root@k8s-2 ~]# more /etc/hosts
# Kubernetes-managed hosts file (host network).
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

172.12.1.10 k8s-1
172.12.1.11 k8s-2
[root@k8s-2 ~]#

[root@k8s-1 ~]# gluster peer probe k8s-2
peer probe: success.
[root@k8s-1 ~]# gluster  peer status
Number of Peers: 1

Hostname: k8s-2
Uuid: b3a49705-dcad-4e7b-86a8-2eb60a0dedcf
State: Peer in Cluster (Connected)
[root@k8s-1 ~]# mkdir /data/brick/gvol0 -pv
mkdir: created directory ‘/data’
mkdir: created directory ‘/data/brick’
mkdir: created directory ‘/data/brick/gvol0’
[root@k8s-1 ~]# gluster volume create gvol0 replica 2 k8s-1:/data/brick/gvol0 k8s-2:/data/brick/gvol0 force       
volume create: gvol0: success: please start the volume to access data
[root@k8s-1 ~]# gluster volume start gvol0
volume start: gvol0: success
[root@k8s-1 ~]# gluster volume info

Volume Name: gvol0
Type: Replicate
Volume ID: c798bde3-0085-462a-811d-d6243bb58c48
Status: Started
Snapshot Count: 0
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: k8s-1:/data/brick/gvol0
Brick2: k8s-2:/data/brick/gvol0
Options Reconfigured:
transport.address-family: inet
nfs.disable: on
performance.client-io-threads: off
[root@k8s-1 ~]#
到此，我们的glusterfs server 的volume创建完成。
5.开始调用：
调用：我们先把该volume挂载上。由于前边的此时，我们本地的/mnt目录已经被挂载了。所以，我重新创建了一个目录：/mnt/test/
[root@k8s-1 pod-gluster]#mount -t glusterfs k8s-1:/gvol0 /mnt/test/    [这个只是验证，实际使用的时候，不要挂载，需要umount。切记，否则会出现本地目录也有pod中的文件！！]
接着创建对应的ep：
[root@k8s-1 pod-gluster]# less gluster-ep.json
{
  "kind": "Endpoints",
  "apiVersion": "v1",
  "metadata": {
    "name": "pod-glusterfs-cluster"
  },
  "subsets": [
    {
      "addresses": [
        {
          "ip": "172.12.1.10"
        }
      ],
      "ports": [
        {
          "port": 1
        }
      ]
    },
    {
      "addresses": [
        {
          "ip": "172.12.1.11"
        }
      ],
      "ports": [
        {
          "port": 1
        }
      ]
    }
  ]
}

[root@k8s-1 pod-gluster]#
6.创建pod来验证一下。[本例子：使用直接调用glusterfs来作为存储，而不使用pv的方式。]
[root@k8s-1 pod-gluster]# less pod-glusterfs-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox-pod
  namespace: default
spec:
  containers:
  - image: busybox
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
    name: busybox
    volumeMounts:
    - mountPath: /busybox-data
      name: data
  volumes:
  - glusterfs:
      endpoints: pod-glusterfs-cluster
      path: gvol0
    name: data

[root@k8s-1 pod-gluster]# 
效果如下：
[root@k8s-1 pod-gluster]# kubectl get pods -o wide
NAME              READY   STATUS    RESTARTS   AGE   IP             NODE    NOMINATED NODE   READINESS GATES
busybox-pod       1/1     Running   1          79m   10.244.1.102   k8s-2   <none>           <none>
glusterfs-8gm8l   1/1     Running   0          97m   172.12.1.10    k8s-1   <none>           <none>
glusterfs-8qdxz   1/1     Running   0          97m   172.12.1.11    k8s-2   <none>           <none>
[root@k8s-1 pod-gluster]#
下面验证一下：在创建的busyox-pod中对应的volumeMounts目录中创建一个文件：
[root@k8s-1 pod-gluster]# kubectl exec -it busybox-pod sh
/ # cd busybox-data/
/busybox-data # ls
pod-glusterfs.txt
/busybox-data # more pod-glusterfs.txt
This is pod-gluster Test
/busybox-data #
而对应的glusterfs client目录上也有相应的文件： 
[root@k8s-1 test]# pwd
/mnt/test
[root@k8s-1 test]# ls
pod-glusterfs.txt
[root@k8s-1 test]# less pod-glusterfs.txt
This is pod-gluster Test
[root@k8s-1 test]#
最重要的是要在glusterfs  server上有对应的文件就OK了。
登录到：
[root@k8s-1 test]# kubectl exec -it glusterfs-8gm8l bash
[root@k8s-1 /]# cd /data/brick/gvol0/
[root@k8s-1 gvol0]# ls
pod-glusterfs.txt
[root@k8s-1 gvol0]# more pod-glusterfs.txt
This is pod-gluster Test
[root@k8s-1 gvol0]#
现在看此种存储方式，在pod湮灭后被重新创建出来以后，前边pod创建的文件是否能同步回来。
经过测试文件是能够同步回来的！！！
[root@k8s-1 test]# kubectl get pods -o wide
NAME              READY   STATUS    RESTARTS   AGE     IP             NODE    NOMINATED NODE   READINESS GATES
busybox-pod2      1/1     Running   0          5m33s   10.244.1.108   k8s-2   <none>           <none>
现在看到该pod被调度到k8s-2：我们看看上边的目录：[这个时候应该看glusterfs server的上的目录，按照道理来说！！！]




For More Information:BurlyLuo <olaf.luo@foxmail.com>

