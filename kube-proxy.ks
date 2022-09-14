kube-proxy service是一组pod的服务抽象，相当于一组pod的LB，负责将请求分发给对应的pod。service会为这个LB提供一个IP，一般称为cluster IP。
kube-proxy的作用主要是负责service的实现，具体来说，就是实现了内部从pod到service和外部的从node port向service的访问。
举个例子，现在有podA，podB，podC和serviceAB。serviceAB是podA，podB的服务抽象(service)。
那么kube-proxy的作用就是可以将pod(不管是podA，podB或者podC)向serviceAB的请求，进行转发到service所代表的一个具体pod(podA或者podB)上。
请求的分配方法一般分配是采用轮询方法进行分配。
另外，kubernetes还提供了一种在node节点上暴露一个端口，从而提供从外部访问service的方式。
比如我们使用这样的一个manifest来创建service
apiVersion: v1
kind: Service
metadata:  labels:    name: mysql
    role: service
  name: mysql-service
spec:  ports:    - port: 3306      targetPort: 3306      nodePort: 30964  type: NodePort
  selector:    mysql-service: "true"
他的含义是在node上暴露出30964端口。当访问node上的30964端口时，其请求会转发到service对应的cluster IP的3306端口，并进一步转发到pod的3306端口。
kuer-proxy目前有userspace和iptables两种实现方式。
userspace是在用户空间，通过kuber-proxy实现LB的代理服务。这个是kube-proxy的最初的版本，较为稳定，但是效率也自然不太高。
另外一种方式是iptables的方式。是纯采用iptables来实现LB。是目前一般kube默认的方式。
userspace这里具体举个例子，以ssh-service1为例，kube为其分配了一个clusterIP。分配clusterIP的作用还是如上文所说，是方便pod到service的数据访问。
[minion@te-yuab6awchg-0-z5nlezoa435h-kube-master-udhqnaxpu5op ~]$ kubectl get service
NAME             LABELS                                    SELECTOR              IP(S)            PORT(S)
kubernetes       component=apiserver,provider=kubernetes   <none>                10.254.0.1       443/TCP
ssh-service1     name=ssh,role=service                     ssh-service=true      10.254.132.107   2222/TCP
使用describe可以查看到详细信息。可以看到暴露出来的NodePort端口30239。
[minion@te-yuab6awchg-0-z5nlezoa435h-kube-master-udhqnaxpu5op ~]$ kubectl describe service ssh-service1 
Name:           ssh-service1
Namespace:      defaultLabels:         name=ssh,role=service
Selector:       ssh-service=trueType:           LoadBalancer
IP:         10.254.132.107Port:           <unnamed>   2222/TCP
NodePort:       <unnamed>   30239/TCP
Endpoints:      <none>
Session Affinity:   None
No events.
nodePort的工作原理与clusterIP大致相同，是发送到node上指定端口的数据，通过iptables重定向到kube-proxy对应的端口上。然后由kube-proxy进一步把数据发送到其中的一个pod上。
该node的ip为10.0.0.5
[minion@te-yuab6awchg-0-z5nlezoa435h-kube-master-udhqnaxpu5op ~]$ sudo iptables -S -t nat
...
-A KUBE-NODEPORT-CONTAINER -p tcp -m comment --comment "default/ssh-service1:" -m tcp --dport 30239 -j REDIRECT --to-ports 36463
-A KUBE-NODEPORT-HOST -p tcp -m comment --comment "default/ssh-service1:" -m tcp --dport 30239 -j DNAT --to-destination 10.0.0.5:36463
-A KUBE-PORTALS-CONTAINER -d 10.254.132.107/32 -p tcp -m comment --comment "default/ssh-service1:" -m tcp --dport 2222 -j REDIRECT --to-ports 36463
-A KUBE-PORTALS-HOST -d 10.254.132.107/32 -p tcp -m comment --comment "default/ssh-service1:" -m tcp --dport 2222 -j DNAT --to-destination 10.0.0.5:36463
可以看到访问node时候的30239端口会被转发到node上的36463端口。而且在访问clusterIP 10.254.132.107的2222端口时，也会把请求转发到本地的36463端口。
36463端口实际被kube-proxy所监听，将流量进行导向到后端的pod上。
iptablesiptables的方式则是利用了linux的iptables的nat转发进行实现。在本例中，创建了名为mysql-service的service。
apiVersion: v1
kind: Service
metadata:  labels:    name: mysql
    role: service
  name: mysql-service
