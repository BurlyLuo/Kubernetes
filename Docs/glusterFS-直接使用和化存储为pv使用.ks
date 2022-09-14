kubernetes存储[glusterFS-直接使用和化存储为pv使用]
Refer URL：http://dockone.io/article/556   
glusterFS
https://jimmysong.io/kubernetes-handbook/practice/using-glusterfs-for-persistent-storage.html
参考这两篇帖子做的：
首先讨论一下，GlusterFS的配置：
https://wiki.centos.org/zh/HowTos/GlusterFSonCentOS
glusterfs server 01的配置：
1.修改/etc/hosts文件：
[root@localhost gvol0]# less /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

172.12.1.20 gfs1
172.12.1.21 gfs2
[root@localhost gvol0]#
2.安装epel和gluster的repo。
yum -y install epel-release
yum install centos-release-gluster
3.安装gluster。
yum install glusterfs-serve gluster-client //使得我们的glusterFS  server也能使用gluster 的CLI//
4.关掉selnux和firewalld，以及清除iptables。[当然如果不想关掉firewalld，那就需要添加防火墙的规则：
GlusterFS 节点之间的沟通必须运用 TCP 端口 24007-24008，另外每件砖块须要一个由 24009 起分派的 TCP 端口。
在防火墙上启用所需的端口：
# firewall-cmd --zone=public --add-port=24007-24008/tcp --permanent
success
# firewall-cmd --reload
success]
[root@localhost gvol0]#vi /etc/selinux/config
[root@localhost gvol0]#iptables -F
5.启动glusterFS：
systemctl restart glusterd
6.互相添加集群。
在gfs1上添加gfs2
gluster peer probe gfs2
在gfs2上添加gfs1
gluster peer probe gfs1
7.创建volume。在gfs1上操作：
$ mkdir /data/brick/gvol0 -pv
$ gluster volume create gvol0 replica 2 gfs1:/data/brick/gvol0 gfs2:/data/brick/gvol0 force
$ gluster volume start gvol0
$ gluster volume info

第7步需要特别注意：以下是安装的具体日志。
[root@localhost ~]# gluster volume create gvol0 replica 2 gfs1:/data/brick/gvol0 gfs2:/data/brick/gvol0
Replica 2 volumes are prone to split-brain. Use Arbiter or Replica 3 to avoid this. See: http://docs.gluster.org/en/latest/Administrator%20Guide/Split%20brain%20and%20ways%20to%20deal%20with%20it/.
Do you still want to continue?
 (y/n) y
volume create: gvol0: failed: The brick gfs1:/data/brick/gvol0 is being created in the root partition. It is recommended that you don't use the system's root partition for storage backend. Or use 'force' at the end of the command if you want to override this behavior.
[root@localhost ~]# gluster volume create gvol0 replica 2 gfs1:/data/brick/gvol0 gfs2:/data/brick/gvol0 force
volume create: gvol0: failed: Staging failed on gfs2. Error: Failed to create brick directory for brick gfs2:/data/brick/gvol0. Reason : No such file or directory
[root@localhost ~]#
[root@localhost ~]#
[root@localhost ~]#
[root@localhost ~]# gluster volume create gvol0 replica 2 gfs1:/data/brick/gvol0 gfs2:/data/brick/gvol0 force
volume create: gvol0: success: please start the volume to access data
[root@localhost ~]# gluster volume start gvol0
volume start: gvol0: success
[root@localhost ~]# gluster volume info

Volume Name: gvol0
Type: Replicate
Volume ID: d0c13ad2-37c2-492f-bc5f-45efc19909ad
Status: Started
Snapshot Count: 0
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: gfs1:/data/brick/gvol0
Brick2: gfs2:/data/brick/gvol0
Options Reconfigured:
transport.address-family: inet
nfs.disable: on
performance.client-io-threads: off
[root@localhost ~]#
8.查看集群的状态：
[root@localhost gvol0]#
[root@localhost gvol0]# gluster peer status
Number of Peers: 1

