# Install Kubernetes V1.13.3 Guide
# Copyright By BurlyLuo.
# Mail：wei.luo@nokia-sbell.com
# Date:2019-2-3
# Description：Kubernetes is an open-source system for 
# automating deployment, scaling, and management of containerized applications.


Master Node：
1.https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.11.md#downloads-for-v1111

2.修改repo源：
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


3.确保SELINUX和Iptables-Firewalld没有开启。
[root@k8s-1 ~]# systemctl stop firewalld
[root@k8s-1 ~]# systemctl disable firewalld
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.
[root@k8s-1 ~]# 
#vi /etc/selinux/config 
[root@k8s-1 ~]# getenforce 
Permissive
[root@k8s-1 ~]# 

#vi /etc/sysctl.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1

4.
[root@k8s-1 ~]# vi /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

172.10.1.20  k8s-1
172.10.1.21  k8s-2

5.配置docker-ce
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum -y install docker-ce 
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
setenforce 0
yum install -y kubelet kubeadm kubectl
systemctl restart network
systemctl enable kubelet && systemctl restart kubelet
=======================================================================================================================================================================================================================================
 Package                                                                                                                                     Arch                                                                                                                        Version                                                                                                                            Repository                                                                                                                       Size
=======================================================================================================================================================================================================================================
Installing:
 kubeadm                                                                                                                                     x86_64                                                                                                                      1.13.3-0                                                                                                                           kubernetes                                                                                                                      7.9 M
 kubectl                                                                                                                                     x86_64                                                                                                                      1.13.3-0                                                                                                                           kubernetes                                                                                                                      8.5 M
 kubelet                                                                                                                                     x86_64                                                                                                                      1.13.3-0                                                                                                                           kubernetes                                                                                                                       21 M
Installing for dependencies:
 conntrack-tools                                                                                                                             x86_64                                                                                                                      1.4.4-4.el7                                                                                                                        base                                                                                                                            186 k
 cri-tools                                                                                                                                   x86_64                                                                                                                      1.12.0-0                                                                                                                           kubernetes                                                                                                                      4.2 M
 kubernetes-cni                                                                                                                              x86_64                                                                                                                      0.6.0-0                                                                                                                            kubernetes                                                                                                                      8.6 M
 libnetfilter_cthelper                                                                                                                       x86_64                                                                                                                      1.0.0-9.el7                                                                                                                        base                                                                                                                             18 k
 libnetfilter_cttimeout                                                                                                                      x86_64                                                                                                                      1.0.0-6.el7                                                                                                                        base                                                                                                                             18 k
 libnetfilter_queue                                                                                                                          x86_64                                                                                                                      1.0.2-2.el7_2                                                                                                                      base                                                                                                                             23 k
 socat                                                                                                                                       x86_64                                                                                                                      1.7.3.2-2.el7                                                                                                                      base                                                                                                                            290 k

Transaction Summary
=======================================================================================================================================================================================================================================
Install  3 Packages (+7 Dependent packages)

6. vi /usr/lib/systemd/system/docker.service 
[Service]
Environment="HTTPS_PROXY=http://www.ik8s.io:10080"
Environment="NO_PROXY=127.0.0.0/8,172.10.0.0/16"
   systemctl daemon-reload
   systemctl start docker 
   docker info
   HTTPS Proxy: http://www.ik8s.io:10080
   No Proxy: 127.0.0.0/8,172.10.0.0/16
   Registry: https://index.docker.io/v1/
Labels:
#




7.Check
[root@k8s-1 ~]# cat /proc/sys/net/bridge/bridge-nf-call-iptables 
1
[root@k8s-1 ~]# cat /proc/sys/net/bridge/bridge-nf-call-ip6tables 
1
[root@k8s-1 ~]#
8.
[root@k8s-1 ~]# rpm -ql kubelet
/etc/kubernetes/manifests
/etc/sysconfig/kubelet
/etc/systemd/system/kubelet.service
/usr/bin/kubelet
[root@k8s-1 ~]# 
9.
[root@k8s-1 ~]# systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/etc/systemd/system/kubelet.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: activating (auto-restart) (Result: exit-code) since Sun 2019-02-03 21:51:44 CST; 139ms ago
     Docs: https://kubernetes.io/docs/
  Process: 3487 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS (code=exited, status=255)
 Main PID: 3487 (code=exited, status=255)

Feb 03 21:51:44 k8s-1 systemd[1]: Unit kubelet.service entered failed state.
Feb 03 21:51:44 k8s-1 systemd[1]: kubelet.service failed.
[root@k8s-1 ~]# 

10.[root@k8s-1 ~]# kubeadm init --help 
  -h, --help                                 help for init
      --ignore-preflight-errors strings      A list of checks whose errors will be shown as warnings. Example: 'IsPrivilegedUser,Swap'. Value 'all' ignores errors from all checks.
      --image-repository string              Choose a container registry to pull control plane images from (default "k8s.gcr.io")
      --kubernetes-version string            Choose a specific Kubernetes version for the control plane. (default "stable-1")
      --node-name string                     Specify the node name.
      --pod-network-cidr string              Specify range of IP addresses for the pod network. If set, the control plane will automatically allocate CIDRs for every node.
      --service-cidr string                  Use alternative range of IP address for service VIPs. (default "10.96.0.0/12")
      --service-dns-domain string            Use alternative domain for services, e.g. "myorg.internal". (default "cluster.local")
      --skip-phases strings                  List of phases to be skipped
      --skip-token-print                     Skip printing of the default bootstrap token generated by 'kubeadm init'.
      --token string                         The token to use for establishing bidirectional trust between nodes and masters. The format is [a-z0-9]{6}\.[a-z0-9]{16} - e.g. abcdef.0123456789abcdef
      --token-ttl duration                   The duration before the token is automatically deleted (e.g. 1s, 2m, 3h). If set to '0', the token will never expire (default 24h0m0s)

Global Flags:
      --log-file string   If non-empty, use this log file
      --rootfs string     [EXPERIMENTAL] The path to the 'real' host root filesystem.
      --skip-headers      If true, avoid header prefixes in the log messages
  -v, --v Level           log level for V logs

