kubernetes 之 StatefulSet
背景：
StatefulSet是为了解决有状态服务的问题（对应Deployments和ReplicaSets是为无状态服务而设计），其应用场景包括：
- 稳定的持久化存储，即Pod重新调度后还是能访问到相同的持久化数据，基于PVC来实现
- 稳定的网络标志，即Pod重新调度后其PodName和HostName不变，基于Headless Service（即没有Cluster IP的Service）来实现
- 有序部署，有序扩展，即Pod是有顺序的，在部署或者扩展的时候要依据定义的顺序依次依次进行（即从0到N-1，在下一个Pod运行之前所有之前的Pod必须都是Running和Ready状态），基于init containers来实现
- 有序收缩，有序删除（即从N-1到0）
先给一个Demo：
[root@k8s-1 statefulset]# less nginx-svc-pod.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: gcr.io/google_containers/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
[root@k8s-1 statefulset]#
现在对这个yaml文件做一个说明：
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
//这里引用了一个叫：volumeClaimTemplates字段：//其实和定义pvc的模板比较相似，标识了对pv的一个需求//
[root@k8s-1 statefulset]# kubectl explain sts.spec.volumeClaimTemplates.spec
KIND:     StatefulSet
VERSION:  apps/v1

RESOURCE: spec <Object>

DESCRIPTION:
     Spec defines the desired characteristics of a volume requested by a pod
     author. More info:
     https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims

     PersistentVolumeClaimSpec describes the common attributes of storage
     devices and allows a Source for provider-specific attributes

FIELDS:
   accessModes  <[]string>
     AccessModes contains the desired access modes the volume should have. More
     info:
     https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes-1

   dataSource   <Object>
     This field requires the VolumeSnapshotDataSource alpha feature gate to be
     enabled and currently VolumeSnapshot is the only supported data source. If
     the provisioner can support VolumeSnapshot data source, it will create a
     new volume and data will be restored to the volume at the same time. If the
     provisioner does not support VolumeSnapshot data source, volume will not be
     created and the failure will be reported as an event. In the future, we
     plan to support more data source types and the behavior of the provisioner
     may change.

   resources    <Object>
     Resources represents the minimum resources the volume should have. More
     info:
     https://kubernetes.io/docs/concepts/storage/persistent-volumes#resources

   selector     <Object>
     A label query over volumes to consider for binding.

   storageClassName     <string>
     Name of the StorageClass required by the claim. More info:
     https://kubernetes.io/docs/concepts/storage/persistent-volumes#class-1

   volumeMode   <string>
     volumeMode defines what type of volume is required by the claim. Value of
     Filesystem is implied when not included in claim spec. This is a beta
     feature.

   volumeName   <string>
     VolumeName is the binding reference to the PersistentVolume backing this
     claim.

[root@k8s-1 statefulset]#  
1.查看sts 的pod相关的信息。
[root@k8s-1 statefulset]# kubectl get sts -l app=nginx -o wide //查看pods情况.//
NAME   READY   AGE   CONTAINERS   IMAGES
web    3/3     58m   nginx        gcr.io/google_containers/nginx-slim:0.8
[root@k8s-1 statefulset]# kubectl get pods  -l app=nginx -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP             NODE    NOMINATED NODE   READINESS GATES
web-0   1/1     Running   0          58m   10.244.1.175   k8s-2   <none>           <none>
web-1   1/1     Running   0          52m   10.244.0.86    k8s-1   <none>           <none>
web-2   1/1     Running   0          52m   10.244.1.176   k8s-2   <none>           <none>
[root@k8s-1 statefulset]#

