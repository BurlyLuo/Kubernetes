kubernetes 存储[emptyDir hostPath NFS]
pod具有生命周期，所以存储资源不能放在pod内部。
现在看一个example：[emptyDir形式]
emptryDir
用途：emptyDir类型的Volume在Pod分配到Node上时被创建，Kubernetes会在Node上自动分配一个目录，因此无需指定宿主机Node上对应的目录文件。 这个目录的初始内容为空，当Pod从Node上移除时，emptyDir中的数据会被永久删除。
emptyDir Volume主要用于某些应用程序无需永久保存的临时目录，多个容器的共享目录等。
apiVersion: v1
kind: Pod
metadata:
  name: pod-volume
  namespace: default
  labels:
    run: http

spec:
  containers:
  - name: pod-v
    image: httpd
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    volumeMounts:
    - name: html
      mountPath: /data/web/html/
  - name: busybox
    image: busybox
    imagePullPolicy: IfNotPresent
    ports:
    volumeMounts:
    - name: html
      mountPath: /data/server   
    command: ["/bin/sh"]
    args: ["-c","while true;do echo $(date) >>/data/server/index.html;sleep 10;done"]
  volumes:
  - name: html
    emptyDir: {}
解说：
1.一个pod中有2和container。
2.使用emptyDir作为volume。
3.其中一个container以sidecar的模式运行。
在用途中提到的，共享目录作用，这里具体说说：
对应上边pod的yaml文件中有两个container：pod-v和busybox。
其中创建的enptyDir的yaml为：
  volumes:
  - name: html
    emptyDir: {}
 [root@k8s-1 volume]#kubectl explain pod.spec
   volumes      <[]Object>   //可看出是一个列表对象//
     List of volumes that can be mounted by containers belonging to the pod.
     More info: https://kubernetes.io/docs/concepts/storage/volumes

[root@k8s-1 volume]#kubectl explain pod.spec.volumes 
     name <string> -required-    //name是必选字段//
     Volume's name. Must be a DNS_LABEL and unique within the pod. More info:
     https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
     emptyDir     <Object>
     EmptyDir represents a temporary directory that shares a pod's lifetime.
     More info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir
对于：共享目录：
其中container 1 pod-v和container 2 busybox
volumeMounts:
    - name: html
      mountPath: /data/server    //container 2 busybox的挂在路径//
    command: ["/bin/sh"]
    args: ["-c","while true;do echo $(date) >>/data/server/index.html;sleep 10;done"]   //负责向/data/server/目录下把内容写到文件index.html//此时就表明，在container 2 busybox下的/data/server/ 就是html这个volume在container 2 busybbox中挂在路径。然后文件又写在这个挂在路径下。//
因为是共享文件，所以在container 1中对应的挂载路径[mountPath: /data/web/html/]下应该有与之对应的文件出现。
登录到该container pod-v中：
[root@k8s-1 volume]# kubectl exec -it pod-volume -c pod-v bash
root@pod-volume:/usr/local/apache2# cd /data/web/html/
root@pod-volume:/data/web/html# ls -l
total 4
-rw-r--r--. 1 root root 168 Mar  5 03:06 index.html
root@pod-volume:/data/web/html# more index.html
Tue Mar 5 03:05:40 UTC 2019
Tue Mar 5 03:05:45 UTC 2019
Tue Mar 5 03:05:50 UTC 2019
Tue Mar 5 03:05:55 UTC 2019
Tue Mar 5 03:06:00 UTC 2019
Tue Mar 5 03:06:05 UTC 2019
Tue Mar 5 03:06:10 UTC 2019
root@pod-volume:/data/web/html#
这里表明：1.当我们创建emptyDir 的volume之后，被挂载到了不同容器的不同挂载路径下。这时候，实际上由于他们使用的是同一个volume。所以，内容可以在不同容器的不同挂载路径下同时被看到。相当于是一个软连接，共同指向这个volume。 
这个volume最终的受体也应该是pod所落在的node上的。
hostPath
hostPath Volume为Pod挂载宿主机上的目录或文件。 hostPath Volume的使得容器可以使用宿主机的高速文件系统进行存储。
先给一个范例:
[root@k8s-1 volume]# less hostPath.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-hostpath
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
    - mountPath: /test/data/
      name: host-path
  volumes:
  - name: host-path
    hostPath:
      path: /root/data/hostPath
      type: Directory