Use "kubeadm init [command] --help" for more information about a command.
[root@k8s-1 ~]# clear   


 kubeadm init --kubernetes-version=v1.12.0 --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --ignore-preflight-errors=Swap
[root@k8s-1 ~]# kubeadm init --ignore-preflight-errors=Swap
I0204 04:02:02.312201   93646 version.go:94] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get https://storage.googleapis.com/kubernetes-release/release/stable-1.txt: net/http: request canceled (Client.Timeout exceeded while awaiting headers)
I0204 04:02:02.312612   93646 version.go:95] falling back to the local client version: v1.13.3
[init] Using Kubernetes version: v1.13.3
[preflight] Running pre-flight checks
        [WARNING Swap]: running with swap on is not supported. Please disable swap
        [WARNING SystemVerification]: this Docker version is not on the list of validated versions: 18.09.0. Latest validated version: 18.06
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-apiserver:v1.13.3: output: Error response from daemon: Get https://k8s.gcr.io/v2/: unexpected EOF
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-controller-manager:v1.13.3: output: Error response from daemon: Get https://k8s.gcr.io/v2/: unexpected EOF
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-scheduler:v1.13.3: output: Error response from daemon: Get https://k8s.gcr.io/v2/: unexpected EOF
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/kube-proxy:v1.13.3: output: Error response from daemon: Get https://k8s.gcr.io/v2/: unexpected EOF
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/pause:3.1: output: Error response from daemon: Get https://k8s.gcr.io/v2/: unexpected EOF
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/etcd:3.2.24: output: Error response from daemon: Get https://k8s.gcr.io/v2/: unexpected EOF
, error: exit status 1
        [ERROR ImagePull]: failed to pull image k8s.gcr.io/coredns:1.2.6: output: Error response from daemon: Get https://k8s.gcr.io/v2/: unexpected EOF
, error: exit status 1


https://www.jianshu.com/p/824912d9afda

docker images:
dokcer pull k8s.gcr.io/kube-apiserver:v1.13.3
docker pull k8s.gcr.io/kube-controller-manager:v1.13.3
docker pull k8s.gcr.io/kube-scheduler:v1.13.3
docker pull k8s.gcr.io/kube-proxy:v1.13.3
docker pull k8s.gcr.io/pause:3.1
docker pull k8s.gcr.io/etcd:3.2.24
docker pull k8s.gcr.io/coredns:1.2.6

[root@host k8s-image]# docker save -o kube-controller-manager.tar k8s.gcr.io/kube-controller-manager:v1.13.3
[root@host k8s-image]# docker svae -o kube-apiserver.tar k8s.gcr.io/kube-apiserver:v1.13.3
[root@host k8s-image]# docker save -o kube-proxy.tar k8s.gcr.io/kube-proxy:v1.13.3
[root@host k8s-image]# docker save -o kube-scheduler.tar k8s.gcr.io/kube-scheduler:v1.13.3
[root@host k8s-image]# docker save -o coredns.tar k8s.gcr.io/coredns:1.2.6
[root@host k8s-image]# docker save -o etcd.tar k8s.gcr.io/etcd:3.2.24
[root@host k8s-image]# docker save -o pause.tar k8s.gcr.io/pause:3.1
[root@host k8s-image]# 
docker image ls 


docker tag 
Usage:  docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]
#实际上不用tag就ok！
[root@k8s-1 k8s-image]# docker load -i kube-controller-manager.tar
[root@k8s-1 k8s-image]# docker load -i kube-apiserver.tar
[root@k8s-1 k8s-image]# docker load -i kube-proxy.tar
[root@k8s-1 k8s-image]# docker load -i kube-scheduler.tar
[root@k8s-1 k8s-image]# docker load -i coredns.tar
[root@k8s-1 k8s-image]# docker load -i etcd.tar
[root@k8s-1 k8s-image]# docker load -i pause.tar


# vi /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS="--fail-swap-on=false"
systemctl restart kubelet
 
 
[root@k8s-1 ~]# kubeadm init  --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --ignore-preflight-errors=Swap 
I0204 06:01:50.942470   21076 version.go:94] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get https://storage.googleapis.com/kubernetes-release/release/stable-1.txt: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
I0204 06:01:50.942727   21076 version.go:95] falling back to the local client version: v1.13.3
[init] Using Kubernetes version: v1.13.3
[preflight] Running pre-flight checks
        [WARNING Swap]: running with swap on is not supported. Please disable swap
        [WARNING SystemVerification]: this Docker version is not on the list of validated versions: 18.09.0. Latest validated version: 18.06
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8s-1 localhost] and IPs [172.10.1.20 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8s-1 localhost] and IPs [172.10.1.20 127.0.0.1 ::1]
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s-1 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 172.10.1.20]
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[kubelet-check] Initial timeout of 40s passed.
[apiclient] All control plane components are healthy after 46.010804 seconds
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.13" in namespace kube-system with the configuration for the kubelets in the cluster
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "k8s-1" as an annotation
[mark-control-plane] Marking the node k8s-1 as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node k8s-1 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: synf3u.di3w9i8ctiumi7zs
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 172.10.1.20:6443 --token synf3u.di3w9i8ctiumi7zs --discovery-token-ca-cert-hash sha256:da003708913cbb502c343eca74fe7ea3e045f4df386a2c4337dbaf092cf73907


[root@k8s-1 ~]#kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
#&#10.
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

