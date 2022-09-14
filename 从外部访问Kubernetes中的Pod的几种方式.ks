从外部访问Kubernetes中的Pod的几种方式
1.hostNetwork：
https://jimmysong.io/posts/accessing-kubernetes-pods-from-outside-of-the-cluster/
[root@k8s-1 volume]# kubectl explain pod.spec.hostNetwork
KIND:     Pod
VERSION:  v1

FIELD:    hostNetwork <boolean>

DESCRIPTION:
     Host networking requested for this pod. Use the host's network namespace.
     If this option is set, the ports that will be used must be specified.
     Default to false.
[root@k8s-1 volume]#
背景：在实际生产环境中，有些容器内应用（比如编码器）需要用到物理层面的网络资源（比如组播流）。这就要求Kubernetes中的该Pod以HOST模式来启动。以下实验了Kubernetes-HOST网络模式，并给出了一些运维建议。
每个Pod都会默认启动一个pod-infrastructure（或pause）的容器，作为共享网络的基准容器。其他业务容器在启动之后，会将自己的网络模式指定为“"NetworkMode": "container:pause_containerID”。这样就能做到Pod中的所有容器网络都是共享的，一个Pod中的所有容器中的网络是一致的，它们能够通过本地地址（localhost）访问其他用户容器的端口。在Kubernetes的网络模型中，每一个Pod都拥有一个扁平化共享网络命名空间的IP，称为PodIP。通过PodIP，Pod就能够跨网络与其他物理机和容器进行通信。
　　也可以设置Pod为Host网络模式，即直接使用宿主机的网络，不进行网络虚拟化隔离。这样一来，Pod中的所有容器就直接暴露在宿主机的网络环境中，这时候，Pod的PodIP就是其所在Node的IP。从原理上来说，当设定Pod的网络为Host时，是设定了Pod中pod-infrastructure（或pause）容器的网络为Host，Pod内部其他容器的网络指向该容器

现在给一个demo：
[root@k8s-1 volume]# less hostNetwork.yaml
apiVersion: v1
kind: Pod
metadata:
  name: httpd
spec:
  hostNetwork: true
  containers:
  - name: httpd
    image: httpd
    imagePullPolicy: IfNotPresent 
[root@k8s-1 volume]#
由于httpd默认是监听80端口，所以在对应的node上应该可以看到80处于listen的状态：
 [root@k8s-1 volume]# kubectl get pods -o wide  | grep httpd
httpd                     1/1     Running   0          2m5s    172.12.1.10    k8s-1   <none>           <none>
[root@k8s-1 volume]#
可以看到是node1上k8s-1[master节点]，所以在master节点上查看：
[root@k8s-1 volume]# netstat -an | grep "LISTEN" | grep 80| grep -v STREAM| grep -v 2380
tcp6       0      0 :::80                   :::*                    LISTEN     
[root@k8s-1 volume]#
的确是处于LISTEN的状态。
对于NTAS上部分pod也是使用此种NetworkMode。例如：
[root@cbam-f21f5ead98db40e1b7511e47b53-oam-node-2 ~]# kubectl get pods -o wide | grep gluster
glusterfs-rmrcp                                     1/1       Running   0          168d      172.24.16.106   172.24.16.106
glusterfs-rrcsp                                     1/1       Running   0          168d      172.24.16.107   172.24.16.107
glusterfs-txz88                                     1/1       Running   0          168d      172.24.16.108   172.24.16.108
[root@cbam-f21f5ead98db40e1b7511e47b53-oam-node-2 ~]#
在对应的node上应该也会监听glusterfs的端口：

[root@cbam-f21f5ead98db40e1b7511e47b53-storage-node-1 ~]# netstat -na | grep 24007
tcp        0      0 0.0.0.0:24007           0.0.0.0:*               LISTEN
- Each node must have the following ports opened for GlusterFS communications:
- 2222 - GlusterFS pod's sshd
- 24007 - GlusterFS Daemon
- 24008 - GlusterFS Management
- 49152 to 49251 - Each brick for every volume on the host requires its own port. For every new brick, one new port will be used starting at 49152. We recommend a default range of 49152-49251 on each host, though you can adjust this to fit your needs.
Note：
注意每次启动这个Pod的时候都可能被调度到不同的节点上，所有外部访问Pod的IP也是变化的[所以比较适合把其部署为ds类型的pods]，而且调度Pod的时候还需要考虑是否与宿主机上的端口冲突，因此一般情况下除非您知道需要某个特定应用占用特定宿主机上的特定端口时才使用hostNetwork: true的方式。
这种Pod的网络模式有一个用处就是可以将网络插件包装在Pod中然后部署在每个宿主机上，这样该Pod就可以控制该宿主机上的所有网络。 

2.hostPort
hostPort是直接将容器的端口与所调度的节点上的端口路由，这样用户就可以通过宿主机的IP加上来访问Pod了，如:
apiVersion: v1
kind: Pod
metadata:
  name: influxdb
spec:
  containers:
  - name: influxdb
    image: influxdb
    ports:
    - containerPort: 8086
      hostPort: 8086
这样做有个缺点，因为Pod重新调度的时候该Pod被调度到的宿主机可能会变动，这样就变化了，用户必须自己维护一个Pod与所在宿主机的对应关系。
这种网络方式可以用来做 nginx Ingress controller。外部流量都需要通过kubenretes node节点的80和443端口。
[实际上对于上期实现的ingress controller方式却不是采用这种方法！]
////

3.NodePort

4.LoadBalancer

5.Ingress
#####
For More Information:BurlyLuo:<olaf.luo@foxmail.com>