现在给出一个说明：
volume的类型为hostPath[顾名思义是主机路径，也就是说pod可以直接使用pod所在主机的存储资源作为其存储。]
  volumes:
  - name: host-path  //创建的volume的名字，供挂载时候调用//
    hostPath:        //创建的存储的类型为hostPath//
      path: /root/data/hostPath   //pod所在主机上的目录，貌似需要手动创建，否则会出现check失败的情况，[实际上第一次创建时候也是没提前创建，没有报错。但是把目录删除以后，就不行了。估计是yaml文件中有的地方钳制了。]//
      type: Directory
为容器挂载volume：
    volumeMounts:
    - mountPath: /test/data/       //pod中存储路径，经过hostPath的挂载会把该目录下的内容映射到pod所在主机上的/root/data/hostPath目录下//
      name: host-path              //调用volume，以名字来索引//
现在做一个验证：
est/data # ls
/test/data # echo "This is a hostPath volume Test!" >>hostPath.txt
/test/data # pwd
/test/data
现在在test/data目录中add一个文件。hostPath.txt。
登录到k8s-2节点上，因为此时该pod调度到了k8s-2节点上。
[root@k8s-2 ~]# cd data/hostPath/
[root@k8s-2 hostPath]# ls
hostPath.txt
[root@k8s-2 hostPath]# less hostPath.txt
This is a hostPath volume Test!
[root@k8s-2 hostPath]#
此时该目录下已经有了一个文件，就是我们在pod中创建的文件。！！！ 
与emptyDir不同的是，pod删除以后，原本在node上对应的目录的文件并不会被删除。
NFS
NFS 是Network File System的缩写，即网络文件系统。Kubernetes中通过简单地配置就可以挂载NFS到Pod中，而NFS中的数据是可以永久保存的，同时NFS支持同时写操作。
现在描述一下环境：
nfs server 为一个linux服务器。地址为：172.12.1.20 [当然也可以写成URL的形式，然后通过dns或是/etc/hosts文件来配置解析。这里做简单的演示就用地址来直接使用]
master 节点地址为：172.12.1.10
node 节点的地址为：172.12.1.11
yaml文件如下：
[root@k8s-1 volume]# less nfs.yamll
apiVersion: v1
kind: Pod
metadata:
  name: pod-nfs
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
      name: host-path
  volumes:
  - name: host-path
    nfs:
      path: /data/volumes
      server: 172.12.1.20
[root@k8s-1 volume]#
现在对该yaml文件进行解说：
  volumes:
  - name: host-path      //volumes的名字//
    nfs:                 //存储类型为nfs//
      path: /data/volumes   //挂载路径， Path that is exported by the NFS server.也就是nfs server所暴露出来的path//
      server: 172.12.1.20   //nfs server的地址//
[root@k8s-1 volume]# kubectl  explain pods.spec.volumes.nfs
KIND:     Pod
VERSION:  v1

RESOURCE: nfs <Object>

DESCRIPTION:
     NFS represents an NFS mount on the host that shares a pod's lifetime More
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
现在对nfs的server配置进行解说：
   13  yum -y install nfs-utils
   14  mkdir /data/volumes -pv