[root@k8s-1 ~]# kubectl get pods -o wide --all-namespaces --show-labels 
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE     IP            NODE    NOMINATED NODE   READINESS GATES   LABELS
kube-system   coredns-86c58d9df4-b4t8q        1/1     Running   0          5m46s   10.244.0.2    k8s-1   <none>           <none>            k8s-app=kube-dns,pod-template-hash=86c58d9df4
kube-system   coredns-86c58d9df4-wpglx        1/1     Running   0          5m46s   10.244.0.3    k8s-1   <none>           <none>            k8s-app=kube-dns,pod-template-hash=86c58d9df4
kube-system   etcd-k8s-1                      1/1     Running   0          5m17s   172.10.1.20   k8s-1   <none>           <none>            component=etcd,tier=control-plane
kube-system   kube-apiserver-k8s-1            1/1     Running   0          5m30s   172.10.1.20   k8s-1   <none>           <none>            component=kube-apiserver,tier=control-plane
kube-system   kube-controller-manager-k8s-1   1/1     Running   0          5m15s   172.10.1.20   k8s-1   <none>           <none>            component=kube-controller-manager,tier=control-plane
kube-system   kube-flannel-ds-amd64-s274z     1/1     Running   0          2m41s   172.10.1.20   k8s-1   <none>           <none>            app=flannel,controller-revision-hash=5ff48f8dc9,pod-template-generation=1,tier=node
kube-system   kube-proxy-zgdh8                1/1     Running   0          5m46s   172.10.1.20   k8s-1   <none>           <none>            controller-revision-hash=868d68f5df,k8s-app=kube-proxy,pod-template-generation=1
kube-system   kube-scheduler-k8s-1            1/1     Running   0          5m19s   172.10.1.20   k8s-1   <none>           <none>            component=kube-scheduler,tier=control-plane
[root@k8s-1 ~]# kubectl get nodes 
NAME    STATUS   ROLES    AGE     VERSION
k8s-1   Ready    master   6m15s   v1.13.3
[root@k8s-1 ~]# 

#======================================================================================================================================================================================================================================
Worker Node 
#======================================================================================================================================================================================================================================

1.https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.11.md#downloads-for-v1111

2.修改repo源：
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


3.确保SELINUX和IPtables没有开启。
[root@k8s-1 ~]# systemctl stop firewalld
[root@k8s-1 ~]# systemctl disable firewalld
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.
[root@k8s-1 ~]# 
#vi /etc/selinux/config 
[root@k8s-1 ~]# getenforce 
Permissive
[root@k8s-1 ~]# 

#vi /etc/sysctl.conf
net.ipv4.ip_forward = 1 
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1

4.
[root@k8s-1 ~]# vi /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

172.10.1.20  k8s-1
172.10.1.21  k8s-2

5.配置docker-ce
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum -y install docker-ce

systemctl daemon-reload
systemctl restart docker
systemctl enable docker
setenforce 0
yum install -y kubelet kubeadm kubectl
systemctl restart network
systemctl enable kubelet && systemctl restart kubelet
[root@k8s-2 ~]# 
[root@k8s-2 ~]# systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/etc/systemd/system/kubelet.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: activating (auto-restart) (Result: exit-code) since Mon 2019-02-04 06:45:00 CST; 918ms ago
     Docs: https://kubernetes.io/docs/
  Process: 11186 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS (code=exited, status=255)
 Main PID: 11186 (code=exited, status=255)

Feb 04 06:45:00 k8s-2 systemd[1]: Unit kubelet.service entered failed state.
Feb 04 06:45:00 k8s-2 systemd[1]: kubelet.service failed.

6.Check
[root@k8s-2 ~]#  cat /proc/sys/net/bridge/bridge-nf-call-iptables 
1
[root@k8s-2 ~]# cat /proc/sys/net/bridge/bridge-nf-call-ip6tables
1
[root@k8s-2 ~]# 

7.load kube-proxy 和 flannel IMAGE
[root@k8s-2 k8s-image]# docker load -i kube-proxy.tar 
[root@k8s-2 k8s-image]# docker load -i flannel.tar
[root@k8s-2 k8s-image]# docker load -i pause.tar




8.
vi /etc/sysconfig/kubelet 
# vi /etc/sysconfig/kubelet 
KUBELET_EXTRA_ARGS="--fail-swap-on=false"
systemctl restart kubelet
9.
[root@k8s-2 ~]# kubeadm join 172.10.1.20:6443 --token synf3u.di3w9i8ctiumi7zs --discovery-token-ca-cert-hash sha256:da003708913cbb502c343eca74fe7ea3e045f4df386a2c4337dbaf092cf73907 --ignore-preflight-errors=Swap
[preflight] Running pre-flight checks
        [WARNING Swap]: running with swap on is not supported. Please disable swap
        [WARNING SystemVerification]: this Docker version is not on the list of validated versions: 18.09.0. Latest validated version: 18.06
[preflight] Some fatal errors occurred:
        [ERROR FileAvailable--etc-kubernetes-kubelet.conf]: /etc/kubernetes/kubelet.conf already exists
        [ERROR FileAvailable--etc-kubernetes-bootstrap-kubelet.conf]: /etc/kubernetes/bootstrap-kubelet.conf already exists
        [ERROR Port-10250]: Port 10250 is in use
        [ERROR FileAvailable--etc-kubernetes-pki-ca.crt]: /etc/kubernetes/pki/ca.crt already exists
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
#[root@k8s-2 ~]# kubeadm reset
[reset] WARNING: changes made to this host by 'kubeadm init' or 'kubeadm join' will be reverted.
[reset] are you sure you want to proceed? [y/N]: y
[preflight] running pre-flight checks
[reset] no etcd config found. Assuming external etcd
[reset] please manually reset etcd to prevent further issues
[reset] stopping the kubelet service
[reset] unmounting mounted directories in "/var/lib/kubelet"
[reset] deleting contents of stateful directories: [/var/lib/kubelet /etc/cni/net.d /var/lib/dockershim /var/run/kubernetes]
[reset] deleting contents of config directories: [/etc/kubernetes/manifests /etc/kubernetes/pki]
[reset] deleting files: [/etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/bootstrap-kubelet.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf]

The reset process does not reset or clean up iptables rules or IPVS tables.
If you wish to reset iptables, you must do so manually.
For example: 
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

If your cluster was setup to utilize IPVS, run ipvsadm --clear (or similar)
to reset your system's IPVS tables.

[root@k8s-2 ~]# kubeadm join 172.10.1.20:6443 --token synf3u.di3w9i8ctiumi7zs --discovery-token-ca-cert-hash sha256:da003708913cbb502c343eca74fe7ea3e045f4df386a2c4337dbaf092cf73907 --ignore-preflight-errors=Swap
[preflight] Running pre-flight checks
        [WARNING Swap]: running with swap on is not supported. Please disable swap
        [WARNING SystemVerification]: this Docker version is not on the list of validated versions: 18.09.0. Latest validated version: 18.06