spec:  ports:    - port: 3306      targetPort: 3306      nodePort: 30964  type: NodePort
  selector:    mysql-service: "true"
mysql-service对应的nodePort暴露出来的端口为30964，对应的cluster IP(10.254.162.44)的端口为3306，进一步对应于后端的pod的端口为3306。
mysql-service后端代理了两个pod，ip分别是192.168.125.129和192.168.125.131。先来看一下iptables。
[root@localhost ~]# iptables -S -t nat...-A PREROUTING -m comment --comment "kubernetes service portals" -j KUBE-SERVICES
-A OUTPUT -m comment --comment "kubernetes service portals" -j KUBE-SERVICES
-A POSTROUTING -m comment --comment "kubernetes postrouting rules" -j KUBE-POSTROUTING
-A KUBE-MARK-MASQ -j MARK --set-xmark 0x4000/0x4000
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/mysql-service:" -m tcp --dport 30964 -j KUBE-MARK-MASQ
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/mysql-service:" -m tcp --dport 30964 -j KUBE-SVC-67RL4FN6JRUPOJYM
-A KUBE-SEP-ID6YWIT3F6WNZ47P -s 192.168.125.129/32 -m comment --comment "default/mysql-service:" -j KUBE-MARK-MASQ
-A KUBE-SEP-ID6YWIT3F6WNZ47P -p tcp -m comment --comment "default/mysql-service:" -m tcp -j DNAT --to-destination 192.168.125.129:3306
-A KUBE-SEP-IN2YML2VIFH5RO2T -s 192.168.125.131/32 -m comment --comment "default/mysql-service:" -j KUBE-MARK-MASQ
-A KUBE-SEP-IN2YML2VIFH5RO2T -p tcp -m comment --comment "default/mysql-service:" -m tcp -j DNAT --to-destination 192.168.125.131:3306
-A KUBE-SERVICES -d 10.254.162.44/32 -p tcp -m comment --comment "default/mysql-service: cluster IP" -m tcp --dport 3306 -j KUBE-SVC-67RL4FN6JRUPOJYM
-A KUBE-SERVICES -m comment --comment "kubernetes service nodeports; NOTE: this must be the last rule in this chain" -m addrtype --dst-type LOCAL -j KUBE-NODEPORTS
-A KUBE-SVC-67RL4FN6JRUPOJYM -m comment --comment "default/mysql-service:" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-ID6YWIT3F6WNZ47P
-A KUBE-SVC-67RL4FN6JRUPOJYM -m comment --comment "default/mysql-service:" -j KUBE-SEP-IN2YML2VIFH5RO2T
下面来逐条分析
首先如果是通过node的30964端口访问，则会进入到以下链
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/mysql-service:" -m tcp --dport 30964 -j KUBE-MARK-MASQ
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/mysql-service:" -m tcp --dport 30964 -j KUBE-SVC-67RL4FN6JRUPOJYM
然后进一步跳转到KUBE-SVC-67RL4FN6JRUPOJYM的链
-A KUBE-SVC-67RL4FN6JRUPOJYM -m comment --comment "default/mysql-service:" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-ID6YWIT3F6WNZ47P
-A KUBE-SVC-67RL4FN6JRUPOJYM -m comment --comment "default/mysql-service:" -j KUBE-SEP-IN2YML2VIFH5RO2T
这里利用了iptables的--probability的特性，使连接有50%的概率进入到KUBE-SEP-ID6YWIT3F6WNZ47P链，50%的概率进入到KUBE-SEP-IN2YML2VIFH5RO2T链。
KUBE-SEP-ID6YWIT3F6WNZ47P的链的具体作用就是将请求通过DNAT发送到192.168.125.129的3306端口。
-A KUBE-SEP-ID6YWIT3F6WNZ47P -s 192.168.125.129/32 -m comment --comment "default/mysql-service:" -j KUBE-MARK-MASQ
-A KUBE-SEP-ID6YWIT3F6WNZ47P -p tcp -m comment --comment "default/mysql-service:" -m tcp -j DNAT --to-destination 192.168.125.129:3306
同理KUBE-SEP-IN2YML2VIFH5RO2T的作用是通过DNAT发送到192.168.125.131的3306端口。
-A KUBE-SEP-IN2YML2VIFH5RO2T -s 192.168.125.131/32 -m comment --comment "default/mysql-service:" -j KUBE-MARK-MASQ
-A KUBE-SEP-IN2YML2VIFH5RO2T -p tcp -m comment --comment "default/mysql-service:" -m tcp -j DNAT --to-destination 192.168.125.131:3306
分析完nodePort的工作方式，接下里说一下clusterIP的访问方式。
对于直接访问cluster IP(10.254.162.44)的3306端口会直接跳转到KUBE-SVC-67RL4FN6JRUPOJYM。
-A KUBE-SERVICES -d 10.254.162.44/32 -p tcp -m comment --comment "default/mysql-service: cluster IP" -m tcp --dport 3306 -j KUBE-SVC-67RL4FN6JRUPOJYM
接下来的跳转方式同上文，这里就不再赘述了。