[root@localhost ~]# mkdir /data/volumes -pv
mkdir: created directory ‘/data’
mkdir: created directory ‘/data/volumes’
[root@localhost ~]# vi /etc/exports
/data/volumes  172.12.1.0/24(rw,no_root_squash)
[root@localhost ~]# systemctl restart nfs
[root@localhost ~]# systemctl enable nfs
Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.
[root@localhost ~]#
[root@localhost ~]# systemctl stop firewalld
[root@localhost ~]# systemctl disable firewalld
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.
[root@localhost ~]#  
- /data/volumes：是共享的数据目录
- *：表示任何人都有权限连接，当然也可以是一个网段，一个 IP，也可以是域名
- rw：读写的权限
- sync：表示文件同时写入硬盘和内存
- no_root_squash：当登录 NFS 主机使用共享目录的使用者是 root 时，其权限将被转换成为匿名使用者，通常它的 UID 与 GID，都会变成 nobody 身份.
cd /data/volumes/
[root@localhost volumes]# ll
total 0
[root@localhost volumes]# vi index.html
This is a nfs server test!
~
然后创建pod：
这里特别注意一下：
[root@k8s-2 ~]# mount -t nfs 172.12.1.20:/data/volumes /mnt
mount: wrong fs type, bad option, bad superblock on 172.12.1.20:/data/volumes,
       missing codepage or helper program, or other error
       (for several filesystems (e.g. nfs, cifs) you might
       need a /sbin/mount.<type> helper program)

       In some cases useful info is found in syslog - try
       dmesg | tail or so.
[root@k8s-2 ~]# yum -y install nfs-utils     //NFS 服务端安装完成后，需要在Kubernetes的每个Node节点上安装NF客户端//
[root@k8s-2 ~]# mount -t nfs 172.12.1.20:/data/volumes /mnt  [这个只是验证，实际使用的时候，不要挂载，需要umount。切记，否则会出现本地目录也有该文件！！]
[root@k8s-2 ~]# mount
[root@k8s-2 ~]# umount /mnt 
[root@k8s-2 ~]#kubectl apply -f nfs.yamll
[root@k8s-1 volume]# kubectl get pods -o wide | grep nfs
pod-nfs                   1/1     Running   0          13m     10.244.1.89   k8s-2   <none>           <none>
[root@k8s-1 volume]#  
[root@k8s-1 volume]# curl 10.244.1.89
This is a nfs server test!
[root@k8s-1 volume]#
Case1:
当在操作：主要是说明在nfs的server上创建的创建共享目录和export目录的必要性。
即：对于本例来说，我们事先创建的共享数据目录。这里是/data/volumes。
由于在创建pv的时候，又重新创建了5和目录 分别是 v1,v2,v3,v4,v5。然后在
[root@localhost volumes]#  exportfs -arv
exporting 172.12.1.0/24:/data/volumes/v5
exporting 172.12.1.0/24:/data/volumes/v4
exporting 172.12.1.0/24:/data/volumes/v3
exporting 172.12.1.0/24:/data/volumes/v2
exporting 172.12.1.0/24:/data/volumes/v1
发现没有/data/volumes 这个目录。在pod上访问也失败。
[root@k8s-1 volume]# curl 10.244.1.89
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.12.2</center>
</body>
</html>
[root@k8s-1 volume]#
这时候相当于他远端指向没有了，就是nfs 的 server上没有了他的共享目录了，这里没有指的是export中看不到，所以检查是否有共享目录，这里需要用一个exportnfs -arv来验证。
后来加上以后，就ok了。编辑：
[root@localhost volumes]# vi /etc/exports
/data/volumes 172.12.1.0/24(rw,no_root_squash)   //加上nfs实验时创建的共享目录//
/data/volumes/v1  172.12.1.0/24(rw,no_root_squash)
/data/volumes/v2  172.12.1.0/24(rw,no_root_squash)
/data/volumes/v3  172.12.1.0/24(rw,no_root_squash)
/data/volumes/v4  172.12.1.0/24(rw,no_root_squash)
/data/volumes/v5  172.12.1.0/24(rw,no_root_squash)
~
现在再具体说说，我们通过这种方法创建的存储。它能不能把我们的pod的内容同步到nfs server上来实现存储。
[root@k8s-1 ~]# kubectl get pods -o wide | grep nfs
pod-nfs                   1/1     Running   0          56m   10.244.1.95   k8s-2   <none>           <none>
[root@k8s-1 ~]# kubectl exec -it pod-nfs sh
/ # vi /usr/share/nginx/html/index.html
/ # more /usr/share/nginx/html/index.html
This is a nfs server test! But there is a case.
Update:2019-3-6
/ #
这是在pod中创建一个文件index.html，然后看到内容如上。
现在我们看看nfs  server上的共享目录中是否有这个文件，并且内容是否一致。
[root@localhost volumes]# ll  //NFS server。//
total 4
-rw-r--r--. 1 root root 64 Mar  6 10:59 index.html
drwxr-xr-x. 2 root root 24 Mar  6 10:03 v1
drwxr-xr-x. 2 root root  6 Mar  5 20:50 v2
drwxr-xr-x. 2 root root  6 Mar  5 20:50 v3
drwxr-xr-x. 2 root root  6 Mar  5 20:50 v4
drwxr-xr-x. 2 root root  6 Mar  5 20:50 v5
[root@localhost volumes]# less index.html
This is a nfs server test! But there is a case.
Update:2019-3-6
[root@localhost volumes]#是一样的！