[discovery] Trying to connect to API Server "172.10.1.20:6443"
[discovery] Created cluster-info discovery client, requesting info from "https://172.10.1.20:6443"
[discovery] Requesting info from "https://172.10.1.20:6443" again to validate TLS against the pinned public key
[discovery] Cluster info signature and contents are valid and TLS certificate validates against pinned roots, will use API Server "172.10.1.20:6443"
[discovery] Successfully established connection with API Server "172.10.1.20:6443"
[join] Reading configuration from the cluster...
[join] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[kubelet] Downloading configuration for the kubelet from the "kubelet-config-1.13" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Activating the kubelet service
[tlsbootstrap] Waiting for the kubelet to perform the TLS Bootstrap...
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "k8s-2" as an annotation

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the master to see this node join the cluster.

[root@k8s-2 ~]# 







####OKOKOK#####
[root@k8s-1 ~]# kubectl get pods -o wide --all-namespaces --show-labels 
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE     IP            NODE    NOMINATED NODE   READINESS GATES   LABELS
kube-system   coredns-86c58d9df4-b4t8q        1/1     Running   0          69m     10.244.0.2    k8s-1   <none>           <none>            k8s-app=kube-dns,pod-template-hash=86c58d9df4
kube-system   coredns-86c58d9df4-wpglx        1/1     Running   0          69m     10.244.0.3    k8s-1   <none>           <none>            k8s-app=kube-dns,pod-template-hash=86c58d9df4
kube-system   etcd-k8s-1                      1/1     Running   0          68m     172.10.1.20   k8s-1   <none>           <none>            component=etcd,tier=control-plane
kube-system   kube-apiserver-k8s-1            1/1     Running   0          68m     172.10.1.20   k8s-1   <none>           <none>            component=kube-apiserver,tier=control-plane
kube-system   kube-controller-manager-k8s-1   1/1     Running   3          68m     172.10.1.20   k8s-1   <none>           <none>            component=kube-controller-manager,tier=control-plane
kube-system   kube-flannel-ds-amd64-qz8r7     1/1     Running   0          2m22s   172.10.1.21   k8s-2   <none>           <none>            app=flannel,controller-revision-hash=5ff48f8dc9,pod-template-generation=1,tier=node
kube-system   kube-flannel-ds-amd64-s274z     1/1     Running   0          66m     172.10.1.20   k8s-1   <none>           <none>            app=flannel,controller-revision-hash=5ff48f8dc9,pod-template-generation=1,tier=node
kube-system   kube-proxy-964h4                1/1     Running   0          2m22s   172.10.1.21   k8s-2   <none>           <none>            controller-revision-hash=868d68f5df,k8s-app=kube-proxy,pod-template-generation=1
kube-system   kube-proxy-zgdh8                1/1     Running   0          69m     172.10.1.20   k8s-1   <none>           <none>            controller-revision-hash=868d68f5df,k8s-app=kube-proxy,pod-template-generation=1
kube-system   kube-scheduler-k8s-1            1/1     Running   2          68m     172.10.1.20   k8s-1   <none>           <none>            component=kube-scheduler,tier=control-plane
[root@k8s-1 ~]# kubectl get cs 
kNAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok                   
scheduler            Healthy   ok                   
etcd-0               Healthy   {"health": "true"}   
[root@k8s-1 ~]# kubectl get nodes 
NAME    STATUS   ROLES    AGE    VERSION
k8s-1   Ready    master   69m    v1.13.3
k8s-2   Ready    <none>   3m1s   v1.13.3
[root@k8s-1 ~]#


##########DNS###############
DNS
bash-4.4# nslookup httpd-svc 10.244.0.3
Server:    10.244.0.3
Address 1: 10.244.0.3 10-244-0-3.kube-dns.kube-system.svc.cluster.local

Name:      httpd-svc
Address 1: 10.102.91.167 httpd-svc.default.svc.cluster.local



kernel:NMI watchdog: BUG: soft lockup - CPU#1 stuck for 57s! [docker:1123]

#======================================================================================================================================================================================================================================
Install Helm
#======================================================================================================================================================================================================================================
1.下载对应包：https://storage.googleapis.com/kubernetes-helm/helm-v2.10.0-linux-amd64.tar.gz
2. tar -xzvf helm-v2.10.0-linux-amd64.tar.gz
3.mv linux-amd64/helm /usr/local/bin/helm
4.helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.10.0 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts 
5. kubectl -n kube-system get pods|grep tiller
6.kubectl create serviceaccount --namespace kube-system tiller
7. kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
8.kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
9.helm list 