Hostname: gfs2
Uuid: aa4c2b53-90d7-4572-9225-3fb29344ac64
State: Peer in Cluster (Connected)
[root@localhost gvol0]#
接下来分析kubernetes调用过程：
1.为了使用glusterfs的资源，需要在node节点上安装glusterfs的client。
即：yum -y install epel-release
    yum install centos-release-gluster
    yum install glusterfs-client
2.mount -t glusterfs gfs1:/gvol0 /mnt   [这个只是验证，实际使用的时候，不要挂载，需要umount。切记，否则会出现本地目录也有该文件！！]
这时候直接执行，发现mount 失败：去看日志发现，less /var/log/glusterfs/mnt.log
发现：
[root@k8s-1 glusterfs]# less mnt
mnt: No such file or directory
[root@k8s-1 glusterfs]# less mnt.log
[2019-03-06 06:17:31.646067] I [MSGID: 100030] [glusterfsd.c:2715:main] 0-/usr/sbin/glusterfs: Started running /usr/sbin/glusterfs version 5.3 (args: /usr/sbin/glusterfs --process-name fuse --volfile-server=gfs1 --volfile-id=/gvol0 /mnt)
[2019-03-06 06:17:32.193428] E [MSGID: 101075] [common-utils.c:508:gf_resolve_ip6] 0-resolver: getaddrinfo failed (Name or service not known)
[2019-03-06 06:17:32.193503] E [name.c:258:af_inet_client_get_remote_sockaddr] 0-glusterfs: DNS resolution failed on host gfs1
[2019-03-06 06:17:32.193902] I [glusterfsd-mgmt.c:2424:mgmt_rpc_notify] 0-glusterfsd-mgmt: disconnected from remote-host: gfs1
[2019-03-06 06:17:32.193926] I [glusterfsd-mgmt.c:2444:mgmt_rpc_notify] 0-glusterfsd-mgmt: Exhausted all volfile servers
[2019-03-06 06:17:32.194099] W [glusterfsd.c:1500:cleanup_and_exit] (-->/lib64/libgfrpc.so.0(+0xee23) [0x7fb32efe9e23] -->/usr/sbin/glusterfs(+0x1284d) [0x55719f8a184d] -->/usr/sbin/glusterfs(cleanup_and_exit+0x6b) [0x55719f899ceb] ) 0-: received signum (1), shutting down
[2019-03-06 06:17:32.194142] I [fuse-bridge.c:5914:fini] 0-fuse: Unmounting '/mnt'.
[2019-03-06 06:17:32.194341] I [MSGID: 101190] [event-epoll.c:622:event_dispatch_epoll_worker] 0-epoll: Started thread with index 1
[2019-03-06 06:17:32.199661] I [fuse-bridge.c:5919:fini] 0-fuse: Closing fuse connection to '/mnt'.
[2019-03-06 06:18:37.969041] I [MSGID: 100030] [glusterfsd.c:2715:main] 0-/usr/sbin/glusterfs: Started running /usr/sbin/glusterfs version 5.3 (args: /usr/sbin/glusterfs --process-name fuse --volfile-server=172.12.1.20 --volfile-id=/gvol0 /mnt)
[2019-03-06 06:18:38.121383] I [MSGID: 101190] [event-epoll.c:622:event_dispatch_epoll_worker] 0-epoll: Started thread with index 1
[2019-03-06 06:18:38.127133] I [MSGID: 101190] [event-epoll.c:622:event_dispatch_epoll_worker] 0-epoll: Started thread with index 2
[2019-03-06 06:18:38.127349] I [MSGID: 114020] [client.c:2354:notify] 0-gvol0-client-0: parent translators are ready, attempting connect on transport
[2019-03-06 06:18:38.197582] E [MSGID: 101075] [common-utils.c:508:gf_resolve_ip6] 0-resolver: getaddrinfo failed (Name or service not known)
[2019-03-06 06:18:38.197614] E [name.c:258:af_inet_client_get_remote_sockaddr] 0-gvol0-client-0: DNS resolution failed on host gfs1
[2019-03-06 06:18:38.197779] I [MSGID: 114020] [client.c:2354:notify] 0-gvol0-client-1: parent translators are ready, attempting connect on transport
[2019-03-06 06:18:38.198011] E [MSGID: 108006] [afr-common.c:5314:__afr_handle_child_down_event] 0-gvol0-replicate-0: All subvolumes are down. Going offline until at least one of them comes back up.
[2019-03-06 06:18:38.269315] E [MSGID: 101075] [common-utils.c:508:gf_resolve_ip6] 0-resolver: getaddrinfo failed (Name or service not known)
[2019-03-06 06:18:38.269352] E [name.c:258:af_inet_client_get_remote_sockaddr] 0-gvol0-client-1: DNS resolution failed on host gfs2
3. 上边的日志中说，解析不了我们挂载的路径。
所以，我们再看看挂载使用的命令：
mount -t glusterfs gfs1:/gvol0 /mnt     [//发现使用的是他的名称，本地和dns都没有解析到，所以报错//]
于是添加在[所有要使用glusterfs]node节点添加：
vi /etc/hosts
[root@k8s-2 ~]# less /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

172.12.1.20 gfs1
172.12.1.21 gfs2
172.12.1.10 k8s-1
172.12.1.11 k8s-2
[root@k8s-2 ~]#
然后再挂载，发现成功了。
接下来创建一个pod试试。
1.创建endpoint。在node节点上做。
$ curl -O https://raw.githubusercontent.com/kubernetes/examples/master/staging/volumes/glusterfs/glusterfs-endpoints.json

# 修改 endpoints.json ，配置 glusters 集群节点ip# 每一个 addresses 为一个 ip 组
[root@k8s-1 volume]# less gluster-ep.json
{
  "kind": "Endpoints",
  "apiVersion": "v1",
  "metadata": {
    "name": "glusterfs-cluster"
  },
  "subsets": [
    {
      "addresses": [
        {
          "ip": "172.12.1.20"
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
          "ip": "172.12.1.21"
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
[root@k8s-1 volume]# 
# 导入 glusterfs-endpoints.json
$ kubectl apply -f gluster-ep.json
# 查看 endpoints 信息
$ kubectl get ep
2.创建pod。
[root@k8s-1 volume]# less glusterfs-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
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
      endpoints: glusterfs-cluster
      path: gvol0
    name: data
[root@k8s-1 volume]#
[root@k8s-1 volume]# kubectl get pods -o wide | grep busybox
busybox                   1/1     Running   4          4h33m   10.244.1.96   k8s-2   <none>           <none>
[root@k8s-1 volume]#
3.验证是否ok。
在busybox的pod的/busy-data 中创建一个文件。
[root@k8s-1 volume]# kubectl exec -it busybox sh
/ # cd busybox-data/
/busybox-data # ls
index.html
/busybox-data # more index.html
This is a glusterfs test!!!
/busybox-data #

这个时候到对应的glusterfs上看：
[root@localhost gvol0]# pwd
/data/brick/gvol0
[root@localhost gvol0]# ll -rth
total 4.0K
-rw-r--r--. 2 root root 28 Mar  6 14:55 index.html
[root@localhost gvol0]# less index.html
This is a glusterfs test!!!
[root@localhost gvol0]#
使用GlusterFS创建pv和pvc
首先为了把glusterfs的资源创建成k8s标准的资源对象。需要创建出pv来供使用:
[root@k8s-1 volume]# less gluster-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gluster-v1
spec:
   accessModes: ["ReadWriteMany","ReadWriteOnce"]
   capacity:
     storage: 7Gi
   glusterfs:
     path: gvol0
     endpoints: "glusterfs-cluster"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gluster-v2
spec:
   accessModes: ["ReadWriteMany","ReadWriteOnce"]
   capacity:
     storage: 9Gi
   glusterfs:
     path: gvol0
     endpoints: "glusterfs-cluster"
[root@k8s-1 volume]#
现在对pv的yaml进行解说一下：
   glusterfs:
     path: gvol0     //在glusterfs服务器上创建的volume//
     endpoints: "glusterfs-cluster"   //使用json文件创建的ep//
查看如下：
[root@k8s-1 volume]# kubectl get ep
NAME                ENDPOINTS                     AGE
glusterfs-cluster   172.12.1.20:1,172.12.1.21:1   22h
现在使用刚才创建的pv来创建对应的pod。
[root@k8s-1 volume]# less pvc-gluster.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-glusterfs
  namespace: default

spec:
  accessModes: ["ReadWriteMany"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-glusterfs
  namespace: default
spec:
  containers:
  - name: myapp-fs
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
      claimName: pvc-glusterfs
[root@k8s-1 volume]#
效果如下：
[root@k8s-1 volume]# kubectl get pods -o wide  | grep gluster
pod-glusterfs             1/1     Running   0          16h     10.244.1.97   k8s-2   <none>           <none>
[root@k8s-1 volume]#
Case1：
由于昨天在直接使用glusterfs作为存储来实现的存储和使用gluster pv，所挂载的目录都是：gvol0，造成二者指向的都是同一个目录。
现在使用两种方式创建的pod，为了验证，在pod创建的文件是否能同步到gluster server上[直接用gluster或是使用pv的方式]
首先看直接使用gluster fs的方式：
[root@k8s-1 volume]# kubectl get pods -o wide | grep busybox
busybox                   1/1     Running   4          4h33m   10.244.1.96   k8s-2   <none>           <none>
1.在这个pod中的busybox-data目录下创建一个文件：
#less busybox-pod.json
# This is busybox test server!
Update:2019-3-7
hostname: busybox
1.1.在gluster server查看：
[root@localhost gvol0]# less busybox-pod.json
# This is busybox test server!
Update:2019-3-7
hostname: busybox

[root@localhost gvol0]# pwd
/data/brick/gvol0
[root@localhost gvol0]#

2. 在pod中pod-glusterfs的：/usr/share/nginx/html/ 目录下创建一个文件：
这时：我们发现：刚才我们在busybox的pod中创建的文件，现在尽然被同步到pod-glusterfs中了。说明了，我们都是在操作远端gluster上的目录和文件！！！所以删除就以为着三处都没有了！！！
[root@k8s-1 volume]# kubectl exec -it pod-glusterfs sh
cd /var/lib/kubelet/pods/cf562666-409b-11e9-a7da-000c295ab45b/volumes/kubernetes.io~glusterfs/gluster-v2     //创建文件所存放的目录//
/ # cd /usr/share/nginx/html/
/usr/share/nginx/html # ls
busybox-pod.json
/usr/share/nginx/html #
现在我们创建一个属于pod-glusterfs的pod的对应目录下的文件：
/usr/share/nginx/html # vi pod-glusterfs.json
/usr/share/nginx/html # ls -l
total 1
-rw-r--r--    1 root     root            66 Mar  7 12:34 busybox-pod.json
-rw-r--r--    1 root     root            69 Mar  7 12:41 pod-glusterfs.json
/usr/share/nginx/html #此时有两个文件了。
此时我们先看glusterfs server上的目录下：
[root@localhost gvol0]# ll -rth
total 8.0K
-rw-r--r--. 2 root root 66 Mar  7 20:34 busybox-pod.json
-rw-r--r--. 2 root root 69 Mar  7 20:41 pod-glusterfs.json
[root@localhost gvol0]#
已经被同步上来了。
这时候，我们再来看busybox的pod中有没有pod-glusterfs刚才创建的文件，理论上是有的：
验证一下：
/busybox-data # ls -l
total 1
-rw-r--r--    1 root     root            66 Mar  7 12:34 busybox-pod.json
-rw-r--r--    1 root     root            69 Mar  7 12:41 pod-glusterfs.json
/busybox-data #
三个地方均有该文件！！！
[][][]所以这种情况下：
1：就严禁使用文件名相同的文件了，因为 别的pod的文件也会被改掉。
2：严禁随便删除文件，因为别的pod中的文件也会被删除的。






For More Information:BurlyLuo:<olaf.luo@foxmail.com>