[root@k8s-1 statefulset]# kubectl get pv -o wide   //pv是使用nfs创建的//
NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM               STORAGECLASS   REASON   AGE
pv01   2Gi        RWO,RWX        Retain           Available                                               63m
pv02   5Gi        RWO            Retain           Bound       default/www-web-0                           63m
pv03   20Gi       RWO,RWX        Retain           Bound       default/www-web-2                           63m
pv04   10Gi       RWO,RWX        Retain           Released    default/www-web-1                           63m
pv05   10Gi       RWO,RWX        Retain           Bound       default/www-web-1                           63m
pv06   1Gi        RWO,RWX        Retain           Available                                               63m
pv07   1Gi        RWO,RWX        Retain           Available                                               63m
[root@k8s-1 statefulset]# kubectl get pvc -o wide //三个pods对应三个pvc//
NAME        STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
www-web-0   Bound    pv02     5Gi        RWO                           63m
www-web-1   Bound    pv05     10Gi       RWO,RWX                       57m
www-web-2   Bound    pv03     20Gi       RWO,RWX                       57m
[root@k8s-1 statefulset]#
[root@k8s-1 statefulset]# kubectl get svc -l app=nginx -o wide  //对应创建出来的svc//
NAME    TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE   SELECTOR
nginx   ClusterIP   None         <none>        80/TCP    73m   app=nginx  //这里使用的是HeadLess模式的service，这也是sts类型的controller的特色//
[root@k8s-1 statefulset]#
2.查看dns解析结果。
bash-4.4# nslookup web-0.nginx       //解析对象为：pod_name.svc_name//  
nslookup: can't resolve '(null)': Name does not resolve

Name:      web-0.nginx
Address 1: 10.244.1.175 web-0.nginx.default.svc.cluster.local
bash-4.4#

bash-4.4# nslookup web-1.nginx
nslookup: can't resolve '(null)': Name does not resolve

Name:      web-1.nginx
Address 1: 10.244.0.86 web-1.nginx.default.svc.cluster.local
bash-4.4#

bash-4.4# nslookup nginx   //解析对象为：svc本身，返回的是三个pods的地址//    
nslookup: can't resolve '(null)': Name does not resolve

Name:      nginx
Address 1: 10.244.1.176 web-2.nginx.default.svc.cluster.local
Address 2: 10.244.0.86 web-1.nginx.default.svc.cluster.local
Address 3: 10.244.1.175 web-0.nginx.default.svc.cluster.local
bash-4.4#  

3.实现文件持久存储。
由于使用的是nfs的存储，所以需要对应的看pod和pv的绑定关系，以及和volume的映射关系。这点尤为重要。[因为涉及到这个是nfs类型的存储，一会你要到哪一个volume的对应的文件的]
比如：
[root@k8s-1 ~]#
[root@k8s-1 ~]# kubectl get pods -o wide | grep web-1  
web-1                           1/1     Running   0          82m     10.244.0.86    k8s-1   <none>           <none>
[root@k8s-1 ~]#
[root@k8s-1 ~]# kubectl get pv -o wide | grep web-1| grep -v Released  //pod web-1是和pv05绑定的//
pv05   10Gi       RWO,RWX        Retain           Bound       default/www-web-1                           90m
[root@k8s-1 ~]#
[root@k8s-1 ~]# kubectl describe pv pv05  //查看pv05是和volume ：data/volumes/v5绑定。//
Name:            pv05
Labels:          name=pv05
Annotations:     kubectl.kubernetes.io/last-applied-configuration:
                   {"apiVersion":"v1","kind":"PersistentVolume","metadata":{"annotations":{},"labels":{"name":"pv05"},"name":"pv05"},"spec":{"accessModes":["...
                 pv.kubernetes.io/bound-by-controller: yes
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:   
Status:          Bound
Claim:           default/www-web-1
Reclaim Policy:  Retain
Access Modes:    RWO,RWX
VolumeMode:      Filesystem
Capacity:        10Gi
Node Affinity:   <none>
Message:         
Source:
    Type:      NFS (an NFS mount that lasts the lifetime of a pod)
    Server:    172.12.1.20
    Path:      /data/volumes/v5
    ReadOnly:  false
Events:        <none>
[root@k8s-1 ~]#
所以我们在web-1的pod中创建一个文件：
[root@k8s-1 statefulset]# kubectl exec -it web-1 bash   //在web-1的pod中创建一个文件//
root@web-1:/usr/share/nginx/html#  echo "This is a sts Test!" >>index.html
root@web-1:/usr/share/nginx/html# ls
index.html
root@web-1:/usr/share/nginx/html#

然后到对应的nfs server查看：
[root@localhost volumes]# cd v5/
[root@localhost v5]# ls
index.html
[root@localhost v5]# less index.html
This is a sts Test!
[root@localhost v5]#

For More information:
Please refer zookeeper:
https://github.com/kubernetes/contrib/tree/master/statefulsets/zookeeper


For More Information：BurlyLuo <olaf.luo@foxmail.com>