#[root@k8s-1 ~]# helm version
Client: &version.Version{SemVer:"v2.10.0", GitCommit:"9ad53aac42165a5fadc6c87be0dea6b115f93090", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.10.0", GitCommit:"9ad53aac42165a5fadc6c87be0dea6b115f93090", GitTreeState:"clean"}

#[root@k8s-1 ~]# kubectl get pods -o wide -n=kube-system 
NAME                             READY   STATUS    RESTARTS   AGE     IP            NODE    NOMINATED NODE   READINESS GATES
coredns-86c58d9df4-b4t8q         1/1     Running   3          3d8h    10.244.0.12   k8s-1   <none>           <none>
coredns-86c58d9df4-wpglx         1/1     Running   3          3d8h    10.244.0.14   k8s-1   <none>           <none>
etcd-k8s-1                       1/1     Running   3          3d8h    172.10.1.20   k8s-1   <none>           <none>
kube-apiserver-k8s-1             1/1     Running   3          3d8h    172.10.1.20   k8s-1   <none>           <none>
kube-controller-manager-k8s-1    1/1     Running   9          3d8h    172.10.1.20   k8s-1   <none>           <none>
kube-flannel-ds-amd64-6mdrr      1/1     Running   2          2d15h   172.10.1.20   k8s-1   <none>           <none>
kube-flannel-ds-amd64-qz8r7      1/1     Running   1          3d7h    172.10.1.21   k8s-2   <none>           <none>
kube-proxy-964h4                 1/1     Running   1          3d7h    172.10.1.21   k8s-2   <none>           <none>
kube-proxy-zgdh8                 1/1     Running   3          3d8h    172.10.1.20   k8s-1   <none>           <none>
kube-scheduler-k8s-1             1/1     Running   8          3d8h    172.10.1.20   k8s-1   <none>           <none>
tiller-deploy-74b58df7d4-kcncx   1/1     Running   0          59m     10.244.0.15   k8s-1   <none>           <none>   ##Tiller##
[root@k8s-1 ~]# 

#======================================================================================================================================================================================================================================

[root@k8s-1 ~]# kubectl get all --all-namespaces -o wide  | grep httpd
default       pod/httpd-8c6c4bd9b-c25tg              1/1     Running   0          80m     10.244.1.8    k8s-2   <none>           <none>

default       service/httpd-svc       ClusterIP      10.102.91.167   <none>        8080/TCP        3d8h   run=httpd


default       deployment.apps/httpd                  1/1     1            1           3d8h   httpd         httpd                                                                run=httpd

default       replicaset.apps/httpd-8c6c4bd9b        1       1            1           3d8h   httpd         httpd                                                                pod-template-hash=8c6c4bd9b,run=httpd
[root@k8s-1 ~]#
#Eg：Deployment_Pod=Deploy + replicaset + Pod_Random
     httpd-8c6c4bd9b-c25tg = httpd + httpd-8c6c4bd9b + httpd-8c6c4bd9b-c25tg
#======================================================================================================================================================================================================================================

#2.使用tgz包直接安装。
[root@k8s-1 ~]# helm fetch bitnami/nginx
nginx-2.1.3.tgz
[root@k8s-1 ~]# helm install -name nginx nginx-2.1.3.tgz
[root@k8s-1 ~]# helm list 
NAME    REVISION        UPDATED                         STATUS          CHART           APP VERSION     NAMESPACE
nginx   1               Thu Feb  7 15:14:22 2019        DEPLOYED        nginx-2.1.3     1.14.2          default  
[root@k8s-1 ~]# 
[root@k8s-1 ~]# helm list 
NAME    REVISION        UPDATED                         STATUS          CHART           APP VERSION     NAMESPACE
nginx   1               Thu Feb  7 15:14:22 2019        DEPLOYED        nginx-2.1.3     1.14.2          default  
[root@k8s-1 ~]# 
[root@k8s-1 ~]# helm ls --all
NAME                    REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
billowing-squirrel      1               Thu Feb  7 15:10:42 2019        DELETED         bitnami-common-0.0.5    0.0.1           default  
loping-peahen           1               Thu Feb  7 13:57:56 2019        DELETED         mysql-0.3.5                             default  
melting-turtle          1               Thu Feb  7 15:08:10 2019        DELETED         consul-4.0.1            1.4.2           default  
nginx                   1               Thu Feb  7 15:14:22 2019        DEPLOYED        nginx-2.1.3             1.14.2          default  #####DEPLOYED#####
piquant-chicken         1               Thu Feb  7 14:18:15 2019        DELETED         nginx-2.1.3             1.14.2          default  
trendy-chipmunk         1               Thu Feb  7 15:02:41 2019        DELETED         mongodb-5.3.2           4.0.6           default  
unsung-puma             1               Thu Feb  7 15:11:36 2019        DELETED         nginx-2.1.3             1.14.2          default  
[root@k8s-1 ~]#

#3.
#======================================================================================================================================================================================================================================
Deploy Kubernetes Dashboard
Dashboard Version:
v1.10.1
Git Commit:
50d59e985dfd97863a2f5ab5396ae049a2bb87d0 
#======================================================================================================================================================================================================================================
#原本kubernetes-dashboard.yaml文件中，有创建serviceaccount和clusterrolebinding 的template。
[root@k8s-1 ~]# kubectl get secret -n=kube-system | grep dashboard
dashboard-admin-token-v75xg                      kubernetes.io/service-account-token   3      14m
kubernetes-dashboard-certs                       Opaque                                0      39m
kubernetes-dashboard-csrf                        Opaque                                1      39m
kubernetes-dashboard-key-holder                  Opaque                                2      76m
kubernetes-dashboard-token-4sbvz                 kubernetes.io/service-account-token   3      39m

[root@k8s-1 ~]# kubectl create serviceaccount dashboard-admin -n kube-system
serviceaccount/dashboard-admin created
[root@k8s-1 ~]# kubectl get secret -n=kube-system | grep dashboard
dashboard-admin-token-v75xg                      kubernetes.io/service-account-token   3      14m
kubernetes-dashboard-certs                       Opaque                                0      39m
kubernetes-dashboard-csrf                        Opaque                                1      39m
kubernetes-dashboard-key-holder                  Opaque                                2      76m
kubernetes-dashboard-token-4sbvz                 kubernetes.io/service-account-token   3      39m
[root@k8s-1 ~]# kubectl create clusterrolebinding cluster-dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
clusterrolebinding.rbac.authorization.k8s.io/cluster-dashboard-admin created
[root@k8s-1 ~]# kubectl get clusterrolebinding -n=kube-system 
NAME                                                   AGE
cluster-admin                                          3d12h
cluster-dashboard-admin                                19m
flannel                                                3d12h
kubeadm:kubelet-bootstrap                              3d12h
kubeadm:node-autoapprove-bootstrap                     3d12h
kubeadm:node-autoapprove-certificate-rotation          3d12h
kubeadm:node-proxier                                   3d12h
system:aws-cloud-provider                              3d12h
system:basic-user                                      3d12h
system:controller:attachdetach-controller              3d12h
system:controller:certificate-controller               3d12h
system:controller:clusterrole-aggregation-controller   3d12h
system:controller:cronjob-controller                   3d12h
system:controller:daemon-set-controller                3d12h
system:controller:deployment-controller                3d12h
system:controller:disruption-controller                3d12h
system:controller:endpoint-controller                  3d12h
system:controller:expand-controller                    3d12h
system:controller:generic-garbage-collector            3d12h
system:controller:horizontal-pod-autoscaler            3d12h
system:controller:job-controller                       3d12h
system:controller:namespace-controller                 3d12h
system:controller:node-controller                      3d12h
system:controller:persistent-volume-binder             3d12h
system:controller:pod-garbage-collector                3d12h
system:controller:pv-protection-controller             3d12h
system:controller:pvc-protection-controller            3d12h
system:controller:replicaset-controller                3d12h
system:controller:replication-controller               3d12h
system:controller:resourcequota-controller             3d12h
system:controller:route-controller                     3d12h
system:controller:service-account-controller           3d12h
system:controller:service-controller                   3d12h
system:controller:statefulset-controller               3d12h
system:controller:ttl-controller                       3d12h
system:coredns                                         3d12h
system:discovery                                       3d12h
system:kube-controller-manager                         3d12h
system:kube-dns                                        3d12h
system:kube-scheduler                                  3d12h
system:node                                            3d12h
system:node-proxier                                    3d12h
system:volume-scheduler                                3d12h
tiller-cluster-rule                                    4h50m
#修改SVC为NodePort的模式。
[root@k8s-1 ~]# kubectl patch svc kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}' -n kube-system
service/kubernetes-dashboard patched

[root@k8s-1 ~]# 
https://www.cnblogs.com/dingbin/p/9801013.html


[root@k8s-1 ~]# kubectl get secret -n=kube-system | grep admin 
dashboard-admin-token-v75xg                      kubernetes.io/service-account-token   3      3m4s
[root@k8s-1 ~]# 
[root@k8s-1 ~]# 
[root@k8s-1 ~]# 
[root@k8s-1 ~]# 
[root@k8s-1 ~]# kubectl describe secret dashboard-admin-token-v75xg -n=kube-system 
Name:         dashboard-admin-token-v75xg
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: dashboard-admin
              kubernetes.io/service-account.uid: 826f925a-2ac1-11e9-a4d4-000c2950df72

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1025 bytes
namespace:  11 bytes
token:   //###//dashboard的登录界面的使用的Token//   eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJkYXNoYm9hcmQtYWRtaW4tdG9rZW4tdjc1eGciLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGFzaGJvYXJkLWFkbWluIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiODI2ZjkyNWEtMmFjMS0xMWU5LWE0ZDQtMDAwYzI5NTBkZjcyIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmUtc3lzdGVtOmRhc2hib2FyZC1hZG1pbiJ9.lJO9b-JvojHtMioZ2BBeNDROhp_eSC6WJeL_GCUZk5SkI2h2DHTcxB7JjO6cS2buJ9MAZz7RbjQ602-xaVxUVkX2Q_G4ju2umR--TZk-iota_fOetPcudAmZpE3AfhAtgnAEhE7lU7PpTQhB7vw3-AymPuKjMhy_FtSEgGBsYWb3e3eDI60Px31Y-WnZf_BAtWOosbBKs7Owz1FEDvsC1TT2frhkU30Jos4P6v7JYwjis8hfRDVYJxwoPGjG6DKV6orODAmrbjM4AgRWBL98KFaNT91Y2sgyKiU1TyG_DklmDUq5qUO8moY8Bw-SYe3WS0ageOeLgeApuGdE2xJdwg
[root@k8s-1 ~]# 

Dashboard Version:
v1.10.1
Git Commit:
50d59e985dfd97863a2f5ab5396ae049a2bb87d0 




4.监控 Weave-scope：
#======================================================================================================================================================================================================================================
Deploy Weave-scope
Currently only Heapster integration is supported, however there are plans to introduce integration framework to Dashboard. It will allow to support and integrate more metric providers as well as additional applications such as Weave Scope or Grafana.
#Refer URL：https://www.weave.works/docs/scope/latest/installing/#k8s
#======================================================================================================================================================================================================================================
docker load -i weave.tar

https://segmentfault.com/a/1190000013383594
改svc以  Cluster IP为NodePort形式：
kubectl patch svc kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}' -n weave
#======================================================================================================================================================================================================================================