[root@cbam-2475aa56d4a44907889bf9d2058-oam-node-1 ~]# kubectl get svc -o wide --show-labels
NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE       SELECTOR       LABELS
gluster-service   ClusterIP   10.254.88.34   <none>        1/TCP     15d       name=gluster   <none>
kubernetes        ClusterIP   10.254.0.1     <none>        443/TCP   15d       <none>         component=apiserver,provider=kubernetes

# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: 2018-06-25T10:20:22Z
  name: gluster-service
  namespace: default
  resourceVersion: "1703"
  selfLink: /api/v1/namespaces/default/services/gluster-service
  uid: 5e679d04-7861-11e8-aa2d-fa163e7f1375
spec:
  clusterIP: 10.254.88.34
  ports:
  - port: 1
    protocol: TCP
    targetPort: 1
  selector:
    name: gluster
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
[root@cbam-2475aa56d4a44907889bf9d2058-oam-node-1 ~]# kubectl get node --show-labels
NAME            STATUS    ROLES     AGE       VERSION   LABELS
172.24.16.103   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-oam-node-3,nodeindex=3,nodename=oam3,nodetype=oam
172.24.16.104   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-oam-node-2,nodeindex=2,nodename=oam2,nodetype=oam
172.24.16.105   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-oam-node-1,nodeindex=1,nodename=oam1,nodetype=oam
172.24.16.106   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-storage-node-0,nodeindex=0,nodename=storage0,nodetype=storage
172.24.16.107   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-storage-node-1,nodeindex=1,nodename=storage1,nodetype=storage
172.24.16.108   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-storage-node-2,nodeindex=2,nodename=storage2,nodetype=storage
172.24.16.109   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-spfe-node-0,nodeindex=0,nodename=spfe0,nodetype=spfe
172.24.16.110   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-ccf-node-0,nodeindex=0,nodename=ccf0,nodetype=ccf
172.24.16.111   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-amc-node-0,nodeindex=0,nodename=amc0,nodetype=amc
172.24.16.112   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-gls-node-0,nodeindex=0,nodename=gls0,nodetype=gls
172.24.16.113   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-rtdb-node-1,nodeindex=1,nodename=rtdb1,nodetype=rtdb
172.24.16.114   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-rtdb-node-0,nodeindex=0,nodename=rtdb0,nodetype=rtdb
172.24.16.115   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-rtdb-node-2,nodeindex=2,nodename=rtdb2,nodetype=rtdb
172.24.16.116   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-scfe-node-0,nodeindex=0,nodename=scfe0,nodetype=scfe
172.24.16.117   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-prs-node-0,nodeindex=0,nodename=prs0,nodetype=prs
172.24.16.118   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-tafe-node-0,nodeindex=0,nodename=tafe0,nodetype=tafe
172.24.16.119   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-db-node-0,nodeindex=0,nodename=db0,nodetype=db
172.24.16.120   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-db-node-1,nodeindex=1,nodename=db1,nodetype=db
172.24.16.121   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-db-node-2,nodeindex=2,nodename=db2,nodetype=db
172.24.16.122   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-vlr-node-0,nodeindex=0,nodename=vlr0,nodetype=vlr
172.24.16.123   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-admintd-node-1,nodeindex=1,nodename=admintd1,nodetype=admintd
172.24.16.124   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-admintd-node-0,nodeindex=0,nodename=admintd0,nodetype=admintd
172.24.16.125   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-ss7-node-0,nodeindex=0,nodename=ss70,nodetype=ss7
172.24.16.126   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-ss7-node-1,nodeindex=1,nodename=ss71,nodetype=ss7
172.24.16.127   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-smd-node-1,nodeindex=1,nodename=smd1,nodetype=smd
172.24.16.128   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-smd-node-3,nodeindex=3,nodename=smd3,nodetype=smd
172.24.16.129   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-smd-node-2,nodeindex=2,nodename=smd2,nodetype=smd
172.24.16.130   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-dtd-node-1,nodeindex=1,nodename=dtd1,nodetype=dtd
172.24.16.131   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-dtd-node-4,nodeindex=4,nodename=dtd4,nodetype=dtd
172.24.16.132   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-smd-node-0,nodeindex=0,nodename=smd0,nodetype=smd
172.24.16.133   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-dtd-node-5,nodeindex=5,nodename=dtd5,nodetype=dtd
172.24.16.134   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-smd-node-4,nodeindex=4,nodename=smd4,nodetype=smd
172.24.16.135   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-dtd-node-0,nodeindex=0,nodename=dtd0,nodetype=dtd
172.24.16.136   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-dtd-node-2,nodeindex=2,nodename=dtd2,nodetype=dtd
172.24.16.137   Ready     <none>    15d       v1.8.7    nodehost=cbam-2475aa56d4a44907889bf9d2058d50e7-dtd-node-3,nodeindex=3,nodename=dtd3,nodetype=dtd
[root@cbam-2475aa56d4a44907889bf9d2058-oam-node-1 ~]# kubectl edit svc gluster-service
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: 2018-06-25T10:20:22Z
  name: gluster-service
  namespace: default
  resourceVersion: "1703"
  selfLink: /api/v1/namespaces/default/services/gluster-service
  uid: 5e679d04-7861-11e8-aa2d-fa163e7f1375