Case2：
在创建pv的时候，我们在nfs的server上没有提前创建对应的目录。然后，直接在kubernetes上创建pv，此时平台上的pv创建是ok。但是，我们使用创建pod的时候去调用pv的时候，pod总是处于containercreating的状态，describe pod以后：发现：
Events:
  Type     Reason       Age   From               Message
  ----     ------       ----  ----               -------
  Normal   Scheduled    82s   default-scheduler  Successfully assigned default/pod-glusterfs to k8s-2
  Warning  FailedMount  79s   kubelet, k8s-2     MountVolume.SetUp failed for volume "pv07" : mount failed: exit status 32
Mounting command: systemd-run
Mounting arguments: --description=Kubernetes transient mount for /var/lib/kubelet/pods/11080aa8-4012-11e9-a7da-000c295ab45b/volumes/kubernetes.io~nfs/pv07 --scope -- mount -t nfs 172.12.1.20:/data/volumes/v7 /var/lib/kubelet/pods/11080aa8-4012-11e9-a7da-000c295ab45b/volumes/kubernetes.io~nfs/pv07
Output: Running scope as unit run-11192.scope.
mount.nfs: mounting 172.12.1.20:/data/volumes/v7 failed, reason given by server: No such file or directory
  Warning  FailedMount  78s  kubelet, k8s-2  MountVolume.SetUp failed for volume "pv07" : mount failed: exit status 32
Mounting command: systemd-run
找不到对应的目录，此时在nfs的server上创建了对应的目录以后，发现pod立马就ok了。
Case2:
    In some cases useful info is found in syslog - try
       dmesg | tail or so.
  Warning  FailedMount  5s  kubelet, k8s-1  MountVolume.SetUp failed for volume "pv04" : mount failed: exit status 32
Mounting command: systemd-run
Mounting arguments: --description=Kubernetes transient mount for /var/lib/kubelet/pods/063cbd9e-456c-11e9-940f-000c295ab45b/volumes/kubernetes.io~nfs/pv04 --scope -- mount -t nfs 172.12.1.20:/data/volumes/v4 /var/lib/kubelet/pods/063cbd9e-456c-11e9-940f-000c295ab45b/volumes/kubernetes.io~nfs/pv04
Output: Running scope as unit run-79727.scope.
mount: wrong fs type, bad option, bad superblock on 172.12.1.20:/data/volumes/v4,
       missing codepage or helper program, or other error
       (for several filesystems (e.g. nfs, cifs) you might
       need a /sbin/mount.<type> helper program)

       In some cases useful info is found in syslog - try

方案是：
该节点上没有装：yum -y install nfs-utils
安装完成以后OK！