5.etcd
#======================================================================================================================================================================================================================================
Deploy ETCD
Refer：https://github.com/etcd-io/etcd/tree/master/hack/kubernetes-deploy
[root@k8s-1 ~]# kubectl get pods -o wide | grep etcd
etcd0                              1/1     Running   0          28m     10.244.1.32   k8s-2   <none>           <none>
etcd1                              1/1     Running   0          28m     10.244.0.53   k8s-1   <none>           <none>
etcd2                              1/1     Running   0          28m     10.244.1.31   k8s-2   <none>           <none>

[root@k8s-1 ~]# kubectl exec -it etcd2 sh 

VERSION:
        3.3.8
#etcdctl server的版本为：3.3.8
#默认情况下，etcdctl使用v2 API与etcd服务器通信以实现向后兼容。要让etcdctl使用v3 API与etcd对话，必须通过ETCDCTL_API环境变量将API版本设置为版本3 。
export ETCDCTL_API=3
/ # etcdctl version
etcdctl version: 3.3.8
API version: 3.3
/ # 
/ # etcdctl member list 
ade526d28b1f92f7: name=etcd1 peerURLs=http://etcd1:2380 clientURLs=http://etcd1:2379 isLeader=false
cf1d15c5d194b5c9: name=etcd0 peerURLs=http://etcd0:2380 clientURLs=http://etcd0:2379 isLeader=false
d282ac2ce600c1ce: name=etcd2 peerURLs=http://etcd2:2380 clientURLs=http://etcd2:2379 isLeader=true     ####etcd-2 is Leader @####

/ # etcdctl endpoint health
127.0.0.1:2379 is healthy: successfully committed proposal: took = 6.922546ms
/ # 
/ # etcdctl endpoint status
127.0.0.1:2379, d282ac2ce600c1ce, 3.3.8, 20 kB, false, 61, 11