spec:
  clusterIP: 10.254.88.34
  ports:
  - port: 1
    protocol: TCP
    targetPort: 1
  selector:
    name: gluster
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
另外一种方式是iptables方式（如下图）。是纯采用iptables来实现LB。在K8S1.2版本之后，kube-proxy默认方式。所有转发都是通过Iptables内核模块实现，而kube-proxy只负责生成相应的Iptables规则。
-A KUBE-SEP-CMDU25RDLJFTQIMH -s 172.24.16.108/32 -m comment --comment "default/gluster-service:" -j KUBE-MARK-MASQ
-A KUBE-SEP-CMDU25RDLJFTQIMH -p tcp -m comment --comment "default/gluster-service:" -m tcp -j DNAT --to-destination 172.24.16.108:1
-A KUBE-SEP-MZYLMF257Z6LKLEA -s 172.24.16.106/32 -m comment --comment "default/gluster-service:" -j KUBE-MARK-MASQ
-A KUBE-SEP-MZYLMF257Z6LKLEA -p tcp -m comment --comment "default/gluster-service:" -m tcp -j DNAT --to-destination 172.24.16.106:1
-A KUBE-SEP-TBCD2UHN4FDJGAYC -s 172.24.16.107/32 -m comment --comment "default/gluster-service:" -j KUBE-MARK-MASQ
-A KUBE-SEP-TBCD2UHN4FDJGAYC -p tcp -m comment --comment "default/gluster-service:" -m tcp -j DNAT --to-destination 172.24.16.107:1
-A KUBE-SERVICES -d 10.254.88.34/32 -p tcp -m comment --comment "default/gluster-service: cluster IP" -m tcp --dport 1 -j KUBE-MARK-MASQ
-A KUBE-SERVICES -d 10.254.88.34/32 -p tcp -m comment --comment "default/gluster-service: cluster IP" -m tcp --dport 1 -j KUBE-SVC-6CXSSDROPYFKV77T
-A KUBE-SVC-6CXSSDROPYFKV77T -m comment --comment "default/gluster-service:" -m statistic --mode random --probability 0.33332999982 -j KUBE-SEP-MZYLMF257Z6LKLEA
-A KUBE-SVC-6CXSSDROPYFKV77T -m comment --comment "default/gluster-service:" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-TBCD2UHN4FDJGAYC
-A KUBE-SVC-6CXSSDROPYFKV77T -m comment --comment "default/gluster-service:" -j KUBE-SEP-CMDU25RDLJFTQIMH