#IMAGE
image：quay.io/coreos/etcd                                          latest              61ad63875109        7 months ago        39.5MB
yaml文件：etcd-latest for test etcd.yml
[root@k8s-1 ~]# kubectl apply -f etcd-latest\ for\ test\ etcd.yml 
service/etcd-client unchanged
pod/etcd0 created
service/etcd0 created
pod/etcd1 created
service/etcd1 created
pod/etcd2 created
service/etcd2 created
[root@k8s-1 ~]# kubectl get pods -o wide 
#SVC
[root@k8s-1 ~]# kubectl get svc 
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
etcd-client   ClusterIP   10.97.188.238    <none>        2379/TCP            35m
etcd0         ClusterIP   10.107.215.230   <none>        2379/TCP,2380/TCP   33m
etcd1         ClusterIP   10.100.178.20    <none>        2379/TCP,2380/TCP   33m
etcd2         ClusterIP   10.105.91.183    <none>        2379/TCP,2380/TCP   33m

#### Description For benchmark of etcd 
Start 3-member etcd cluster on 3 machines
Update $leader and $servers in the script
Run the script in a separate machine
####
#!/bin/bash -e

leader=http://localhost:2379
# assume three servers
servers=( http://localhost:2379 http://localhost:22379 http://localhost:32379 )

keyarray=( 64 256 )

for keysize in ${keyarray[@]}; do

  echo write, 1 client, $keysize key size, to leader
  ./hey -m PUT -n 10 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 1 -T application/x-www-form-urlencoded $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

  echo write, 64 client, $keysize key size, to leader
  ./hey -m PUT -n 640 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 64 -T application/x-www-form-urlencoded $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

  echo write, 256 client, $keysize key size, to leader
  ./hey -m PUT -n 2560 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 256 -T application/x-www-form-urlencoded $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

  echo write, 64 client, $keysize key size, to all servers
  for i in ${servers[@]}; do
    ./hey -m PUT -n 210 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 21 -T application/x-www-form-urlencoded $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
  done
  # wait for all heys to start running
  sleep 3
  # wait for all heys to finish
  for pid in $(pgrep 'hey'); do
    while kill -0 "$pid" 2> /dev/null; do
      sleep 3
    done
  done

  echo write, 256 client, $keysize key size, to all servers
  for i in ${servers[@]}; do
    ./hey -m PUT -n 850 -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 85 -T application/x-www-form-urlencoded $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
  done
  sleep 3
  for pid in $(pgrep 'hey'); do
    while kill -0 "$pid" 2> /dev/null; do
      sleep 3
    done
  done

  echo read, 1 client, $keysize key size, to leader
  ./hey -n 100 -c 1 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

  echo read, 64 client, $keysize key size, to leader
  ./hey -n 6400 -c 64 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

  echo read, 256 client, $keysize key size, to leader
  ./hey -n 25600 -c 256 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

  echo read, 64 client, $keysize key size, to all servers
  # bench servers one by one, so it doesn't overload this benchmark machine
  # It doesn't impact correctness because read request doesn't involve peer interaction.
  for i in ${servers[@]}; do
    ./hey -n 21000 -c 21 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo
  done

  echo read, 256 client, $keysize key size, to all servers
  for i in ${servers[@]}; do
    ./hey -n 85000 -c 85 $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo
  done

done

#======================================================================================================================================================================================================================================

6.istio

kubectl delete crd adapters.config.istio.io                
kubectl delete crd apikeys.config.istio.io                 
kubectl delete crd attributemanifests.config.istio.io      
kubectl delete crd authorizations.config.istio.io          
kubectl delete crd bypasses.config.istio.io                
kubectl delete crd checknothings.config.istio.io           
kubectl delete crd circonuses.config.istio.io              
kubectl delete crd deniers.config.istio.io                 
kubectl delete crd destinationrules.networking.istio.io    
kubectl delete crd edges.config.istio.io                   
kubectl delete crd envoyfilters.networking.istio.io        
kubectl delete crd fluentds.config.istio.io                
kubectl delete crd gateways.networking.istio.io            
kubectl delete crd handlers.config.istio.io                
kubectl delete crd httpapispecbindings.config.istio.io     
kubectl delete crd httpapispecs.config.istio.io            
kubectl delete crd instances.config.istio.io               
kubectl delete crd kubernetesenvs.config.istio.io          
kubectl delete crd kuberneteses.config.istio.io            
kubectl delete crd listcheckers.config.istio.io            
kubectl delete crd listentries.config.istio.io             
kubectl delete crd logentries.config.istio.io              
kubectl delete crd memquotas.config.istio.io               
kubectl delete crd metrics.config.istio.io                 
kubectl delete crd noops.config.istio.io                   
kubectl delete crd opas.config.istio.io                    
kubectl delete crd prometheuses.config.istio.io            
kubectl delete crd quotas.config.istio.io                  
kubectl delete crd quotaspecbindings.config.istio.io       
kubectl delete crd quotaspecs.config.istio.io              
kubectl delete crd rbacconfigs.rbac.istio.io               
kubectl delete crd rbacs.config.istio.io                   
kubectl delete crd redisquotas.config.istio.io             
kubectl delete crd reportnothings.config.istio.io          
kubectl delete crd rules.config.istio.io                   
kubectl delete crd servicecontrolreports.config.istio.io   
kubectl delete crd servicecontrols.config.istio.io         
kubectl delete crd serviceentries.networking.istio.io      
kubectl delete crd servicerolebindings.rbac.istio.io       
kubectl delete crd serviceroles.rbac.istio.io              
kubectl delete crd signalfxs.config.istio.io               
kubectl delete crd solarwindses.config.istio.io            
kubectl delete crd stackdrivers.config.istio.io            
kubectl delete crd statsds.config.istio.io                 
kubectl delete crd stdios.config.istio.io                  
kubectl delete crd templates.config.istio.io               
kubectl delete crd tracespans.config.istio.io              
kubectl delete crd virtualservices.networking.istio.io     
kubectl get  crd 

kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml

[root@k8s-1 istio-1.0.6]# helm install install/kubernetes/helm/istio --name istio --namespace istio-system
NAME:   istio
LAST DEPLOYED: Wed Feb 20 11:44:45 2019
NAMESPACE: istio-system
STATUS: DEPLOYED

RESOURCES:
==> v1alpha3/Gateway
NAME                             AGE
istio-autogenerated-k8s-ingress  31s

==> v1alpha2/kubernetesenv
handler  25s

==> v1alpha2/prometheus
handler  22s

==> v1/ConfigMap
NAME                             DATA  AGE
istio-galley-configuration       1     33s
istio-statsd-prom-bridge         1     33s
prometheus                       1     33s
istio-security-custom-resources  2     33s
istio                            1     33s
istio-sidecar-injector           1     33s

==> v1/ServiceAccount
NAME                                    SECRETS  AGE
istio-galley-service-account            1        33s
istio-ingressgateway-service-account    1        33s
istio-egressgateway-service-account     1        33s
istio-mixer-service-account             1        33s
istio-pilot-service-account             1        33s
prometheus                              1        33s
istio-security-post-install-account     1        33s
istio-citadel-service-account           1        33s
istio-sidecar-injector-service-account  1        33s

==> v1/Service
NAME                    TYPE          CLUSTER-IP      EXTERNAL-IP  PORT(S)                                                                                                                  AGE
istio-galley            ClusterIP     10.105.148.64   <none>       443/TCP,9093/TCP                                                                                                         33s
istio-egressgateway     ClusterIP     10.102.24.123   <none>       80/TCP,443/TCP                                                                                                           33s
istio-ingressgateway    LoadBalancer  10.99.193.254   <pending>    80:31380/TCP,443:31390/TCP,31400:31400/TCP,15011:31660/TCP,8060:30824/TCP,853:31662/TCP,15030:32679/TCP,15031:32077/TCP  33s
istio-policy            ClusterIP     10.99.221.188   <none>       9091/TCP,15004/TCP,9093/TCP                                                                                              33s
istio-telemetry         ClusterIP     10.103.224.190  <none>       9091/TCP,15004/TCP,9093/TCP,42422/TCP                                                                                    33s
istio-pilot             ClusterIP     10.103.76.193   <none>       15010/TCP,15011/TCP,8080/TCP,9093/TCP                                                                                    33s
prometheus              ClusterIP     10.108.85.65    <none>       9090/TCP                                                                                                                 33s
istio-citadel           ClusterIP     10.96.61.121    <none>       8060/TCP,9093/TCP                                                                                                        33s
istio-sidecar-injector  ClusterIP     10.105.84.238   <none>       443/TCP                                                                                                                  33s

==> v1alpha3/DestinationRule
NAME             AGE
istio-policy     32s
istio-telemetry  32s

==> v1beta1/Deployment
NAME                    DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
istio-galley            1        1        1           0          33s
istio-ingressgateway    1        1        1           1          33s
istio-egressgateway     1        1        1           0          33s
istio-policy            1        1        1           1          33s
istio-telemetry         1        1        1           0          33s
istio-pilot             1        1        1           0          33s
prometheus              1        1        1           1          32s
istio-citadel           1        1        1           1          32s
istio-sidecar-injector  1        1        1           0          32s

==> v1alpha2/attributemanifest
NAME        AGE
kubernetes  25s
istioproxy  25s

==> v1alpha2/logentry
tcpaccesslog  24s
accesslog     24s

==> v1alpha2/metric
tcpbytesent      24s
requestduration  24s
responsesize     24s
requestsize      24s
requestcount     24s
tcpbytereceived  24s

==> v1beta1/ClusterRole
istio-galley-istio-system                 33s
istio-ingressgateway-istio-system         33s
istio-egressgateway-istio-system          33s
istio-mixer-istio-system                  33s
istio-pilot-istio-system                  33s
prometheus-istio-system                   33s
istio-citadel-istio-system                33s
istio-security-post-install-istio-system  33s
istio-sidecar-injector-istio-system       33s

==> v1beta1/ClusterRoleBinding
NAME                                                    AGE
istio-galley-admin-role-binding-istio-system            33s
istio-ingressgateway-istio-system                       33s
istio-egressgateway-istio-system                        33s
istio-mixer-admin-role-binding-istio-system             33s
istio-pilot-istio-system                                33s
prometheus-istio-system                                 33s
istio-citadel-istio-system                              33s
istio-security-post-install-role-binding-istio-system   33s
istio-sidecar-injector-admin-role-binding-istio-system  33s

==> v1beta1/MutatingWebhookConfiguration
NAME                    AGE
istio-sidecar-injector  26s

==> v1alpha2/kubernetes
attributes  25s

==> v2beta1/HorizontalPodAutoscaler
NAME                  REFERENCE                        TARGETS        MINPODS  MAXPODS  REPLICAS  AGE
istio-ingressgateway  Deployment/istio-ingressgateway  <unknown>/80%  1        5        1         31s
istio-egressgateway   Deployment/istio-egressgateway   <unknown>/80%  1        5        1         27s
istio-policy          Deployment/istio-policy          <unknown>/80%  1        5        1         26s
istio-telemetry       Deployment/istio-telemetry       <unknown>/80%  1        5        1         26s
istio-pilot           Deployment/istio-pilot           <unknown>/80%  1        5        1         26s

==> v1alpha2/rule
NAME                    AGE
promtcp                 21s
stdio                   20s
promhttp                20s
tcpkubeattrgenrulerule  20s
stdiotcp                20s
kubeattrgenrulerule     19s

==> v1alpha2/stdio
handler  19s

==> v1/Pod(related)
NAME                                     READY  STATUS             RESTARTS  AGE
istio-galley-685bb48846-bbt8p            0/1    ContainerCreating  0         32s
istio-ingressgateway-5b64fffc9f-fh75p    1/1    Running            0         32s
istio-egressgateway-6d79447874-rgb56     0/1    ContainerCreating  0         32s
istio-policy-547d64b8d7-5wzhw            2/2    Running            0         32s
istio-telemetry-c5488fc49-r7k8j          0/2    ContainerCreating  0         32s
istio-pilot-8645f5655b-6dq2s             1/2    Running            0         32s
prometheus-76b7745b64-sm585              1/1    Running            0         31s
istio-citadel-6f444d9999-zjxdt           1/1    Running            0         32s
istio-sidecar-injector-5d8dd9448d-k9zbn  0/1    ContainerCreating  0         31s


[root@k8s-1 istio-1.0.6]# 


@###
For More Infoormation:BurlyLuo:<olaf.luo@foxmail.com>