先看一个例子：
iptables -S -t nat | grep zookeeper1
-A KUBE-SEP-BZJZKIUQRVYJVMQB -s 10.0.45.4/32 -m comment --comment "default/zookeeper1:3" -j KUBE-MARK-MASQ
-A KUBE-SEP-BZJZKIUQRVYJVMQB -p tcp -m comment --comment "default/zookeeper1:3" -m tcp -j DNAT --to-destination 10.0.45.4:3888
-A KUBE-SEP-C3J2QHMJ3LTD3GR7 -s 10.0.45.4/32 -m comment --comment "default/zookeeper1:2" -j KUBE-MARK-MASQ
-A KUBE-SEP-C3J2QHMJ3LTD3GR7 -p tcp -m comment --comment "default/zookeeper1:2" -m tcp -j DNAT --to-destination 10.0.45.4:2888
-A KUBE-SEP-RZ4H7H2HFI3XFCXZ -s 10.0.45.4/32 -m comment --comment "default/zookeeper1:1" -j KUBE-MARK-MASQ
-A KUBE-SEP-RZ4H7H2HFI3XFCXZ -p tcp -m comment --comment "default/zookeeper1:1" -m tcp -j DNAT --to-destination 10.0.45.4:2181
-A KUBE-SERVICES -d 10.254.181.6/32 -p tcp -m comment --comment "default/zookeeper1:1 cluster IP" -m tcp --dport 2181 -j KUBE-SVC-HHEJUKXW5P7DV7BX
-A KUBE-SERVICES -d 10.254.181.6/32 -p tcp -m comment --comment "default/zookeeper1:2 cluster IP" -m tcp --dport 2888 -j KUBE-SVC-2SVOYTXLXAXVV7L3
-A KUBE-SERVICES -d 10.254.181.6/32 -p tcp -m comment --comment "default/zookeeper1:3 cluster IP" -m tcp --dport 3888 -j KUBE-SVC-KAVJ7GO67HRSOAM3
-A KUBE-SVC-2SVOYTXLXAXVV7L3 -m comment --comment "default/zookeeper1:2" -j KUBE-SEP-C3J2QHMJ3LTD3GR7
-A KUBE-SVC-HHEJUKXW5P7DV7BX -m comment --comment "default/zookeeper1:1" -j KUBE-SEP-RZ4H7H2HFI3XFCXZ
-A KUBE-SVC-KAVJ7GO67HRSOAM3 -m comment --comment "default/zookeeper1:3" -j KUBE-SEP-BZJZKIUQRVYJVMQB
解释：
从iptables的规则来看，对目的ip是10.254.181.6，端口是2181、2888或者3888的消息，规则指向了KUBE-SVC-HHEJUKXW5P7DV7BX、KUBE-SVC-2SVOYTXLXAXVV7L3、KUBE-SVC-KAVJ7GO67HRSOAM3，他们三又分别指向了KUBE-SEP-C3J2QHMJ3LTD3GR7、KUBE-SEP-RZ4H7H2HFI3XFCXZ、KUBE-SEP-BZJZKIUQRVYJVMQB，这三条规则定义了DNAT转换规则，将访问重定向到了10.0.45.4:3888、10.0.45.4:2888、10.0.45.4:2181
https://xuxinkun.github.io/2016/07/22/kubernetes-proxy/
